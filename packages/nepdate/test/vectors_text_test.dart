// Phase 3 and 4 vectors: formatting, parsing, and the interop files (YYYYMMDD, batch, JSON).

import 'package:nepdate/nepdate.dart';
import 'package:test/test.dart';

import 'support/helpers.dart';
import 'support/vectors.dart';

String _parseOutcome(NepaliDate Function() parse) {
  try {
    return iso(parse());
  } on NepDateException catch (error) {
    return 'ERR:${error.kind.name[0].toUpperCase()}${error.kind.name.substring(1)}';
  }
}

void main() {
  test('dates.tsv: the text columns (1018 rows)', () {
    for (final row in readVectors('csharp-golden/dates.tsv')) {
      final date = bs(row['bs']);
      expect(date.toString(), row['to_string'], reason: '$row');
      expect(date.toShortString(lang: Lang.ne), row['unicode'], reason: '$row');
      expect(date.toLongString(), row['long_en'], reason: '$row');
      expect(date.toLongString(weekday: true), row['long_en_weekday'], reason: '$row');
      expect(date.toLongString(lang: Lang.ne), row['long_ne'], reason: '$row');
      expect(date.toLongString(weekday: true, lang: Lang.ne), row['long_ne_weekday'],
          reason: '$row');
      expect(
        date.toShortString(order: DateOrder.dmy, separator: Separator.dash, pad: false),
        row['dmy_dash_nopad'],
        reason: '$row',
      );
    }
  });

  test('format-pattern.tsv (452 rows; D-04 rows skipped)', () {
    final rows = readVectors('csharp-golden/format-pattern.tsv');
    expect(rows, hasLength(452));
    var skipped = 0;
    for (final row in rows) {
      final date = bs(row['bs']);
      final pattern = row['pattern'];
      // D-04: C# writes `Ash` for both Ashad and Ashoj; the port writes `Asa` and `Aso`.
      if (pattern.contains('MMM') &&
          !pattern.contains('MMMM') &&
          (date.month == 3 || date.month == 6)) {
        skipped++;
        continue;
      }
      expect(date.format(pattern), row['result'], reason: '$row');
    }
    expect(skipped, greaterThan(0));
  });

  test('D-04: the Ashad and Ashoj abbreviations are Asa and Aso', () {
    expect(bs('2081-03-01').format('MMM'), 'Asa');
    expect(bs('2081-06-01').format('MMM'), 'Aso');
    expect(Month.ashad.shortName(), 'Asa');
    expect(Month.ashoj.shortName(), 'Aso');
  });

  test('format-matrix.tsv: short formats (D-15); try_format has no buffer in Dart', () {
    final rows = readVectors('csharp-golden/format-matrix.tsv');
    expect(rows, hasLength(102));
    var shorts = 0;
    for (final row in rows) {
      if (row['kind'] == 'try_format') {
        // NF07 is "none; string return" in the Dart column: a string is never too short, so the
        // row's content is covered by the pattern vectors. The capacity only decides ERR.
        final text = row['format'] == 'default'
            ? bs(row['bs']).toString()
            : bs(row['bs']).format(row['format']);
        if (row['result'] != 'ERR') expect(text, row['result'], reason: '$row');
        continue;
      }
      shorts++;
      expect(
        bs(row['bs']).toShortString(
          order: orderByName[row['order']]!,
          separator: separatorByName[row['separator']]!,
          pad: row['pad'] == 'true',
          lang: row['lang'] == 'ne' ? Lang.ne : Lang.en,
        ),
        row['result'],
        reason: '$row',
      );
    }
    expect(shorts, 94);
  });

  test('parse.tsv: strict and lenient, with the error kind (69 rows)', () {
    final rows = readVectors('parse.tsv');
    expect(rows, hasLength(69));
    for (final row in rows) {
      final input = row['input'];
      expect(_parseOutcome(() => NepaliDate.parse(input)), row['strict'], reason: '$row');
      expect(_parseOutcome(() => NepaliDate.parseLenient(input)), row['lenient'], reason: '$row');
      expect(NepaliDate.tryParse(input) == null, row['strict'].startsWith('ERR'), reason: '$row');
      expect(
        NepaliDate.tryParseLenient(input) == null,
        row['lenient'].startsWith('ERR'),
        reason: '$row',
      );
    }
  });

  test('ymd-int.tsv: the YYYYMMDD integer both ways (14 rows; D-11)', () {
    final rows = readVectors('csharp-golden/ymd-int.tsv');
    expect(rows, hasLength(14));
    for (final row in rows) {
      if (row['kind'] == 'date') {
        final date = bs(row['input']);
        expect(date.ymd, int.parse(row['ymd']), reason: '$row');
        expect(iso(NepaliDate.fromYmd(date.ymd)), row['result'], reason: '$row');
      } else {
        expect(attempt(() => NepaliDate.fromYmd(int.parse(row['ymd']))), row['result'],
            reason: '$row');
      }
    }
  });

  test('bulk.tsv: batch conversion keeps input order (6 rows)', () {
    final rows = readVectors('csharp-golden/bulk.tsv');
    expect(rows, hasLength(6));
    for (final row in rows) {
      final inputs = row['input'].split(';');
      String result;
      try {
        result = switch (row['operation']) {
          'to_nepali_dates' ||
          'batch_to_nepali_dates' =>
            NepaliDate.fromGregorianAll(inputs.map(ad)).map(iso).join(';'),
          'to_english_dates_from_strings' => NepaliDate.parseAll(inputs).map(adIso).join(';'),
          'to_english_dates_from_dates' ||
          'batch_to_english_dates' =>
            NepaliDate.toGregorianAll(inputs.map(bs)).map(adIso).join(';'),
          final other => throw StateError('unknown operation $other'),
        };
      } on NepDateException {
        result = 'ERR';
      }
      expect(result, row['output'], reason: '$row');
    }
  });

  test('serialization.tsv: toJson and fromJson (11 rows; D-01, D-11)', () {
    final rows = readVectors('csharp-golden/serialization.tsv');
    expect(rows, hasLength(11));
    for (final row in rows) {
      switch (row['kind']) {
        case 'write':
          expect('"${bs(row['input']).toJson()}"', row['json'], reason: '$row');
        case 'roundtrip':
          final date = bs(row['input']);
          expect('"${date.toJson()}"', row['json'], reason: '$row');
          expect(iso(NepaliDate.fromJson(date.toJson())), row['result'], reason: '$row');
        case 'read':
          final json = row['input'];
          final Object? value = json == 'null' ? null : json.substring(1, json.length - 1);
          expect(attempt(() => NepaliDate.fromJson(value)), row['result'], reason: '$row');
        default:
          fail('unknown kind in $row');
      }
    }
  });
}
