// B1 to B8 of shared/spec/BENCHMARK.md, plus B1 and B2 for the selected competitor.
//
// Run from the repository root, pinned to one performance core:
//
//   dart compile exe bench/bin/bench.dart -o .dart_tool/bench.exe
//   .dart_tool/bench.exe
//
// Each operation runs over all 64 inputs in one iteration. The reported time is the mean per single
// operation in nanoseconds. Bytes are not reported: the Dart VM has no allocation counter that can
// be read per operation, so the table says "not measured" rather than guessing.

import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:nepali_utils/nepali_utils.dart' as competitor;
import 'package:nepdate/nepdate.dart';
import 'package:nepdate_patro/nepdate_patro.dart';

const int _count = 64;

/// Input date `i` of section 2: the BS date at serial `s0 + i * ((s1 - s0) / 63)`.
List<NepaliDate> _dates() {
  final first = NepaliDate.fromBs(2000, 1, 1);
  final last = NepaliDate.fromBs(2090, 12, 30);
  final s0 = NepaliDate.min.daysUntil(first);
  final s1 = NepaliDate.min.daysUntil(last);
  return [
    for (var i = 0; i < _count; i++) NepaliDate.min.addDays(s0 + i * ((s1 - s0) ~/ (_count - 1))),
  ];
}

/// The patro input for B7 and B8: 64 dates spread over the patro coverage.
List<NepaliDate> _patroDates() {
  final coverageRange = coverage();
  final s0 = NepaliDate.min.daysUntil(coverageRange.start);
  final s1 = NepaliDate.min.daysUntil(coverageRange.end);
  return [
    for (var i = 0; i < _count; i++) NepaliDate.min.addDays(s0 + i * ((s1 - s0) ~/ (_count - 1))),
  ];
}

/// Keeps a result observable, so the compiler cannot remove the work.
int sink = 0;

class _Bench extends BenchmarkBase {
  _Bench(super.name, this.body);

  final void Function() body;

  @override
  void run() => body();

  // Report the time of one call to run() (one pass over the 64 inputs), not ten.
  @override
  void exercise() => run();
}

double _nsPerOp(_Bench benchmark, int operations) => benchmark.measure() * 1000 / operations;

void main() {
  final dates = _dates();
  final patroDates = _patroDates();
  final texts = [
    for (final date in dates)
      '${date.year.toString().padLeft(4, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.day.toString().padLeft(2, '0')}',
  ];
  final adDates = [for (final date in dates) date.toDateTime()];
  final adFields = [
    for (final date in adDates) (date.year, date.month, date.day),
  ];

  stdout.writeln('nepdate ${Platform.version.split(' ').first} on ${Platform.operatingSystem}');
  stdout.writeln('64 inputs, ns per operation, lower is better');

  final b1 = _Bench('B1 BS to AD', () {
    for (var i = 0; i < _count; i++) {
      final date = dates[i];
      final ad = NepaliDate.fromBs(date.year, date.month, date.day).toDateTime();
      sink += ad.year;
    }
  });
  stdout.writeln('B1 ${_nsPerOp(b1, _count).toStringAsFixed(2)}');

  final b2 = _Bench('B2 AD to BS', () {
    for (var i = 0; i < _count; i++) {
      final (year, month, day) = adFields[i];
      sink += NepaliDate.fromGregorian(DateTime.utc(year, month, day)).day;
    }
  });
  stdout.writeln('B2 ${_nsPerOp(b2, _count).toStringAsFixed(2)}');

  final b3 = _Bench('B3 add 1000 days', () {
    for (var i = 0; i < _count; i++) {
      sink += dates[i].addDays(1000).month;
    }
  });
  stdout.writeln('B3 ${_nsPerOp(b3, _count).toStringAsFixed(2)}');

  final b4 = _Bench('B4 add 13 months clamp', () {
    for (var i = 0; i < _count; i++) {
      sink += dates[i].addMonths(13).day;
    }
  });
  stdout.writeln('B4 ${_nsPerOp(b4, _count).toStringAsFixed(2)}');

  final b5 = _Bench('B5 long Nepali with weekday', () {
    for (var i = 0; i < _count; i++) {
      sink += dates[i].toLongString(weekday: true, lang: Lang.ne).length;
    }
  });
  stdout.writeln('B5 ${_nsPerOp(b5, _count).toStringAsFixed(2)}');

  final b6 = _Bench('B6 strict parse', () {
    for (var i = 0; i < _count; i++) {
      sink += NepaliDate.parse(texts[i]).day;
    }
  });
  stdout.writeln('B6 ${_nsPerOp(b6, _count).toStringAsFixed(2)}');

  final b7 = _Bench('B7 patro info', () {
    for (var i = 0; i < _count; i++) {
      final day = info(patroDates[i]);
      sink += (day.tithi?.english.length ?? 0) + (day.isPublicHoliday ? 1 : 0) + day.events.length;
    }
  });
  stdout.writeln('B7 ${_nsPerOp(b7, _count).toStringAsFixed(2)}');

  final b8 = _Bench('B8 patro month grid', () {
    for (var i = 0; i < _count; i++) {
      final date = patroDates[i];
      for (var day = 1; day <= date.monthLength; day++) {
        final infoDay = info(NepaliDate.fromBs(date.year, date.month, day));
        sink += (infoDay.tithi?.english.length ?? 0) + infoDay.events.length;
      }
    }
  });
  stdout.writeln('B8 ${_nsPerOp(b8, _count).toStringAsFixed(2)}');

  final competitorB1 = _Bench('nepali_utils B1 BS to AD', () {
    for (var i = 0; i < _count; i++) {
      final date = dates[i];
      final ad = competitor.NepaliDateTime(date.year, date.month, date.day).toDateTime();
      sink += ad.year;
    }
  });
  stdout.writeln('nepali_utils B1 ${_nsPerOp(competitorB1, _count).toStringAsFixed(2)}');

  final competitorB2 = _Bench('nepali_utils B2 AD to BS', () {
    for (var i = 0; i < _count; i++) {
      final (year, month, day) = adFields[i];
      sink += DateTime.utc(year, month, day).toNepaliDateTime().day;
    }
  });
  stdout.writeln('nepali_utils B2 ${_nsPerOp(competitorB2, _count).toStringAsFixed(2)}');

  stdout.writeln('sink $sink');
}
