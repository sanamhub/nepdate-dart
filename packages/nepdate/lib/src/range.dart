part of '../nepdate.dart';

/// An inclusive range of dates, from [start] to [end]. A range always has at least one day, so
/// there is no empty range (D-01).
///
/// A range is an [Iterable] of every day in it, in order. Equal bounds make equal ranges.
///
/// ```dart
/// final range = NepaliDateRange.of(NepaliDate.fromBs(2081, 4, 10), NepaliDate.fromBs(2081, 4, 20));
/// range.length; // => 11
/// range.toString(); // => 2081/04/10 - 2081/04/20
/// ```
final class NepaliDateRange extends IterableBase<NepaliDate> {
  const NepaliDateRange._(this.start, this.end);

  /// The range from [start] to [end], both included.
  ///
  /// Throws a [NepDateException] of kind [ErrorKind.outOfRange] when [end] is before [start].
  ///
  /// ```dart
  /// NepaliDateRange.of(NepaliDate.min, NepaliDate.fromBs(1901, 1, 5)).length; // => 5
  /// ```
  factory NepaliDateRange.of(NepaliDate start, NepaliDate end) {
    if (end._serial < start._serial) {
      throw const NepDateException(ErrorKind.outOfRange, 'the range ends before it starts');
    }
    return NepaliDateRange._(start, end);
  }

  /// A range of one day.
  ///
  /// ```dart
  /// NepaliDateRange.singleDay(NepaliDate.fromBs(2081, 4, 15)).length; // => 1
  /// ```
  factory NepaliDateRange.singleDay(NepaliDate date) => NepaliDateRange._(date, date);

  /// [days] days from [start], so [start] to `start + days - 1`.
  ///
  /// Throws an [ArgumentError] when [days] is below 1, and a [NepDateException] of kind
  /// [ErrorKind.outOfRange] when the range would pass 2199-12-30.
  ///
  /// ```dart
  /// NepaliDateRange.fromDayCount(NepaliDate.fromBs(2081, 4, 15), 5).toString();
  /// // => 2081/04/15 - 2081/04/19
  /// ```
  factory NepaliDateRange.fromDayCount(NepaliDate start, int days) {
    if (days < 1) throw ArgumentError.value(days, 'days', 'must be at least 1');
    return NepaliDateRange._(start, start.addDays(days - 1));
  }

  /// Day 1 to the last day of BS [month] in [year].
  ///
  /// Throws as [NepaliDate.fromBs] for a bad year or month.
  ///
  /// ```dart
  /// NepaliDateRange.forMonth(2081, 4).length; // => 32
  /// ```
  factory NepaliDateRange.forMonth(int year, int month) {
    final first = NepaliDate.fromBs(year, month, 1);
    return NepaliDateRange._(first, first.lastDayOfMonth);
  }

  /// 1 Baishakh to the last day of Chaitra of BS [year].
  ///
  /// ```dart
  /// NepaliDateRange.forYear(2081).length; // => 366
  /// ```
  factory NepaliDateRange.forYear(int year) => NepaliDateRange._(
        NepaliDate.fromBs(year, 1, 1),
        NepaliDate.fromBs(year, 12, 1).lastDayOfMonth,
      );

  /// The month that contains today in [timeZone]. The zones are those of [NepaliDate.today].
  ///
  /// ```dart
  /// NepaliDateRange.currentMonth(timeZone: 'UTC', clock: () => DateTime.utc(2024, 7, 30)).toString();
  /// // => 2081/04/01 - 2081/04/32
  /// ```
  factory NepaliDateRange.currentMonth({
    String timeZone = _nepalZone,
    DateTime Function()? clock,
  }) {
    final today = NepaliDate.today(timeZone: timeZone, clock: clock);
    return NepaliDateRange.forMonth(today.year, today.month);
  }

  /// The fiscal year that contains today in [timeZone].
  ///
  /// ```dart
  /// NepaliDateRange.currentFiscalYear(timeZone: 'UTC', clock: () => DateTime.utc(2024, 7, 30))
  ///     .toString(); // => 2081/04/01 - 2082/03/32
  /// ```
  factory NepaliDateRange.currentFiscalYear({
    String timeZone = _nepalZone,
    DateTime Function()? clock,
  }) =>
      FiscalYear.containing(NepaliDate.today(timeZone: timeZone, clock: clock)).range();

  /// The BS year that contains today in [timeZone].
  ///
  /// ```dart
  /// NepaliDateRange.currentCalendarYear(timeZone: 'UTC', clock: () => DateTime.utc(2024, 7, 30))
  ///     .toString(); // => 2081/01/01 - 2081/12/31
  /// ```
  factory NepaliDateRange.currentCalendarYear({
    String timeZone = _nepalZone,
    DateTime Function()? clock,
  }) =>
      NepaliDateRange.forYear(NepaliDate.today(timeZone: timeZone, clock: clock).year);

  /// The first date.
  final NepaliDate start;

  /// The last date, included.
  final NepaliDate end;

  /// The number of days, at least 1.
  @override
  int get length => end._serial - start._serial + 1;

  @override
  NepaliDate get first => start;

  @override
  NepaliDate get last => end;

  @override
  bool get isEmpty => false;

  @override
  bool get isNotEmpty => true;

  /// True when [element] is a [NepaliDate] on or between [start] and [end].
  ///
  /// ```dart
  /// NepaliDateRange.forMonth(2081, 4).contains(NepaliDate.fromBs(2081, 4, 32)); // => true
  /// ```
  @override
  bool contains(Object? element) =>
      element is NepaliDate && element._serial >= start._serial && element._serial <= end._serial;

  /// True when every date of [other] is in this range.
  ///
  /// ```dart
  /// NepaliDateRange.forYear(2081).containsRange(NepaliDateRange.forMonth(2081, 4)); // => true
  /// ```
  bool containsRange(NepaliDateRange other) =>
      start._serial <= other.start._serial && other.end._serial <= end._serial;

  /// True when the two ranges share at least one date.
  ///
  /// ```dart
  /// NepaliDateRange.forMonth(2081, 4).overlaps(NepaliDateRange.forMonth(2081, 5)); // => false
  /// ```
  bool overlaps(NepaliDateRange other) =>
      start._serial <= other.end._serial && end._serial >= other.start._serial;

  /// True when one range starts the day after the other ends. A range that touches the end of the
  /// calendar is never adjacent to a date that does not exist (D-16).
  ///
  /// ```dart
  /// NepaliDateRange.forMonth(2081, 4).isAdjacentTo(NepaliDateRange.forMonth(2081, 5)); // => true
  /// ```
  bool isAdjacentTo(NepaliDateRange other) =>
      (end._serial < _maxSerial && end._serial + 1 == other.start._serial) ||
      (start._serial > 0 && start._serial - 1 == other.end._serial);

  /// The dates in both ranges, or `null` when they share none (D-01).
  ///
  /// ```dart
  /// NepaliDateRange.forMonth(2081, 4).intersect(NepaliDateRange.forMonth(2081, 5)); // => null
  /// ```
  NepaliDateRange? intersect(NepaliDateRange other) {
    if (!overlaps(other)) return null;
    return NepaliDateRange._(
      start._serial >= other.start._serial ? start : other.start,
      end._serial <= other.end._serial ? end : other.end,
    );
  }

  /// The smallest range that covers both, including any gap between them.
  ///
  /// ```dart
  /// NepaliDateRange.forMonth(2081, 4).union(NepaliDateRange.forMonth(2081, 6)).toString();
  /// // => 2081/04/01 - 2081/06/30
  /// ```
  NepaliDateRange union(NepaliDateRange other) => NepaliDateRange._(
        start._serial <= other.start._serial ? start : other.start,
        end._serial >= other.end._serial ? end : other.end,
      );

  /// This range with the dates of [other] removed: no range, one, or two.
  ///
  /// ```dart
  /// NepaliDateRange.forMonth(2081, 4).except(NepaliDateRange.forMonth(2081, 4)); // => []
  /// ```
  List<NepaliDateRange> except(NepaliDateRange other) {
    if (!overlaps(other)) return [this];
    final pieces = <NepaliDateRange>[];
    if (start._serial < other.start._serial) {
      pieces.add(NepaliDateRange._(start, _fromSerial(other.start._serial - 1)));
    }
    if (end._serial > other.end._serial) {
      pieces.add(NepaliDateRange._(_fromSerial(other.end._serial + 1), end));
    }
    return pieces;
  }

  /// One range per month this range touches, the first and last clipped to the range ends.
  ///
  /// ```dart
  /// NepaliDateRange.forYear(2081).splitByMonth().length; // => 12
  /// ```
  List<NepaliDateRange> splitByMonth() {
    final pieces = <NepaliDateRange>[];
    var cursor = start;
    while (true) {
      final monthEnd = cursor.lastDayOfMonth;
      if (monthEnd._serial >= end._serial) {
        pieces.add(NepaliDateRange._(cursor, end));
        return pieces;
      }
      pieces.add(NepaliDateRange._(cursor, monthEnd));
      cursor = _fromSerial(monthEnd._serial + 1);
    }
  }

  /// One range per fiscal quarter this range touches, the first and last clipped to the range
  /// ends.
  ///
  /// ```dart
  /// NepaliDateRange.forYear(2081).splitByFiscalQuarter().length; // => 4
  /// ```
  List<NepaliDateRange> splitByFiscalQuarter() {
    final pieces = <NepaliDateRange>[];
    var cursor = start;
    while (true) {
      final quarterEndMonth = (cursor.month - 1) ~/ 3 * 3 + 3;
      final quarterEnd = NepaliDate.fromBs(cursor.year, quarterEndMonth, 1).lastDayOfMonth;
      if (quarterEnd._serial >= end._serial) {
        pieces.add(NepaliDateRange._(cursor, end));
        return pieces;
      }
      pieces.add(NepaliDateRange._(cursor, quarterEnd));
      cursor = _fromSerial(quarterEnd._serial + 1);
    }
  }

  /// Every [interval] days from [start], never past [end].
  ///
  /// Throws an [ArgumentError] when [interval] is below 1.
  ///
  /// ```dart
  /// NepaliDateRange.forMonth(2081, 4).datesWithInterval(10).map((d) => d.day).toList();
  /// // => [1, 11, 21, 31]
  /// ```
  Iterable<NepaliDate> datesWithInterval(int interval) {
    if (interval < 1) throw ArgumentError.value(interval, 'interval', 'must be at least 1');
    return _everyDay(step: interval);
  }

  /// Every day except Saturday, and except Sunday too when [excludeSunday] is true.
  ///
  /// ```dart
  /// NepaliDateRange.forMonth(2081, 4).workingDays().length; // => 28
  /// ```
  Iterable<NepaliDate> workingDays({bool excludeSunday = false}) => _everyDay().where(
        (d) => d.weekday != Weekday.saturday && !(excludeSunday && d.weekday == Weekday.sunday),
      );

  /// Every Saturday, and every Sunday too when [includeSunday] is true.
  ///
  /// ```dart
  /// NepaliDateRange.forMonth(2081, 4).weekendDays(includeSunday: false).length; // => 4
  /// ```
  Iterable<NepaliDate> weekendDays({bool includeSunday = true}) => _everyDay().where(
        (d) => d.weekday == Weekday.saturday || (includeSunday && d.weekday == Weekday.sunday),
      );

  Iterable<NepaliDate> _everyDay({int step = 1}) sync* {
    // Every serial between two valid dates is valid, so nothing is range-checked per step. The
    // loop stops before adding a step that would pass the end, so a huge step cannot overflow.
    for (var serial = start._serial;; serial += step) {
      yield _fromSerial(serial);
      if (end._serial - serial < step) return;
    }
  }

  /// Every day from [start] to [end], in order.
  @override
  Iterator<NepaliDate> get iterator => _everyDay().iterator;

  /// The two dates formatted with [NepaliDate.toShortString] and joined with ` - `.
  ///
  /// ```dart
  /// NepaliDateRange.forMonth(2081, 4).toStringWith(DateOrder.dmy, Separator.dash);
  /// // => 01-04-2081 - 32-04-2081
  /// ```
  String toStringWith(
    DateOrder order, [
    Separator separator = Separator.slash,
    Lang lang = Lang.en,
  ]) =>
      '${start.toShortString(order: order, separator: separator, lang: lang)} - '
      '${end.toShortString(order: order, separator: separator, lang: lang)}';

  @override
  bool operator ==(Object other) =>
      other is NepaliDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  /// `YYYY/MM/DD - YYYY/MM/DD`.
  @override
  String toString() => '$start - $end';
}
