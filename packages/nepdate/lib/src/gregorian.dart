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

/// The Gregorian (year, month, day) of a count of days since 1970-01-01 (ALGORITHM section 5).
(int, int, int) _civilFromDays(int days) {
  final z = days + 719468;
  final era = z ~/ 146097;
  final doe = z - era * 146097;
  final yoe = (doe - doe ~/ 1460 + doe ~/ 36524 - doe ~/ 146096) ~/ 365;
  final doy = doe - (365 * yoe + yoe ~/ 4 - yoe ~/ 100);
  final mp = (5 * doy + 2) ~/ 153;
  final day = doy - (153 * mp + 2) ~/ 5 + 1;
  final month = mp < 10 ? mp + 3 : mp - 9;
  return (yoe + era * 400 + (month <= 2 ? 1 : 0), month, day);
}
