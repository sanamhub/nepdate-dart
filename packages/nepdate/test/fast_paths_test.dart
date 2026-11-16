// The conversion, formatting and parsing shortcuts must give the same answers as the plain
// definitions for every date of the calendar.

import 'package:nepdate/nepdate.dart';
import 'package:test/test.dart';

const _devanagari = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];

String _pad(int value, int width) => value.toString().padLeft(width, '0');

String _nepali(String text) {
  var out = text;
  for (var digit = 0; digit < 10; digit++) {
    out = out.replaceAll('$digit', _devanagari[digit]);
  }
  return out;
}

void main() {
  final total = NepaliDate.min.daysUntil(NepaliDate.max) + 1;

  test('every day converts to midnight UTC and back', () {
    final epoch = DateTime.utc(1844, 4, 11);
    for (var serial = 0; serial < total; serial++) {
      final date = NepaliDate.min.addDays(serial);
      final gregorian = date.toDateTime();
      expect(gregorian.isUtc, isTrue);
      expect(gregorian, epoch.add(Duration(days: serial)));
      expect(NepaliDate.fromGregorian(gregorian), date);
    }
  });

  test('a UTC time of day does not change the date, before and after 1970', () {
    for (final day in [
      DateTime.utc(1844, 4, 11),
      DateTime.utc(1950, 6, 15),
      DateTime.utc(1969, 12, 31),
      DateTime.utc(1970, 1, 1),
      DateTime.utc(2024, 7, 30),
      DateTime.utc(2143, 4, 15),
    ]) {
      final expected = NepaliDate.fromGregorian(day);
      final lastInstant =
          day.add(const Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
      expect(NepaliDate.fromGregorian(day.add(const Duration(milliseconds: 1))), expected);
      expect(NepaliDate.fromGregorian(lastInstant), expected);
    }
  });

  test('a local DateTime converts the day on its wall clock', () {
    final local = DateTime(2024, 7, 30, 23, 30);
    expect(local.isUtc, isFalse);
    expect(NepaliDate.fromGregorian(local), NepaliDate.fromBs(2081, 4, 15));
    expect(NepaliDate.fromGregorian(DateTime(2024, 7, 30, 0, 15)), NepaliDate.fromBs(2081, 4, 15));
  });

  test('the first instant outside the calendar is rejected on both sides', () {
    final before = DateTime.utc(1844, 4, 11).subtract(const Duration(milliseconds: 1));
    final after = DateTime.utc(2143, 4, 16);
    for (final date in [before, after, DateTime(1844, 4, 10), DateTime(2143, 4, 16)]) {
      expect(
        () => NepaliDate.fromGregorian(date),
        throwsA(isA<NepDateException>().having((e) => e.kind, 'kind', ErrorKind.outOfRange)),
      );
    }
    expect(NepaliDate.fromGregorian(DateTime.utc(2143, 4, 15, 23, 59, 59, 999)), NepaliDate.max);
  });

  test('every day prints the same text as the padded numbers', () {
    for (var serial = 0; serial < total; serial++) {
      final date = NepaliDate.min.addDays(serial);
      final year = _pad(date.year, 4);
      final month = _pad(date.month, 2);
      final day = _pad(date.day, 2);
      expect(date.toString(), '$year/$month/$day');
      expect(date.toJson(), '$year-$month-$day');
      expect(date.toShortString(lang: Lang.ne), _nepali('$year/$month/$day'));
      expect(
        date.toShortString(order: DateOrder.dmy, separator: Separator.dash, pad: false),
        '${date.day}-${date.month}-${date.year}',
      );
      expect(
        date.toLongString(weekday: true, lang: Lang.ne),
        '${date.weekday.fullName(Lang.ne)}, ${date.monthEnum.fullName(Lang.ne)} '
        '${_nepali(day)}, ${_nepali(year)}',
      );
      expect(
        date.toLongString(pad: false),
        '${date.monthEnum.fullName()} ${date.day}, ${date.year}',
      );
      expect(date.format('yy M d', lang: Lang.ne),
          _nepali('${_pad(date.year % 100, 2)} ${date.month} ${date.day}'));
      expect(NepaliDate.parse(date.toString()), date);
      expect(NepaliDate.tryParse(_nepali(date.toJson())), date);
    }
  });

  test('every order of a short date places the three parts', () {
    final date = NepaliDate.fromBs(2081, 4, 5);
    const expected = {
      DateOrder.ymd: '2081.04.05',
      DateOrder.ydm: '2081.05.04',
      DateOrder.myd: '04.2081.05',
      DateOrder.mdy: '04.05.2081',
      DateOrder.dym: '05.2081.04',
      DateOrder.dmy: '05.04.2081',
    };
    for (final order in DateOrder.values) {
      expect(date.toShortString(order: order, separator: Separator.dot), expected[order]);
    }
    expect(date.toLongString(weekday: true, year: false), 'Saturday, Shrawan 05');
    expect(date.toLongString(year: false, pad: false, lang: Lang.ne), 'साउन ५');
  });

  test('parse and tryParse agree on what fails and why', () {
    const cases = {
      '2081/04/15/1': ErrorKind.wrongGroupCount,
      '2081/04': ErrorKind.wrongGroupCount,
      '': ErrorKind.wrongGroupCount,
      '20811/04/15': ErrorKind.numberTooLong,
      '2081/04/15x': ErrorKind.invalidCharacter,
      '2081/04/15/x': ErrorKind.invalidCharacter,
      '2081/04/15/12345': ErrorKind.wrongGroupCount,
      '1900/01/01': ErrorKind.outOfRange,
      '2081/13/01': ErrorKind.invalidMonth,
      '2081/04/33': ErrorKind.invalidDay,
      '0/0/0': ErrorKind.outOfRange,
    };
    cases.forEach((text, kind) {
      expect(NepaliDate.tryParse(text), isNull, reason: text);
      expect(
        () => NepaliDate.parse(text),
        throwsA(isA<NepDateException>().having((e) => e.kind, 'kind', kind)),
        reason: text,
      );
    });
    expect(
      () => NepaliDate.parse('2081/04/15x'),
      throwsA(isA<NepDateException>().having((e) => e.message, 'message', contains('U+0078'))),
    );
    expect(NepaliDate.parse('  2081//4।15 |'), NepaliDate.fromBs(2081, 4, 15));
  });
}
