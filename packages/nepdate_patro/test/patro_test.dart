// PATRO section 4 anchors, the summary counts, and the shape guarantees of info().

import 'dart:convert';

import 'package:nepdate/nepdate.dart';
import 'package:nepdate_patro/nepdate_patro.dart';
import 'package:test/test.dart';

import '../../nepdate/test/support/vectors.dart';

NepaliDate of(int y, int m, int d) => NepaliDate.fromBs(y, m, d);

void main() {
  final summary = readPatroSummary();

  test('the tables hold the counts of patro-summary.json', () {
    final first = of(2077, 1, 1);
    final days = coverage().toList();
    expect(coverage().start, first);
    expect(coverage().start.toJson(), summary['first_day']);
    expect(coverage().end.toJson(), summary['last_day']);
    expect(days, hasLength(summary['days']! as int));
    expect(days.where((d) => info(d).tithi != null), hasLength(summary['tithi_days']! as int));
    expect(publicHolidays(), hasLength(summary['holidays']! as int));
    expect(days.where((d) => info(d).events.isNotEmpty), hasLength(summary['event_days']! as int));
    expect(days.fold<int>(0, (sum, d) => sum + info(d).events.length), summary['events']);
    final names = <Named>{};
    for (final d in days) {
      final tithi = info(d).tithi;
      if (tithi != null) names.add(tithi);
      names.addAll(info(d).events);
    }
    expect(names, hasLength(summary['names']! as int));
    final bytes = names.fold<int>(
      0,
      (sum, n) => sum + utf8.encode(n.nepali).length + utf8.encode(n.english).length,
    );
    expect(bytes, summary['name_bytes']);
  });

  test('tithi runs without a gap from its first to its last day', () {
    final firstDay = of(2078, 1, 2);
    final lastDay = of(2083, 12, 30);
    expect(info(firstDay).tithi, isNotNull);
    expect(info(lastDay).tithi, isNotNull);
    expect(info(firstDay.addDays(-1)).tithi, isNull);
    expect(info(lastDay.addDays(1)).tithi, isNull);
    for (var d = firstDay; d <= lastDay; d = d.addDays(1)) {
      expect(info(d).tithi, isNotNull, reason: '$d');
    }
  });

  test('PATRO anchors', () {
    List<String> english(NepaliDate d) => info(d).events.map((e) => e.english).toList();

    expect(info(of(2081, 1, 1)).tithi?.english, 'Panchami');
    expect(info(of(2081, 1, 1)).isPublicHoliday, isTrue);
    expect(english(of(2081, 1, 1)), ['New Year', 'Mesh Sankranti', 'Bisket Jatra']);
    expect(info(of(2081, 1, 2)).tithi?.english, 'Shashthi');
    expect(info(of(2081, 1, 2)).isPublicHoliday, isFalse);
    expect(english(of(2081, 1, 2)), isEmpty);
    expect(info(of(2081, 2, 15)).tithi?.english, 'Panchami');
    expect(english(of(2081, 2, 15)), ['Republic Day']);
    expect(info(of(2080, 11, 1)).tithi?.english, 'Chaturthi');
    expect(english(of(2080, 11, 1)), [
      'Mangala Chauthi Brata',
      "People's War Day",
      'Tilakund Chauthi',
      'Kumbha Sankranti',
      'World Radio Day',
    ]);
    expect(info(of(2081, 4, 15)).tithi?.english, 'Dashami');
    expect(info(of(2081, 4, 15)).isPublicHoliday, isFalse);
    expect(english(of(2081, 4, 15)), [
      'Kheer Khane Din',
      'World Day Against Human Trafficking',
      'International Friendship Day',
    ]);
    for (final date in [of(2070, 6, 15), of(2090, 1, 1)]) {
      expect(info(date).tithi, isNull);
      expect(info(date).isPublicHoliday, isFalse);
      expect(info(date).events, isEmpty);
    }
  });

  test('names are shown exactly as the data has them, markers included', () {
    final marked = coverage()
        .map((d) => info(d).tithi)
        .whereType<Named>()
        .where((t) => t.nepali.endsWith('*'));
    expect(marked, isNotEmpty);
    expect(marked.every((t) => t.english.endsWith(' (K)')), isTrue);
    expect(marked.first.english, endsWith(' (K)'));
  });

  test('name picks the language', () {
    final tithi = info(of(2081, 1, 1)).tithi!;
    expect(tithi.name(Lang.ne), 'पञ्चमी');
    expect(tithi.name(Lang.en), 'Panchami');
  });

  test('info never throws and returns the same object for the same day', () {
    expect(identical(info(NepaliDate.min), info(NepaliDate.max)), isTrue);
    expect(identical(info(of(2081, 1, 1)), info(of(2081, 1, 1))), isTrue);
    expect(() => info(NepaliDate.max), returnsNormally);
  });

  test('the events list cannot be changed', () {
    final events = info(of(2081, 1, 1)).events;
    expect(() => events.add(events.first), throwsUnsupportedError);
    expect(() => info(of(2090, 1, 1)).events.add(events.first), throwsUnsupportedError);
  });

  test('public holidays are ascending and every one is flagged', () {
    NepaliDate? previous;
    for (final date in publicHolidays()) {
      if (previous != null) expect(date, greaterThan(previous));
      expect(info(date).isPublicHoliday, isTrue);
      previous = date;
    }
    expect(publicHolidays().first.toJson(), '2077-01-01');
  });
}
