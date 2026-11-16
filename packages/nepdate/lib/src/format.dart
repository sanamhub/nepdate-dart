part of '../nepdate.dart';

String _pad(int value, int width) => value.toString().padLeft(width, '0');

// Every number a date prints is below 100 or is a year of two such halves, so formatting reads
// these tables instead of converting and padding each time.

/// `00` to `99`.
final List<String> _twoDigitsEn = List<String>.generate(100, (i) => _pad(i, 2), growable: false);

/// `००` to `९९`.
final List<String> _twoDigitsNe =
    List<String>.generate(100, (i) => _localize(_pad(i, 2), Lang.ne), growable: false);

/// `0` to `99`, not padded.
final List<String> _plainEn = List<String>.generate(100, (i) => '$i', growable: false);

/// `०` to `९९`, not padded.
final List<String> _plainNe =
    List<String>.generate(100, (i) => _localize('$i', Lang.ne), growable: false);

/// [value] (0 to 99) in the digits of [lang], padded to two digits when [pad] is true.
String _number(int value, bool pad, Lang lang) => lang == Lang.en
    ? (pad ? _twoDigitsEn[value] : _plainEn[value])
    : (pad ? _twoDigitsNe[value] : _plainNe[value]);

/// `1901` to `2199`, one text per supported year.
final List<String> _yearsEn =
    List<String>.generate(kMaxYear - kMinYear + 1, (i) => '${kMinYear + i}', growable: false);

/// `१९०१` to `२१९९`.
final List<String> _yearsNe = List<String>.generate(
  kMaxYear - kMinYear + 1,
  (i) => _localize('${kMinYear + i}', Lang.ne),
  growable: false,
);

/// The year of a date in the digits of [lang]. Every supported year has four digits, so the
/// padded and the plain form are the same text.
String _fourDigits(int year, Lang lang) =>
    lang == Lang.en ? _yearsEn[year - kMinYear] : _yearsNe[year - kMinYear];

/// Replaces every ASCII digit with its Devanagari counterpart when [lang] is Nepali.
String _localize(String text, Lang lang) {
  if (lang == Lang.en) return text;
  final units = text.codeUnits;
  final out = List<int>.filled(units.length, 0);
  for (var i = 0; i < units.length; i++) {
    final unit = units[i];
    out[i] = unit >= 0x30 && unit <= 0x39 ? unit + 0x966 - 0x30 : unit;
  }
  return String.fromCharCodes(out);
}

String _short(NepaliDate date, DateOrder order, Separator separator, bool pad, Lang lang) {
  final year = _fourDigits(date.year, lang);
  final month = _number(date.month, pad, lang);
  final day = _number(date.day, pad, lang);
  final mark = separator.character;
  return switch (order) {
    DateOrder.ymd => '$year$mark$month$mark$day',
    DateOrder.ydm => '$year$mark$day$mark$month',
    DateOrder.myd => '$month$mark$year$mark$day',
    DateOrder.mdy => '$month$mark$day$mark$year',
    DateOrder.dym => '$day$mark$year$mark$month',
    DateOrder.dmy => '$day$mark$month$mark$year',
  };
}

String _long(NepaliDate date, bool weekday, bool year, bool pad, Lang lang) {
  final monthName = date.monthEnum.fullName(lang);
  final day = _number(date.day, pad, lang);
  if (weekday) {
    final weekdayName = date.weekday.fullName(lang);
    return year
        ? '$weekdayName, $monthName $day, ${_fourDigits(date.year, lang)}'
        : '$weekdayName, $monthName $day';
  }
  return year ? '$monthName $day, ${_fourDigits(date.year, lang)}' : '$monthName $day';
}

const int _backslash = 0x5C;
const int _quote = 0x27;

String _pattern(NepaliDate date, String pattern, Lang lang) {
  switch (pattern) {
    case '' || 'G' || 'g' || 'd':
      return _localize(date.toString(), lang);
    case 'D':
      return _long(date, false, true, true, lang);
    case 's':
      return _localize(date.toJson(), lang);
  }
  final out = StringBuffer();
  final length = pattern.length;
  var i = 0;
  while (i < length) {
    final unit = pattern.codeUnitAt(i);
    if (unit == _backslash) {
      // A backslash at the very end writes itself.
      out.writeCharCode(i + 1 < length ? pattern.codeUnitAt(i + 1) : _backslash);
      i += 2;
    } else if (unit == _quote) {
      final close = pattern.indexOf("'", i + 1);
      final end = close < 0 ? length : close;
      out.write(pattern.substring(i + 1, end));
      i = end + 1;
    } else if (unit == 0x79 || unit == 0x4D || unit == 0x64) {
      var j = i;
      while (j < length && pattern.codeUnitAt(j) == unit) {
        j++;
      }
      final run = j - i;
      i = j;
      switch (unit) {
        case 0x79: // y
          out.write(run >= 4 ? _fourDigits(date.year, lang) : _number(date.year % 100, true, lang));
        case 0x4D: // M
          if (run >= 4) {
            out.write(date.monthEnum.fullName(lang));
          } else if (run == 3) {
            out.write(date.monthEnum.shortName(lang));
          } else {
            out.write(_number(date.month, run == 2, lang));
          }
        default: // d
          out.write(_number(date.day, run == 2, lang));
      }
    } else {
      out.writeCharCode(unit);
      i++;
    }
  }
  return out.toString();
}
