part of '../nepdate.dart';

/// The outcome of a parse: a date, or the kind and message of the failure.
final class _Parsed {
  const _Parsed.ok(NepaliDate this.date) : error = null;
  const _Parsed.fail(NepDateException this.error) : date = null;

  final NepaliDate? date;
  final NepDateException? error;
}

NepaliDate _parsedOrThrow(_Parsed parsed) {
  final error = parsed.error;
  if (error != null) throw error;
  return parsed.date!;
}

_Parsed _fail(ErrorKind kind, String message) => _Parsed.fail(NepDateException(kind, message));

/// Validates year, month and day as [NepaliDate.fromBs] does, without throwing.
_Parsed _validated(int year, int month, int day) {
  final date = NepaliDate._valid(year, month, day);
  return date != null ? _Parsed.ok(date) : _Parsed.fail(_invalidBs(year, month, day));
}

/// The separators of PARSING section 1: `- / . _ \ space ।` and `|`.
bool _isSeparator(int unit) =>
    unit == 0x2D ||
    unit == 0x2F ||
    unit == 0x2E ||
    unit == 0x5F ||
    unit == 0x5C ||
    unit == 0x20 ||
    unit == 0x964 ||
    unit == 0x7C;

/// The ASCII digit value of an ASCII or Devanagari digit, or -1.
int _digit(int unit) {
  if (unit >= 0x30 && unit <= 0x39) return unit - 0x30;
  if (unit >= 0x966 && unit <= 0x96F) return unit - 0x966;
  return -1;
}

/// [_scanStrict] result: a number has more than four digits.
const int _scanTooLong = -1;

/// [_scanStrict] result: the text does not have exactly three numbers.
const int _scanWrongCount = -2;

/// Each of the three numbers has at most four digits, so they pack into one integer in base
/// 10000.
const int _scanBase = 10000;

/// Reads the strict form (PARSING section 1) in one pass, without allocating.
///
/// Returns `(year * 10000 + month) * 10000 + day` when the text has exactly three numbers.
/// Otherwise the result is negative: [_scanTooLong], [_scanWrongCount], or `-(unit + 3)` for a
/// code unit that is neither a digit nor a separator. The first problem in reading order wins.
int _scanStrict(String text) {
  var groups = 0;
  var packed = 0;
  var digits = 0;
  var value = 0;
  final length = text.length;
  for (var i = 0; i < length; i++) {
    final unit = text.codeUnitAt(i);
    final digit = _digit(unit);
    if (digit >= 0) {
      if (digits == 4) return _scanTooLong;
      if (groups == 3) return _scanWrongCount;
      value = value * 10 + digit;
      digits++;
    } else if (_isSeparator(unit)) {
      if (digits > 0) {
        packed = packed * _scanBase + value;
        groups++;
        value = 0;
        digits = 0;
      }
    } else {
      return -(unit + 3);
    }
  }
  if (digits > 0) {
    packed = packed * _scanBase + value;
    groups++;
  }
  return groups == 3 ? packed : _scanWrongCount;
}

/// The date of a strict text, or `null` for any failure. The fast path of [NepaliDate.parse] and
/// [NepaliDate.tryParse].
NepaliDate? _tryParseStrict(String text) {
  final packed = _scanStrict(text);
  if (packed < 0) return null;
  return NepaliDate._valid(
    packed ~/ (_scanBase * _scanBase),
    packed ~/ _scanBase % _scanBase,
    packed % _scanBase,
  );
}

/// The strict parse with the reason for a failure.
_Parsed _parseStrict(String text) {
  final packed = _scanStrict(text);
  if (packed >= 0) {
    return _validated(
      packed ~/ (_scanBase * _scanBase),
      packed ~/ _scanBase % _scanBase,
      packed % _scanBase,
    );
  }
  return switch (packed) {
    _scanTooLong => _fail(ErrorKind.numberTooLong, 'a number has more than 4 digits'),
    _scanWrongCount => _fail(ErrorKind.wrongGroupCount, 'expected year, month and day'),
    _ => _fail(ErrorKind.invalidCharacter, 'unexpected character U+${_hex(-packed - 3)}'),
  };
}

String _hex(int unit) => unit.toRadixString(16).toUpperCase().padLeft(4, '0');

/// Month names of PARSING section 3, lower case for the Latin ones.
final Map<String, int> _monthNames = () {
  const names = [
    'baishakh baisakh baishak vaishakh vaisakh bai बैशाख वैशाख बैसाख',
    'jestha jeth jyestha jes जेठ जेष्ठ ज्येष्ठ',
    'ashad ashadh asar asadh asa असार आषाढ असाढ',
    'shrawan shravan srawan sawan saun shr साउन श्रावण सावन',
    'bhadra bhadau bha भदौ भाद्र भाद्रपद',
    'ashoj asoj ashwin aso असोज आश्विन असौज',
    'kartik kattik kar कार्तिक कात्तिक',
    'mangsir mansir margashirsha man मंसिर मङ्सिर मार्गशीर्ष',
    'poush paush push pus pou पुष पौष पुस',
    'magh mag माघ',
    'falgun phalgun fagun fal फागुन फाल्गुन',
    'chaitra chait cha चैत चैत्र',
  ];
  return {
    for (final (i, row) in names.indexed)
      for (final name in row.split(' ')) name: i + 1,
  };
}();

const Set<String> _eraMarkers = {
  'bs',
  'b.s.',
  'b.s',
  'vs',
  'v.s.',
  'v.s',
  'बि.सं.',
  'वि.सं.',
  'बि.सं',
  'वि.सं',
};

/// Folds A to Z to a to z and the Kelvin sign to `k`, like the reference's `str.lower()` onto
/// ASCII (PARSING section 2). No other character folds.
String _fold(String token) {
  final out = StringBuffer();
  for (final unit in token.codeUnits) {
    if (unit >= 0x41 && unit <= 0x5A) {
      out.writeCharCode(unit + 0x20);
    } else if (unit == 0x212A) {
      out.write('k');
    } else {
      out.writeCharCode(unit);
    }
  }
  return out.toString();
}

bool _allAsciiDigits(String token) {
  if (token.isEmpty) return false;
  for (final unit in token.codeUnits) {
    if (unit < 0x30 || unit > 0x39) return false;
  }
  return true;
}

_Parsed _parseLenient(String text) {
  final strict = _parseStrict(text);
  if (strict.date != null) return strict;

  // Devanagari digits become ASCII; no other normalisation happens.
  final mapped = StringBuffer();
  for (final unit in text.codeUnits) {
    final digit = _digit(unit);
    mapped.writeCharCode(digit >= 0 ? 0x30 + digit : unit);
  }
  final raw = <String>[];
  final current = StringBuffer();
  void flush() {
    if (current.isNotEmpty) {
      raw.add(current.toString());
      current.clear();
    }
  }

  for (final unit in mapped.toString().codeUnits) {
    if ((_isSeparator(unit) && unit != 0x2E) || unit == 0x2C) {
      flush();
    } else {
      current.writeCharCode(unit);
    }
  }
  flush();

  // A token of only digits and dots is split on the dots; anything else stays one word.
  final tokens = <String>[];
  for (final token in raw) {
    final digitsAndDots = token.codeUnits.every((u) => u == 0x2E || (u >= 0x30 && u <= 0x39));
    if (digitsAndDots) {
      tokens.addAll(token.split('.').where((part) => part.isNotEmpty));
    } else {
      tokens.add(token);
    }
  }
  final kept =
      tokens.where((t) => !_eraMarkers.contains(_fold(t)) && t != 'गते' && t != 'मिति').toList();
  final numbers = kept.where(_allAsciiDigits).toList();
  final words = kept.where((t) => !_allAsciiDigits(t)).toList();

  if (numbers.any((n) => n.length > 4)) {
    return _fail(ErrorKind.numberTooLong, 'a number has more than 4 digits');
  }
  if (words.length == 1 && _monthNames.containsKey(_fold(words[0])) && numbers.length == 2) {
    final month = _monthNames[_fold(words[0])]!;
    final fourDigit = numbers.where((n) => n.length == 4).toList();
    if (fourDigit.length != 1) {
      return _fail(ErrorKind.ambiguous, 'exactly one number must have four digits');
    }
    final other = numbers[0].length == 4 ? numbers[1] : numbers[0];
    if (other.length > 2) return _fail(ErrorKind.ambiguous, 'the day has more than two digits');
    return _validated(int.parse(fourDigit.single), month, int.parse(other));
  }
  if (words.isEmpty && numbers.length == 3) {
    if (numbers[0].length == 4) {
      return _validated(int.parse(numbers[0]), int.parse(numbers[1]), int.parse(numbers[2]));
    }
    if (numbers[2].length == 4) {
      return _validated(int.parse(numbers[2]), int.parse(numbers[1]), int.parse(numbers[0]));
    }
    return _fail(ErrorKind.ambiguous, 'no number has four digits');
  }
  return _fail(ErrorKind.unrecognized, 'not a date in an accepted form');
}
