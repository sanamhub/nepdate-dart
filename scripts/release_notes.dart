// Prints the changelog section of a version, for the GitHub release notes.
//
//   dart run scripts/release_notes.dart 0.2.0-rc.1
//
// The section runs from its heading to the next level-two heading. A missing or empty section is an
// error, because a release with no notes is a release nobody can read.

import 'dart:io';

Never _fail(String message) {
  stderr.writeln('release-notes: $message');
  exit(1);
}

void main(List<String> arguments) {
  if (arguments.length != 1) _fail('usage: dart run scripts/release_notes.dart <version>');
  final version = arguments.single;
  final lines = File('CHANGELOG.md').readAsLinesSync();
  final heading = RegExp('^## \\[?${RegExp.escape(version)}\\]?\\s*\$');
  var start = -1;
  for (var i = 0; i < lines.length; i++) {
    if (heading.hasMatch(lines[i])) {
      start = i + 1;
      break;
    }
  }
  if (start < 0) _fail('CHANGELOG.md has no section for $version');
  final out = <String>[];
  for (var i = start; i < lines.length; i++) {
    if (lines[i].startsWith('## ')) break;
    out.add(lines[i]);
  }
  while (out.isNotEmpty && out.first.trim().isEmpty) {
    out.removeAt(0);
  }
  while (out.isNotEmpty && out.last.trim().isEmpty) {
    out.removeLast();
  }
  if (out.isEmpty) _fail('the section for $version is empty');
  stdout.writeln(out.join('\n'));
}
