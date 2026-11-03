// Runs every Dart example in the README, docs/API.md and the library doc comments, and compares
// each `// =>` line with the value the expression produces. Run from the repository root:
//
//   dart run tool/check_docs.dart
//
// Every example is compiled into one generated program and its assertions run in a closure, so a
// declaration in one example cannot collide with the same name in another. A `// =>` comment is
// mandatory only where the example shows a result; an example without one still has to compile and
// run. The prose is checked at the same time: no em dashes, and every relative link resolves.

import 'dart:convert';
import 'dart:io';

const _resultMarker = '// =>';
const _docs = <String>[
  'README.md',
  'packages/nepdate/README.md',
  'packages/nepdate_patro/README.md',
  'docs/API.md',
  'docs/benchmarks.md',
  'docs/competitors.md',
  'docs/runbooks/release.md',
];

Never _fail(String message) {
  stderr.writeln('docs: $message');
  exit(1);
}

class Snippet {
  Snippet(this.label, this.code);

  final String label;
  final String code;
}

class Chunk {
  Chunk.code(this.lines)
      : expression = null,
        expected = null;

  Chunk.expect(this.expression, this.expected) : lines = const <String>[];

  final List<String> lines;
  final String? expression;
  final String? expected;

  bool get isExpression => expression != null;
}

/// The ```dart blocks of a Markdown file.
List<Snippet> _markdownSnippets(String path, String text) {
  final snippets = <Snippet>[];
  final lines = const LineSplitter().convert(text);
  String? label;
  final code = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (label == null && line.trim() == '```dart') {
      label = '$path:${i + 1}';
      code.clear();
    } else if (label != null && line.trim() == '```') {
      snippets.add(Snippet(label, code.join('\n')));
      label = null;
    } else if (label != null) {
      code.add(line);
    }
  }
  if (label != null) _fail('$path: unclosed ```dart block at $label');
  return snippets;
}

/// The ```dart blocks inside the `///` doc comment blocks of a source file.
List<Snippet> _docSnippets(String path) {
  final snippets = <Snippet>[];
  final lines = File(path).readAsLinesSync();
  var block = <String>[];
  var blockLine = 0;

  void flush() {
    if (block.isEmpty) return;
    var inFence = false;
    var fence = <String>[];
    for (var i = 0; i < block.length; i++) {
      final line = block[i];
      if (!inFence && line.trim() == '```dart') {
        inFence = true;
        fence = <String>[];
      } else if (inFence && line.trim() == '```') {
        snippets.add(Snippet('$path:${blockLine + i}', fence.join('\n')));
        inFence = false;
      } else if (inFence) {
        fence.add(line);
      }
    }
    if (inFence) _fail('$path: unclosed doc example after line $blockLine');
    block = <String>[];
  }

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('///')) {
      if (block.isEmpty) blockLine = i + 1;
      var text = trimmed.substring(3);
      if (text.startsWith(' ')) text = text.substring(1);
      block.add(text);
    } else {
      flush();
    }
  }
  flush();
  return snippets;
}

/// Splits an example into statements, keeping a `// =>` result with the expression it describes.
///
/// A statement ends at a semicolon outside braces, or at a closing brace. A marker on its own line
/// belongs to the statement before it; a marker inside a block (a `try` or `if`) stays in place and
/// is rewritten where it is.
List<Chunk> _chunks(String code) {
  final lines = const LineSplitter().convert(code);
  final chunks = <Chunk>[];
  var current = <String>[];
  var depth = 0;

  void flush() {
    if (current.isEmpty) return;
    final text = current.join('\n');
    final hasMarker = text.contains(_resultMarker);
    final expected = _expectedOf(text);
    if (hasMarker && expected != null && _isExpressionStatement(text)) {
      chunks.add(Chunk.expect(_expressionOf(text), expected));
    } else {
      chunks.add(Chunk.code(current));
    }
    current = <String>[];
  }

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      flush();
      continue;
    }
    if (trimmed.startsWith('//') && !trimmed.startsWith(_resultMarker)) {
      current.add(line);
      continue;
    }
    if (trimmed.startsWith(_resultMarker)) {
      final expected = trimmed.substring(_resultMarker.length).trim();
      if (current.isEmpty && chunks.isNotEmpty && chunks.last.lines.isNotEmpty) {
        // The marker stands after a statement that was already flushed: attach it to that
        // statement's expression.
        final last = chunks.removeLast();
        final text = last.lines.join('\n');
        if (expected.isNotEmpty && _isExpressionStatement(text)) {
          chunks.add(Chunk.expect(_expressionOf(text), expected));
        } else {
          chunks.add(last);
          chunks.add(Chunk.code([line]));
        }
      } else {
        current.add(line);
        flush();
      }
      continue;
    }
    current.add(line);
    final withoutComment = line.split(_resultMarker).first;
    for (final unit in withoutComment.codeUnits) {
      if (unit == 0x7B /* { */) depth++;
      if (unit == 0x7D /* } */) depth--;
    }
    if (depth <= 0 && withoutComment.trimRight().endsWith(';')) flush();
    if (withoutComment.trim() == '}') flush();
  }
  flush();
  return chunks;
}

String? _expectedOf(String text) {
  final index = text.indexOf(_resultMarker);
  if (index < 0) return null;
  final rest = text.substring(index + _resultMarker.length);
  final line = rest.split('\n').first.trim();
  return line.isEmpty ? null : line;
}

bool _isExpressionStatement(String text) {
  final withoutComment = text.split(_resultMarker).first.trim();
  if (withoutComment.isEmpty) return false;
  final first = withoutComment.split(RegExp(r'\s')).first;
  const keywords = {
    'if',
    'for',
    'while',
    'do',
    'switch',
    'try',
    'catch',
    'finally',
    'return',
    'throw',
    'class',
    'void',
    'final',
    'var',
    'const',
    'late',
  };
  return !keywords.contains(first) && !withoutComment.contains('{');
}

String _expressionOf(String text) {
  final code = text.split(_resultMarker).first.trim();
  return code.endsWith(';') ? code.substring(0, code.length - 1) : code;
}

String? _expectedLiteral(String expected) => jsonEncode(expected);

/// Removes the `import` lines from an example and returns them, so a README quick start can show
/// the import a user writes while the generated program imports it once at the top.
List<String> _takeImports(List<String> lines) {
  final imports = <String>[];
  lines.removeWhere((line) {
    if (line.trim().startsWith('import ')) {
      imports.add(line.trim());
      return true;
    }
    return false;
  });
  return imports;
}

/// Rewrites an example into a closure body.
String _body(String label, String code) {
  final out = StringBuffer();
  for (final chunk in _chunks(code)) {
    if (chunk.isExpression) {
      out.writeln(
        '  _expect(${chunk.expression}, ${_expectedLiteral(chunk.expected!)}, ${jsonEncode(label)});',
      );
      continue;
    }
    for (final line in chunk.lines) {
      final index = line.indexOf(_resultMarker);
      if (index < 0) {
        out.writeln('  $line');
        continue;
      }
      final expected = _expectedOf(line);
      if (expected == null) {
        out.writeln('  ${line.substring(0, index)}');
        continue;
      }
      final before = line.substring(0, index).trimRight();
      final expression = before.endsWith(';') ? before.substring(0, before.length - 1) : before;
      out.writeln(
        '  _expect(${expression.trim()}, ${_expectedLiteral(expected)}, ${jsonEncode(label)});',
      );
    }
  }
  return out.toString();
}

void _prose() {
  final files = <String>[
    ..._docs,
    'CHANGELOG.md',
    'CONTRIBUTING.md',
    'SECURITY.md',
    'AGENTS.md',
  ];
  final docsDir = Directory('docs');
  if (docsDir.existsSync()) {
    for (final file in docsDir.listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (path.endsWith('.md') && !files.contains(path)) files.add(path);
    }
  }
  final link = RegExp(r'!?\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)');
  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) _fail('$path is missing');
    final text = file.readAsStringSync();
    final lines = const LineSplitter().convert(text);
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].contains('\u2014')) _fail('$path:${i + 1} has an em dash');
    }
    for (final match in link.allMatches(text)) {
      var target = match.group(1)!;
      if (target.startsWith('<') && target.endsWith('>')) {
        target = target.substring(1, target.length - 1);
      }
      if (RegExp(r'^[a-z][a-z0-9+.-]*:', caseSensitive: false).hasMatch(target)) continue;
      final withoutFragment = target.split('#').first;
      if (withoutFragment.isEmpty) continue;
      final resolved = File('${file.parent.path}/$withoutFragment').absolute.uri.normalizePath();
      if (!File.fromUri(resolved).existsSync() && !Directory.fromUri(resolved).existsSync()) {
        _fail('$path: link $target does not resolve');
      }
    }
  }
}

void main() {
  _prose();

  final snippets = <Snippet>[
    ..._markdownSnippets('README.md', File('README.md').readAsStringSync()),
    ..._markdownSnippets(
      'packages/nepdate/README.md',
      File('packages/nepdate/README.md').readAsStringSync(),
    ),
    ..._markdownSnippets(
      'packages/nepdate_patro/README.md',
      File('packages/nepdate_patro/README.md').readAsStringSync(),
    ),
    ..._markdownSnippets('docs/API.md', File('docs/API.md').readAsStringSync()),
  ];
  for (final path in [
    'packages/nepdate/lib/nepdate.dart',
    ...Directory('packages/nepdate/lib/src')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'))
        .map((file) => file.path),
    'packages/nepdate_patro/lib/nepdate_patro.dart',
  ]) {
    snippets.addAll(_docSnippets(path));
  }

  final imports = <String>{};
  final cleaned = <Snippet>[];
  for (final snippet in snippets) {
    final lines = const LineSplitter().convert(snippet.code);
    imports.addAll(_takeImports(lines));
    cleaned.add(Snippet(snippet.label, lines.join('\n')));
  }

  final program = StringBuffer('''
// Generated by tool/check_docs.dart. Do not edit.
import 'dart:io';

import 'package:nepdate/nepdate.dart';
import 'package:nepdate_patro/nepdate_patro.dart';
''');
  for (final line in imports) {
    if (line.contains('package:nepdate/')) continue;
    program.writeln(line);
  }
  program.write('''

int failures = 0;

void _expect(Object? actual, String expected, String label) {
  final text = '\$actual';
  if (text != expected) {
    failures++;
    stderr.writeln('docs: \$label: expected \$expected, got \$text');
  }
}

void main() {
''');
  var assertions = 0;
  for (final snippet in cleaned) {
    program.writeln('  // ${snippet.label}');
    program.writeln('  () {');
    for (final chunk in _chunks(snippet.code)) {
      if (chunk.isExpression) assertions++;
      assertions += chunk.lines.where((line) => line.contains(_resultMarker)).length;
    }
    program.write(_body(snippet.label, snippet.code));
    program.writeln('  }();');
  }
  program.writeln('  if (failures > 0) exitCode = 1;');
  program.writeln('}');

  final target = File('.dart_tool/docs_examples.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(program.toString());
  final result = Process.runSync(
    Platform.resolvedExecutable,
    ['--packages=.dart_tool/package_config.json', target.path],
  );
  final out = '${result.stdout}'.trim();
  final err = '${result.stderr}'.trim();
  if (out.isNotEmpty) stdout.writeln(out);
  if (err.isNotEmpty) stderr.writeln(err);
  if (result.exitCode != 0) {
    _fail('the examples in ${snippets.length} blocks did not run cleanly (${target.path})');
  }
  stdout.writeln(
    'docs: ${snippets.length} examples ran, $assertions result comments checked, '
    'prose has no em dash and every link resolves',
  );
}
