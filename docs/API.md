# API

Every public type and member of `nepdate` and `nepdate_patro`, grouped like the hub's
`spec/API.md`. Argument names, defaults and errors are exact. Dates are Bikram Sambat unless the
name says Gregorian, and every "today" call takes a zone and an optional clock.

The two packages share one version line. `nepdate` has no dependency at all and imports
`dart:core` and `dart:collection` only; `nepdate_patro` depends on `nepdate` and holds the patro
tables.

```dart
import 'package:nepdate/nepdate.dart';
import 'package:nepdate_patro/nepdate_patro.dart';
```

## Dates, identity and comparison

A `NepaliDate` is immutable and is always a real day of the calendar, from 1901-01-01 to
2199-12-30 BS. Every constructor validates and throws `NepDateException`. `==`, `hashCode`,
`compareTo` and the comparison operators use the date.

| Member | Signature | Notes |
|---|---|---|
| `NepaliDate.fromBs` | `NepaliDate.fromBs(int year, int month, int day)` | Validates year, then month, then day. |
| `NepaliDate.parse` | `NepaliDate.parse(String text)` | Strict parse, section "Parsing". |
| `NepaliDate.fromGregorian` | `NepaliDate.fromGregorian(DateTime date)` | Converts the date part only. |
| `NepaliDate.fromYmd` | `NepaliDate.fromYmd(int value)` | Reads `YYYYMMDD`. |
| `NepaliDate.fromJson` | `NepaliDate.fromJson(Object? json)` | Reads the `YYYY-MM-DD` string. |
| `NepaliDate.today` | `NepaliDate.today({String timeZone = 'Asia/Kathmandu', DateTime Function()? clock})` | Reads the clock in `timeZone`. |
| `NepaliDate.tryParse` | `static NepaliDate? tryParse(String text)` | `null` instead of throwing. |
| `NepaliDate.tryParseLenient` | `static NepaliDate? tryParseLenient(String text)` | `null` instead of throwing. |
| `year`, `month`, `day` | `final int` | The BS fields. |
| `monthEnum` | `Month get monthEnum` | The month as an enum value. |
| `weekday` | `Weekday get weekday` | Sunday is index 0. |
| `dayOfYear` | `int get dayOfYear` | 1-based, counted in the BS year. |
| `monthLength` | `int get monthLength` | 29 to 32. |
| `yearLength` | `int get yearLength` | 364 to 367 (`D-12`). |
| `lastDayOfMonth` | `NepaliDate get lastDayOfMonth` | This year and month on its last day. |
| `ymd` | `int get ymd` | The packed `YYYYMMDD` integer. |
| `fiscalYear` | `FiscalYear get fiscalYear` | The containing fiscal year. |
| `quarter` | `Quarter get quarter` | The containing fiscal quarter. |
| `toRecord` | `(int, int, int) toRecord()` | The three fields for destructuring. |
| `toDateTime` | `DateTime toDateTime()` | Midnight UTC on the Gregorian date. |
| `isToday` | `bool isToday(String timeZone, {DateTime Function()? clock})` | `today(zone) == this`. |
| `isYesterday` | `bool isYesterday(String timeZone, {DateTime Function()? clock})` | `today(zone) - 1 == this`. |
| `isTomorrow` | `bool isTomorrow(String timeZone, {DateTime Function()? clock})` | `today(zone) + 1 == this`. |
| `compareTo` | `int compareTo(NepaliDate other)` | `Comparable`: negative, zero or positive. |
| `==` | `bool operator ==(Object other)` | Value equality, false for another type. |
| `hashCode` | `int get hashCode` | Equal dates hash equally. |
| `<`, `<=`, `>`, `>=` | `bool operator <(NepaliDate other)` and the rest | Date order. |
| `min`, `max` | `static const NepaliDate min`, `max` | 1901-01-01 and 2199-12-30. |

```dart
final date = NepaliDate.fromBs(2081, 4, 15);
date.year; // => 2081
date.month; // => 4
date.day; // => 15
date.monthEnum; // => Month.shrawan
date.weekday; // => Weekday.tuesday
date.dayOfYear; // => 109
date.monthLength; // => 32
date.yearLength; // => 366
date.lastDayOfMonth.toString(); // => 2081/04/32
date.ymd; // => 20810415
date.fiscalYear.label(); // => 2081/82
date.quarter; // => Quarter.q1
date.toRecord(); // => (2081, 4, 15)
date.toDateTime().toIso8601String(); // => 2024-07-30T00:00:00.000Z
NepaliDate.min.toString(); // => 1901/01/01
NepaliDate.max.toString(); // => 2199/12/30
NepaliDate.fromBs(2081, 4, 15).compareTo(NepaliDate.fromBs(2081, 4, 16)); // => -1
NepaliDate.fromBs(2081, 4, 15) < NepaliDate.fromBs(2081, 4, 16); // => true
NepaliDate.fromBs(2081, 4, 15) == NepaliDate.fromBs(2081, 4, 15); // => true
```

The clock is injectable, so the relative predicates are deterministic in tests and in CI:

```dart
final clock = () => DateTime.utc(2024, 7, 30, 18, 30);
NepaliDate.today(clock: clock).toString(); // => 2081/04/16
NepaliDate.today(timeZone: 'UTC', clock: clock).toString(); // => 2081/04/15
NepaliDate.fromBs(2081, 4, 16).isToday('Asia/Kathmandu', clock: clock); // => true
NepaliDate.fromBs(2081, 4, 15).isYesterday('Asia/Kathmandu', clock: clock); // => true
NepaliDate.fromBs(2081, 4, 17).isTomorrow('Asia/Kathmandu', clock: clock); // => true
```

`timeZone` accepts `Asia/Kathmandu` (also spelled `Asia/Katmandu`), `UTC`, `GMT`, `Z`,
`Etc/UTC`, `Etc/GMT`, or a fixed offset such as `+05:45` or `-08:00`. Dart's core library has no
time zone database, so any other name is an `ArgumentError`. For the device's own zone, use
`NepaliDate.fromGregorian(DateTime.now())`.

## Conversion and serialization

| Member | Signature | Notes |
|---|---|---|
| `fromGregorian` | `NepaliDate.fromGregorian(DateTime date)` | Throws `outOfRange` outside the supported AD span. |
| `fromGregorianAll` | `static List<NepaliDate> fromGregorianAll(Iterable<DateTime> dates)` | Keeps order. |
| `parseAll` | `static List<DateTime> parseAll(Iterable<String> texts)` | Parses strictly, keeps order. |
| `toGregorianAll` | `static List<DateTime> toGregorianAll(Iterable<NepaliDate> dates)` | Keeps order. |
| `fromYmd` | `NepaliDate.fromYmd(int value)` | `20810415` is 2081-04-15. |
| `ymd` | `int get ymd` | The inverse. |
| `toJson` | `String toJson()` | `YYYY-MM-DD`, the one interchange form. |
| `fromJson` | `NepaliDate.fromJson(Object? json)` | Accepts only that string. |

```dart
NepaliDate.fromGregorian(DateTime.utc(2024, 7, 30)).toString(); // => 2081/04/15
NepaliDate.fromGregorianAll([DateTime.utc(2024, 7, 30)]).single.toString(); // => 2081/04/15
NepaliDate.parseAll(['2081-04-15']).single.toIso8601String(); // => 2024-07-30T00:00:00.000Z
NepaliDate.toGregorianAll([NepaliDate.min]).single.toIso8601String(); // => 1844-04-11T00:00:00.000Z
NepaliDate.fromYmd(20810415).toString(); // => 2081/04/15
NepaliDate.fromBs(2081, 4, 15).toJson(); // => 2081-04-15
NepaliDate.fromJson('2081-04-15').toString(); // => 2081/04/15
```

`toJson` returns a `String`, so a `jsonEncode` of a date gives `"2081-04-15"`, and `fromJson` accepts
that string, never a map or `null`. The object form, XML, Newtonsoft and the C# `TypeConverter` type
are not ported (`D-11`).

## Arithmetic

| Member | Signature | Notes |
|---|---|---|
| `addDays` | `NepaliDate addDays(int days)` | A negative value subtracts. |
| `addMonths` | `NepaliDate addMonths(int months, {MonthOverflow overflow = MonthOverflow.clamp})` | Whole months only. |
| `addYears` | `NepaliDate addYears(int years, {MonthOverflow overflow = MonthOverflow.clamp})` | `addMonths(12 * years)`. |
| `daysUntil` | `int daysUntil(NepaliDate other)` | `other - this` (`D-07`). |
| `diff` | `DateDiff diff(NepaliDate other)` | Whole years, months and days, signed. |
| `-` | `DateDiff operator -(NepaliDate other)` | `this - other`, the C# direction (`D-07`). |

`MonthOverflow.clamp` uses the last day of a shorter target month; `MonthOverflow.spill` carries the
extra days into the next month. The `DateDiff` fields are `negative`, `years`, `months`, `days` and
`totalDays`, and the breakdown counts from the earlier of the two dates.

```dart
final date = NepaliDate.fromBs(2081, 4, 32);
date.addDays(30).toString(); // => 2081/05/30
date.addDays(-31).toString(); // => 2081/04/01
date.addMonths(2).toString(); // => 2081/06/30
date.addMonths(2, overflow: MonthOverflow.spill).toString(); // => 2081/07/02
date.addMonths(-2).toString(); // => 2081/02/32
date.addYears(1).toString(); // => 2082/04/31
date.daysUntil(NepaliDate.fromBs(2081, 5, 1)); // => 1
(date - NepaliDate.fromBs(2081, 4, 15)).totalDays; // => 17
date.diff(NepaliDate.fromBs(2081, 5, 31)).months; // => 1
date.diff(NepaliDate.fromBs(2081, 5, 31)).days; // => 0
date.diff(NepaliDate.fromBs(2081, 5, 31)).negative; // => false
```

## Formatting

| Member | Signature | Notes |
|---|---|---|
| `toString` | `String toString()` | `YYYY/MM/DD`, ASCII digits. |
| `toShortString` | `String toShortString({DateOrder order = DateOrder.ymd, Separator separator = Separator.slash, bool pad = true, Lang lang = Lang.en})` | Any of six orders and six separators. |
| `toLongString` | `String toLongString({bool weekday = false, bool year = true, bool pad = true, Lang lang = Lang.en})` | `[Weekday, ]Month day[, year]`. |
| `format` | `String format(String pattern, {Lang lang = Lang.en})` | Standard patterns and the custom language. |
| `Lang` | `enum Lang { en, ne }` | English or Nepali names and digits. |
| `DateOrder` | `enum DateOrder { ymd, ydm, myd, mdy, dym, dmy }` | Field order. |
| `Separator` | `enum Separator { slash, backslash, dot, underscore, dash, space }` | `character` is the string. |
| `Month` | `enum Month { baishakh, ..., chaitra }` | `number`, `fullName`, `shortName`, `fromNumber`. |
| `Weekday` | `enum Weekday { sunday, ..., saturday }` | `fullName`, `shortName`. |

`format` accepts the standard patterns `''`, `G`, `g`, `d`, `D` and `s`, plus `yyyy` (four digits)
and longer runs, `yy` (two digits), `MMMM` (full month), `MMM` (three-letter abbreviation), `MM`,
`M`, `dd`, `d`, a backslash escape and a single-quoted literal. `MMM` writes `Asa` for Ashad and
`Aso` for Ashoj (`D-04`).

```dart
final date = NepaliDate.fromBs(2081, 4, 15);
date.toString(); // => 2081/04/15
date.toShortString(order: DateOrder.dmy, separator: Separator.dash); // => 15-04-2081
date.toShortString(order: DateOrder.mdy, separator: Separator.dot, pad: false); // => 4.15.2081
date.toShortString(lang: Lang.ne); // => २०८१/०४/१५
date.toLongString(); // => Shrawan 15, 2081
date.toLongString(weekday: true); // => Tuesday, Shrawan 15, 2081
date.toLongString(weekday: true, lang: Lang.ne); // => मङ्गलवार, साउन १५, २०८१
date.format('yyyy-MM-dd'); // => 2081-04-15
date.format('dd.MM.yyyy'); // => 15.04.2081
date.format('MMMM d, yyyy'); // => Shrawan 15, 2081
date.format('MMM yy'); // => Shr 81
date.format("'BS' yyyy"); // => BS 2081
date.format(r'\M\M d'); // => MM 15
Month.shrawan.number; // => 4
Month.shrawan.fullName(); // => Shrawan
Month.ashad.shortName(); // => Asa
Month.fromNumber(4); // => Month.shrawan
Weekday.tuesday.fullName(); // => Tuesday
Weekday.tuesday.shortName(); // => Tue
Separator.dash.character; // => -
DateOrder.dmy; // => DateOrder.dmy
Lang.ne; // => Lang.ne
```

## Parsing

| Member | Signature | Notes |
|---|---|---|
| `NepaliDate.parse` | `NepaliDate.parse(String text)` | Strict: year, month, day. |
| `tryParse` | `static NepaliDate? tryParse(String text)` | No throw. |
| `NepaliDate.parseLenient` | `NepaliDate.parseLenient(String text)` | Month names and reordered fields. |
| `tryParseLenient` | `static NepaliDate? tryParseLenient(String text)` | No throw. |

The strict parser accepts ASCII and Devanagari digits, up to four digits in a group, and the
separators `- / . _ \ space | ।`. Leading, trailing and repeated separators are ignored. The
lenient parser removes era markers (`B.S.`, `V.S.`, `बि.सं.`, `वि.सं.`), `गते` and `मिति`, matches
a month name from the closed list in English or Nepali, then reads the remaining two numbers as the
day and the four-digit year, in either order. A two-digit year is `ambiguous`, never guessed
(`D-06`).

Parse failures throw `NepDateException` with one of `ErrorKind.invalidCharacter`,
`wrongGroupCount`, `numberTooLong`, `ambiguous`, `unrecognized`, or the date validation kinds.

```dart
NepaliDate.parse('2081/04/15').toString(); // => 2081/04/15
NepaliDate.parse('२०८१/०४/१५').toString(); // => 2081/04/15
NepaliDate.parse('2081 04 15').toString(); // => 2081/04/15
NepaliDate.parseLenient('15 Shrawan 2081 B.S.').toString(); // => 2081/04/15
NepaliDate.parseLenient('Shrawan 15, 2081').toString(); // => 2081/04/15
NepaliDate.parseLenient('2081-04-15').toString(); // => 2081/04/15
NepaliDate.tryParse('2081/13/01'); // => null
NepaliDate.tryParseLenient('15 Foo 2081'); // => null
NepaliDate.parse('2081-04-15'); // => 2081/04/15
```

`parseLenient` of a string that already parses strictly returns the strict result.

## Ranges

A `NepaliDateRange` is inclusive and never empty. It extends `IterableBase`, so it iterates its days
in order, and it has value equality.

| Member | Signature | Notes |
|---|---|---|
| `NepaliDateRange.of` | `NepaliDateRange.of(NepaliDate start, NepaliDate end)` | `end` before `start` throws `outOfRange` (`D-01`). |
| `singleDay` | `static NepaliDateRange singleDay(NepaliDate date)` | One day. |
| `fromDayCount` | `static NepaliDateRange fromDayCount(NepaliDate start, int days)` | `days` at least 1, else `ArgumentError`. |
| `forMonth` | `static NepaliDateRange forMonth(int year, int month)` | Day 1 to month end. |
| `forYear` | `static NepaliDateRange forYear(int year)` | 1 Baishakh to Chaitra end. |
| `currentMonth` | `static NepaliDateRange currentMonth({String timeZone = 'Asia/Kathmandu', DateTime Function()? clock})` | The month containing today. |
| `currentFiscalYear` | `static NepaliDateRange currentFiscalYear({String timeZone = 'Asia/Kathmandu', DateTime Function()? clock})` | The fiscal year containing today. |
| `currentCalendarYear` | `static NepaliDateRange currentCalendarYear({String timeZone = 'Asia/Kathmandu', DateTime Function()? clock})` | The BS year containing today. |
| `start`, `end` | `final NepaliDate` | The bounds, both included. |
| `length` | `int get length` | Number of days, at least 1. |
| `first`, `last` | `NepaliDate get first`, `last` | The bounds as `Iterable` members. |
| `contains` | `bool contains(Object? date)` | A date on or between the bounds. |
| `containsRange` | `bool containsRange(NepaliDateRange other)` | Every day of `other`. |
| `overlaps` | `bool overlaps(NepaliDateRange other)` | At least one shared day. |
| `isAdjacentTo` | `bool isAdjacentTo(NepaliDateRange other)` | One starts the day after the other ends. |
| `intersect` | `NepaliDateRange? intersect(NepaliDateRange other)` | `null` when disjoint. |
| `union` | `NepaliDateRange union(NepaliDateRange other)` | Smallest covering range. |
| `except` | `List<NepaliDateRange> except(NepaliDateRange other)` | Zero, one or two pieces. |
| `splitByMonth` | `List<NepaliDateRange> splitByMonth()` | One piece per month touched. |
| `splitByFiscalQuarter` | `List<NepaliDateRange> splitByFiscalQuarter()` | One piece per fiscal quarter touched. |
| `datesWithInterval` | `Iterable<NepaliDate> datesWithInterval(int interval)` | Every interval days; `ArgumentError` below 1. |
| `workingDays` | `Iterable<NepaliDate> workingDays({bool excludeSunday = false})` | Every day except Saturday, and Sunday when asked. |
| `weekendDays` | `Iterable<NepaliDate> weekendDays({bool includeSunday = true})` | Every Saturday, and Sunday when asked. |
| `iterator` | `Iterator<NepaliDate> get iterator` | Every day. |
| `toStringWith` | `String toStringWith(DateOrder order, [Separator separator = Separator.slash, Lang lang = Lang.en])` | Both bounds formatted. |
| `toString` | `String toString()` | `start - end`. |
| `==`, `hashCode` | value equality | The two bounds. |

```dart
final range = NepaliDateRange.of(
  NepaliDate.fromBs(2081, 4, 10),
  NepaliDate.fromBs(2081, 4, 20),
);
NepaliDateRange.singleDay(NepaliDate.fromBs(2081, 4, 15)).length; // => 1
NepaliDateRange.fromDayCount(NepaliDate.fromBs(2081, 4, 15), 5).toString();
// => 2081/04/15 - 2081/04/19
NepaliDateRange.forMonth(2081, 4).length; // => 32
NepaliDateRange.forYear(2081).length; // => 366
range.length; // => 11
range.start.toString(); // => 2081/04/10
range.end.toString(); // => 2081/04/20
range.contains(NepaliDate.fromBs(2081, 4, 15)); // => true
range.containsRange(NepaliDateRange.forMonth(2081, 4)); // => false
range.overlaps(NepaliDateRange.forMonth(2081, 4)); // => true
NepaliDateRange.forMonth(2081, 4).isAdjacentTo(NepaliDateRange.forMonth(2081, 5)); // => true
range.intersect(NepaliDateRange.forMonth(2081, 5)); // => null
range.union(NepaliDateRange.forMonth(2081, 5)).toString(); // => 2081/04/10 - 2081/05/31
range.except(NepaliDateRange.forMonth(2081, 4)).length; // => 0
range.splitByMonth().length; // => 1
range.datesWithInterval(5).length; // => 3
range.workingDays().length; // => 9
range.weekendDays().length; // => 4
range.toString(); // => 2081/04/10 - 2081/04/20
range.toStringWith(DateOrder.dmy, Separator.dash); // => 10-04-2081 - 20-04-2081
NepaliDateRange.currentMonth(timeZone: 'UTC', clock: () => DateTime.utc(2024, 7, 30)).toString();
// => 2081/04/01 - 2081/04/32
NepaliDateRange.currentFiscalYear(timeZone: 'UTC', clock: () => DateTime.utc(2024, 7, 30)).toString();
// => 2081/04/01 - 2082/03/32
NepaliDateRange.currentCalendarYear(timeZone: 'UTC', clock: () => DateTime.utc(2024, 7, 30)).toString();
// => 2081/01/01 - 2081/12/31
```

`D-16` is why a range that reaches 2199-12-30 still works: the splits, the day helpers,
`isAdjacentTo` and `intersect` never step past the data end to throw.

## Fiscal year

| Member | Signature | Notes |
|---|---|---|
| `FiscalYear` | `const FiscalYear(int startYear)` | The BS year in which 1 Shrawan falls. |
| `containing` | `factory FiscalYear.containing(NepaliDate date)` | The fiscal year of a date. |
| `startYear` | `final int startYear` | The stored year. |
| `start` | `NepaliDate start()` | 1 Shrawan of `startYear`. |
| `end` | `NepaliDate end()` | Last day of Ashad of `startYear + 1`. |
| `range` | `NepaliDateRange range()` | The whole fiscal year. |
| `quarterRange` | `NepaliDateRange quarterRange(Quarter q)` | One quarter. |
| `label` | `String label([Lang lang = Lang.en])` | `2082/83`, or `२०८२/८३`. |
| `Quarter` | `enum Quarter { q1, q2, q3, q4 }` | Q1 Shrawan to Ashoj, Q4 Baishakh to Ashad. |
| `number` | `int get number` | 1 to 4. |

```dart
final fiscal = FiscalYear(2082);
fiscal.startYear; // => 2082
fiscal.start().toString(); // => 2082/04/01
fiscal.end().toString(); // => 2083/03/32
fiscal.range().toString(); // => 2082/04/01 - 2083/03/32
fiscal.quarterRange(Quarter.q1).toString(); // => 2082/04/01 - 2082/06/31
fiscal.quarterRange(Quarter.q4).toString(); // => 2083/01/01 - 2083/03/32
fiscal.label(); // => 2082/83
fiscal.label(Lang.ne); // => २०८२/८३
FiscalYear.containing(NepaliDate.fromBs(2082, 2, 1)).label(); // => 2081/82
Quarter.q4.number; // => 4
```

`FiscalYear` replaces the C# `yearOffset` arguments and the static `GetFiscalYear*` helpers (`D-08`).
The vector columns for fiscal start, end and quarters still match.

## Patro

The `nepdate_patro` package is the second library. `info` never throws, and a day without data or
outside the coverage gets one shared empty `CalendarInfo`.

| Member | Signature | Notes |
|---|---|---|
| `info` | `CalendarInfo info(NepaliDate date)` | The tithi, holiday flag and events of a day. |
| `coverage` | `NepaliDateRange coverage()` | The smallest range holding every day with data. |
| `publicHolidays` | `Iterable<NepaliDate> publicHolidays()` | Every gazetted holiday, ascending. |
| `CalendarInfo.tithi` | `final Named? tithi` | `null` when the day has none. |
| `CalendarInfo.isPublicHoliday` | `final bool isPublicHoliday` | The gazetted flag. |
| `CalendarInfo.events` | `final List<Named> events` | File order, unmodifiable, empty when none. |
| `Named.nepali`, `english` | `final String` | The two names, exactly as the data has them. |
| `Named.name` | `String name(Lang lang)` | `nepali` for `Lang.ne`, else `english`. |

```dart
final day = info(NepaliDate.fromBs(2081, 1, 1));
day.tithi?.english; // => Panchami
day.tithi?.nepali; // => पञ्चमी
day.isPublicHoliday; // => true
day.events.map((event) => event.english).toList(); // => [New Year, Mesh Sankranti, Bisket Jatra]
day.events.first.name(Lang.ne); // => नयाँ वर्ष
info(NepaliDate.fromBs(2081, 2, 15)).events.single.english; // => Republic Day
info(NepaliDate.fromBs(2090, 1, 1)).events; // => []
coverage().start.toString(); // => 2077/01/01
coverage().end.toString(); // => 2084/08/20
publicHolidays().first.toString(); // => 2077/01/01
publicHolidays().length; // => 294
```

The counts come from `shared/spec/vectors/patro-summary.json`: 2,190 tithi days, 294 holidays, 1,671
event days and 3,032 events. The tithi range is 2078-01-02 to 2083-12-30; the whole data range is
2077-01-01 to 2084-08-20.

## Errors

| Member | Signature | Notes |
|---|---|---|
| `NepDateException` | `const NepDateException(ErrorKind kind, String message)` | The one exception type. |
| `kind` | `final ErrorKind kind` | Which check failed. |
| `message` | `final String message` | A human-readable description. |
| `toString` | `String toString()` | `NepDateException(kind): message`. |
| `ErrorKind` | `enum ErrorKind` | `outOfRange`, `invalidMonth`, `invalidDay`, `invalidCharacter`, `wrongGroupCount`, `numberTooLong`, `ambiguous`, `unrecognized`. |

A bad argument that has nothing to do with the calendar, such as an interval below 1 or an unknown
zone name, throws `ArgumentError` instead.

```dart
try {
  NepaliDate.fromBs(2081, 13, 1);
} on NepDateException catch (error) {
  error.kind; // => ErrorKind.invalidMonth
}
const error = NepDateException(ErrorKind.invalidDay, 'day 33 does not exist');
error.kind; // => ErrorKind.invalidDay
error.toString(); // => NepDateException(invalidDay): day 33 does not exist
```
