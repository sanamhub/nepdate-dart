# 0001: one repository, two packages, a pub workspace and pure Dart

Status: accepted.

## Context

The hub's ADR-0004 puts the core date library and the patro data in separate packages with one
release tag. The Dart ecosystem resolves packages by name, and pub.dev needs one manifest per
package. The library must run on every platform, the web included, so `dart:io` and `dart:ffi`
cannot appear in it.

## Decision

- One repository, `sanamhub/nepdate-dart`, with two published packages: `nepdate` and
  `nepdate_patro`.
- A pub workspace at the root with both packages as members, and a `bench` member that is never
  published. The workspace has one lockfile, so CI installs exactly what a user gets.
- The core library imports `dart:core` and `dart:collection` only. The patro package imports
  `package:nepdate/nepdate.dart`.
- Dart `^3.6.0`. CI runs the oldest supported SDK as well as a current stable release, so a newer
  language feature cannot slip in.
- No runtime dependency in either package. Dev dependencies are pinned exactly and must be at least
  14 days old when the lock is made; `tool/check_dependency_age.dart` enforces the age from pub.dev.
- The tests and the generator may use `dart:io`; the libraries may not.

## Consequences

A user can add either package without pulling in build tools or another date library. The web
build of a Flutter app has no conditional import to worry about. The patro package can be released
faster than the core only by moving the shared tag, which the hub's line does not allow, so the two
always move together.
