// Fails when a package in pubspec.lock was published on pub.dev less than 14 days ago.
//
//   dart run tool/check_dependency_age.dart [--days 14] [--now 2026-11-02]
//
// The lock is what CI installs, so this is the check that a new dependency, a dev tool included,
// is old enough to have been noticed if it was bad.

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  var days = 14;
  var now = DateTime.now().toUtc();
  for (var i = 0; i < arguments.length; i++) {
    switch (arguments[i]) {
      case '--days':
        days = int.parse(arguments[++i]);
      case '--now':
        now = DateTime.parse('${arguments[++i]}T00:00:00Z');
      default:
        stderr.writeln('unknown argument ${arguments[i]}');
        exit(2);
    }
  }
  final cutoff = now.subtract(Duration(days: days));
  final lock = File('pubspec.lock').readAsStringSync();
  final packages = RegExp(
    r'^  (\w+):\n(?:    .*\n)*?    version: "([^"]+)"',
    multiLine: true,
  ).allMatches(lock).map((m) => (m.group(1)!, m.group(2)!)).toList();

  final client = HttpClient();
  final tooNew = <String>[];
  try {
    for (final (name, version) in packages) {
      final request = await client.getUrl(
        Uri.https('pub.dev', '/api/packages/$name/versions/$version'),
      );
      request.headers.set('User-Agent', 'nepdate-dependency-age');
      final response = await request.close();
      if (response.statusCode != 200) {
        stderr.writeln('$name $version: pub.dev answered ${response.statusCode}');
        exit(1);
      }
      final body = await response.transform(utf8.decoder).join();
      final published = DateTime.parse(
        (jsonDecode(body) as Map<String, dynamic>)['published'] as String,
      );
      if (published.isAfter(cutoff)) {
        tooNew.add('$name $version (${published.toIso8601String().substring(0, 10)})');
      }
    }
  } finally {
    client.close();
  }
  if (tooNew.isNotEmpty) {
    stderr.writeln('published within the last $days days:');
    tooNew.forEach(stderr.writeln);
    exit(1);
  }
  stdout.writeln('dependency age: ${packages.length} packages, all at least $days days old');
}
