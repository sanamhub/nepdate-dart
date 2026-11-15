# Changelog

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project follows
[Semantic Versioning](https://semver.org/). The two packages share one version. The repository
changelog has the full history.

## Unreleased

### Changed

- `info` keeps the answer of each day in a list indexed by day, not in a hash map. Measured on the
  reference machine: one day 25 ns to 4 ns, a month grid 1017 ns to 290 ns.

## 1.0.0-rc.1

### Changed

- The API is stable from 1.0 (hub ADR-0009). No code change in this package; released with the family on the 1.0 line.

## 0.2.0-rc.1

### Added

- Tithi, public holidays and events for BS 2077-01-01 to 2084-08-20, compiled into constant tables.
- `info`, `coverage` and `publicHolidays`, with an empty answer outside the data and no exception.
- Depends on `nepdate` for the date type. Pure Dart, every platform including the web.
