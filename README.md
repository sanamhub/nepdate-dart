<p align="center">
  <img src="https://raw.githubusercontent.com/sanamhub/nepdate-dart/main/docs/assets/nepdate-dart-128.png" width="128" alt="NepDate for Dart logo">
</p>

<h1 align="center">nepdate-dart</h1>

<p align="center">
  <a href="https://github.com/sanamhub/nepdate-dart/actions/workflows/ci.yml"><img src="https://github.com/sanamhub/nepdate-dart/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://pub.dev/packages/nepdate"><img src="https://img.shields.io/pub/v/nepdate?include_prereleases&label=nepdate&logo=dart&logoColor=white" alt="nepdate on pub.dev"></a>
  <a href="https://pub.dev/packages/nepdate_patro"><img src="https://img.shields.io/pub/v/nepdate_patro?include_prereleases&label=nepdate_patro&logo=dart&logoColor=white" alt="nepdate_patro on pub.dev"></a>
  <img src="https://img.shields.io/badge/Dart-%5E3.6.0-0175C2?logo=dart&logoColor=white" alt="Dart ^3.6.0">
  <a href="https://github.com/sanamhub/nepdate-dart/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="License: MIT"></a>
</p>

Bikram Sambat (Nepali calendar) dates for Dart and Flutter: conversion to and from Gregorian,
arithmetic, formatting, parsing, ranges and fiscal years. Part of the NepDate family: the shared
data and spec live in the hub [`sanamhub/nepdate`](https://github.com/sanamhub/nepdate); the C#
original is [NepDate](https://github.com/RajuPrasai/NepDate).

> **Status:** 0.2.0-rc.1 is the first release of the Dart port and is not on pub.dev yet. The API
> is listed in [docs/API.md](https://github.com/sanamhub/nepdate-dart/blob/main/docs/API.md) and
> may still change before 0.2.0. Patro data (tithi, holidays, events) is informational, not an
> official calendar.

Two pub.dev packages, released together with the same version and one tag:

- [`nepdate`](https://pub.dev/packages/nepdate): dates, conversion, arithmetic, formatting,
  parsing, ranges and fiscal years. No dependencies and no event data.
- [`nepdate_patro`](https://pub.dev/packages/nepdate_patro): the patro (पात्रो, the Nepali almanac):
  tithi, public holidays and events from BS 2077-01-01 to 2084-08-20. It depends on `nepdate`.

Pure Dart, so it runs on the VM, in Flutter on every platform and on the web. There is no time zone
database: `today` takes a zone name or a fixed offset, or a clock you inject, so it never reads a
hidden local zone. BS 1901-01-01 to 2199-12-30 (AD 1844-04-11 to 2143-04-15), with the same results
as C# NepDate and the other ports, checked against the shared vectors.

## Install

```sh
dart pub add nepdate
```

In a Flutter app, use `flutter pub add nepdate`. While only the release candidate exists, pub picks
it; pin `nepdate: 0.2.0-rc.1` in `pubspec.yaml` to stay on this one.

```dart
import 'package:nepdate/nepdate.dart';
```

The tithi, holidays and events are the second package:

```sh
dart pub add nepdate_patro
```

```dart
import 'package:nepdate_patro/nepdate_patro.dart';
```

## Quick start

```dart
import 'package:nepdate/nepdate.dart';

final date = NepaliDate.fromBs(2081, 4, 15);
date.toString(); // => 2081/04/15
date.toDateTime().toIso8601String(); // => 2024-07-30T00:00:00.000Z
date.toLongString(weekday: true); // => Tuesday, Shrawan 15, 2081
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

## Patro: tithi, holidays and events

The core has no patro data. Add both packages:

```sh
dart pub add nepdate nepdate_patro
```

The `nepdate_patro` package compiles the tithi, public holiday and event data into constant tables,
so nothing is read or parsed at run time. `info` never throws: a day without data, and any day
outside the coverage, gets an empty `CalendarInfo`. The data covers BS 2077-01-01 to 2084-08-20.

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

## Supported versions and platforms

- Dart `^3.6.0`, tested on 3.6 and the current stable release.
- Every platform Dart supports: the VM, Flutter on Android, iOS, macOS, Windows and Linux, and the
  web. The libraries import `dart:core` and `dart:collection` only.
- `nepdate` and `nepdate_patro` share one version and one release tag.

## Data and correctness

The calendar data is the same data every NepDate port uses, a read-only copy of the hub's
`shared/data/`. The test suite loads every shared vector file, including the golden output of C#
NepDate 2.0.7, and the properties the specification states. Dates and behaviour come from
`shared/spec`, not from another port's README. Month lengths beyond the officially published
calendar are projections inherited from C# NepDate.

## Documentation

| Page | What it covers |
|---|---|
| [API](https://github.com/sanamhub/nepdate-dart/blob/main/docs/API.md) | Every public type and member, with an example |
| [Benchmarks](https://github.com/sanamhub/nepdate-dart/blob/main/docs/benchmarks.md) | B1 to B8 against `nepali_utils` and C# NepDate |
| [Competitors](https://github.com/sanamhub/nepdate-dart/blob/main/docs/competitors.md) | The pub.dev packages considered for the benchmark |
| [ADRs](https://github.com/sanamhub/nepdate-dart/blob/main/docs/adr/README.md) | Why the design is what it is |
| [Release](https://github.com/sanamhub/nepdate-dart/blob/main/docs/runbooks/release.md) | Tagging, publishing and the post-publish check |
| [Changelog](https://github.com/sanamhub/nepdate-dart/blob/main/CHANGELOG.md) | What changed in each version |
| [Contributing](https://github.com/sanamhub/nepdate-dart/blob/main/CONTRIBUTING.md) | Setup, gates and commits |
| [Security](https://github.com/sanamhub/nepdate-dart/blob/main/SECURITY.md) | Reporting a vulnerability |
| [Data error form](https://github.com/sanamhub/nepdate/issues/new/choose) | A wrong date, holiday or tithi, reported in the hub |
| [Spec](https://github.com/sanamhub/nepdate/tree/main/spec) | Behaviour and vectors, in the hub |
| [Other languages](https://github.com/sanamhub/nepdate#packages) | The same library in the other NepDate ports |

## Benchmarks

`bench/` measures B1 to B8 of the shared benchmark specification against `nepali_utils`, the one
pub.dev package that passes the competitor bar, and against the C# NepDate baseline. The machine,
the method and the current numbers are in
[docs/benchmarks.md](https://github.com/sanamhub/nepdate-dart/blob/main/docs/benchmarks.md).

## Contributing

Bug reports, fixes and documentation improvements are welcome; open an issue before a new feature
or an API change. `dart run tool/ci.dart` runs every gate and must pass before a pull request. The
details are in
[CONTRIBUTING.md](https://github.com/sanamhub/nepdate-dart/blob/main/CONTRIBUTING.md).

## Credit

NepDate for Dart is a port of [NepDate](https://github.com/RajuPrasai/NepDate), the C# library by
Raju Prasai and contributors. The data and the behaviour follow it with the deliberate, documented
deviations in the hub's
[`spec/PARITY.md`](https://github.com/sanamhub/nepdate/blob/main/spec/PARITY.md).

## License

MIT ([LICENSE](https://github.com/sanamhub/nepdate-dart/blob/main/LICENSE)). Calendar and patro
data from NepDate by Raju Prasai and contributors, MIT
([NOTICE](https://github.com/sanamhub/nepdate-dart/blob/main/NOTICE)). Not affiliated with the
Government of Nepal.
