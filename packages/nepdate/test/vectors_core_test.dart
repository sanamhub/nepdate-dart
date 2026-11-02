// Phase 1 vectors: month boundaries, the full serial round trip, year length, and the golden
// dates.tsv columns for conversion, weekday and day of year.

import 'package:nepdate/nepdate.dart';
import 'package:test/test.dart';

import 'support/helpers.dart';
import 'support/vectors.dart';

void main() {
  test('month-boundaries.csv: every first and last day of a BS month (7176 rows)', () {
    final rows = readVectors('month-boundaries.csv');
    expect(rows, hasLength(7176));
    for (final row in rows) {
      final date = bs(row['bs']);
      expect(adIso(date.toDateTime()), row['ad'], reason: '$row');
      expect(adIso(NepaliDate.fromGregorian(ad(row['ad'])).toDateTime()), row['ad']);
      expect(iso(NepaliDate.fromGregorian(ad(row['ad']))), row['bs'], reason: '$row');
      expect(date.weekday, weekdayByName[row['weekday']], reason: '$row');
      expect(date.monthLength, int.parse(row['month_length']), reason: '$row');
    }
  });

  test('all 109,212 serials round-trip through Gregorian and BS', () {
    var date = NepaliDate.min;
    var count = 0;
    while (true) {
      final back = NepaliDate.fromGregorian(date.toDateTime());
      expect(back, date);
      expect(NepaliDate.min.daysUntil(date), count);
      count++;
      if (date == NepaliDate.max) break;
      date = date.addDays(1);
    }
    expect(count, 109212);
  });

  test('year-length.tsv: 299 years of 364 to 367 days (D-12)', () {
    final rows = readVectors('year-length.tsv');
    expect(rows, hasLength(299));
    for (final row in rows) {
      final year = int.parse(row['bs_year']);
      expect(NepaliDate.fromBs(year, 1, 1).yearLength, int.parse(row['year_length']));
      expect(NepaliDate.fromBs(year, 12, 1).yearLength, int.parse(row['year_length']));
    }
  });

  test('dates.tsv: ad, weekday, day_of_year and month_length (1018 rows)', () {
    final rows = readVectors('csharp-golden/dates.tsv');
    expect(rows, hasLength(1018));
    for (final row in rows) {
      final date = bs(row['bs']);
      expect(adIso(date.toDateTime()), row['ad'], reason: '$row');
      expect(iso(NepaliDate.fromGregorian(ad(row['ad']))), row['bs'], reason: '$row');
      expect(date.weekday, weekdayByName[row['weekday']], reason: '$row');
      expect(date.dayOfYear, int.parse(row['day_of_year']), reason: '$row');
      expect(date.monthLength, int.parse(row['month_length']), reason: '$row');
    }
  });

  test('the calendar ends: 2081-04-32 is valid, 2081-04-33 is not, AD ends are out of range', () {
    expect(NepaliDate.fromBs(2081, 4, 32).day, 32);
    expect(
      () => NepaliDate.fromBs(2081, 4, 33),
      throwsA(isA<NepDateException>().having((e) => e.kind, 'kind', ErrorKind.invalidDay)),
    );
    expect(
      () => NepaliDate.fromGregorian(DateTime.utc(1844, 4, 10)),
      throwsA(isA<NepDateException>().having((e) => e.kind, 'kind', ErrorKind.outOfRange)),
    );
    expect(
      () => NepaliDate.fromGregorian(DateTime.utc(2143, 4, 16)),
      throwsA(isA<NepDateException>().having((e) => e.kind, 'kind', ErrorKind.outOfRange)),
    );
    expect(iso(NepaliDate.fromGregorian(DateTime.utc(1844, 4, 11))), '1901-01-01');
    expect(iso(NepaliDate.fromGregorian(DateTime.utc(2143, 4, 15))), '2199-12-30');
  });

  test('validation reports the year first, then the month, then the day', () {
    ErrorKind kind(int y, int m, int d) {
      try {
        NepaliDate.fromBs(y, m, d);
      } on NepDateException catch (error) {
        return error.kind;
      }
      throw StateError('no error');
    }

    expect(kind(1900, 13, 40), ErrorKind.outOfRange);
    expect(kind(2200, 0, 0), ErrorKind.outOfRange);
    expect(kind(2081, 13, 40), ErrorKind.invalidMonth);
    expect(kind(2081, 0, 1), ErrorKind.invalidMonth);
    expect(kind(2081, 4, 0), ErrorKind.invalidDay);
    expect(kind(2199, 12, 31), ErrorKind.invalidDay);
  });
}
