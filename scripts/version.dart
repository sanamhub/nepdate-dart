// Reads the one version of the two packages and checks that they agree, and that nepdate_patro
// requires exactly that version of nepdate (ADR-0011).
//
//   dart run scripts/version.dart              print 0.2.0-rc.1
//   dart run scripts/version.dart --line       print 0.2
//   dart run scripts/version.dart --check-tag v0.2.0-rc.1
//
// The manifests are the source of truth; the tag is checked against them before a release.

import 'dart:io';

Never _fail(String message) {
  stderr.writeln('version: $message');
  exit(1);
}

String _versionOf(String path) {
  final text = File(path).readAsStringSync();
  final match = RegExp(r'^version:\s*(\S+)\s*$', multiLine: true).firstMatch(text);
  if (match == null) _fail('$path has no version');
  return match.group(1)!;
}

// The constraint the patro puts on nepdate under `dependencies:`, as written, or null.
String? _coreRequirementOf(String path) {
  final text = File(path).readAsStringSync();
  final match = RegExp(
    r'^dependencies:\n(?:  .*\n)*?  nepdate:[ \t]*(\S+)[ \t]*$',
    multiLine: true,
  ).firstMatch(text);
  return match?.group(1);
}

void main(List<String> arguments) {
  final core = _versionOf('packages/nepdate/pubspec.yaml');
  const patroPath = 'packages/nepdate_patro/pubspec.yaml';
  final patro = _versionOf(patroPath);
  if (core != patro) _fail('nepdate is $core but nepdate_patro is $patro');
  final requirement = _coreRequirementOf(patroPath);
  if (requirement != core) {
    _fail('nepdate_patro requires nepdate $requirement, expected exactly $core');
  }

  if (arguments.contains('--line')) {
    final parts = core.split('.');
    if (parts.length < 2) _fail('$core is not a SemVer version');
    stdout.writeln('${parts[0]}.${parts[1]}');
    return;
  }
  final tagIndex = arguments.indexOf('--check-tag');
  if (tagIndex >= 0) {
    if (tagIndex + 1 >= arguments.length) _fail('--check-tag needs a tag');
    final tag = arguments[tagIndex + 1];
    if (tag != 'v$core') _fail('tag $tag does not match version $core');
  }
  stdout.writeln(core);
}
