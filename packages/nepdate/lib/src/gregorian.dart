part of '../nepdate.dart';

/// Days since 1970-01-01 of a proleptic Gregorian date (ALGORITHM section 5, Howard Hinnant).
/// The caller has checked that [year] is 1844 or later, so every intermediate value is positive.
int _daysFromCivil(int year, int month, int day) {
  final y = month <= 2 ? year - 1 : year;
  final era = y ~/ 400;
  final yoe = y - era * 400;
  final mp = (month + 9) % 12;
  final doy = (153 * mp + 2) ~/ 5 + day - 1;
  final doe = yoe * 365 + yoe ~/ 4 - yoe ~/ 100 + doy;
  return era * 146097 + doe - 719468;
}
