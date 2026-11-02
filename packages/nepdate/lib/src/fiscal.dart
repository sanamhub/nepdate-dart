part of '../nepdate.dart';

/// A quarter of the fiscal year: Q1 is Shrawan to Ashoj, Q4 is Baishakh to Ashad.
///
/// ```dart
/// NepaliDate.fromBs(2082, 4, 1).quarter; // => Quarter.q1
/// Quarter.q4.number; // => 4
/// ```
enum Quarter {
  /// Shrawan to Ashoj.
  q1,

  /// Kartik to Poush.
  q2,

  /// Magh to Chaitra.
  q3,

  /// Baishakh to Ashad of the next BS year.
  q4;

  /// The quarter number, 1 to 4.
  int get number => index + 1;
}

/// Day 1 of BS month [year]-[month], or an out-of-range error for a year outside 1901 to 2199.
NepaliDate _firstOf(int year, int month) {
  if (year < kMinYear || year > kMaxYear) {
    throw NepDateException(ErrorKind.outOfRange, 'year $year is outside $kMinYear..$kMaxYear');
  }
  return NepaliDate.fromBs(year, month, 1);
}

/// A Nepali fiscal year, 1 Shrawan to the end of Ashad of the next BS year (ALGORITHM section 8b).
/// FY 2082/83 is `FiscalYear(2082)`.
///
/// ```dart
/// FiscalYear(2082).label(); // => 2082/83
/// FiscalYear(2082).label(Lang.ne); // => २०८२/८३
/// ```
final class FiscalYear {
  /// The fiscal year that starts on 1 Shrawan of [startYear]. Any integer is accepted; the methods
  /// that return dates throw an out-of-range [NepDateException] when the date is outside BS
  /// 1901 to 2199.
  const FiscalYear(this.startYear);

  /// The fiscal year that contains [date].
  ///
  /// ```dart
  /// FiscalYear.containing(NepaliDate.fromBs(2082, 2, 1)).label(); // => 2081/82
  /// ```
  factory FiscalYear.containing(NepaliDate date) =>
      FiscalYear(date.month >= 4 ? date.year : date.year - 1);

  /// The BS year in which the fiscal year starts.
  final int startYear;

  /// 1 Shrawan of [startYear].
  ///
  /// ```dart
  /// FiscalYear(2082).start().toString(); // => 2082/04/01
  /// ```
  NepaliDate start() => _firstOf(startYear, 4);

  /// The last day of Ashad of the next BS year.
  ///
  /// ```dart
  /// FiscalYear(2081).end().toString(); // => 2082/03/32
  /// ```
  NepaliDate end() => _firstOf(startYear + 1, 3).lastDayOfMonth;

  /// Every day of the fiscal year.
  ///
  /// ```dart
  /// FiscalYear(2080).range().toString(); // => 2080/04/01 - 2081/03/31
  /// ```
  NepaliDateRange range() => NepaliDateRange.of(start(), end());

  /// Every day of quarter [q]: Q1 Shrawan to Ashoj, Q2 Kartik to Poush, Q3 Magh to Chaitra, Q4
  /// Baishakh to Ashad of the next BS year.
  ///
  /// ```dart
  /// FiscalYear(2081).quarterRange(Quarter.q4).toString(); // => 2082/01/01 - 2082/03/32
  /// ```
  NepaliDateRange quarterRange(Quarter q) {
    final year = q == Quarter.q4 ? startYear + 1 : startYear;
    final month = q == Quarter.q4 ? 1 : q.number * 3 + 1;
    return NepaliDateRange.of(_firstOf(year, month), _firstOf(year, month + 2).lastDayOfMonth);
  }

  /// `2082/83`, or `२०८२/८३` in Nepali.
  String label([Lang lang = Lang.en]) {
    final next = (startYear + 1) % 100;
    return _localize('$startYear/${_pad(next, 2)}', lang);
  }

  @override
  bool operator ==(Object other) => other is FiscalYear && other.startYear == startYear;

  @override
  int get hashCode => startYear.hashCode;

  @override
  String toString() => label();
}
