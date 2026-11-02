part of '../nepdate.dart';

String _pad(int value, int width) => value.toString().padLeft(width, '0');

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
  final year = pad ? _pad(date.year, 4) : '${date.year}';
  final month = pad ? _pad(date.month, 2) : '${date.month}';
  final day = pad ? _pad(date.day, 2) : '${date.day}';
  final parts = switch (order) {
    DateOrder.ymd => [year, month, day],
    DateOrder.ydm => [year, day, month],
    DateOrder.myd => [month, year, day],
    DateOrder.mdy => [month, day, year],
    DateOrder.dym => [day, year, month],
    DateOrder.dmy => [day, month, year],
  };
  return _localize(parts.join(separator.character), lang);
}

String _long(NepaliDate date, bool weekday, bool year, bool pad, Lang lang) {
  final out = StringBuffer();
  if (weekday) out.write('${date.weekday.fullName(lang)}, ');
  out
    ..write(date.monthEnum.fullName(lang))
    ..write(' ')
    ..write(_localize(pad ? _pad(date.day, 2) : '${date.day}', lang));
  if (year) out.write(', ${_localize(_pad(date.year, 4), lang)}');
  return out.toString();
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
          out.write(_localize(run >= 4 ? _pad(date.year, 4) : _pad(date.year % 100, 2), lang));
        case 0x4D: // M
          if (run >= 4) {
            out.write(date.monthEnum.fullName(lang));
          } else if (run == 3) {
            out.write(date.monthEnum.shortName(lang));
          } else {
            out.write(_localize(run == 2 ? _pad(date.month, 2) : '${date.month}', lang));
          }
        default: // d
          out.write(_localize(run == 2 ? _pad(date.day, 2) : '${date.day}', lang));
      }
    } else {
      out.writeCharCode(unit);
      i++;
    }
  }
  return out.toString();
}
