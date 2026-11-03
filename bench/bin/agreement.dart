// Whether the selected competitor agrees with shared/data on the 64 benchmark dates. Run from the
// repository root:
//
//   dart run bench/bin/agreement.dart
//
// The count is the "agrees" column of docs/benchmarks.md. A fast wrong answer is listed, never
// ranked first (shared/spec/BENCHMARK.md section 4).

import 'dart:io';

import 'package:nepali_utils/nepali_utils.dart' as competitor;
import 'package:nepdate/nepdate.dart';

const int _count = 64;

List<NepaliDate> _dates() {
  final first = NepaliDate.fromBs(2000, 1, 1);
  final last = NepaliDate.fromBs(2090, 12, 30);
  final s0 = NepaliDate.min.daysUntil(first);
  final s1 = NepaliDate.min.daysUntil(last);
  return [
    for (var i = 0; i < _count; i++) NepaliDate.min.addDays(s0 + i * ((s1 - s0) ~/ (_count - 1))),
  ];
}

void main() {
  var bsToAd = 0;
  var adToBs = 0;
  for (final date in _dates()) {
    final ad = date.toDateTime();
    final competitorAd = competitor.NepaliDateTime(date.year, date.month, date.day).toDateTime();
    if (competitorAd.year == ad.year &&
        competitorAd.month == ad.month &&
        competitorAd.day == ad.day) {
      bsToAd++;
    }
    final competitorBs = DateTime.utc(ad.year, ad.month, ad.day).toNepaliDateTime();
    if (competitorBs.year == date.year &&
        competitorBs.month == date.month &&
        competitorBs.day == date.day) {
      adToBs++;
    }
  }
  stdout.writeln('nepali_utils agrees on B1: $bsToAd/$_count');
  stdout.writeln('nepali_utils agrees on B2: $adToBs/$_count');
}
