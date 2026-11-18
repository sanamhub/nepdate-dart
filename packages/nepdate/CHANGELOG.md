# Changelog

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project follows
[Semantic Versioning](https://semver.org/). The two packages share one version. The repository
changelog has the full history.

## 1.0.0

### Changed

- Faster conversion, formatting and parsing, with the same results for every date. Measured on the
  reference machine, per operation: AD to BS 77 ns to 39 ns, the long Nepali date 567 ns to 158 ns,
  strict parse 64 ns to 34 ns.
  - `toDateTime` builds the `DateTime` from the day count, and `fromGregorian` reads the day count
    of a UTC value directly. Neither goes through year, month and day fields.
  - Formatting reads digit and year texts from tables and builds each result in one step.
  - `parse` and `tryParse` read the text in one pass without allocating. `tryParse` no longer
    builds an error it would throw away.

## 1.0.0-rc.1

### Changed

- The API is stable from 1.0 (hub ADR-0009). No code change in this package; released with the family on the 1.0 line.

## 0.2.0-rc.1

### Added

- Bikram Sambat dates from 1901-01-01 to 2199-12-30 with conversion to and from Gregorian, the
  `YYYYMMDD` integer form, arithmetic with clamp and spill, the calendar breakdown between two
  dates, fiscal years and quarters, English and Nepali formatting with patterns, strict and lenient
  parsing, inclusive date ranges, ordered batch conversion, and `toJson` with `fromJson`.
- Pure Dart with no dependencies, every platform including the web.
