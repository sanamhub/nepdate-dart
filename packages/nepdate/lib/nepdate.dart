/// Bikram Sambat (the Nepali calendar) dates for Dart and Flutter.
///
/// Convert to and from Gregorian, add days, months and years, format in English or Nepali, parse
/// text, work with ranges and fiscal years. The package is pure Dart with no dependencies and runs
/// on every platform, the web included.
///
/// ```dart
/// final date = NepaliDate.fromBs(2081, 4, 15);
/// date.toDateTime().toIso8601String(); // => 2024-07-30T00:00:00.000Z
/// date.toLongString(weekday: true); // => Tuesday, Shrawan 15, 2081
/// ```
///
/// The tithi, public holidays and events live in the separate `nepdate_patro` package.
library;

import 'dart:collection' show IterableBase;

import 'src/calendar.g.dart';

part 'src/date.dart';
part 'src/errors.dart';
part 'src/fiscal.dart';
part 'src/format.dart';
part 'src/gregorian.dart';
part 'src/names.dart';
part 'src/parse.dart';
part 'src/range.dart';
