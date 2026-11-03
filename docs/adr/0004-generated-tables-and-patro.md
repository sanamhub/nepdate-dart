# 0004: generated tables, core isolation and the patro layout

Status: accepted.

## Context

The calendar and patro data live in the hub's `shared/data`. Every port compiles them into constant
tables so nothing is parsed or loaded at run time. The core package must not carry tithi, holiday or
event data (hub ADR-0004), and a Dart library that runs on the web cannot read a file at run time.

## Decision

- `tool/generate.dart` reads `shared/data/calendar/bs-calendar.json` and writes
  `packages/nepdate/lib/src/calendar.g.dart`: the month lengths, the month-start serials and the
  total. It refuses a year range, month count or month length outside the hub's data.
- The generator reads the same data for `packages/nepdate_patro/lib/src/tables.g.dart`: the name
  pool, one tithi index per day of the contiguous tithi range, sorted holiday serials, and sorted
  event-day serials with an offset and a name id per event. It checks every count against
  `shared/spec/vectors/patro-summary.json` and fails on a disagreement, so the counts are never
  pinned in this repository.
- The generator has a `--check` mode that compares the bytes it would write with the files on disk.
  CI runs `--check`, so a table cannot drift from the data.
- The core package has no patro data and no reference to `nepdate_patro`. CI checks the manifest,
  the library sources, and a compiled program that imports only the core for a known patro event
  string.
- `info` is a binary search over sorted serials, then an array read for the tithi. It never throws
  and returns one shared empty `CalendarInfo` outside the data.

## Consequences

The generated files are large but have no run time cost beyond loading constants. A data change is a
generated diff, not a hand edit. The patro package carries all the data, so an app that only
converts dates does not download it.
