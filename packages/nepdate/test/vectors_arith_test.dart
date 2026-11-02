// Phase 2 vectors: add days and months, day difference, fiscal year and quarters, and every range
// file. Rows whose note is a D number hold the port's expected value (spec/PARITY.md).

import 'package:nepdate/nepdate.dart';
import 'package:test/test.dart';

import 'support/helpers.dart';
import 'support/vectors.dart';

void main() {
  test('add-days.tsv (9162 rows)', () {
    final rows = readVectors('csharp-golden/add-days.tsv');
    expect(rows, hasLength(9162));
    for (final row in rows) {
      expect(attempt(() => bs(row['bs']).addDays(int.parse(row['days']))), row['result'],
          reason: '$row');
    }
  });

  test('add-months.tsv: clamp and overflow (10180 rows)', () {
    final rows = readVectors('csharp-golden/add-months.tsv');
    expect(rows, hasLength(10180));
    for (final row in rows) {
      final date = bs(row['bs']);
      final months = int.parse(row['months']);
      expect(attempt(() => date.addMonths(months)), row['clamp'], reason: '$row');
      expect(
        attempt(() => date.addMonths(months, overflow: MonthOverflow.spill)),
        row['overflow'],
        reason: '$row',
      );
      if (months % 12 == 0) {
        expect(attempt(() => date.addYears(months ~/ 12)), row['clamp'], reason: '$row');
      }
    }
  });

  test('ALGORITHM section 8 examples', () {
    final date = bs('2081-04-32');
    expect(iso(date.addMonths(2)), '2081-06-30');
    expect(iso(date.addMonths(2, overflow: MonthOverflow.spill)), '2081-07-02');
    expect(iso(date.addMonths(5)), '2081-09-29');
    expect(iso(date.addMonths(5, overflow: MonthOverflow.spill)), '2081-10-03');
  });

  test('day-diff.tsv: days_until is other - this, the operator is this - other (D-07)', () {
    final rows = readVectors('csharp-golden/day-diff.tsv');
    expect(rows, hasLength(16));
    for (final row in rows) {
      final a = bs(row['a']);
      final b = bs(row['b']);
      expect(a.daysUntil(b), int.parse(row['days_until']), reason: '$row');
      expect(a.diff(b).totalDays, int.parse(row['days_until']), reason: '$row');
      expect((a - b).totalDays, int.parse(row['operator_minus']), reason: '$row');
    }
  });

  test('ALGORITHM section 8a calendar breakdown', () {
    void check(String a, String b, bool negative, int years, int months, int days, int total) {
      final diff = bs(a).diff(bs(b));
      expect(
        (diff.negative, diff.years, diff.months, diff.days, diff.totalDays),
        (negative, years, months, days, total),
        reason: '$a to $b',
      );
    }

    check('2080-01-01', '2081-04-15', false, 1, 3, 14, 473);
    check('2081-04-15', '2080-01-01', true, 1, 3, 14, -473);
    check('2081-04-32', '2081-05-31', false, 0, 1, 0, 31);
    check('2081-04-32', '2081-06-01', false, 0, 1, 1, 32);
    check('2081-01-31', '2081-02-30', false, 0, 0, 30, 30);
    check('2081-03-15', '2081-03-15', false, 0, 0, 0, 0);
  });

  test('dates.tsv: fiscal year and quarter columns (1018 rows)', () {
    for (final row in readVectors('csharp-golden/dates.tsv')) {
      final date = bs(row['bs']);
      final fiscal = date.fiscalYear;
      expect(attempt(fiscal.start), row['fy_start'], reason: '$row');
      expect(attempt(fiscal.end), row['fy_end'], reason: '$row');
      expect(attempt(() => fiscal.quarterRange(date.quarter).start), row['quarter_start'],
          reason: '$row');
      expect(attempt(() => fiscal.quarterRange(date.quarter).end), row['quarter_end'],
          reason: '$row');
    }
  });

  test('FY 2082 label in Nepali is २०८२/८३', () {
    expect(FiscalYear(2082).label(Lang.ne), '२०८२/८३');
    expect(FiscalYear(2082).label(), '2082/83');
    expect(FiscalYear(2099).label(), '2099/00');
  });

  test('every year range has the sum of its month lengths', () {
    for (var year = 1901; year <= 2199; year++) {
      final range = NepaliDateRange.forYear(year);
      var sum = 0;
      for (var month = 1; month <= 12; month++) {
        sum += NepaliDate.fromBs(year, month, 1).monthLength;
      }
      expect(range.length, sum, reason: '$year');
      expect(range.length, NepaliDate.fromBs(year, 6, 1).yearLength, reason: '$year');
    }
  });

  test('ranges.tsv (54 rows; D-01, D-16)', () {
    final rows = readVectors('csharp-golden/ranges.tsv');
    expect(rows, hasLength(54));
    for (final row in rows) {
      final operation = row['operation'];
      String result;
      if (operation == 'construct') {
        result = _attemptRange(row['start'], row['end']);
      } else {
        final range = NepaliDateRange.of(bs(row['start']), bs(row['end']));
        final argument = row['argument'];
        result = switch (operation) {
          'length' => '${range.length}',
          'contains_date' => '${range.contains(bs(argument))}',
          'contains_range' => '${range.containsRange(rangeOf(argument))}',
          'overlaps' => '${range.overlaps(rangeOf(argument))}',
          'is_adjacent_to' => '${range.isAdjacentTo(rangeOf(argument))}',
          'intersect' => _optional(range.intersect(rangeOf(argument))),
          'union' => rangeText(range.union(rangeOf(argument))),
          'except' => rangesText(range.except(rangeOf(argument))),
          'equals' => '${range == rangeOf(argument)}',
          'to_string' => range.toString(),
          'enumerate' => datesText(range),
          _ => throw StateError('unknown operation $operation'),
        };
      }
      expect(result, row['result'], reason: '$row');
    }
  });

  test('range-factories.tsv (27 rows; D-01)', () {
    final rows = readVectors('csharp-golden/range-factories.tsv');
    expect(rows, hasLength(27));
    for (final row in rows) {
      final argument = row['argument'];
      final parts = argument.split(',');
      final result = _attemptFactory(() => switch (row['factory']) {
            'single_day' => NepaliDateRange.singleDay(_bsOrThrow(argument)),
            'from_day_count' =>
              NepaliDateRange.fromDayCount(_bsOrThrow(parts[0]), int.parse(parts[1])),
            'for_month' => NepaliDateRange.forMonth(int.parse(parts[0]), int.parse(parts[1])),
            'for_calendar_year' => NepaliDateRange.forYear(int.parse(argument)),
            'for_fiscal_year' => FiscalYear(int.parse(argument)).range(),
            'construct' => NepaliDateRange.of(bs(parts[0]), bs(parts[1])),
            final other => throw StateError('unknown factory $other'),
          });
      expect(result, row['result'], reason: '$row');
    }
  });

  test('range-splits.tsv (9 rows; D-16)', () {
    final rows = readVectors('csharp-golden/range-splits.tsv');
    expect(rows, hasLength(9));
    for (final row in rows) {
      final range = NepaliDateRange.of(bs(row['start']), bs(row['end']));
      final pieces = switch (row['operation']) {
        'split_by_month' => range.splitByMonth(),
        'split_by_fiscal_quarter' => range.splitByFiscalQuarter(),
        final other => throw StateError('unknown operation $other'),
      };
      expect(rangesText(pieces), row['result'], reason: '$row');
    }
  });

  test('range-days.tsv (18 rows; D-16)', () {
    final rows = readVectors('csharp-golden/range-days.tsv');
    expect(rows, hasLength(18));
    for (final row in rows) {
      final range = NepaliDateRange.of(bs(row['start']), bs(row['end']));
      final argument = row['argument'];
      String result;
      try {
        result = datesText(switch (row['operation']) {
          'dates_with_interval' => range.datesWithInterval(int.parse(argument)),
          'working_days' => range.workingDays(excludeSunday: argument == 'true'),
          'weekend_days' => range.weekendDays(includeSunday: argument == 'true'),
          'enumerate' => range,
          final other => throw StateError('unknown operation $other'),
        });
      } on ArgumentError {
        result = 'ERR';
      }
      expect(result, row['result'], reason: '$row');
    }
  });

  test('range-format.tsv (18 rows; D-01, D-15)', () {
    final rows = readVectors('csharp-golden/range-format.tsv');
    expect(rows, hasLength(18));
    for (final row in rows) {
      final lang = row['lang'] == 'ne' ? Lang.ne : Lang.en;
      final String result;
      try {
        final range = NepaliDateRange.of(bs(row['start']), bs(row['end']));
        result = row['kind'] == 'default'
            ? range.toString()
            : range.toStringWith(
                orderByName[row['order']]!,
                separatorByName[row['separator']]!,
                lang,
              );
      } on NepDateException {
        expect(row['result'], 'ERR', reason: '$row');
        continue;
      }
      expect(result, row['result'], reason: '$row');
    }
  });

  test('a range is iterable, hashable and refuses a bad argument', () {
    final range = NepaliDateRange.forMonth(2081, 4);
    expect(range.first, bs('2081-04-01'));
    expect(range.last, bs('2081-04-32'));
    expect(range.isEmpty, isFalse);
    expect(range.isNotEmpty, isTrue);
    expect(range.toList(), hasLength(32));
    expect({range, NepaliDateRange.forMonth(2081, 4)}, hasLength(1));
    expect(() => range.datesWithInterval(0), throwsArgumentError);
    expect(() => NepaliDateRange.fromDayCount(bs('2081-04-15'), 0), throwsArgumentError);
  });
}

NepaliDate _bsOrThrow(String text) => bs(text);

String _optional(NepaliDateRange? range) => range == null ? 'none' : rangeText(range);

String _attemptRange(String start, String end) {
  try {
    return rangeText(NepaliDateRange.of(bs(start), bs(end)));
  } on NepDateException {
    return 'ERR';
  } on FormatException {
    return 'ERR';
  }
}

String _attemptFactory(NepaliDateRange Function() build) {
  try {
    return rangeText(build());
  } on NepDateException {
    return 'ERR';
  } on ArgumentError {
    return 'ERR';
  } on FormatException {
    return 'ERR';
  }
}
