// Fails a release when the tag, the two manifests and the changelog disagree.
//
//   dart run scripts/release_check.dart 0.2.0-rc.1
//
// The version must be a SemVer version with an optional -beta.N or -rc.N suffix, both packages must
// carry it, and the changelog must have a heading for it. The tag itself is checked by the
// workflow, which passes its name to `scripts/version.dart --check-tag`.

import 'dart:io';

Never _fail(String message) {
  stderr.writeln('release-check: $message');
  exit(1);
}

String _versionOf(String path) {
  final text = File(path).readAsStringSync();
  final match = RegExp(r'^version:\s*(\S+)\s*$', multiLine: true).firstMatch(text);
  if (match == null) _fail('$path has no version');
  return match.group(1)!;
}

void main(List<String> arguments) {
  if (arguments.length != 1) _fail('usage: dart run scripts/release_check.dart <version>');
  final version = arguments.single;
  if (!RegExp(r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-(?:beta|rc)\.[1-9]\d*)?$')
      .hasMatch(version)) {
    _fail('$version is not a SemVer version this project uses');
  }
  for (final path in [
    'packages/nepdate/pubspec.yaml',
    'packages/nepdate_patro/pubspec.yaml',
  ]) {
    final found = _versionOf(path);
    if (found != version) _fail('$path says $found, expected $version');
  }
  for (final path in [
    'CHANGELOG.md',
    'packages/nepdate/CHANGELOG.md',
    'packages/nepdate_patro/CHANGELOG.md',
  ]) {
    final text = File(path).readAsStringSync();
    final heading = RegExp(
      '^## \\[?${RegExp.escape(version)}\\]?\\s*\$',
      multiLine: true,
    );
    if (!heading.hasMatch(text)) {
      _fail('$path has no "## $version" section');
    }
  }
  stdout.writeln(
    'release-check: $version matches both manifests and all three changelogs',
  );
}
