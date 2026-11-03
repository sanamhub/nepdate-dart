# 0003: one error type, deterministic parsers, an injectable clock and explicit zones

Status: accepted.

## Context

C# uses `ArgumentOutOfRangeException`, `InvalidNepaliDateFormatException` and `FormatException` for
different failures. Its strict parser has no digit limit and rejects Devanagari digits; its smart
parser guesses permutations, expands two-digit years and ignores extra groups. Its `Today` reads
the machine's local zone.

## Decision

- Every calendar or parse failure throws `NepDateException` with an `ErrorKind`: `outOfRange`,
  `invalidMonth`, `invalidDay`, `invalidCharacter`, `wrongGroupCount`, `numberTooLong`,
  `ambiguous` or `unrecognized`. A bad argument with no calendar meaning, such as an interval below
  one or an unknown zone name, throws `ArgumentError`.
- The strict parser is deterministic: year, month and day in that order, ASCII or Devanagari digits,
  at most four digits per group, the separators of `PARSING.md`. The lenient parser is the closed
  month list and explicit rules of `PARSING.md`, with no guessing (`D-05`, `D-06`).
- Every non-throwing parse returns `null`: `tryParse` and `tryParseLenient`.
- `today`, `isToday`, `isYesterday` and `isTomorrow` take a zone and an optional `DateTime
  Function()` clock. The default zone is `Asia/Kathmandu`; `UTC`, `GMT` and fixed offsets are also
  accepted. Dart has no time zone database, so an unknown name is an `ArgumentError` and the docs
  point at `fromGregorian(DateTime.now())` for the device's zone.
- The clock default is `DateTime.now`. Tests always pass a clock, so the suite is deterministic on
  every machine and every CI runner.

## Consequences

A caller catches one type and switches on `kind`. A parse of user input never depends on the
machine or a hidden permutation. The zone limitation is visible in the signature instead of being
a surprise at run time.
