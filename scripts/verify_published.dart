// Installs a published version of `nepdate` and `nepdate_patro` from pub.dev the way a user does,
// and checks it.
//
//   dart run scripts/verify_published.dart latest --resolve    print the newest version
//   dart run scripts/verify_published.dart 0.2.0-rc.1 --metadata
//   dart run scripts/verify_published.dart 0.2.0-rc.1 --install
//
// `--resolve` prints only the version, for a workflow output. `--metadata` checks the registry
// listing and both archive URLs with HEAD requests, so it downloads nothing. `--install` creates a
// clean project in the system temp directory, resolves the exact versions, and runs one conversion,
// one parse and one patro lookup.

import 'dart:convert';
import 'dart:io';

Never _fail(String message) {
  stderr.writeln('verify-published: $message');
  exit(1);
}

final HttpClient _client = HttpClient()..connectionTimeout = const Duration(seconds: 30);

Future<Map<String, Object?>> _json(String url) async {
  final request = await _client.getUrl(Uri.parse(url));
  request.headers.set('User-Agent', 'nepdate-verify-published');
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) _fail('$url answered ${response.statusCode}: $body');
  return jsonDecode(body) as Map<String, Object?>;
}

Future<int> _head(String url) async {
  final request = await _client.headUrl(Uri.parse(url));
  request.headers.set('User-Agent', 'nepdate-verify-published');
  final response = await request.close();
  await response.drain<void>();
  return response.statusCode;
}

Future<String> _latest() async {
  final body = await _json('https://pub.dev/api/packages/nepdate');
  final latest = body['latest'];
  if (latest is! Map<String, Object?>) _fail('nepdate has no latest version');
  final version = latest['version'];
  if (version is! String) _fail('nepdate latest has no version');
  return version;
}

Future<void> _metadata(String version) async {
  for (final package in ['nepdate', 'nepdate_patro']) {
    final body = await _json('https://pub.dev/api/packages/$package');
    final versions = body['versions'];
    if (versions is! List<Object?>) _fail('$package has no versions');
    final found = versions.any(
      (entry) => entry is Map<String, Object?> && entry['version'] == version,
    );
    if (!found) _fail('$package $version is not listed');
    final status = await _head('https://pub.dev/api/archives/$package-$version.tar.gz');
    if (status != 200) _fail('$package $version archive answered $status');
    stdout.writeln('$package $version: listed, archive HTTP 200');
  }
}

Future<int> _run(String executable, List<String> arguments, String directory) async {
  stdout.writeln(r'$ ' + [executable, ...arguments].join(' '));
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: directory,
    runInShell: false,
  );
  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);
  return process.exitCode;
}

Future<void> _install(String version) async {
  final directory = Directory.systemTemp.createTempSync('nepdate-published-');
  try {
    File('${directory.path}/pubspec.yaml').writeAsStringSync('''
name: nepdate_published_check
publish_to: none

environment:
  sdk: ^3.6.0

dependencies:
  nepdate: $version
  nepdate_patro: $version
''');
    Directory('${directory.path}/bin').createSync();
    File('${directory.path}/bin/main.dart').writeAsStringSync(r'''
import 'package:nepdate/nepdate.dart';
import 'package:nepdate_patro/nepdate_patro.dart';

void main() {
  final date = NepaliDate.fromBs(2081, 4, 15);
  if (date.toJson() != '2081-04-15') {
    throw StateError('toJson gave ${date.toJson()}');
  }
  if (date.toDateTime().toIso8601String() != '2024-07-30T00:00:00.000Z') {
    throw StateError('toDateTime gave ${date.toDateTime()}');
  }
  if (NepaliDate.parse('2081/04/15') != date) {
    throw StateError('parse gave a different date');
  }
  if (NepaliDate.fromYmd(date.ymd) != date) {
    throw StateError('fromYmd gave a different date');
  }
  if (date.addMonths(2).toJson() != '2081-06-30') {
    throw StateError('addMonths gave ${date.addMonths(2)}');
  }
  if (date.toLongString(weekday: true) != 'Tuesday, Shrawan 15, 2081') {
    throw StateError('toLongString gave ${date.toLongString(weekday: true)}');
  }
  final day = info(NepaliDate.fromBs(2081, 2, 15));
  if (!day.isPublicHoliday || day.tithi?.english != 'Panchami') {
    throw StateError('patro lookup gave $day');
  }
  if (day.events.single.english != 'Republic Day') {
    throw StateError('events gave ${day.events}');
  }
  final range = coverage();
  if (range.start.toJson() != '2077-01-01') {
    throw StateError('coverage starts at ${range.start}');
  }
  print('verified $date, ${day.tithi?.english}, ${range.start}');
}
''');
    final get = await _run(Platform.resolvedExecutable, ['pub', 'get'], directory.path);
    if (get != 0) _fail('dart pub get exited with $get');
    final run = await _run(
      Platform.resolvedExecutable,
      ['run', 'bin/main.dart'],
      directory.path,
    );
    if (run != 0) _fail('the installed example exited with $run');
    if (!File('${directory.path}/pubspec.lock').existsSync()) {
      _fail('dart pub get wrote no lockfile');
    }
  } finally {
    try {
      directory.deleteSync(recursive: true);
    } on FileSystemException {
      // A Windows file handle can outlive the process for a moment; the temp directory is cleaned
      // by the runner later.
    }
  }
}

Future<void> main(List<String> arguments) async {
  String? version;
  var resolve = false;
  var metadata = false;
  var install = false;
  for (final argument in arguments) {
    switch (argument) {
      case '--resolve':
        resolve = true;
      case '--metadata':
        metadata = true;
      case '--install':
        install = true;
      default:
        if (version != null) _fail('two versions given: $version and $argument');
        version = argument;
    }
  }
  if (!resolve && !metadata && !install) install = true;
  try {
    final resolved = version == null || version == 'latest' ? await _latest() : version;
    if (resolve) {
      stdout.writeln(resolved);
      return;
    }
    stdout.writeln('verify-published: $resolved');
    if (metadata) await _metadata(resolved);
    if (install) await _install(resolved);
  } finally {
    _client.close(force: true);
  }
}
