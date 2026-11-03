# 0002: immutable dates, a serial day model and integer arithmetic

Status: accepted.

## Context

C# `NepaliDate` is a struct with a `default` value of `0000/00/00` that throws when used. Its
`AddMonths(double)` treats a fraction as 30.4167 days, and `AddDays(double)` floors. Both are easy
to call by accident and hard to reproduce across languages.

## Decision

- A `NepaliDate` holds `year`, `month`, `day` and a private serial. It is immutable and `final`.
  There is no invalid value; every constructor validates and throws.
- The serial is the number of days since 1901-01-01 BS. The 109,212-day table is generated from
  `shared/data/calendar/bs-calendar.json` and stored as month-start serials. A lookup is an array
  read, and the Gregorian conversion is the integer civil-days algorithm of the hub's
  `ALGORITHM.md`.
- Month arithmetic takes an `int` and a `MonthOverflow` value: `clamp` uses the last day of the
  target month, `spill` carries the extra days into the following month. It never takes a fraction.
  Day arithmetic takes an `int`.
- `==`, `hashCode`, `compareTo` and the comparison operators use the serial. The packed
  `YYYYMMDD` integer is a separate accessor, not the identity.
- A `DateDiff` reports the calendar breakdown and a signed `totalDays`. The `-` operator keeps the
  C# direction, `this - other`; `daysUntil` keeps the opposite direction, `other - this` (`D-07`).

## Consequences

An invalid date cannot be built, so a caller never has to check a default. Arithmetic is exact and
the same in every port. The sign of the two difference forms is a documented trap, so the API docs
state both and the tests use both directions from `day-diff.tsv`.
