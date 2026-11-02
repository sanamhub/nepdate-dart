part of '../nepdate.dart';

/// The language of month names, weekday names and digits.
///
/// ```dart
/// NepaliDate.fromBs(2081, 4, 15).toLongString(lang: Lang.ne); // => साउन १५, २०८१
/// ```
enum Lang {
  /// English names and ASCII digits.
  en,

  /// Nepali names and Devanagari digits.
  ne,
}

/// The order of year, month and day in a short date.
///
/// ```dart
/// NepaliDate.fromBs(2081, 4, 15).toShortString(order: DateOrder.dmy); // => 15/04/2081
/// ```
enum DateOrder {
  /// Year, month, day.
  ymd,

  /// Year, day, month.
  ydm,

  /// Month, year, day.
  myd,

  /// Month, day, year.
  mdy,

  /// Day, year, month.
  dym,

  /// Day, month, year.
  dmy,
}

/// The character between the parts of a short date.
///
/// ```dart
/// Separator.dash.character; // => -
/// ```
enum Separator {
  /// `/`
  slash('/'),

  /// `\`
  backslash(r'\'),

  /// `.`
  dot('.'),

  /// `_`
  underscore('_'),

  /// `-`
  dash('-'),

  /// A space.
  space(' ');

  const Separator(this.character);

  /// The separator as a one-character string.
  final String character;
}

/// What [NepaliDate.addMonths] and [NepaliDate.addYears] do when the day does not exist in the
/// target month.
///
/// ```dart
/// final date = NepaliDate.fromBs(2081, 4, 32);
/// date.addMonths(2).toString(); // => 2081/06/30
/// date.addMonths(2, overflow: MonthOverflow.spill).toString(); // => 2081/07/02
/// ```
enum MonthOverflow {
  /// Use the last day of the target month. This is C# `AddMonths(n)`.
  clamp,

  /// Carry the extra days into the next month. This is C# `AddMonths(n, awayFromMonthEnd: true)`.
  spill,
}

const List<String> _monthEn = [
  'Baishakh',
  'Jestha',
  'Ashad',
  'Shrawan',
  'Bhadra',
  'Ashoj',
  'Kartik',
  'Mangsir',
  'Poush',
  'Magh',
  'Falgun',
  'Chaitra',
];

const List<String> _monthShortEn = [
  'Bai',
  'Jes',
  'Asa',
  'Shr',
  'Bha',
  'Aso',
  'Kar',
  'Man',
  'Pou',
  'Mag',
  'Fal',
  'Cha',
];

const List<String> _monthNe = [
  'बैशाख',
  'जेठ',
  'असार',
  'साउन',
  'भदौ',
  'असोज',
  'कार्तिक',
  'मंसिर',
  'पुष',
  'माघ',
  'फागुन',
  'चैत',
];

/// A Bikram Sambat month, Baishakh (1) to Chaitra (12).
///
/// ```dart
/// Month.shrawan.number; // => 4
/// Month.shrawan.fullName(Lang.ne); // => साउन
/// ```
enum Month {
  /// Month 1.
  baishakh,

  /// Month 2.
  jestha,

  /// Month 3.
  ashad,

  /// Month 4, the first month of the fiscal year.
  shrawan,

  /// Month 5.
  bhadra,

  /// Month 6.
  ashoj,

  /// Month 7.
  kartik,

  /// Month 8.
  mangsir,

  /// Month 9.
  poush,

  /// Month 10.
  magh,

  /// Month 11.
  falgun,

  /// Month 12.
  chaitra;

  /// The month with the given [number], 1 to 12.
  ///
  /// Throws a [NepDateException] of kind [ErrorKind.invalidMonth] for any other number.
  ///
  /// ```dart
  /// Month.fromNumber(4); // => Month.shrawan
  /// ```
  static Month fromNumber(int number) {
    if (number < 1 || number > 12) {
      throw NepDateException(ErrorKind.invalidMonth, 'month $number is outside 1..12');
    }
    return values[number - 1];
  }

  /// The month number, 1 to 12.
  int get number => index + 1;

  /// The full name: `Shrawan`, or `साउन` in Nepali.
  String fullName([Lang lang = Lang.en]) => lang == Lang.ne ? _monthNe[index] : _monthEn[index];

  /// The three-letter English abbreviation (`Shr`; Ashad is `Asa` and Ashoj is `Aso`). Nepali has
  /// no customary abbreviation, so this is the full name for [Lang.ne].
  String shortName([Lang lang = Lang.en]) =>
      lang == Lang.ne ? _monthNe[index] : _monthShortEn[index];
}

const List<String> _weekdayEn = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

const List<String> _weekdayShortEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

const List<String> _weekdayNe = [
  'आइतवार',
  'सोमवार',
  'मङ्गलवार',
  'बुधवार',
  'बिहिवार',
  'शुक्रवार',
  'शनिवार',
];

const List<String> _weekdayShortNe = ['आइत', 'सोम', 'मङ्गल', 'बुध', 'बिहि', 'शुक्र', 'शनि'];

/// A day of the week. Unlike [DateTime.sunday], Sunday is the first day and has index 0.
///
/// ```dart
/// NepaliDate.fromBs(2081, 4, 15).weekday; // => Weekday.tuesday
/// ```
enum Weekday {
  /// Sunday, index 0.
  sunday,

  /// Monday, index 1.
  monday,

  /// Tuesday, index 2.
  tuesday,

  /// Wednesday, index 3.
  wednesday,

  /// Thursday, index 4.
  thursday,

  /// Friday, index 5.
  friday,

  /// Saturday, index 6. Saturday is the weekly holiday in Nepal.
  saturday;

  /// The full name: `Tuesday`, or `मङ्गलवार` in Nepali.
  String fullName([Lang lang = Lang.en]) => lang == Lang.ne ? _weekdayNe[index] : _weekdayEn[index];

  /// The short name: `Tue`, or `मङ्गल` in Nepali.
  String shortName([Lang lang = Lang.en]) =>
      lang == Lang.ne ? _weekdayShortNe[index] : _weekdayShortEn[index];
}
