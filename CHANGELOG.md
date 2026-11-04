# Changelog

All notable changes are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project follows
[Semantic Versioning](https://semver.org/). Every NepDate SDK shares one `MAJOR.MINOR` line, so this
repository joins at `0.2.0-rc.1` with the other ports
([hub ADR-0007](https://github.com/sanamhub/nepdate/blob/main/docs/adr/0007-one-version-line-for-every-sdk.md)).

## 1.0.0-rc.1

### Changed

- The API is stable from 1.0 (hub ADR-0009). No code change in these packages; released with the family on the 1.0 line.

## 0.2.0-rc.1

### Added

- The `nepdate` package: Bikram Sambat dates from 1901-01-01 to 2199-12-30 with conversion to and
  from Gregorian, the `YYYYMMDD` integer form, arithmetic with clamp and spill, the calendar
  breakdown between two dates, fiscal years and quarters, English and Nepali formatting with
  patterns, strict and lenient parsing, inclusive date ranges, ordered batch conversion, and
  `toJson` with `fromJson`.
- The `nepdate_patro` package: tithi, public holidays and events for 2077-01-01 to 2084-08-20.
- Both packages are pure Dart with no dependencies and run on every platform, the web included.
- Calendar tables generated from the shared data, a `--check` mode that fails on drift, and a
  check of the patro counts against the hub's summary.
- Tests for every shared vector file, for every test of the C# library that applies, and for the
  properties that hold for all dates.
- One CI command, `dart run tool/ci.dart`, that runs formatting, analysis, the generator check, both
  test suites, a 90% line-coverage gate, dependency age, the documentation examples and the core
  isolation check.
- API documentation for every public member, six architecture decisions, a release runbook, and a
  README whose examples run in CI.
- A benchmark of B1 to B8 against the selected pub.dev competitor and the C# baseline, with the
  competitor evidence in `docs/competitors.md`.
- CI on Linux, macOS and Windows, the oldest supported Dart SDK, the hub's shared-check, CodeQL for
  Actions, Scorecard, dependency review, a scheduled mutation run, and the release and
  verify-published workflows.

### Changed

- The development toolchain now requires Dart 3.11.0: `test` 1.33 and the analyzer it resolves
  require 3.11, `lints` 6.1 requires 3.8, `coverage` 1.16 requires 3.9 and `benchmark_harness` 2.4
  requires 3.10. The packages themselves still support Dart 3.6, and the published-package check
  keeps testing 3.6.2.
