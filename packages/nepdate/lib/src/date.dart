part of '../nepdate.dart';

const int _months = (kMaxYear - kMinYear + 1) * 12;
const int _maxSerial = kTotalDays - 1;

/// Zone used when none is given: Nepal Standard Time.
const String _nepalZone = 'Asia/Kathmandu';

/// The calendar breakdown between two dates, from [NepaliDate.diff] or the `-` operator.
///
/// ```dart
/// final diff = NepaliDate.fromBs(2080, 1, 1).diff(NepaliDate.fromBs(2081, 4, 15));
/// (diff.years, diff.months, diff.days, diff.totalDays); // => (1, 3, 14, 473)
/// ```
final class DateDiff {
  const DateDiff._(this.negative, this.years, this.months, this.days, this.totalDays);

  /// True when the second date is before the first.
  final bool negative;

  /// Whole years, 0 to 298.
  final int years;

  /// Whole months after the years, 0 to 11.
  final int months;

  /// Days after the months, 0 to 32.
  final int days;

  /// The signed day difference. For [NepaliDate.diff] it is `other - this`, the same as
  /// [NepaliDate.daysUntil]. For the `-` operator it is `this - other`.
  final int totalDays;

  @override
  bool operator ==(Object other) =>
      other is DateDiff &&
      other.negative == negative &&
      other.years == years &&
      other.months == months &&
      other.days == days &&
      other.totalDays == totalDays;

  @override
  int get hashCode => Object.hash(negative, years, months, days, totalDays);

  @override
  String toString() =>
      'DateDiff(${negative ? '-' : '+'}${years}y ${months}m ${days}d, $totalDays days)';
}

/// A Bikram Sambat date from 1901-01-01 to 2199-12-30 (AD 1844-04-11 to 2143-04-15).
///
/// A value is always a real date of the calendar: the constructors throw a [NepDateException] for
/// anything else, so there is no invalid or default date. Values are immutable and compare by
/// date.
///
/// ```dart
/// final date = NepaliDate.fromBs(2081, 4, 15);
/// date.toString(); // => 2081/04/15
/// date.toDateTime().toIso8601String(); // => 2024-07-30T00:00:00.000Z
/// ```
final class NepaliDate implements Comparable<NepaliDate> {
  const NepaliDate._(this.year, this.month, this.day, this._serial);

  /// Builds a date from BS [year], [month] and [day], checking them in that order.
  ///
  /// Throws a [NepDateException] of kind [ErrorKind.outOfRange] for a year outside 1901 to 2199,
  /// [ErrorKind.invalidMonth] for a month outside 1 to 12, and [ErrorKind.invalidDay] for a day
  /// that the month does not have. Months have 29 to 32 days; Shrawan 2081 has 32.
  ///
  /// ```dart
  /// NepaliDate.fromBs(2081, 4, 32).toString(); // => 2081/04/32
  /// ```
  factory NepaliDate.fromBs(int year, int month, int day) {
    if (year < kMinYear || year > kMaxYear) {
      throw NepDateException(ErrorKind.outOfRange, 'year $year is outside $kMinYear..$kMaxYear');
    }
    if (month < 1 || month > 12) {
      throw NepDateException(ErrorKind.invalidMonth, 'month $month is outside 1..12');
    }
    final index = (year - kMinYear) * 12 + month - 1;
    final start = kMonthStart[index];
    final length = kMonthStart[index + 1] - start;
    if (day < 1 || day > length) {
      throw NepDateException(
        ErrorKind.invalidDay,
        'day $day is outside 1..$length for $year-${_pad(month, 2)}',
      );
    }
    return NepaliDate._(year, month, day, start + day - 1);
  }

  /// Parses `year month day` in that order, strictly (PARSING section 1).
  ///
  /// Accepts ASCII and Devanagari digits, up to four digits per number, and the separators
  /// `- / . _ \ space । |`. Leading, trailing and repeated separators are ignored.
  ///
  /// Throws a [NepDateException] whose kind says why: [ErrorKind.invalidCharacter],
  /// [ErrorKind.wrongGroupCount], [ErrorKind.numberTooLong], or the validation kinds of
  /// [NepaliDate.fromBs].
  ///
  /// ```dart
  /// NepaliDate.parse('२०८१/०४/१५').toString(); // => 2081/04/15
  /// ```
  factory NepaliDate.parse(String text) => _parsedOrThrow(_parseStrict(text));

  /// Like [NepaliDate.parse], but returns `null` instead of throwing.
  ///
  /// ```dart
  /// NepaliDate.tryParse('2081/13/01'); // => null
  /// ```
  static NepaliDate? tryParse(String text) => _parseStrict(text).date;

  /// Parses text a person typed (PARSING section 2): month names in English or Nepali, the day
  /// before the year, era markers such as `B.S.`. It rejects rather than guesses, so a two-digit
  /// year is [ErrorKind.ambiguous].
  ///
  /// Throws a [NepDateException]; the kind is one of those of [NepaliDate.parse] plus
  /// [ErrorKind.ambiguous] and [ErrorKind.unrecognized].
  ///
  /// ```dart
  /// NepaliDate.parseLenient('15 Shrawan 2081 B.S.').toString(); // => 2081/04/15
  /// ```
  factory NepaliDate.parseLenient(String text) => _parsedOrThrow(_parseLenient(text));

  /// Like [NepaliDate.parseLenient], but returns `null` instead of throwing.
  ///
  /// ```dart
  /// NepaliDate.tryParseLenient('15 Foo 2081'); // => null
  /// ```
  static NepaliDate? tryParseLenient(String text) => _parseLenient(text).date;

  /// The BS date of the Gregorian date that [date] shows. The time of day is ignored, and so is
  /// the zone: a local [DateTime] converts the day it shows on the wall clock.
  ///
  /// Throws a [NepDateException] of kind [ErrorKind.outOfRange] for a date before 1844-04-11 or
  /// after 2143-04-15.
  ///
  /// ```dart
  /// NepaliDate.fromGregorian(DateTime.utc(2024, 7, 30)).toString(); // => 2081/04/15
  /// ```
  factory NepaliDate.fromGregorian(DateTime date) {
    final year = date.year;
    if (year < 1844 || year > 2143) throw _gregorianOutOfRange(date);
    final serial = _daysFromCivil(year, date.month, date.day) - kEpochUnixDays;
    if (serial < 0 || serial > _maxSerial) throw _gregorianOutOfRange(date);
    return _fromSerial(serial);
  }

  /// The date of a `YYYYMMDD` integer, for example `20810415`.
  ///
  /// Throws a [NepDateException] when the digits are not a real date of the calendar.
  ///
  /// ```dart
  /// NepaliDate.fromYmd(20810415).toString(); // => 2081/04/15
  /// ```
  factory NepaliDate.fromYmd(int value) => NepaliDate.fromBs(
        value ~/ 10000,
        (value ~/ 100).remainder(100),
        value.remainder(100),
      );

  /// The date written by [toJson], read back. Reads the string `YYYY-MM-DD` the way
  /// [NepaliDate.parse] does.
  ///
  /// Throws a [NepDateException] for anything that is not such a string, `null` included.
  ///
  /// ```dart
  /// NepaliDate.fromJson('2081-04-15').toString(); // => 2081/04/15
  /// ```
  factory NepaliDate.fromJson(Object? json) {
    if (json is! String) {
      throw NepDateException(
        ErrorKind.unrecognized,
        'expected a YYYY-MM-DD string, got ${json == null ? 'null' : json.runtimeType}',
      );
    }
    return NepaliDate.parse(json);
  }

  /// Today in the zone [timeZone], from [clock] (the system clock by default).
  ///
  /// Dart's core library has no time zone database, so [timeZone] is one of `Asia/Kathmandu` (the
  /// default), `UTC`, or a fixed offset such as `+05:45` or `-08:00`. Anything else is an
  /// [ArgumentError]. To use the device's own zone, convert `DateTime.now()` with
  /// [NepaliDate.fromGregorian].
  ///
  /// Throws a [NepDateException] of kind [ErrorKind.outOfRange] when the clock is before AD
  /// 1844-04-11 or after 2143-04-15.
  ///
  /// ```dart
  /// NepaliDate.today(clock: () => DateTime.utc(2024, 7, 30, 18, 30)).toString(); // => 2081/04/16
  /// NepaliDate.today(timeZone: 'UTC', clock: () => DateTime.utc(2024, 7, 30, 18, 30))
  ///     .toString(); // => 2081/04/15
  /// ```
  factory NepaliDate.today({String timeZone = _nepalZone, DateTime Function()? clock}) {
    final serial = _todaySerial(timeZone, clock);
    if (serial < 0 || serial > _maxSerial) {
      throw const NepDateException(ErrorKind.outOfRange, 'the clock is outside AD 1844..2143');
    }
    return _fromSerial(serial);
  }

  /// The first supported date, BS 1901-01-01 (AD 1844-04-11).
  static const NepaliDate min = NepaliDate._(kMinYear, 1, 1, 0);

  /// The last supported date, BS 2199-12-30 (AD 2143-04-15).
  static const NepaliDate max = NepaliDate._(kMaxYear, 12, 30, _maxSerial);

  /// Converts every date in [dates], in order. Throws as [NepaliDate.fromGregorian] on the first
  /// date that is out of range.
  ///
  /// ```dart
  /// NepaliDate.fromGregorianAll([DateTime.utc(2024, 7, 30)]).single.toString(); // => 2081/04/15
  /// ```
  static List<NepaliDate> fromGregorianAll(Iterable<DateTime> dates) =>
      [for (final date in dates) NepaliDate.fromGregorian(date)];

  /// Parses every text with [NepaliDate.parse] and returns the Gregorian dates, in order. The
  /// whole call throws if one text does not parse.
  ///
  /// ```dart
  /// NepaliDate.parseAll(['2081-04-15']).single.toIso8601String(); // => 2024-07-30T00:00:00.000Z
  /// ```
  static List<DateTime> parseAll(Iterable<String> texts) =>
      [for (final text in texts) NepaliDate.parse(text).toDateTime()];

  /// The Gregorian date of every date in [dates], in order.
  ///
  /// ```dart
  /// NepaliDate.toGregorianAll([NepaliDate.min]).single.toIso8601String(); // => 1844-04-11T00:00:00.000Z
  /// ```
  static List<DateTime> toGregorianAll(Iterable<NepaliDate> dates) =>
      [for (final date in dates) date.toDateTime()];

  /// The BS year, 1901 to 2199.
  final int year;

  /// The BS month number, 1 to 12.
  final int month;

  /// The day of the month, 1 to [monthLength].
  final int day;

  final int _serial;

  /// The month as a [Month].
  Month get monthEnum => Month.values[month - 1];

  /// The day of the week.
  Weekday get weekday => Weekday.values[(_serial + 4) % 7];

  /// The 1-based day number in the BS year, up to [yearLength].
  int get dayOfYear => _serial - kMonthStart[(year - kMinYear) * 12] + 1;

  /// The number of days in this date's month, 29 to 32.
  int get monthLength {
    final index = (year - kMinYear) * 12 + month - 1;
    return kMonthStart[index + 1] - kMonthStart[index];
  }

  /// The number of days in this date's BS year, 364 to 367.
  ///
  /// This replaces C# `IsLeapYear()`, which follows the Gregorian year (D-12).
  int get yearLength {
    final first = (year - kMinYear) * 12;
    return kMonthStart[first + 12] - kMonthStart[first];
  }

  /// The last day of this date's month.
  NepaliDate get lastDayOfMonth {
    final length = monthLength;
    return NepaliDate._(year, month, length, _serial + length - day);
  }

  /// The `YYYYMMDD` integer of this date, for example `20810415`.
  int get ymd => year * 10000 + month * 100 + day;

  /// The fiscal year that contains this date (ALGORITHM section 8b).
  ///
  /// ```dart
  /// NepaliDate.fromBs(2082, 1, 15).fiscalYear.label(); // => 2081/82
  /// ```
  FiscalYear get fiscalYear => FiscalYear.containing(this);

  /// The fiscal quarter that contains this date.
  ///
  /// ```dart
  /// NepaliDate.fromBs(2082, 1, 15).quarter; // => Quarter.q4
  /// ```
  Quarter get quarter => month >= 4 ? Quarter.values[(month - 4) ~/ 3] : Quarter.q4;

  /// The year, month and day as a record, for destructuring.
  ///
  /// ```dart
  /// final (year, month, day) = NepaliDate.fromBs(2081, 4, 15).toRecord();
  /// ```
  (int, int, int) toRecord() => (year, month, day);

  /// The Gregorian date at midnight UTC.
  ///
  /// ```dart
  /// NepaliDate.min.toDateTime().toIso8601String(); // => 1844-04-11T00:00:00.000Z
  /// ```
  DateTime toDateTime() {
    final (y, m, d) = _civilFromDays(_serial + kEpochUnixDays);
    return DateTime.utc(y, m, d);
  }

  /// True when this is today in [timeZone] (see [NepaliDate.today] for the accepted zones).
  /// A clock outside the supported range makes every date not today.
  ///
  /// ```dart
  /// NepaliDate.fromBs(2081, 4, 16)
  ///     .isToday('Asia/Kathmandu', clock: () => DateTime.utc(2024, 7, 30, 18, 30)); // => true
  /// ```
  bool isToday(String timeZone, {DateTime Function()? clock}) =>
      _todaySerial(timeZone, clock) == _serial;

  /// True when this is the day before today in [timeZone].
  ///
  /// ```dart
  /// NepaliDate.fromBs(2081, 4, 15)
  ///     .isYesterday('Asia/Kathmandu', clock: () => DateTime.utc(2024, 7, 30, 18, 30)); // => true
  /// ```
  bool isYesterday(String timeZone, {DateTime Function()? clock}) =>
      _todaySerial(timeZone, clock) - 1 == _serial;

  /// True when this is the day after today in [timeZone].
  ///
  /// ```dart
  /// NepaliDate.fromBs(2081, 4, 17)
  ///     .isTomorrow('Asia/Kathmandu', clock: () => DateTime.utc(2024, 7, 30, 18, 30)); // => true
  /// ```
  bool isTomorrow(String timeZone, {DateTime Function()? clock}) =>
      _todaySerial(timeZone, clock) + 1 == _serial;

  /// The date [days] later, or earlier when negative.
  ///
  /// Throws a [NepDateException] of kind [ErrorKind.outOfRange] past either end of the calendar.
  ///
  /// ```dart
  /// NepaliDate.fromBs(2081, 4, 15).addDays(30).toString(); // => 2081/05/13
  /// ```
  NepaliDate addDays(int days) {
    final serial = _serial + days;
    if (serial < 0 || serial > _maxSerial) throw _outOfRange('$this + $days days');
    return _fromSerial(serial);
  }

  /// The date [months] months later, or earlier when negative, on the same day of the month. When
  /// that month is shorter, [MonthOverflow.clamp] (the default) gives its last day and
  /// [MonthOverflow.spill] carries the extra days into the next month.
  ///
  /// Throws a [NepDateException] of kind [ErrorKind.outOfRange] past either end of the calendar.
  ///
  /// ```dart
  /// NepaliDate.fromBs(2081, 4, 32).addMonths(2).toString(); // => 2081/06/30
  /// NepaliDate.fromBs(2081, 4, 32).addMonths(2, overflow: MonthOverflow.spill).toString();
  /// // => 2081/07/02
  /// ```
  NepaliDate addMonths(int months, {MonthOverflow overflow = MonthOverflow.clamp}) {
    if (months < -_months || months > _months) throw _outOfRange('$this + $months months');
    return _shiftMonths(months, overflow);
  }

  /// The date [years] years later, or earlier when negative: [addMonths] with `12 * years`.
  ///
  /// ```dart
  /// NepaliDate.fromBs(2081, 4, 15).addYears(-1).toString(); // => 2080/04/15
  /// ```
  NepaliDate addYears(int years, {MonthOverflow overflow = MonthOverflow.clamp}) {
    if (years < -(kMaxYear - kMinYear) || years > kMaxYear - kMinYear) {
      throw _outOfRange('$this + $years years');
    }
    return _shiftMonths(12 * years, overflow);
  }

  NepaliDate _shiftMonths(int months, MonthOverflow overflow) {
    final target = (year - kMinYear) * 12 + month - 1 + months;
    if (target < 0 || target >= _months) throw _outOfRange('$this + $months months');
    final start = kMonthStart[target];
    final length = kMonthStart[target + 1] - start;
    final targetYear = kMinYear + target ~/ 12;
    final targetMonth = target % 12 + 1;
    if (day <= length) return NepaliDate._(targetYear, targetMonth, day, start + day - 1);
    if (overflow == MonthOverflow.clamp) {
      return NepaliDate._(targetYear, targetMonth, length, start + length - 1);
    }
    if (target + 1 >= _months) throw _outOfRange('$this + $months months');
    return targetMonth == 12
        ? NepaliDate._(targetYear + 1, 1, day - length, start + day - 1)
        : NepaliDate._(targetYear, targetMonth + 1, day - length, start + day - 1);
  }

  /// The signed number of days from this date to [other]: `other - this`, positive when [other]
  /// is later. The `-` operator has the opposite sign (D-07).
  ///
  /// ```dart
  /// NepaliDate.fromBs(2081, 4, 15).daysUntil(NepaliDate.fromBs(2081, 4, 16)); // => 1
  /// ```
  int daysUntil(NepaliDate other) => other._serial - _serial;

  /// Years, months and days from this date to [other], counted from the earlier of the two
  /// (ALGORITHM section 8a). [DateDiff.totalDays] is the same as [daysUntil].
  ///
  /// ```dart
  /// NepaliDate.fromBs(2081, 4, 32).diff(NepaliDate.fromBs(2081, 5, 31)).months; // => 1
  /// ```
  DateDiff diff(NepaliDate other) {
    final total = other._serial - _serial;
    final negative = total < 0;
    final from = negative ? other : this;
    final to = negative ? this : other;
    // The month count from the fields is right or one too many, never too few.
    var count = (to.year - from.year) * 12 + to.month - from.month;
    var middle = from._clampedSerial(count);
    if (middle > to._serial) middle = from._clampedSerial(--count);
    return DateDiff._(negative, count ~/ 12, count % 12, to._serial - middle, total);
  }

  /// Serial of this date moved by [months] with clamp; the caller knows the target is in range.
  int _clampedSerial(int months) {
    final target = (year - kMinYear) * 12 + month - 1 + months;
    final start = kMonthStart[target];
    final length = kMonthStart[target + 1] - start;
    return start + (day <= length ? day : length) - 1;
  }

  /// The difference as the C# `-` operator gives it: `this - other`, positive when this date is
  /// later (D-07). [DateDiff.totalDays] is `this - other`, so `a - b` is `b.diff(a)`.
  ///
  /// ```dart
  /// (NepaliDate.fromBs(2081, 4, 16) - NepaliDate.fromBs(2081, 4, 15)).totalDays; // => 1
  /// ```
  DateDiff operator -(NepaliDate other) => other.diff(this);

  /// Whether this date is before [other].
  bool operator <(NepaliDate other) => _serial < other._serial;

  /// Whether this date is before or the same as [other].
  bool operator <=(NepaliDate other) => _serial <= other._serial;

  /// Whether this date is after [other].
  bool operator >(NepaliDate other) => _serial > other._serial;

  /// Whether this date is after or the same as [other].
  bool operator >=(NepaliDate other) => _serial >= other._serial;

  @override
  int compareTo(NepaliDate other) => _serial.compareTo(other._serial);

  @override
  bool operator ==(Object other) => other is NepaliDate && other._serial == _serial;

  @override
  int get hashCode => _serial;

  /// `YYYY/MM/DD` with ASCII digits.
  @override
  String toString() => '${_pad(year, 4)}/${_pad(month, 2)}/${_pad(day, 2)}';

  /// `YYYY-MM-DD`, the canonical text form for JSON. Read it back with [NepaliDate.fromJson].
  ///
  /// ```dart
  /// NepaliDate.fromBs(2081, 4, 15).toJson(); // => 2081-04-15
  /// ```
  String toJson() => '${_pad(year, 4)}-${_pad(month, 2)}-${_pad(day, 2)}';

  /// The three parts in [order], joined by [separator]. With [pad] the year has four digits and
  /// the month and day two; without it none are padded.
  ///
  /// ```dart
  /// NepaliDate.fromBs(2080, 5, 15).toShortString(order: DateOrder.dmy, separator: Separator.dash,
  ///     pad: false); // => 15-5-2080
  /// ```
  String toShortString({
    DateOrder order = DateOrder.ymd,
    Separator separator = Separator.slash,
    bool pad = true,
    Lang lang = Lang.en,
  }) =>
      _short(this, order, separator, pad, lang);

  /// `[Weekday, ]Month day[, year]` in [lang]. [pad] pads the day to two digits.
  ///
  /// ```dart
  /// NepaliDate.fromBs(2081, 4, 15).toLongString(weekday: true); // => Tuesday, Shrawan 15, 2081
  /// ```
  String toLongString({
    bool weekday = false,
    bool year = true,
    bool pad = true,
    Lang lang = Lang.en,
  }) =>
      _long(this, weekday, year, pad, lang);

  /// Formats with a pattern (FORMATTING section 5): `yyyy`, `yy`, `MMMM`, `MMM`, `MM`, `M`, `dd`,
  /// `d`, `\x` for a literal character and `'text'` for literal text. The single letters `G`, `g`,
  /// `d`, `D` and `s`, and the empty pattern, are the standard formats.
  ///
  /// ```dart
  /// NepaliDate.fromBs(2081, 4, 15).format('MMM yyyy'); // => Shr 2081
  /// ```
  String format(String pattern, {Lang lang = Lang.en}) => _pattern(this, pattern, lang);
}

NepDateException _outOfRange(String what) => NepDateException(
      ErrorKind.outOfRange,
      '$what is outside BS $kMinYear-01-01..$kMaxYear-12-30',
    );

NepDateException _gregorianOutOfRange(DateTime date) => NepDateException(
      ErrorKind.outOfRange,
      '${_pad(date.year, 4)}-${_pad(date.month, 2)}-${_pad(date.day, 2)} is outside '
      'AD 1844-04-11..2143-04-15',
    );

/// The date at [serial], which the caller has checked is in `0..kTotalDays - 1`.
NepaliDate _fromSerial(int serial) {
  // The mean month is 30.44 days, so this estimate is at most one month off.
  var index = serial * _months ~/ kTotalDays;
  while (kMonthStart[index] > serial) {
    index--;
  }
  while (kMonthStart[index + 1] <= serial) {
    index++;
  }
  return NepaliDate._(
    kMinYear + index ~/ 12,
    index % 12 + 1,
    serial - kMonthStart[index] + 1,
    serial,
  );
}

final RegExp _offsetZone = RegExp(r'^(?:UTC|GMT)?([+-])(\d{2})(?::?(\d{2}))?$');

Duration _zoneOffset(String zone) {
  switch (zone) {
    case 'Asia/Kathmandu' || 'Asia/Katmandu':
      return const Duration(hours: 5, minutes: 45);
    case 'UTC' || 'Z' || 'GMT' || 'Etc/UTC' || 'Etc/GMT':
      return Duration.zero;
  }
  final match = _offsetZone.firstMatch(zone);
  if (match != null) {
    final hours = int.parse(match.group(2)!);
    final minutes = int.parse(match.group(3) ?? '0');
    if (hours <= 14 && minutes < 60) {
      final total = Duration(hours: hours, minutes: minutes);
      return match.group(1) == '-' ? -total : total;
    }
  }
  throw ArgumentError.value(
    zone,
    'timeZone',
    'expected Asia/Kathmandu, UTC or a fixed offset such as +05:45',
  );
}

/// Serial of today in [zone]; outside `0..kTotalDays - 1` when the clock is outside the calendar.
int _todaySerial(String zone, DateTime Function()? clock) {
  final offset = _zoneOffset(zone);
  final now = (clock ?? DateTime.now)().toUtc().add(offset);
  final year = now.year;
  if (year < 1844) return -1;
  if (year > 2143) return _maxSerial + 1;
  return _daysFromCivil(year, now.month, now.day) - kEpochUnixDays;
}
