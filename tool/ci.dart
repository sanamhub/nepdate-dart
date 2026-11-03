// Runs every gate in order and stops at the first failure. Run from the repository root:
//
//   dart run tool/ci.dart
//
// The last line is the summary. A gate is never skipped: a missing tool or a missing file fails the
// run, so a green local run means the same thing as a green CI run.

import 'dart:convert';
import 'dart:io';

const _packages = ['packages/nepdate', 'packages/nepdate_patro'];
const _core = 'packages/nepdate';
const _minimumCoverage = 90.0;

/// The event name that would make a real release fail if it appeared in the core package.
const _eventSentinel = 'World Day Against Human Trafficking';

Never _fail(String message) {
  stderr.writeln('ci: $message');
  exit(1);
}

String get _dart => Platform.resolvedExecutable;

ProcessResult _run(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  bool quiet = false,
}) {
  final printable = [executable, ...arguments].join(' ');
  stdout.writeln(r'$ ' + printable);
  final result = Process.runSync(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: false,
  );
  final out = '${result.stdout}'.trim();
  final err = '${result.stderr}'.trim();
  if (!quiet && out.isNotEmpty) stdout.writeln(out);
  if (err.isNotEmpty) stderr.writeln(err);
  if (result.exitCode != 0) {
    _fail('$printable exited with ${result.exitCode}');
  }
  return result;
}

void _format() {
  // The generated tables are written by tool/generate.dart and compared byte for byte by its
  // --check mode; the formatter would rewrite them, so they are not part of this gate.
  final files = <String>[];
  for (final entity in Directory.current.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (path.contains('/.dart_tool/') || path.endsWith('.g.dart')) continue;
    files.add(path);
  }
  files.sort();
  _run(_dart, ['format', '--output=none', '--set-exit-if-changed', ...files]);
}

void _analyze() {
  _run(_dart, ['analyze', '--fatal-infos', '.']);
}

void _generate() {
  _run(_dart, ['run', 'tool/generate.dart', '--check']);
}

void _tests() {
  _run(_dart, ['test', ..._packages]);
}

double _coverage(String packageDir) {
  final covDir = '$packageDir/.dart_tool/coverage';
  _run(
    _dart,
    ['test', '--coverage=${File(covDir).absolute.path}', '--reporter=compact'],
    workingDirectory: packageDir,
    quiet: true,
  );
  final lcov = '${File(covDir).absolute.path}/lcov.info';
  _run(_dart, [
    'run',
    'coverage:format_coverage',
    '--lcov',
    '--in=${File(covDir).absolute.path}',
    '--out=$lcov',
    '--packages=${File('.dart_tool/package_config.json').absolute.path}',
    '--report-on=${File('$packageDir/lib').absolute.path}',
  ], quiet: true);
  var hit = 0;
  var found = 0;
  for (final line in File(lcov).readAsLinesSync()) {
    if (!line.startsWith('DA:')) continue;
    final parts = line.substring(3).split(',');
    found++;
    if (int.parse(parts[1]) > 0) hit++;
  }
  if (found == 0) _fail('coverage: $packageDir has no executable lines');
  final percent = 100.0 * hit / found;
  stdout.writeln('coverage $packageDir: $hit/$found lines, ${percent.toStringAsFixed(2)}%');
  return percent;
}

void _checkCoverage() {
  for (final packageDir in _packages) {
    final percent = _coverage(packageDir);
    if (percent < _minimumCoverage) {
      _fail('coverage of $packageDir is ${percent.toStringAsFixed(2)}%, below $_minimumCoverage%');
    }
  }
}

void _dependencyAge() {
  _run(_dart, ['run', 'tool/check_dependency_age.dart']);
}

void _docs() {
  _run(_dart, ['run', 'tool/check_docs.dart']);
}

void _coreIsolation() {
  final manifest = File('$_core/pubspec.yaml').readAsStringSync();
  if (manifest.contains('nepdate_patro')) _fail('$_core/pubspec.yaml names nepdate_patro');
  for (final file in Directory('$_core/lib').listSync(recursive: true).whereType<File>()) {
    final text = file.readAsStringSync();
    if (text.contains('package:nepdate_patro')) {
      _fail('${file.path} imports or links to the patro package');
    }
    if (text.contains(_eventSentinel)) _fail('${file.path} contains patro event data');
  }
  stdout.writeln('core lib/ imports no patro package and holds no patro event data');

  // A compiled program that imports only the core must not carry the patro data either.
  final program = File('.dart_tool/core_isolation.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
import 'package:nepdate/nepdate.dart';

void main() {
  final date = NepaliDate.fromBs(2081, 4, 15);
  print(date.toLongString());
}
''');
  final executable = File('.dart_tool/core_isolation.exe');
  _run(_dart, ['compile', 'exe', program.path, '-o', executable.path], quiet: true);
  final bytes = executable.readAsBytesSync();
  final sentinel = utf8.encode(_eventSentinel);
  if (_indexOf(bytes, sentinel) >= 0) {
    _fail('the compiled core program contains patro event data');
  }
  stdout.writeln('compiled core program holds no patro event data (${bytes.length} bytes)');
}

int _indexOf(List<int> haystack, List<int> needle) {
  outer:
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}

void main(List<String> arguments) {
  final started = DateTime.now();
  stdout.writeln('ci: ${Platform.resolvedExecutable}');
  _format();
  _analyze();
  _generate();
  _tests();
  _checkCoverage();
  _dependencyAge();
  _docs();
  _coreIsolation();
  final elapsed = DateTime.now().difference(started);
  stdout.writeln(
    'ci: all gates passed in ${elapsed.inSeconds}s '
    '(format, analyze, generate --check, tests, coverage $_minimumCoverage%, '
    'dependency age, docs examples, core isolation)',
  );
}
