import 'package:nepdate/nepdate.dart';

/// A BS date from `YYYY-MM-DD`, built with the validating constructor and nothing else.
NepaliDate bs(String text) {
  final parts = text.split('-');
  return NepaliDate.fromBs(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// A Gregorian date from `YYYY-MM-DD` as a UTC [DateTime].
DateTime ad(String text) {
  final parts = text.split('-');
  return DateTime.utc(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// `YYYY-MM-DD` of a date, the vector files' form.
String iso(NepaliDate date) => date.toJson();

/// The vector files' `YYYY-MM-DD` of a Gregorian [DateTime].
String adIso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// The date of the vectors' text, or `ERR` when building it throws a [NepDateException].
String attempt(NepaliDate Function() build) {
  try {
    return iso(build());
  } on NepDateException {
    return 'ERR';
  }
}

/// `start..end`, the vector files' form for a range.
String rangeText(NepaliDateRange range) => '${iso(range.start)}..${iso(range.end)}';

/// A `start..end` argument as a range.
NepaliDateRange rangeOf(String text) {
  final parts = text.split('..');
  return NepaliDateRange.of(bs(parts[0]), bs(parts[1]));
}

/// `none` for no ranges, else `a..b;c..d`.
String rangesText(Iterable<NepaliDateRange> ranges) =>
    ranges.isEmpty ? 'none' : ranges.map(rangeText).join(';');

/// `none` for no dates, else `d1;d2`.
String datesText(Iterable<NepaliDate> dates) => dates.isEmpty ? 'none' : dates.map(iso).join(';');

const Map<String, Weekday> weekdayByName = {
  'Sunday': Weekday.sunday,
  'Monday': Weekday.monday,
  'Tuesday': Weekday.tuesday,
  'Wednesday': Weekday.wednesday,
  'Thursday': Weekday.thursday,
  'Friday': Weekday.friday,
  'Saturday': Weekday.saturday,
};

const Map<String, DateOrder> orderByName = {
  'Ymd': DateOrder.ymd,
  'Ydm': DateOrder.ydm,
  'Myd': DateOrder.myd,
  'Mdy': DateOrder.mdy,
  'Dym': DateOrder.dym,
  'Dmy': DateOrder.dmy,
};

const Map<String, Separator> separatorByName = {
  'Slash': Separator.slash,
  'Backslash': Separator.backslash,
  'Dot': Separator.dot,
  'Underscore': Separator.underscore,
  'Dash': Separator.dash,
  'Space': Separator.space,
};
