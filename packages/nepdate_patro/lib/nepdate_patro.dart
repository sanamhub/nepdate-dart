/// The Nepali patro: tithi, public holidays and events for every Bikram Sambat day from
/// 2077-01-01 to 2084-08-20.
///
/// The data is compiled into the package, so every lookup is a table read and nothing is parsed or
/// loaded at run time. The package depends on `nepdate` for the date type; the core package has no
/// patro data.
///
/// ```dart
/// final day = info(NepaliDate.fromBs(2081, 2, 15));
/// day.isPublicHoliday; // => true
/// day.events.single.english; // => Republic Day
/// ```
library;

import 'package:nepdate/nepdate.dart';

import 'src/tables.g.dart';

export 'package:nepdate/nepdate.dart' show Lang;

/// A name in both languages: a tithi or an event.
///
/// Names are shown exactly as the data has them. A few tithi names end in `*` (and `(K)` in
/// English); the data does not say what the marker means, so it is kept.
///
/// ```dart
/// info(NepaliDate.fromBs(2081, 1, 1)).tithi!.english; // => Panchami
/// ```
final class Named {
  const Named._(this.nepali, this.english);

  /// The name in Nepali.
  final String nepali;

  /// The name in English.
  final String english;

  /// The name in [lang]: [nepali] for [Lang.ne], [english] for [Lang.en].
  ///
  /// ```dart
  /// info(NepaliDate.fromBs(2081, 1, 1)).tithi!.name(Lang.ne); // => पञ्चमी
  /// ```
  String name(Lang lang) => lang == Lang.ne ? nepali : english;

  @override
  bool operator ==(Object other) =>
      other is Named && other.nepali == nepali && other.english == english;

  @override
  int get hashCode => Object.hash(nepali, english);

  @override
  String toString() => english;
}

/// What the patro knows about one day: the tithi, whether it is a gazetted public holiday, and the
/// events in display order.
///
/// ```dart
/// final day = info(NepaliDate.fromBs(2081, 1, 1));
/// day.events.map((e) => e.english).toList(); // => [New Year, Mesh Sankranti, Bisket Jatra]
/// ```
final class CalendarInfo {
  const CalendarInfo._(this.tithi, this.isPublicHoliday, this.events);

  /// The tithi, or `null` outside the days that have one (2078-01-02 to 2083-12-30).
  final Named? tithi;

  /// True on a gazetted public holiday.
  final bool isPublicHoliday;

  /// The events of the day in file order; empty when there are none. The list is unmodifiable.
  final List<Named> events;

  @override
  String toString() =>
      'CalendarInfo(tithi: ${tithi ?? 'none'}, holiday: $isPublicHoliday, events: $events)';
}

const CalendarInfo _empty = CalendarInfo._(null, false, <Named>[]);

final List<Named> _names = List<Named>.unmodifiable([
  for (var i = 0; i < kNamesNp.length; i++) Named._(kNamesNp[i], kNamesEn[i]),
]);

/// The one [CalendarInfo] of each day with any data, built on first use.
final Map<int, CalendarInfo> _cache = <int, CalendarInfo>{};

/// First index in [sorted] whose value is at least [value], or the length.
int _lowerBound(List<int> sorted, int value) {
  var low = 0;
  var high = sorted.length;
  while (low < high) {
    final mid = (low + high) >> 1;
    if (sorted[mid] < value) {
      low = mid + 1;
    } else {
      high = mid;
    }
  }
  return low;
}

/// Offsets of each event day's first name id in [kEventNameIds].
final List<int> _eventStart = () {
  final starts = List<int>.filled(kEventCounts.length + 1, 0);
  for (var i = 0; i < kEventCounts.length; i++) {
    starts[i + 1] = starts[i] + kEventCounts[i];
  }
  return starts;
}();

/// What the patro knows about [date].
///
/// Never throws: a day without data, and any day outside [coverage], gets an empty answer (no
/// tithi, not a holiday, no events). The same day always gets the same object.
///
/// ```dart
/// info(NepaliDate.fromBs(2090, 1, 1)).events; // => []
/// ```
CalendarInfo info(NepaliDate date) {
  final serial = NepaliDate.min.daysUntil(date);
  if (serial < kCoverageFirst || serial > kCoverageLast) return _empty;
  return _cache.putIfAbsent(serial, () {
    final tithiOffset = serial - kTithiFirst;
    final tithi =
        tithiOffset >= 0 && tithiOffset < kTithiIds.length ? _names[kTithiIds[tithiOffset]] : null;
    final holiday = _contains(kHolidayDays, serial);
    final eventIndex = _lowerBound(kEventDays, serial);
    final hasEvents = eventIndex < kEventDays.length && kEventDays[eventIndex] == serial;
    final events = hasEvents
        ? List<Named>.unmodifiable([
            for (var i = _eventStart[eventIndex]; i < _eventStart[eventIndex + 1]; i++)
              _names[kEventNameIds[i]],
          ])
        : const <Named>[];
    if (tithi == null && !holiday && events.isEmpty) return _empty;
    return CalendarInfo._(tithi, holiday, events);
  });
}

bool _contains(List<int> sorted, int value) {
  final index = _lowerBound(sorted, value);
  return index < sorted.length && sorted[index] == value;
}

/// The smallest range that contains every day with data, BS 2077-01-01 to 2084-08-20 with the
/// current data. Use it to decide whether to show "no data for this year".
///
/// ```dart
/// coverage().start.toString(); // => 2077/01/01
/// ```
NepaliDateRange coverage() => NepaliDateRange.of(
      NepaliDate.min.addDays(kCoverageFirst),
      NepaliDate.min.addDays(kCoverageLast),
    );

/// Every public holiday, in ascending order.
///
/// ```dart
/// publicHolidays().first.toString(); // => 2077/01/01
/// ```
Iterable<NepaliDate> publicHolidays() sync* {
  for (final serial in kHolidayDays) {
    yield NepaliDate.min.addDays(serial);
  }
}
