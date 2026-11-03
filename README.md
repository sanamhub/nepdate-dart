# NepDate for Dart

Bikram Sambat (the Nepali calendar) dates for Dart and Flutter: conversion to and from Gregorian,
arithmetic, formatting, parsing, ranges and fiscal years. Pure Dart, no dependencies, every platform
including the web.

The package has no time zone database of its own. `today` takes a zone name or a fixed offset, or a
clock you inject, so it never reads a hidden local zone. The tithi, public holidays and events live
in the separate [`nepdate_patro`](https://pub.dev/packages/nepdate_patro) package.

```dart
import 'package:nepdate/nepdate.dart';

final date = NepaliDate.fromBs(2081, 4, 15);
date.toString(); // => 2081/04/15
date.toDateTime().toIso8601String(); // => 2024-07-30T00:00:00.000Z
date.toLongString(weekday: true); // => Tuesday, Shrawan 15, 2081
```

## Install

```sh
dart pub add nepdate
```

```dart
import 'package:nepdate/nepdate.dart';
```

The tithi, holidays and events are a second package:

```sh
dart pub add nepdate_patro
```

```dart
import 'package:nepdate_patro/nepdate_patro.dart';
```

## Dates

A date is always a real day of the calendar, from 1901-01-01 to 2199-12-30 BS (1844-04-11 to
2143-04-15 AD). The validating constructor reports the year first, then the month, then the day, and
throws a `NepDateException` with an `ErrorKind`. There is no invalid or default date.

```dart
final date = NepaliDate.fromBs(2081, 4, 32);
date.year; // => 2081
date.month; // => 4
date.day; // => 32
date.weekday; // => Weekday.friday
date.dayOfYear; // => 126
date.monthLength; // => 32
date.yearLength; // => 366
NepaliDate.min.toString(); // => 1901/01/01
NepaliDate.max.toString(); // => 2199/12/30
```

The month enum, the day-of-week enum and the year length replace the C# `MonthName` and
`IsLeapYear()`. The length is the BS year length, 364 to 367 days (`D-12`).

```dart
NepaliDate.fromBs(2081, 4, 15).monthEnum; // => Month.shrawan
NepaliDate.fromBs(2081, 4, 15).lastDayOfMonth.toString(); // => 2081/04/32
NepaliDate.fromBs(2081, 4, 15).toRecord(); // => (2081, 4, 15)
NepaliDate.fromBs(2081, 4, 15).fiscalYear.label(); // => 2081/82
```

## Conversion and serialization

Convert a `DateTime` by its date part; the time of day and the zone are ignored. The canonical text
form is `YYYY-MM-DD`, and the `YYYYMMDD` integer is available both ways.

```dart
NepaliDate.fromGregorian(DateTime.utc(2024, 7, 30)).toString(); // => 2081/04/15
NepaliDate.fromYmd(20810415).toString(); // => 2081/04/15
NepaliDate.fromBs(2081, 4, 15).ymd; // => 20810415
NepaliDate.fromBs(2081, 4, 15).toJson(); // => 2081-04-15
NepaliDate.fromJson('2081-04-15').toString(); // => 2081/04/15
```

Batch conversion keeps input order. A single bad item makes the whole call throw.

```dart
NepaliDate.fromGregorianAll([DateTime.utc(2024, 7, 30)]).single.toString(); // => 2081/04/15
NepaliDate.parseAll(['2081-04-15']).single.toIso8601String(); // => 2024-07-30T00:00:00.000Z
NepaliDate.toGregorianAll([NepaliDate.min]).single.toIso8601String(); // => 1844-04-11T00:00:00.000Z
```

## Arithmetic

Months are whole numbers. When the day does not exist in the target month, `MonthOverflow.clamp`
(the default) uses the last day and `MonthOverflow.spill` carries the extra days into the next
month. A signed day difference is a plain `int`; the named `daysUntil` is `other - this` while the
`-` operator is `this - other` (`D-07`).

```dart
final date = NepaliDate.fromBs(2081, 4, 32);
date.addDays(30).toString(); // => 2081/05/30
date.addMonths(2).toString(); // => 2081/06/30
date.addMonths(2, overflow: MonthOverflow.spill).toString(); // => 2081/07/02
date.addYears(1).toString(); // => 2082/04/31
date.daysUntil(NepaliDate.fromBs(2081, 5, 1)); // => 1
(date - NepaliDate.fromBs(2081, 4, 15)).totalDays; // => 17
date.diff(NepaliDate.fromBs(2081, 5, 31)).days; // => 0
```

## Formatting

Short formats take an order, a separator, a padding flag and a language. The long form is
`[Weekday, ]Month day[, year]`. Nepali output uses Devanagari names and digits. Patterns accept
`yyyy`, `yy`, `MMMM`, `MMM`, `MM`, `M`, `dd`, `d`, a backslash escape and a quoted literal.

```dart
final date = NepaliDate.fromBs(2081, 4, 15);
date.toString(); // => 2081/04/15
date.toShortString(order: DateOrder.dmy, separator: Separator.dash); // => 15-04-2081
date.toShortString(lang: Lang.ne); // => २०८१/०४/१५
date.toLongString(); // => Shrawan 15, 2081
date.toLongString(weekday: true, lang: Lang.ne); // => मङ्गलवार, साउन १५, २०८१
date.format('MMMM d, yyyy'); // => Shrawan 15, 2081
date.format('MMM yy'); // => Shr 81
```

## Parsing

The strict parser takes year, month and day in that order, with ASCII or Devanagari digits and the
separators `- / . _ \ space | ।`. The lenient parser accepts month names in English or Nepali, the
day before the year, and era markers such as `B.S.`. Both have non-throwing forms.

```dart
NepaliDate.parse('2081/04/15').toString(); // => 2081/04/15
NepaliDate.parse('२०८१/०४/१५').toString(); // => 2081/04/15
NepaliDate.parseLenient('15 Shrawan 2081 B.S.').toString(); // => 2081/04/15
NepaliDate.tryParse('2081/13/01'); // => null
NepaliDate.tryParseLenient('15 Foo 2081'); // => null
```

A parse failure throws `NepDateException`; `error.kind` says whether the character, the group count,
the number length, the date fields or the form was wrong.

## Ranges

A range is inclusive and always has at least one day. It is an `Iterable` of its days, with value
equality and a hash code, and it offers containment, overlap, adjacency, intersection, union,
difference, month and fiscal-quarter splits, an interval walk, working days and weekend days.

```dart
final range = NepaliDateRange.of(
  NepaliDate.fromBs(2081, 4, 10),
  NepaliDate.fromBs(2081, 4, 20),
);
range.length; // => 11
range.toString(); // => 2081/04/10 - 2081/04/20
range.contains(NepaliDate.fromBs(2081, 4, 15)); // => true
range.overlaps(NepaliDateRange.forMonth(2081, 4)); // => true
range.intersect(NepaliDateRange.forMonth(2081, 5)); // => null
range.splitByMonth().length; // => 1
range.datesWithInterval(5).length; // => 3
range.workingDays().length; // => 9
NepaliDateRange.forMonth(2081, 4).length; // => 32
NepaliDateRange.forYear(2081).length; // => 366
NepaliDateRange.currentMonth(timeZone: 'UTC', clock: () => DateTime.utc(2024, 7, 30)).toString();
// => 2081/04/01 - 2081/04/32
```

## Fiscal year

A fiscal year starts on 1 Shrawan and ends on the last day of Ashad of the next BS year. Quarters
are Q1 Shrawan to Ashoj, Q2 Kartik to Poush, Q3 Magh to Chaitra and Q4 Baishakh to Ashad. A
`FiscalYear` value answers all of them, so there is no `yearOffset` argument.

```dart
final fiscal = FiscalYear.containing(NepaliDate.fromBs(2082, 2, 1));
fiscal.label(); // => 2081/82
fiscal.start().toString(); // => 2081/04/01
fiscal.end().toString(); // => 2082/03/32
fiscal.quarterRange(Quarter.q1).toString(); // => 2081/04/01 - 2081/06/30
fiscal.quarterRange(Quarter.q4).toString(); // => 2082/01/01 - 2082/03/32
```

## Today

`today` reads the system clock by default, or a clock you pass. The zone is `Asia/Kathmandu` by
default; `UTC`, `GMT` and fixed offsets such as `+05:45` are also accepted. To use the device's own
zone, convert `DateTime.now()` with `fromGregorian`.

```dart
NepaliDate.today(clock: () => DateTime.utc(2024, 7, 30, 18, 30)).toString(); // => 2081/04/16
NepaliDate.today(timeZone: 'UTC', clock: () => DateTime.utc(2024, 7, 30, 18, 30)).toString();
// => 2081/04/15
NepaliDate.fromBs(2081, 4, 16)
    .isToday('Asia/Kathmandu', clock: () => DateTime.utc(2024, 7, 30, 18, 30)); // => true
```

## Patro

The `nepdate_patro` package compiles the tithi, public holiday and event data into constant tables.
`info` never throws: a day without data, and any day outside the coverage, gets an empty
`CalendarInfo`. The data covers BS 2077-01-01 to 2084-08-20.

```dart
import 'package:nepdate/nepdate.dart';
import 'package:nepdate_patro/nepdate_patro.dart';

final day = info(NepaliDate.fromBs(2081, 2, 15));
day.isPublicHoliday; // => true
day.tithi?.english; // => Panchami
day.events.map((event) => event.english).toList(); // => [Republic Day]
coverage().start.toString(); // => 2077/01/01
publicHolidays().length; // => 294
```

## Supported versions

- Dart `^3.6.0`, tested on 3.6 and the current stable release.
- Every platform Dart supports: the VM, Flutter on Android, iOS, macOS, Windows and Linux, and the
  web. The libraries import `dart:core` and `dart:collection` only.
- `nepdate` and `nepdate_patro` share one version and one release tag.

## Data and correctness

The calendar data is the same data every NepDate port uses, from the hub repository. The test suite
loads every shared vector file, including the golden output of C# NepDate 2.0.7, and the properties
the specification states. Dates and behaviour come from `shared/spec`, not from another port's
README.

NepDate for Dart is a port of [NepDate](https://github.com/RajuPrasai/NepDate), the C# library by
Raju Prasai. The data and the behaviour follow it with the deliberate, documented deviations in the
hub's `spec/PARITY.md`. See [NOTICE](NOTICE) for the attribution.

## Documentation

| Topic | Where |
|---|---|
| Every public type and member, with an example | [docs/API.md](docs/API.md) |
| Benchmarks and the competitors they compare | [docs/benchmarks.md](docs/benchmarks.md), [docs/competitors.md](docs/competitors.md) |
| Design decisions | [docs/adr](docs/adr/README.md) |
| Releasing | [docs/runbooks/release.md](docs/runbooks/release.md) |
| What changed | [CHANGELOG.md](CHANGELOG.md) |

## License

MIT. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
