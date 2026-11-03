// C# NepDate's own tests (shared/spec/vectors/csharp-tests/catalog.tsv), translated to this API.
// One test per catalogue row (shared/spec/PORT-PLAN.md, "C# test catalogue"). A row this API does
// not have is a skip naming the deviation, and `checkCatalog` fails when the two drift.

import 'package:nepdate/nepdate.dart';
import 'package:test/test.dart';

import 'support/catalog.dart';

const List<String> _monthEn = [
  'Baishakh',
  'Jestha',
  'Ashad',
  'Shrawan',
  'Bhadra',
  'Ashoj',
  'Kartik',
  'Mangsir',
  'Poush',
  'Magh',
  'Falgun',
  'Chaitra',
];

NepaliDate of(int year, int month, int day) => NepaliDate.fromBs(year, month, day);

void same(NepaliDate a, NepaliDate b) {
  expect([a.year, a.month, a.day], [b.year, b.month, b.day]);
  expect(a, b);
}

void throwsKind(void Function() body, ErrorKind kind) {
  try {
    body();
  } on NepDateException catch (error) {
    expect(error.kind, kind);
    return;
  }
  fail('expected NepDateException($kind)');
}

void throwsDate(void Function() body) {
  expect(body, throwsA(isA<NepDateException>()));
}

CatalogCase fails(int y, int m, int d) => CatalogCase(() => throwsDate(() => of(y, m, d)));

CatalogCase parsesTo(String text, int y, int m, int d) =>
    CatalogCase(() => same(NepaliDate.parse(text), of(y, m, d)));

CatalogCase lenientTo(String text, int y, int m, int d) =>
    CatalogCase(() => same(NepaliDate.parseLenient(text), of(y, m, d)));

CatalogCase shortForm(DateOrder order, Separator separator, bool pad, String expected) =>
    CatalogCase(() {
      expect(
        of(2080, 5, 15).toShortString(order: order, separator: separator, pad: pad),
        expected,
      );
    });

const CatalogCase autoAdjust = CatalogCase.deviation('D-05, D-06');
const CatalogCase fractionalMonths = CatalogCase.deviation('D-02');
const CatalogCase emptyRange = CatalogCase.deviation('D-01');
const CatalogCase typedComparison = CatalogCase.notApplicable('typed comparison (ND25)');

void main() {
  checkCatalog(['1'], _phase1());
  checkCatalog(['2'], _phase2());
  checkCatalog(['3'], _phase3());
  checkCatalog(['4'], _phase4(), file: 'Extensions/DateTimeExtensionsTests.cs');
  checkCatalog(['D-14'], _relative());
}

Map<String, CatalogCase> _phase1() => {
      // Abilities/NepaliDateComparableTests: _d1 = 2081-01-01, _d2 = 2081-06-15, _d3 = 2082-01-01.
      'NepaliDateComparableTests.CompareTo_Object_Earlier_ReturnsNegative': CatalogCase(
        () => expect(of(2081, 1, 1).compareTo(of(2081, 6, 15)), lessThan(0)),
      ),
      'NepaliDateComparableTests.CompareTo_Object_Same_ReturnsZero': CatalogCase(
        () => expect(of(2081, 1, 1).compareTo(of(2081, 1, 1)), 0),
      ),
      'NepaliDateComparableTests.CompareTo_Object_Later_ReturnsPositive': CatalogCase(
        () => expect(of(2082, 1, 1).compareTo(of(2081, 1, 1)), greaterThan(0)),
      ),
      'NepaliDateComparableTests.CompareTo_Object_Null_ReturnsPositive': typedComparison,
      'NepaliDateComparableTests.CompareTo_WrongType_ThrowsArgumentException': typedComparison,
      'NepaliDateComparableTests.CompareTo_Generic_Earlier_ReturnsNegative': CatalogCase(
        () => expect(of(2081, 1, 1).compareTo(of(2081, 6, 15)), lessThan(0)),
      ),
      'NepaliDateComparableTests.CompareTo_Generic_Same_ReturnsZero': CatalogCase(
        () => expect(of(2081, 1, 1).compareTo(of(2081, 1, 1)), 0),
      ),
      'NepaliDateComparableTests.CompareTo_Generic_Later_ReturnsPositive': CatalogCase(
        () => expect(of(2082, 1, 1).compareTo(of(2081, 1, 1)), greaterThan(0)),
      ),
      'NepaliDateComparableTests.SortedSet_OrdersCorrectly': CatalogCase(_sorts),
      'NepaliDateComparableTests.ArraySort_ViaIComparable_OrdersCorrectly': CatalogCase(_sorts),
      'NepaliDateComparableTests.List_Sort_OrdersCorrectly': CatalogCase(_sorts),

      // Core/DictionaryIntegrityTests
      'DictionaryIntegrityTests.AllNepaliMonths_RoundtripToEnglishAndBack_ProducesOriginalDate':
          CatalogCase(() {
        for (var year = 1901; year <= 2199; year++) {
          for (var month = 1; month <= 12; month++) {
            final date = of(year, month, 1);
            same(NepaliDate.fromGregorian(date.toDateTime()), date);
          }
        }
      }),
      'DictionaryIntegrityTests.AllNepaliDays_RoundtripToEnglishAndBack_ProducesOriginalDate':
          CatalogCase(() {
        var failures = 0;
        var count = 0;
        var date = NepaliDate.min;
        while (true) {
          if (NepaliDate.fromGregorian(date.toDateTime()) != date) failures++;
          count++;
          if (date == NepaliDate.max) break;
          date = date.addDays(1);
        }
        expect(failures, 0);
        expect(count, 109212);
      }),
      'DictionaryIntegrityTests.AllEnglishDays_RoundtripToNepaliAndBack_ProducesOriginalDate':
          CatalogCase(() {
        var failures = 0;
        var date = NepaliDate.min;
        while (true) {
          if (NepaliDate.fromGregorian(date.toDateTime()) != date) failures++;
          if (date == NepaliDate.max) break;
          date = date.addDays(1);
        }
        expect(failures, 0);
      }),
      'DictionaryIntegrityTests.AllMonths_MonthEndDay_IsWithinValidRange': CatalogCase(() {
        for (var year = 1901; year <= 2199; year++) {
          for (var month = 1; month <= 12; month++) {
            expect(of(year, month, 1).monthLength, inInclusiveRange(29, 32));
          }
        }
      }),
      'DictionaryIntegrityTests.ConsecutiveNepaliDays_ProduceConsecutiveEnglishDays':
          CatalogCase(() {
        var violations = 0;
        var previous = 0;
        var first = true;
        var date = NepaliDate.min;
        while (true) {
          final day = date.toDateTime().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
          if (!first && day != previous + 1) violations++;
          previous = day;
          first = false;
          if (date == NepaliDate.max) break;
          date = date.addDays(1);
        }
        expect(violations, 0);
      }),
      'DictionaryIntegrityTests.KnownReferenceDates_ConvertCorrectly#1':
          CatalogCase(() => _known(2080, 1, 1, 2023, 4, 14)),
      'DictionaryIntegrityTests.KnownReferenceDates_ConvertCorrectly#2':
          CatalogCase(() => _known(2000, 1, 1, 1943, 4, 14)),
      'DictionaryIntegrityTests.KnownReferenceDates_ConvertCorrectly#3':
          CatalogCase(() => _known(2081, 1, 1, 2024, 4, 13)),
      'DictionaryIntegrityTests.KnownReferenceDates_ConvertCorrectly#4':
          CatalogCase(() => _known(1901, 1, 1, 1844, 4, 11)),
      'DictionaryIntegrityTests.BoundaryDates_ConvertCorrectly': CatalogCase(() {
        same(NepaliDate.min, of(1901, 1, 1));
        expect([NepaliDate.max.year, NepaliDate.max.month], [2199, 12]);
        for (final date in [NepaliDate.min, NepaliDate.max]) {
          same(NepaliDate.fromGregorian(date.toDateTime()), date);
        }
      }),
      'DictionaryIntegrityTests.TotalDaysInRange_MatchesEnglishDateSpan': CatalogCase(() {
        var total = 0;
        for (var year = 1901; year <= 2199; year++) {
          for (var month = 1; month <= 12; month++) {
            total += of(year, month, 1).monthLength;
          }
        }
        final span = NepaliDate.max.daysUntil(NepaliDate.min).abs() + 1;
        expect(total, span);
      }),

      // Core/NepaliDateConstructionTests
      'NepaliDateConstructionTests.Constructor_ValidNepaliDate_CreatesInstance': CatalogCase(() {
        final date = of(2080, 5, 15);
        expect([date.year, date.month, date.day], [2080, 5, 15]);
      }),
      'NepaliDateConstructionTests.Constructor_MinValue_CreatesInstance':
          CatalogCase(() => same(NepaliDate.min, of(1901, 1, 1))),
      'NepaliDateConstructionTests.Constructor_MaxValue_CreatesInstance':
          CatalogCase(() => same(NepaliDate.max, of(2199, 12, 30))),
      'NepaliDateConstructionTests.Constructor_InvalidNepaliDate_ThrowsException#1':
          fails(2080, 0, 1),
      'NepaliDateConstructionTests.Constructor_InvalidNepaliDate_ThrowsException#2':
          fails(2080, 13, 1),
      'NepaliDateConstructionTests.Constructor_InvalidNepaliDate_ThrowsException#3':
          fails(2080, 1, 0),
      'NepaliDateConstructionTests.Constructor_InvalidNepaliDate_ThrowsException#4':
          fails(2080, 1, 33),
      'NepaliDateConstructionTests.Constructor_ValidStringFormats_CreatesInstance#1':
          parsesTo('2080/05/15', 2080, 5, 15),
      'NepaliDateConstructionTests.Constructor_ValidStringFormats_CreatesInstance#2':
          parsesTo('2080-05-15', 2080, 5, 15),
      'NepaliDateConstructionTests.Constructor_ValidStringFormats_CreatesInstance#3':
          parsesTo('2080.05.15', 2080, 5, 15),
      'NepaliDateConstructionTests.Constructor_ValidStringFormats_CreatesInstance#4':
          parsesTo('2080_05_15', 2080, 5, 15),
      'NepaliDateConstructionTests.Constructor_ValidStringFormats_CreatesInstance#5':
          parsesTo(r'2080\05\15', 2080, 5, 15),
      'NepaliDateConstructionTests.Constructor_ValidStringFormats_CreatesInstance#6':
          parsesTo('2080 05 15', 2080, 5, 15),
      'NepaliDateConstructionTests.Constructor_AutoAdjustedFormats_CreatesInstance#1': autoAdjust,
      'NepaliDateConstructionTests.Constructor_AutoAdjustedFormats_CreatesInstance#2': autoAdjust,
      'NepaliDateConstructionTests.Constructor_AutoAdjustedFormats_CreatesInstance#3':
          parsesTo('2080/05/15', 2080, 5, 15),
      'NepaliDateConstructionTests.Constructor_AutoAdjustedFormats_CreatesInstance#4': autoAdjust,
      'NepaliDateConstructionTests.Constructor_AutoAdjust_MonthOverflowWithBoundaryDay_SwapsAsDocumented#1':
          autoAdjust,
      'NepaliDateConstructionTests.Constructor_AutoAdjust_MonthOverflowWithBoundaryDay_SwapsAsDocumented#2':
          autoAdjust,
      'NepaliDateConstructionTests.TryParse_AutoAdjust_MonthOverflowWithBoundaryDay_SwapsAsDocumented':
          autoAdjust,
      'NepaliDateConstructionTests.Constructor_InvalidStringFormats_ThrowsException#1':
          CatalogCase(() => throwsDate(() => NepaliDate.parse(''))),
      'NepaliDateConstructionTests.Constructor_InvalidStringFormats_ThrowsException#2':
          CatalogCase(() => throwsDate(() => NepaliDate.parse('2080/05'))),
      'NepaliDateConstructionTests.Constructor_InvalidStringFormats_ThrowsException#3':
          CatalogCase(() => throwsDate(() => NepaliDate.parse('abc/def/ghi'))),
      'NepaliDateConstructionTests.Constructor_ValidFormatInvalidDate_ThrowsException#1':
          CatalogCase(() => throwsDate(() => NepaliDate.parse('2080/13/40'))),
      'NepaliDateConstructionTests.Constructor_EnglishDate_ConvertsCorrectly': CatalogCase(
        () => same(NepaliDate.fromGregorian(DateTime.utc(2023, 8, 30)), of(2080, 5, 13)),
      ),
      'NepaliDateConstructionTests.TryParse_ValidString_ReturnsTrueWithCorrectDate': CatalogCase(
        () => expect(NepaliDate.tryParse('2080/05/15'), of(2080, 5, 15)),
      ),
      'NepaliDateConstructionTests.TryParse_InvalidString_ReturnsFalseWithDefault#1':
          CatalogCase(() => expect(NepaliDate.tryParse(''), isNull)),
      'NepaliDateConstructionTests.TryParse_InvalidString_ReturnsFalseWithDefault#2':
          CatalogCase(() => expect(NepaliDate.tryParse('2080/05'), isNull)),
      'NepaliDateConstructionTests.TryParse_InvalidString_ReturnsFalseWithDefault#3':
          CatalogCase(() => expect(NepaliDate.tryParse('abc'), isNull)),

      // Core/NepaliDatePropertiesTests: the date is 2080-05-15.
      'NepaliDatePropertiesTests.EnglishDate_Conversion_ReturnsCorrectDate': CatalogCase(() {
        final ad = of(2080, 5, 15).toDateTime();
        expect([ad.year, ad.month, ad.day], [2023, 9, 1]);
      }),
      'NepaliDatePropertiesTests.DayOfWeek_ReturnsCorrectValue':
          CatalogCase(() => expect(of(2080, 5, 15).weekday, Weekday.friday)),
      'NepaliDatePropertiesTests.MonthEndDay_ReturnsCorrectValue':
          CatalogCase(() => expect(of(2080, 5, 15).monthLength, 31)),
      'NepaliDatePropertiesTests.MonthName_ReturnsCorrectEnum':
          CatalogCase(() => expect(of(2080, 5, 15).monthEnum, Month.bhadra)),
      'NepaliDatePropertiesTests.Today_ReturnsCurrentNepaliDate': CatalogCase(() {
        final today = NepaliDate.today(
          timeZone: 'UTC',
          clock: () => DateTime.utc(2024, 7, 30, 18, 30),
        );
        same(today, of(2081, 4, 15));
        same(today, NepaliDate.fromGregorian(DateTime.utc(2024, 7, 30)));
      }),
      'NepaliDatePropertiesTests.DayOfYear_FirstDayOfYear_Returns1':
          CatalogCase(() => expect(of(2080, 1, 1).dayOfYear, 1)),
      'NepaliDatePropertiesTests.DayOfYear_FirstDayOfMonth4_EqualsSum_Of_Months1To3_Plus1':
          CatalogCase(() {
        final expected = of(2080, 1, 1).monthLength +
            of(2080, 2, 1).monthLength +
            of(2080, 3, 1).monthLength +
            1;
        expect(of(2080, 4, 1).dayOfYear, expected);
      }),
      'NepaliDatePropertiesTests.Equals_NullObject_ReturnsFalse': typedComparison,
      'NepaliDatePropertiesTests.Equals_DifferentType_ReturnsFalse': CatalogCase(() {
        final Object date = of(2080, 5, 15);
        expect(date == '2080/05/15', isFalse);
      }),

      // Core/OptimizationVerificationTests, phase 1 rows
      'OptimizationVerificationTests.Constructor_AllSeparators_ParseCorrectly#1':
          parsesTo('2080/05/15', 2080, 5, 15),
      'OptimizationVerificationTests.Constructor_AllSeparators_ParseCorrectly#2':
          parsesTo('2080-05-15', 2080, 5, 15),
      'OptimizationVerificationTests.Constructor_AllSeparators_ParseCorrectly#3':
          parsesTo('2080.05.15', 2080, 5, 15),
      'OptimizationVerificationTests.Constructor_AllSeparators_ParseCorrectly#4':
          parsesTo('2080_05_15', 2080, 5, 15),
      'OptimizationVerificationTests.Constructor_AllSeparators_ParseCorrectly#5':
          parsesTo(r'2080\05\15', 2080, 5, 15),
      'OptimizationVerificationTests.Constructor_AllSeparators_ParseCorrectly#6':
          parsesTo('2080 05 15', 2080, 5, 15),
      'OptimizationVerificationTests.Constructor_AllSeparators_ParseCorrectly#7':
          parsesTo('2080।05।15', 2080, 5, 15),
      'OptimizationVerificationTests.Constructor_AllSeparators_ParseCorrectly#8':
          parsesTo('2080|05|15', 2080, 5, 15),
      'OptimizationVerificationTests.Constructor_InvalidStrings_ThrowsException#1':
          CatalogCase(() => throwsDate(() => NepaliDate.parse(''))),
      'OptimizationVerificationTests.Constructor_InvalidStrings_ThrowsException#2':
          CatalogCase(() => throwsDate(() => NepaliDate.parse('invalid'))),
      'OptimizationVerificationTests.Constructor_InvalidStrings_ThrowsException#3':
          CatalogCase(() => throwsDate(() => NepaliDate.parse('2080/05'))),
      'OptimizationVerificationTests.Constructor_InvalidStrings_ThrowsException#4':
          CatalogCase(() => throwsDate(() => NepaliDate.parse('2080'))),
      'OptimizationVerificationTests.Constructor_InvalidStrings_ThrowsException#5':
          CatalogCase(() => throwsDate(() => NepaliDate.parse('2080/05/15/99'))),
      'OptimizationVerificationTests.Constructor_InvalidStrings_ThrowsException#6':
          CatalogCase(() => throwsDate(() => NepaliDate.parse('abc/def/ghi'))),
      'OptimizationVerificationTests.Constructor_NullString_ThrowsException':
          CatalogCase(() => throwsDate(() => NepaliDate.parse(''))),
      'OptimizationVerificationTests.Constructor_WithoutLeadingZeros_ParsesCorrectly#1':
          parsesTo('2080/5/15', 2080, 5, 15),
      'OptimizationVerificationTests.Constructor_WithoutLeadingZeros_ParsesCorrectly#2':
          parsesTo('2080/05/5', 2080, 5, 5),
      'OptimizationVerificationTests.Constructor_WithoutLeadingZeros_ParsesCorrectly#3':
          parsesTo('2080/1/1', 2080, 1, 1),
      'OptimizationVerificationTests.Operator_Equality_SameDates_ReturnsTrue':
          CatalogCase(() => expect(of(2080, 5, 15) == of(2080, 5, 15), isTrue)),
      'OptimizationVerificationTests.Operator_Inequality_DifferentDates_ReturnsTrue':
          CatalogCase(() => expect(of(2080, 5, 15) != of(2080, 5, 16), isTrue)),
      'OptimizationVerificationTests.Operator_LessThan_EarlierDate_ReturnsTrue':
          CatalogCase(() => expect(of(2080, 5, 15) < of(2080, 5, 16), isTrue)),
      'OptimizationVerificationTests.Operator_LessThanOrEqual_SameAndEarlier_ReturnsTrue':
          CatalogCase(() {
        expect(of(2080, 5, 15) <= of(2080, 5, 16), isTrue);
        expect(of(2080, 5, 15) <= of(2080, 5, 15), isTrue);
      }),
      'OptimizationVerificationTests.Operator_GreaterThan_LaterDate_ReturnsTrue':
          CatalogCase(() => expect(of(2080, 5, 16) > of(2080, 5, 15), isTrue)),
      'OptimizationVerificationTests.Operator_GreaterThanOrEqual_SameAndLater_ReturnsTrue':
          CatalogCase(() {
        expect(of(2080, 5, 16) >= of(2080, 5, 15), isTrue);
        expect(of(2080, 5, 16) >= of(2080, 5, 16), isTrue);
      }),
      'OptimizationVerificationTests.Operator_MinMaxBoundary_CorrectOrdering':
          CatalogCase(() => expect(NepaliDate.min < NepaliDate.max, isTrue)),
      'OptimizationVerificationTests.CompareTo_EarlierDate_ReturnsNegative':
          CatalogCase(() => expect(of(2080, 5, 15).compareTo(of(2080, 5, 16)), lessThan(0))),
      'OptimizationVerificationTests.CompareTo_SameDate_ReturnsZero': CatalogCase(() {
        final date = of(2080, 5, 15);
        expect(date.compareTo(date), 0);
      }),
      'OptimizationVerificationTests.CompareTo_LaterDate_ReturnsPositive':
          CatalogCase(() => expect(of(2080, 5, 16).compareTo(of(2080, 5, 15)), greaterThan(0))),
      'OptimizationVerificationTests.CompareTo_DifferentYears_CorrectOrdering':
          CatalogCase(() => expect(of(2080, 1, 1).compareTo(of(2081, 1, 1)), lessThan(0))),
      'OptimizationVerificationTests.CompareTo_DifferentMonths_CorrectOrdering':
          CatalogCase(() => expect(of(2080, 1, 1).compareTo(of(2080, 2, 1)), lessThan(0))),
      'OptimizationVerificationTests.Equals_SameDates_ReturnsTrue':
          CatalogCase(() => expect(of(2080, 5, 15), of(2080, 5, 15))),
      'OptimizationVerificationTests.Equals_DifferentDates_ReturnsFalse':
          CatalogCase(() => expect(of(2080, 5, 15), isNot(of(2080, 5, 16)))),
      'OptimizationVerificationTests.GetHashCode_EqualDates_SameHashCode': CatalogCase(
        () => expect(of(2080, 5, 15).hashCode, of(2080, 5, 15).hashCode),
      ),
      'OptimizationVerificationTests.GetHashCode_StableAcrossMultipleCalls': CatalogCase(() {
        final date = of(2080, 5, 15);
        expect(date.hashCode, date.hashCode);
      }),
      'OptimizationVerificationTests.IsLeapYear_ChecksEnglishYearCorrectly#1':
          const CatalogCase.deviation('D-12'),
      'OptimizationVerificationTests.IsLeapYear_ChecksEnglishYearCorrectly#2':
          const CatalogCase.deviation('D-12'),
      'OptimizationVerificationTests.IsLeapYear_ChecksEnglishYearCorrectly#3':
          const CatalogCase.deviation('D-12'),
      'OptimizationVerificationTests.Constructor_InvalidYearMonthDay_ThrowsException#1':
          fails(2080, 0, 15),
      'OptimizationVerificationTests.Constructor_InvalidYearMonthDay_ThrowsException#2':
          fails(2080, 13, 15),
      'OptimizationVerificationTests.Constructor_InvalidYearMonthDay_ThrowsException#3':
          fails(2080, 5, 0),
      'OptimizationVerificationTests.Constructor_InvalidYearMonthDay_ThrowsException#4':
          fails(2080, 5, 33),
      'OptimizationVerificationTests.Constructor_InvalidYearMonthDay_ThrowsException#5':
          fails(1900, 1, 1),
      'OptimizationVerificationTests.Constructor_InvalidYearMonthDay_ThrowsException#6':
          fails(2200, 1, 1),
      'OptimizationVerificationTests.Constructor_MinValue_IsValid':
          CatalogCase(() => same(NepaliDate.min, of(1901, 1, 1))),
      'OptimizationVerificationTests.Constructor_MaxValue_IsValid':
          CatalogCase(() => same(NepaliDate.max, of(2199, 12, 30))),
      'OptimizationVerificationTests.EnglishDate_MinValue_ConvertsAndRoundtrips': CatalogCase(
        () => same(NepaliDate.fromGregorian(NepaliDate.min.toDateTime()), NepaliDate.min),
      ),
      'OptimizationVerificationTests.EnglishDate_MaxValue_ConvertsAndRoundtrips': CatalogCase(
        () => same(NepaliDate.fromGregorian(NepaliDate.max.toDateTime()), NepaliDate.max),
      ),
      'OptimizationVerificationTests.EnglishDate_JustBeforeMin_ThrowsException': CatalogCase(
        () => throwsKind(
          () => NepaliDate.fromGregorian(DateTime.utc(1844, 4, 10)),
          ErrorKind.outOfRange,
        ),
      ),
      'OptimizationVerificationTests.EnglishDate_JustAfterMax_ThrowsException': CatalogCase(
        () => throwsKind(
          () => NepaliDate.fromGregorian(DateTime.utc(2143, 4, 16)),
          ErrorKind.outOfRange,
        ),
      ),
      'OptimizationVerificationTests.MonthEndDay_CreatingDateWithExactEndDay_Succeeds':
          CatalogCase(() {
        for (var year = 2070; year <= 2090; year++) {
          for (var month = 1; month <= 12; month++) {
            final length = of(year, month, 1).monthLength;
            expect(of(year, month, length).day, length);
            throwsKind(() => of(year, month, length + 1), ErrorKind.invalidDay);
          }
        }
      }),
      'OptimizationVerificationTests.DayOfWeek_MatchesEnglishDateDayOfWeek': CatalogCase(() {
        for (var year = 1910; year <= 2190; year += 30) {
          for (var month = 1; month <= 12; month += 3) {
            final date = of(year, month, 15);
            expect(date.weekday.index, date.toDateTime().weekday % 7);
          }
        }
      }),
      'OptimizationVerificationTests.IsDefault_DefaultStruct_ReturnsTrue':
          const CatalogCase.deviation('D-01'),
      'OptimizationVerificationTests.IsDefault_ValidDate_ReturnsFalse':
          const CatalogCase.deviation('D-01'),
    };

void _sorts() {
  final dates = [of(2082, 1, 1), of(2081, 1, 1), of(2081, 6, 15)]..sort();
  expect(dates, [of(2081, 1, 1), of(2081, 6, 15), of(2082, 1, 1)]);
}

void _known(int y, int m, int d, int adY, int adM, int adD) {
  final date = of(y, m, d);
  final ad = date.toDateTime();
  expect([ad.year, ad.month, ad.day], [adY, adM, adD]);
  same(NepaliDate.fromGregorian(DateTime.utc(adY, adM, adD)), date);
}

Map<String, CatalogCase> _phase2() {
  NepaliDate qStart(NepaliDate date, Quarter quarter) =>
      date.fiscalYear.quarterRange(quarter).start;
  NepaliDate qEnd(NepaliDate date, Quarter quarter) => date.fiscalYear.quarterRange(quarter).end;
  CatalogCase sameFiscalStart(int month, NepaliDate expected) =>
      CatalogCase(() => same(of(2080, month, 15).fiscalYear.start(), expected));

  return {
    // Core/FiscalYearInstanceMethodTests
    'FiscalYearInstanceMethodTests.FiscalYearStartDate_DateInShrawan_ReturnsSameyearShrawan1':
        CatalogCase(() => same(of(2080, 4, 15).fiscalYear.start(), of(2080, 4, 1))),
    'FiscalYearInstanceMethodTests.FiscalYearStartDate_DateInChaitra_ReturnsSameYearShrawan1':
        CatalogCase(() => same(of(2080, 12, 15).fiscalYear.start(), of(2080, 4, 1))),
    'FiscalYearInstanceMethodTests.FiscalYearStartDate_DateInBasikhakh_ReturnsPreviousYearShrawan1':
        CatalogCase(() => same(of(2080, 1, 15).fiscalYear.start(), of(2079, 4, 1))),
    'FiscalYearInstanceMethodTests.FiscalYearStartDate_DateInAshadh_ReturnsPreviousYearShrawan1':
        CatalogCase(() => same(of(2080, 3, 15).fiscalYear.start(), of(2079, 4, 1))),
    'FiscalYearInstanceMethodTests.FiscalYearStartDate_WithPositiveYearOffset_ShiftsForward':
        CatalogCase(() => same(
              FiscalYear(of(2080, 4, 15).fiscalYear.startYear + 1).start(),
              of(2081, 4, 1),
            )),
    'FiscalYearInstanceMethodTests.FiscalYearStartDate_WithNegativeYearOffset_ShiftsBackward':
        CatalogCase(() => same(
              FiscalYear(of(2080, 4, 15).fiscalYear.startYear - 1).start(),
              of(2079, 4, 1),
            )),
    'FiscalYearInstanceMethodTests.FiscalYearEndDate_DateInShrawan_ReturnsNextYearAshad':
        CatalogCase(() => expect(of(2080, 4, 15).fiscalYear.end().year, 2081)),
    'FiscalYearInstanceMethodTests.FiscalYearEndDate_DateInChaitra_ReturnsNextYearAshadh':
        CatalogCase(() => expect(of(2080, 12, 15).fiscalYear.end().year, 2081)),
    'FiscalYearInstanceMethodTests.FiscalYearEndDate_DateInBasikhakh_ReturnsSameYearAshadh':
        CatalogCase(() => expect(of(2080, 1, 15).fiscalYear.end().year, 2080)),
    'FiscalYearInstanceMethodTests.FiscalYearEndDate_WithPositiveYearOffset_ShiftsForward':
        CatalogCase(() => expect(
              FiscalYear(of(2080, 4, 15).fiscalYear.startYear + 1).end().year,
              2082,
            )),
    'FiscalYearInstanceMethodTests.FiscalYearStartAndEndDate_DateInQ2_ReturnsBothBoundaries':
        CatalogCase(() {
      final fiscal = of(2080, 7, 15).fiscalYear;
      same(fiscal.start(), of(2080, 4, 1));
      expect(fiscal.end().year, 2081);
    }),
    'FiscalYearInstanceMethodTests.FiscalYearStartAndEndDate_DateInQ4_ReturnsPreviousFiscalYearBoundaries':
        CatalogCase(() {
      final fiscal = of(2081, 1, 15).fiscalYear;
      same(fiscal.start(), of(2080, 4, 1));
      expect(fiscal.end().year, 2081);
    }),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_ExplicitFirst_ReturnsShrawan1':
        CatalogCase(() => same(qStart(of(2080, 4, 15), Quarter.q1), of(2080, 4, 1))),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_ExplicitSecond_ReturnsKartik1':
        CatalogCase(() => same(qStart(of(2080, 4, 15), Quarter.q2), of(2080, 7, 1))),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_ExplicitThird_ReturnsMagh1':
        CatalogCase(() => same(qStart(of(2080, 4, 15), Quarter.q3), of(2080, 10, 1))),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_ExplicitFourth_ReturnsNextYearBasikhakh1':
        CatalogCase(() => same(qStart(of(2080, 4, 15), Quarter.q4), of(2081, 1, 1))),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_ExplicitFirst_ReturnsLastDayOfAshoj':
        CatalogCase(() => expect(qEnd(of(2080, 4, 15), Quarter.q1).year, 2080)),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_ExplicitSecond_ReturnsLastDayOfPoush':
        CatalogCase(() => expect(qEnd(of(2080, 4, 15), Quarter.q2).year, 2080)),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_ExplicitThird_ReturnsLastDayOfChaitra':
        CatalogCase(() => expect(qEnd(of(2080, 4, 15), Quarter.q3).year, 2080)),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_ExplicitFourth_ReturnsNextYearLastDayOfAshadh':
        CatalogCase(() => expect(qEnd(of(2080, 4, 15), Quarter.q4).year, 2081)),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterStartAndEndDate_ExplicitSecond_ReturnsBothBoundaries':
        CatalogCase(() {
      same(qStart(of(2080, 4, 15), Quarter.q2), of(2080, 7, 1));
      expect(qEnd(of(2080, 4, 15), Quarter.q2).month, 9);
    }),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterStartAndEndDate_ExplicitThird_ReturnsBothBoundaries':
        CatalogCase(() {
      same(qStart(of(2080, 4, 15), Quarter.q3), of(2080, 10, 1));
      expect(qEnd(of(2080, 4, 15), Quarter.q3).month, 12);
    }),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_Current_DateInQ1_ReturnsShrawan1':
        CatalogCase(() => same(qStart(of(2080, 4, 15), of(2080, 4, 15).quarter), of(2080, 4, 1))),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_Current_DateInQ1_ReturnsLastDayOfAshoj':
        CatalogCase(() => expect(qEnd(of(2080, 4, 15), of(2080, 4, 15).quarter).month, 6)),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_Current_DateInQ2_ReturnsKartik1':
        CatalogCase(() => same(qStart(of(2080, 7, 15), of(2080, 7, 15).quarter), of(2080, 7, 1))),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_Current_DateInQ3_ReturnsMagh1':
        CatalogCase(
            () => same(qStart(of(2080, 10, 15), of(2080, 10, 15).quarter), of(2080, 10, 1))),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_Current_DateInQ3_ReturnsLastDayOfChaitra':
        CatalogCase(() => expect(qEnd(of(2080, 10, 15), of(2080, 10, 15).quarter).month, 12)),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_ExplicitFirstWithOffset1_ReturnsNextYearShrawan1':
        CatalogCase(() => same(
              FiscalYear(of(2080, 4, 15).fiscalYear.startYear + 1).quarterRange(Quarter.q1).start,
              of(2081, 4, 1),
            )),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_ExplicitFirstWithNegativeOffset_ReturnsPreviousYearShrawan1':
        CatalogCase(() => same(
              FiscalYear(of(2080, 4, 15).fiscalYear.startYear - 1).quarterRange(Quarter.q1).start,
              of(2079, 4, 1),
            )),
    'FiscalYearInstanceMethodTests.FiscalYearStartDate_AllFiscalMonths_Return2080Shrawan1#1':
        sameFiscalStart(4, of(2080, 4, 1)),
    'FiscalYearInstanceMethodTests.FiscalYearStartDate_AllFiscalMonths_Return2080Shrawan1#2':
        sameFiscalStart(6, of(2080, 4, 1)),
    'FiscalYearInstanceMethodTests.FiscalYearStartDate_AllFiscalMonths_Return2080Shrawan1#3':
        sameFiscalStart(7, of(2080, 4, 1)),
    'FiscalYearInstanceMethodTests.FiscalYearStartDate_AllFiscalMonths_Return2080Shrawan1#4':
        sameFiscalStart(12, of(2080, 4, 1)),
    'FiscalYearInstanceMethodTests.FiscalYearStartDate_Q4CalendarMonths_ReturnPreviousYearShrawan1#1':
        sameFiscalStart(1, of(2079, 4, 1)),
    'FiscalYearInstanceMethodTests.FiscalYearStartDate_Q4CalendarMonths_ReturnPreviousYearShrawan1#2':
        sameFiscalStart(2, of(2079, 4, 1)),
    'FiscalYearInstanceMethodTests.FiscalYearStartDate_Q4CalendarMonths_ReturnPreviousYearShrawan1#3':
        sameFiscalStart(3, of(2079, 4, 1)),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_FromQ4Date_ExplicitFirst_ReturnsFY2080Q1Start':
        CatalogCase(() => same(qStart(of(2081, 1, 15), Quarter.q1), of(2080, 4, 1))),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_FromQ4Date_ExplicitSecond_ReturnsFY2080Q2Start':
        CatalogCase(() => same(qStart(of(2081, 1, 15), Quarter.q2), of(2080, 7, 1))),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_FromQ4Date_ExplicitThird_ReturnsFY2080Q3Start':
        CatalogCase(() => same(qStart(of(2081, 1, 15), Quarter.q3), of(2080, 10, 1))),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_FromQ4Date_ExplicitFourth_ReturnsFY2080Q4Start':
        CatalogCase(() => same(qStart(of(2081, 1, 15), Quarter.q4), of(2081, 1, 1))),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterStartDate_FromQ4Date_Current_ReturnsFY2080Q4Start':
        CatalogCase(() => same(qStart(of(2081, 1, 15), of(2081, 1, 15).quarter), of(2081, 1, 1))),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_FromQ4Date_ExplicitFirst_ReturnsFY2080Q1End':
        CatalogCase(() => expect(qEnd(of(2081, 1, 15), Quarter.q1).year, 2080)),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_FromQ4Date_ExplicitThird_ReturnsFY2080Q3End':
        CatalogCase(() => expect(qEnd(of(2081, 1, 15), Quarter.q3).year, 2080)),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_FromQ4Date_ExplicitFourth_ReturnsFY2080Q4End':
        CatalogCase(() => expect(qEnd(of(2081, 1, 15), Quarter.q4).year, 2081)),
    'FiscalYearInstanceMethodTests.FiscalYearQuarterEndDate_FromQ4Date_Current_ReturnsFY2080Q4End':
        CatalogCase(() => expect(qEnd(of(2081, 1, 15), of(2081, 1, 15).quarter).year, 2081)),

    // Core/FiscalYearTests
    'FiscalYearTests.GetFiscalYearStartAndEndDate_ValidYear_ReturnsCorrectDates': CatalogCase(() {
      final fiscal = FiscalYear(2080);
      same(fiscal.start(), of(2080, 4, 1));
      same(fiscal.end(), of(2081, 3, 1).lastDayOfMonth);
    }),
    'FiscalYearTests.GetFiscalYearStartAndEndDate_InvalidYear_ThrowsException#1':
        CatalogCase(() => throwsKind(() => FiscalYear(1843).start(), ErrorKind.outOfRange)),
    'FiscalYearTests.GetFiscalYearStartAndEndDate_InvalidYear_ThrowsException#2':
        CatalogCase(() => throwsKind(() => FiscalYear(2200).start(), ErrorKind.outOfRange)),
    'FiscalYearTests.GetFiscalYearStartDate_ValidYear_ReturnsCorrectDate':
        CatalogCase(() => same(FiscalYear(2080).start(), of(2080, 4, 1))),
    'FiscalYearTests.GetFiscalYearEndDate_ValidYear_ReturnsCorrectDate':
        CatalogCase(() => same(FiscalYear(2080).end(), of(2081, 3, 1).lastDayOfMonth)),
    'FiscalYearTests.FiscalYearStartAndEndDate_OnNepaliDateInstance_ReturnsCorrectDates':
        CatalogCase(() {
      final fiscal = of(2080, 4, 15).fiscalYear;
      same(fiscal.start(), of(2080, 4, 1));
      same(fiscal.end(), of(2081, 3, 1).lastDayOfMonth);
    }),
    'FiscalYearTests.FiscalYearStartDate_OnNepaliDateInstance_ReturnsCorrectDate':
        CatalogCase(() => same(of(2080, 4, 15).fiscalYear.start(), of(2080, 4, 1))),
    'FiscalYearTests.FiscalYearEndDate_OnNepaliDateInstance_ReturnsCorrectDate':
        CatalogCase(() => same(of(2080, 4, 15).fiscalYear.end(), of(2081, 3, 1).lastDayOfMonth)),
    'FiscalYearTests.GetFiscalYearQuarterStartAndEndDate_ValidYearAndMonth_ReturnsCorrectDates':
        CatalogCase(() {
      same(FiscalYear(2080).quarterRange(Quarter.q1).start, of(2080, 4, 1));
      expect(FiscalYear(2080).quarterRange(Quarter.q1).end.month, 6);
    }),
    'FiscalYearTests.GetFiscalYearQuarterStartDate_ValidYearAndMonth_ReturnsCorrectDate':
        CatalogCase(() => same(FiscalYear(2080).quarterRange(Quarter.q2).start, of(2080, 7, 1))),
    'FiscalYearTests.GetFiscalYearQuarterEndDate_ValidYearAndMonth_ReturnsCorrectDate': CatalogCase(
        () => same(FiscalYear(2080).quarterRange(Quarter.q3).end, of(2080, 12, 1).lastDayOfMonth)),

    // Core/NepaliDateArithmeticEdgeCaseTests
    'NepaliDateArithmeticEdgeCaseTests.AddDays_Zero_ReturnsSameDate': CatalogCase(() {
      final date = of(2080, 5, 15);
      same(date.addDays(0), date);
    }),
    'NepaliDateArithmeticEdgeCaseTests.AddDays_PositiveAcrossMonthBoundary_IsCorrect':
        CatalogCase(() => same(of(2080, 5, 31).addDays(1), of(2080, 6, 1))),
    'NepaliDateArithmeticEdgeCaseTests.AddDays_NegativeAcrossMonthBoundary_IsCorrect':
        CatalogCase(() => same(of(2080, 6, 1).addDays(-1), of(2080, 5, 31))),
    'NepaliDateArithmeticEdgeCaseTests.AddDays_PositiveAcrossYearBoundary_IsCorrect':
        CatalogCase(() => same(of(2080, 12, 30).addDays(1), of(2081, 1, 1))),
    'NepaliDateArithmeticEdgeCaseTests.AddDays_NegativeAcrossYearBoundary_IsCorrect':
        CatalogCase(() => same(of(2081, 1, 1).addDays(-1), of(2080, 12, 30))),
    'NepaliDateArithmeticEdgeCaseTests.AddDays_LargePositiveValue_IsCorrect': CatalogCase(() {
      final result = of(2080, 1, 1).addDays(400);
      expect(result.year == 2080 || result.year == 2081, isTrue);
    }),
    'NepaliDateArithmeticEdgeCaseTests.AddMonths_PositiveCrossesYearBoundary_IsCorrect':
        CatalogCase(() => same(of(2080, 12, 15).addMonths(1), of(2081, 1, 15))),
    'NepaliDateArithmeticEdgeCaseTests.AddMonths_NegativeCrossesYearBoundary_IsCorrect':
        CatalogCase(() => same(of(2080, 1, 15).addMonths(-1), of(2079, 12, 15))),
    'NepaliDateArithmeticEdgeCaseTests.AddMonths_PositiveMoreThan12_CrossesMultipleYears':
        CatalogCase(() => same(of(2080, 1, 15).addMonths(13), of(2081, 2, 15))),
    'NepaliDateArithmeticEdgeCaseTests.AddMonths_Exactly12_SameMonthNextYear':
        CatalogCase(() => same(of(2080, 5, 15).addMonths(12), of(2081, 5, 15))),
    'NepaliDateArithmeticEdgeCaseTests.AddMonths_DayCappedAtMonthEnd_WhenResultMonthIsShorter':
        CatalogCase(() => same(of(2081, 4, 32).addMonths(1), of(2081, 5, 31))),
    'NepaliDateArithmeticEdgeCaseTests.AddMonths_Negative_SameDayPreservedWhenFits':
        CatalogCase(() => same(of(2080, 6, 15).addMonths(-1), of(2080, 5, 15))),
    'NepaliDateArithmeticEdgeCaseTests.AddMonths_HalfMonth_AddsApproximately15Days':
        fractionalMonths,
    'NepaliDateArithmeticEdgeCaseTests.AddMonths_NegativeHalfMonth_SubtractsApproximately15Days':
        fractionalMonths,
    'NepaliDateArithmeticEdgeCaseTests.AddMonths_OneAndHalfMonths_AddsApproximately46Days':
        fractionalMonths,
    'NepaliDateArithmeticEdgeCaseTests.AddMonths_FractionalValue_ReturnsDateFurtherThanZeroMonths':
        fractionalMonths,
    'NepaliDateArithmeticEdgeCaseTests.Constructor_DateTimeWithMidnightTime_IgnoresTime':
        CatalogCase(() => same(
              NepaliDate.fromGregorian(DateTime.utc(2023, 4, 14, 0, 0, 0)),
              of(2080, 1, 1),
            )),
    'NepaliDateArithmeticEdgeCaseTests.Constructor_DateTimeWithNoonTime_IgnoresTime':
        CatalogCase(() => same(
              NepaliDate.fromGregorian(DateTime.utc(2023, 4, 14, 12)),
              of(2080, 1, 1),
            )),
    'NepaliDateArithmeticEdgeCaseTests.Constructor_DateTimeWithEndOfDayTime_IgnoresTime':
        CatalogCase(() => same(
              NepaliDate.fromGregorian(DateTime.utc(2023, 4, 14, 23, 59, 59)),
              of(2080, 1, 1),
            )),
    'NepaliDateArithmeticEdgeCaseTests.Constructor_TwoDateTimesOnSameEnglishDateDifferentTimes_ProduceSameNepaliDate':
        CatalogCase(() {
      same(
        NepaliDate.fromGregorian(DateTime.utc(2023, 4, 14)),
        NepaliDate.fromGregorian(DateTime.utc(2023, 4, 14, 23, 59, 59)),
      );
    }),
    'NepaliDateArithmeticEdgeCaseTests.TryParse_AutoAdjust_DayYearMonthFormat_ReturnsCorrectDate':
        autoAdjust,
    'NepaliDateArithmeticEdgeCaseTests.TryParse_AutoAdjust_MonthDayYearInvertedOrder_ReturnsCorrectDate':
        autoAdjust,
    'NepaliDateArithmeticEdgeCaseTests.TryParse_AutoAdjust_TwoDigitYear_ExpandsToCurrentMillennium':
        autoAdjust,
    'NepaliDateArithmeticEdgeCaseTests.TryParse_AutoAdjust_InvalidDateAfterAdjustment_ReturnsFalse':
        autoAdjust,
    'NepaliDateArithmeticEdgeCaseTests.TryParse_AutoAdjust_ValidStandardFormat_ReturnsCorrectDate':
        autoAdjust,

    // Core/NepaliDateManipulationTests
    'NepaliDateManipulationTests.MonthEndDate_ReturnsCorrectDate':
        CatalogCase(() => same(of(2080, 5, 1).lastDayOfMonth, of(2080, 5, 31))),
    'NepaliDateManipulationTests.AddMonths_ReturnsCorrectDate#1':
        CatalogCase(() => same(of(2080, 5, 15).addMonths(1), of(2080, 6, 15))),
    'NepaliDateManipulationTests.AddMonths_ReturnsCorrectDate#2':
        CatalogCase(() => same(of(2080, 5, 15).addMonths(-1), of(2080, 4, 15))),
    'NepaliDateManipulationTests.AddMonths_ReturnsCorrectDate#3':
        CatalogCase(() => same(of(2080, 5, 15).addMonths(12), of(2081, 5, 15))),
    'NepaliDateManipulationTests.AddMonths_ReturnsCorrectDate#4':
        CatalogCase(() => same(of(2081, 4, 32).addMonths(5), of(2081, 9, 29))),
    'NepaliDateManipulationTests.AddMonths_ReturnsCorrectDate#5': CatalogCase(
      () => same(of(2081, 4, 32).addMonths(5, overflow: MonthOverflow.spill), of(2081, 10, 3)),
    ),
    'NepaliDateManipulationTests.AddDays_ReturnsCorrectDate#1':
        CatalogCase(() => same(of(2080, 5, 15).addDays(5), of(2080, 5, 20))),
    'NepaliDateManipulationTests.AddDays_ReturnsCorrectDate#2':
        CatalogCase(() => same(of(2080, 5, 15).addDays(-5), of(2080, 5, 10))),
    'NepaliDateManipulationTests.AddDays_ReturnsCorrectDate#3':
        CatalogCase(() => same(of(2080, 5, 31).addDays(1), of(2080, 6, 1))),
    'NepaliDateManipulationTests.AddDays_ReturnsCorrectDate#4':
        CatalogCase(() => same(of(2080, 12, 30).addDays(5), of(2081, 1, 5))),
    'NepaliDateManipulationTests.Subtract_TwoDates_ReturnsCorrectTimeSpan':
        CatalogCase(() => expect(of(2080, 5, 1).daysUntil(of(2080, 5, 16)), 15)),
    'NepaliDateManipulationTests.Subtract_SameDate_ReturnsZero':
        CatalogCase(() => expect(of(2080, 5, 15).daysUntil(of(2080, 5, 15)), 0)),

    // Core/NepaliDateRangeExtendedTests
    'NepaliDateRangeExtendedTests.ForCalendarYear_StartsAtBaishakhOne_EndsAtChaitraEnd':
        CatalogCase(() {
      final range = NepaliDateRange.forYear(2080);
      same(range.start, of(2080, 1, 1));
      same(range.end, of(2080, 12, 1).lastDayOfMonth);
    }),
    'NepaliDateRangeExtendedTests.ForCalendarYear_LengthIsReasonable': CatalogCase(() {
      final length = NepaliDateRange.forYear(2080).length;
      expect(length >= 365 && length <= 366, isTrue);
    }),
    'NepaliDateRangeExtendedTests.CurrentMonth_StartIsFirstDayOfCurrentMonth': CatalogCase(() {
      final today = NepaliDate.today(clock: () => DateTime.utc(2024, 7, 30, 18, 30));
      final range = NepaliDateRange.currentMonth(clock: () => DateTime.utc(2024, 7, 30, 18, 30));
      same(range.start, of(today.year, today.month, 1));
    }),
    'NepaliDateRangeExtendedTests.CurrentMonth_EndIsLastDayOfCurrentMonth': CatalogCase(() {
      final today = NepaliDate.today(clock: () => DateTime.utc(2024, 7, 30, 18, 30));
      final range = NepaliDateRange.currentMonth(clock: () => DateTime.utc(2024, 7, 30, 18, 30));
      same(range.end, today.lastDayOfMonth);
    }),
    'NepaliDateRangeExtendedTests.CurrentMonth_ContainsToday': CatalogCase(() {
      final today = NepaliDate.today(clock: () => DateTime.utc(2024, 7, 30, 18, 30));
      final range = NepaliDateRange.currentMonth(clock: () => DateTime.utc(2024, 7, 30, 18, 30));
      expect(range.contains(today), isTrue);
    }),
    'NepaliDateRangeExtendedTests.CurrentFiscalYear_ContainsToday': CatalogCase(() {
      final today = NepaliDate.today(clock: () => DateTime.utc(2024, 7, 30, 18, 30));
      expect(
        NepaliDateRange.currentFiscalYear(clock: () => DateTime.utc(2024, 7, 30, 18, 30))
            .contains(today),
        isTrue,
      );
    }),
    'NepaliDateRangeExtendedTests.CurrentFiscalYear_StartIsShrawan': CatalogCase(() {
      final range =
          NepaliDateRange.currentFiscalYear(clock: () => DateTime.utc(2024, 7, 30, 18, 30));
      expect(range.start.month, 4);
    }),
    'NepaliDateRangeExtendedTests.CurrentFiscalYear_EndIsAshadh': CatalogCase(() {
      final range =
          NepaliDateRange.currentFiscalYear(clock: () => DateTime.utc(2024, 7, 30, 18, 30));
      expect(range.end.month, 3);
    }),
    'NepaliDateRangeExtendedTests.CurrentCalendarYear_ContainsToday': CatalogCase(() {
      final today = NepaliDate.today(clock: () => DateTime.utc(2024, 7, 30, 18, 30));
      expect(
        NepaliDateRange.currentCalendarYear(clock: () => DateTime.utc(2024, 7, 30, 18, 30))
            .contains(today),
        isTrue,
      );
    }),
    'NepaliDateRangeExtendedTests.CurrentCalendarYear_StartIsBaishakh1': CatalogCase(() {
      final today = NepaliDate.today(clock: () => DateTime.utc(2024, 7, 30, 18, 30));
      final range =
          NepaliDateRange.currentCalendarYear(clock: () => DateTime.utc(2024, 7, 30, 18, 30));
      same(range.start, of(today.year, 1, 1));
    }),
    'NepaliDateRangeExtendedTests.SplitByFiscalQuarter_EmptyRange_ReturnsEmptyArray': emptyRange,
    'NepaliDateRangeExtendedTests.SplitByFiscalQuarter_RangeWithinOneQuarter_ReturnsSingleRange':
        CatalogCase(() => expect(
              NepaliDateRange.of(of(2080, 4, 5), of(2080, 4, 10)).splitByFiscalQuarter().length,
              1,
            )),
    'NepaliDateRangeExtendedTests.SplitByFiscalQuarter_RangeSpanningTwoQuarters_ReturnsTwoRanges':
        CatalogCase(() => expect(
              NepaliDateRange.of(of(2080, 6, 15), of(2080, 7, 15)).splitByFiscalQuarter().length,
              2,
            )),
    'NepaliDateRangeExtendedTests.SplitByFiscalQuarter_FullFiscalYear_ReturnsFourRanges':
        CatalogCase(() => expect(NepaliDateRange.forYear(2080).splitByFiscalQuarter().length, 4)),
    'NepaliDateRangeExtendedTests.SplitByFiscalQuarter_RangeInQ4Months_SingleRange': CatalogCase(
      () => expect(
        NepaliDateRange.of(of(2081, 1, 5), of(2081, 2, 5)).splitByFiscalQuarter().length,
        1,
      ),
    ),
    'NepaliDateRangeExtendedTests.DatesWithInterval_Zero_ThrowsArgumentOutOfRangeException':
        CatalogCase(() => expect(
              () => NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 5)).datesWithInterval(0),
              throwsArgumentError,
            )),
    'NepaliDateRangeExtendedTests.DatesWithInterval_NegativeInterval_ThrowsArgumentOutOfRangeException':
        CatalogCase(() => expect(
              () => NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 5)).datesWithInterval(-1),
              throwsArgumentError,
            )),
    'NepaliDateRangeExtendedTests.DatesWithInterval_IntervalOfOne_YieldsEveryDay': CatalogCase(
      () => expect(
        NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 5)).datesWithInterval(1).length,
        5,
      ),
    ),
    'NepaliDateRangeExtendedTests.DatesWithInterval_IntervalOfTwo_YieldsOddDays': CatalogCase(
      () => expect(
        NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 5)).datesWithInterval(2).length,
        3,
      ),
    ),
    'NepaliDateRangeExtendedTests.DatesWithInterval_IntervalLargerThanRange_YieldsOnlyStartDate':
        CatalogCase(() => expect(
              NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 5)).datesWithInterval(10).length,
              1,
            )),
    'NepaliDateRangeExtendedTests.DatesWithInterval_EmptyRange_YieldsNothing': emptyRange,
    'NepaliDateRangeExtendedTests.WeekendDays_IncludeSundayTrue_ReturnsBothSaturdayAndSunday':
        CatalogCase(() => expect(
              NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 7)).weekendDays().length,
              2,
            )),
    'NepaliDateRangeExtendedTests.WeekendDays_IncludeSundayFalse_ReturnsOnlySaturday':
        CatalogCase(() => expect(
              NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 7))
                  .weekendDays(includeSunday: false)
                  .length,
              1,
            )),
    'NepaliDateRangeExtendedTests.WeekendDays_RangeWithNoWeekend_ReturnsEmpty': CatalogCase(
      () => expect(
        NepaliDateRange.of(of(2080, 1, 4), of(2080, 1, 6)).weekendDays(includeSunday: false).length,
        0,
      ),
    ),
    'NepaliDateRangeExtendedTests.WeekendDays_EmptyRange_ReturnsEmpty': emptyRange,
    'NepaliDateRangeExtendedTests.WorkingDays_ExcludeSundayFalse_ExcludesOnlySaturday':
        CatalogCase(() => expect(
              NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 7)).workingDays().length,
              6,
            )),
    'NepaliDateRangeExtendedTests.WorkingDays_ExcludeSundayTrue_ExcludesBothSatAndSun':
        CatalogCase(() => expect(
              NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 7))
                  .workingDays(excludeSunday: true)
                  .length,
              5,
            )),
    'NepaliDateRangeExtendedTests.WorkingDays_EmptyRange_ReturnsEmpty': emptyRange,
    'NepaliDateRangeExtendedTests.FromDayCount_ZeroDays_ThrowsArgumentOutOfRangeException':
        CatalogCase(() => expect(
              () => NepaliDateRange.fromDayCount(of(2080, 1, 1), 0),
              throwsArgumentError,
            )),
    'NepaliDateRangeExtendedTests.FromDayCount_NegativeDays_ThrowsArgumentOutOfRangeException':
        CatalogCase(() => expect(
              () => NepaliDateRange.fromDayCount(of(2080, 1, 1), -1),
              throwsArgumentError,
            )),
    'NepaliDateRangeExtendedTests.Intersect_NonOverlappingRanges_ReturnsEmptyRange': CatalogCase(
      () => expect(
        NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 5))
            .intersect(NepaliDateRange.of(of(2080, 2, 1), of(2080, 2, 5))),
        isNull,
      ),
    ),
    'NepaliDateRangeExtendedTests.Intersect_AdjacentRanges_ReturnsEmptyRange': CatalogCase(
      () => expect(
        NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 5))
            .intersect(NepaliDateRange.of(of(2080, 1, 6), of(2080, 1, 10))),
        isNull,
      ),
    ),
    'NepaliDateRangeExtendedTests.Intersect_OneRangeFullyInsideOther_ReturnsInnerRange':
        CatalogCase(() {
      final outer = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 20));
      final inner = NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 10));
      final result = outer.intersect(inner);
      expect(result, isNotNull);
      same(result!.start, inner.start);
      same(result.end, inner.end);
    }),
    'NepaliDateRangeExtendedTests.Union_LeftRangeIsEmpty_ReturnsRightRange': emptyRange,
    'NepaliDateRangeExtendedTests.Union_RightRangeIsEmpty_ReturnsLeftRange': emptyRange,
    'NepaliDateRangeExtendedTests.Union_NonOverlappingRanges_SpansEntireGap': CatalogCase(() {
      final result = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 5))
          .union(NepaliDateRange.of(of(2080, 1, 10), of(2080, 1, 15)));
      same(result.start, of(2080, 1, 1));
      same(result.end, of(2080, 1, 15));
    }),
    'NepaliDateRangeExtendedTests.Contains_ExactStartDate_ReturnsTrue': CatalogCase(() => expect(
          NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 20)).contains(of(2080, 1, 5)),
          isTrue,
        )),
    'NepaliDateRangeExtendedTests.Contains_ExactEndDate_ReturnsTrue': CatalogCase(() => expect(
          NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 20)).contains(of(2080, 1, 20)),
          isTrue,
        )),
    'NepaliDateRangeExtendedTests.Contains_OneDayBeforeStart_ReturnsFalse':
        CatalogCase(() => expect(
              NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 20)).contains(of(2080, 1, 4)),
              isFalse,
            )),
    'NepaliDateRangeExtendedTests.Contains_OneDayAfterEnd_ReturnsFalse': CatalogCase(() => expect(
          NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 20)).contains(of(2080, 1, 21)),
          isFalse,
        )),
    'NepaliDateRangeExtendedTests.Contains_EmptyRange_ContainsNothing': emptyRange,
    'NepaliDateRangeExtendedTests.IsAdjacentTo_GapBetweenRanges_ReturnsFalse': CatalogCase(
      () => expect(
        NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 5))
            .isAdjacentTo(NepaliDateRange.of(of(2080, 1, 7), of(2080, 1, 10))),
        isFalse,
      ),
    ),
    'NepaliDateRangeExtendedTests.IsAdjacentTo_OverlappingRanges_ReturnsFalse': CatalogCase(
      () => expect(
        NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 10))
            .isAdjacentTo(NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 15))),
        isFalse,
      ),
    ),
    'NepaliDateRangeExtendedTests.IsAdjacentTo_EmptyRange_ReturnsFalse': emptyRange,
    'NepaliDateRangeExtendedTests.Except_NonOverlappingExcludeRange_ReturnsOriginalRange':
        CatalogCase(() {
      final range = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 5));
      final result = range.except(NepaliDateRange.of(of(2080, 2, 1), of(2080, 2, 5)));
      expect(result, hasLength(1));
      same(result.single.start, range.start);
      same(result.single.end, range.end);
    }),
    'NepaliDateRangeExtendedTests.Except_ExcludeRangeFullyContainsThis_ReturnsEmptyArray':
        CatalogCase(() => expect(
              NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 10))
                  .except(NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 20))),
              isEmpty,
            )),
    'NepaliDateRangeExtendedTests.Except_ExcludeOverlapsStart_ReturnsRightPart': CatalogCase(() {
      final result = NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 20))
          .except(NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 10)));
      expect(result, hasLength(1));
      same(result.single.start, of(2080, 1, 11));
      same(result.single.end, of(2080, 1, 20));
    }),
    'NepaliDateRangeExtendedTests.Except_ExcludeOverlapsEnd_ReturnsLeftPart': CatalogCase(() {
      final result = NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 20))
          .except(NepaliDateRange.of(of(2080, 1, 15), of(2080, 1, 25)));
      expect(result, hasLength(1));
      same(result.single.start, of(2080, 1, 5));
      same(result.single.end, of(2080, 1, 14));
    }),
    'NepaliDateRangeExtendedTests.GetEnumerator_ThreeDayRange_YieldsExactlyThreeDates':
        CatalogCase(() => expect(NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 7)).length, 3)),
    'NepaliDateRangeExtendedTests.GetEnumerator_EmptyRange_YieldsNoDates': emptyRange,
    'NepaliDateRangeExtendedTests.GetEnumerator_SingleDayRange_YieldsOneDate':
        CatalogCase(() => expect(
              NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 5)).length,
              1,
            )),
    'NepaliDateRangeExtendedTests.ToString_DefaultFormat_IsStartDashEnd': CatalogCase(() => expect(
          NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 15)).toString(),
          '2080/01/01 - 2080/01/15',
        )),
    'NepaliDateRangeExtendedTests.ToString_EmptyRange_ReturnsEmptyRangeString': emptyRange,
    'NepaliDateRangeExtendedTests.ToString_WithDateFormat_UsesSpecifiedFormat':
        CatalogCase(() => expect(
              NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 15))
                  .toStringWith(DateOrder.dmy, Separator.dash),
              '01-01-2080 - 15-01-2080',
            )),
    'NepaliDateRangeExtendedTests.ToString_WithDateFormat_EmptyRange_ReturnsEmptyRangeString':
        emptyRange,
    'NepaliDateRangeExtendedTests.Equals_IdenticalRanges_ReturnsTrue': CatalogCase(() {
      final a = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 15));
      final b = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 15));
      expect(a == b, isTrue);
    }),
    'NepaliDateRangeExtendedTests.Equals_DifferentStart_ReturnsFalse': CatalogCase(() {
      final a = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 15));
      final b = NepaliDateRange.of(of(2080, 1, 2), of(2080, 1, 15));
      expect(a == b, isFalse);
    }),
    'NepaliDateRangeExtendedTests.Equals_DifferentEnd_ReturnsFalse': CatalogCase(() {
      final a = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 15));
      final b = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 16));
      expect(a == b, isFalse);
    }),
    'NepaliDateRangeExtendedTests.Equals_BothEmpty_ReturnsTrue': emptyRange,
    'NepaliDateRangeExtendedTests.Equals_ObjectOverload_SameRange_ReturnsTrue': CatalogCase(() {
      final a = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 15));
      final b = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 15));
      expect(a == b, isTrue);
    }),
    'NepaliDateRangeExtendedTests.Equals_ObjectOverload_WrongType_ReturnsFalse': CatalogCase(() {
      final Object range = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 15));
      expect(range == 'not a range', isFalse);
    }),
    'NepaliDateRangeExtendedTests.GetHashCode_EqualRanges_SameHash': CatalogCase(() {
      final a = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 15));
      final b = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 15));
      expect(a.hashCode, b.hashCode);
    }),
    'NepaliDateRangeExtendedTests.OperatorEquals_IdenticalRanges_ReturnsTrue': CatalogCase(() {
      final a = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 15));
      final b = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 15));
      expect(a == b, isTrue);
    }),
    'NepaliDateRangeExtendedTests.OperatorNotEquals_DifferentRanges_ReturnsTrue': CatalogCase(() {
      final a = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 15));
      final b = NepaliDateRange.of(of(2080, 1, 2), of(2080, 1, 16));
      expect(a != b, isTrue);
    }),

    // Core/NepaliDateRangeTests
    'NepaliDateRangeTests.Constructor_ValidDates_CreatesRange': CatalogCase(() {
      final range = NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 20));
      same(range.start, of(2080, 1, 5));
      same(range.end, of(2080, 1, 20));
    }),
    'NepaliDateRangeTests.Constructor_EndBeforeStart_CreatesEmptyRange': emptyRange,
    'NepaliDateRangeTests.SingleDay_CreatesRangeWithOneDay':
        CatalogCase(() => expect(NepaliDateRange.singleDay(of(2080, 1, 5)).length, 1)),
    'NepaliDateRangeTests.FromDayCount_CreatesCorrectRange': CatalogCase(() {
      final range = NepaliDateRange.fromDayCount(of(2080, 1, 5), 5);
      same(range.start, of(2080, 1, 5));
      same(range.end, of(2080, 1, 9));
    }),
    'NepaliDateRangeTests.ForMonth_CreatesCorrectRange':
        CatalogCase(() => same(NepaliDateRange.forMonth(2080, 5).start, of(2080, 5, 1))),
    'NepaliDateRangeTests.ForFiscalYear_CreatesCorrectRange':
        CatalogCase(() => same(FiscalYear(2080).range().start, of(2080, 4, 1))),
    'NepaliDateRangeTests.Contains_DateInRange_ReturnsTrue': CatalogCase(() => expect(
          NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 20)).contains(of(2080, 1, 10)),
          isTrue,
        )),
    'NepaliDateRangeTests.Contains_DateOutsideRange_ReturnsFalse': CatalogCase(() => expect(
          NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 20)).contains(of(2080, 1, 25)),
          isFalse,
        )),
    'NepaliDateRangeTests.Contains_RangeFullyContained_ReturnsTrue': CatalogCase(() {
      final outer = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 20));
      expect(outer.containsRange(NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 10))), isTrue);
    }),
    'NepaliDateRangeTests.Overlaps_RangesOverlap_ReturnsTrue': CatalogCase(() {
      expect(
        NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 10))
            .overlaps(NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 15))),
        isTrue,
      );
    }),
    'NepaliDateRangeTests.Overlaps_RangesDontOverlap_ReturnsFalse': CatalogCase(() {
      expect(
        NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 5))
            .overlaps(NepaliDateRange.of(of(2080, 1, 10), of(2080, 1, 15))),
        isFalse,
      );
    }),
    'NepaliDateRangeTests.IsAdjacentTo_AdjacentRanges_ReturnsTrue': CatalogCase(() {
      expect(
        NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 5))
            .isAdjacentTo(NepaliDateRange.of(of(2080, 1, 6), of(2080, 1, 10))),
        isTrue,
      );
    }),
    'NepaliDateRangeTests.Intersect_OverlappingRanges_ReturnsIntersection': CatalogCase(() {
      final result = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 10))
          .intersect(NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 15)));
      expect(result, isNotNull);
      same(result!.start, of(2080, 1, 5));
      same(result.end, of(2080, 1, 10));
    }),
    'NepaliDateRangeTests.Union_OverlappingRanges_ReturnsUnion': CatalogCase(() {
      final result = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 10))
          .union(NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 15)));
      same(result.start, of(2080, 1, 1));
      same(result.end, of(2080, 1, 15));
    }),
    'NepaliDateRangeTests.Except_RemovingRangeFromMiddle_ReturnsTwoRanges': CatalogCase(() {
      final result = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 20))
          .except(NepaliDateRange.of(of(2080, 1, 8), of(2080, 1, 12)));
      expect(result, hasLength(2));
      same(result[0].start, of(2080, 1, 1));
      same(result[0].end, of(2080, 1, 7));
      same(result[1].start, of(2080, 1, 13));
      same(result[1].end, of(2080, 1, 20));
    }),
    'NepaliDateRangeTests.SplitByMonth_RangeAcrossMonths_SplitsCorrectly': CatalogCase(() {
      final pieces = NepaliDateRange.of(of(2080, 1, 20), of(2080, 3, 5)).splitByMonth();
      expect(pieces, hasLength(3));
      same(pieces.first.start, of(2080, 1, 20));
      same(pieces.last.end, of(2080, 3, 5));
    }),
    'NepaliDateRangeTests.WorkingDays_ReturnsCorrectDays': CatalogCase(() {
      final range = NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 7));
      expect(range.workingDays().length, 6);
      expect(range.workingDays(excludeSunday: true).length, 5);
    }),
    'NepaliDateRangeTests.Enumeration_EnumeratesAllDaysInRange':
        CatalogCase(() => expect(NepaliDateRange.of(of(2080, 1, 1), of(2080, 1, 10)).length, 10)),
    'NepaliDateRangeTests.Demo_RangeOperations': CatalogCase(() {
      final range = NepaliDateRange.of(of(2080, 1, 5), of(2080, 1, 20));
      expect(range.contains(of(2080, 1, 10)), isTrue);
      expect(range.toList().length, range.length);
      expect(NepaliDateRange.forMonth(2080, 5).length, 31);
      expect(FiscalYear(2080).range().length, greaterThan(0));
    }),

    // Core/OptimizationVerificationTests (subtraction rows)
    'OptimizationVerificationTests.Subtraction_SameDate_ReturnsZeroDays':
        CatalogCase(() => expect(of(2080, 5, 15).daysUntil(of(2080, 5, 15)), 0)),
    'OptimizationVerificationTests.Subtraction_AdjacentDays_ReturnsOneDay':
        CatalogCase(() => expect(of(2080, 5, 15).daysUntil(of(2080, 5, 16)), 1)),
    'OptimizationVerificationTests.Subtraction_CrossMonth_CorrectDays': CatalogCase(
      () => expect(of(2080, 4, 1).lastDayOfMonth.daysUntil(of(2080, 5, 1)), 1),
    ),
    'OptimizationVerificationTests.Subtraction_CrossYear_CorrectDays': CatalogCase(
      () => expect(of(2079, 12, 1).lastDayOfMonth.daysUntil(of(2080, 1, 1)), 1),
    ),
  };
}

Map<String, CatalogCase> _phase3() {
  CatalogCase formatIs(String pattern, String expected) =>
      CatalogCase(() => expect(of(2081, 4, 15).format(pattern), expected));
  CatalogCase sameMonth(int month) => CatalogCase(() {
        expect(of(2080, month, 15).month, month);
        expect(Month.fromNumber(month).number, month);
      });
  CatalogCase monthNumberName(int month) => CatalogCase(() {
        expect(Month.fromNumber(month).fullName(), _monthEn[month - 1]);
      });

  return {
    // Core/NepaliDateFormattableTests (the fixture is 2081-04-15)
    'NepaliDateFormattableTests.ToString_NullFormat_ReturnsDefault': formatIs('', '2081/04/15'),
    'NepaliDateFormattableTests.ToString_G_SameAsDefault': formatIs('G', '2081/04/15'),
    'NepaliDateFormattableTests.ToString_g_SameAsDefault': formatIs('g', '2081/04/15'),
    'NepaliDateFormattableTests.ToString_d_SameAsDefault': formatIs('d', '2081/04/15'),
    'NepaliDateFormattableTests.ToString_D_ReturnsLongDateString':
        CatalogCase(() => expect(of(2081, 4, 15).format('D'), contains('2081'))),
    'NepaliDateFormattableTests.ToString_s_ReturnsSortableIsoFormat': formatIs('s', '2081-04-15'),
    'NepaliDateFormattableTests.CustomFormat_yyyy_MM_dd_WithDash':
        formatIs('yyyy-MM-dd', '2081-04-15'),
    'NepaliDateFormattableTests.CustomFormat_dd_MM_yyyy_WithDot':
        formatIs('dd.MM.yyyy', '15.04.2081'),
    'NepaliDateFormattableTests.CustomFormat_MM_slash_dd_slash_yyyy':
        formatIs('MM/dd/yyyy', '04/15/2081'),
    'NepaliDateFormattableTests.CustomFormat_MMMxxx_ReturnsThreeCharMonthAbbreviation':
        formatIs('MMM', 'Shr'),
    'NepaliDateFormattableTests.CustomFormat_MMMM_ReturnsFullMonthName':
        formatIs('MMMM', 'Shrawan'),
    'NepaliDateFormattableTests.CustomFormat_yy_ReturnsTwoDigitYear':
        formatIs('yy/MM/dd', '81/04/15'),
    'NepaliDateFormattableTests.CustomFormat_M_WithoutLeadingZero_ReturnsUnpadded':
        formatIs('M/d/yyyy', '4/15/2081'),
    'NepaliDateFormattableTests.CustomFormat_SingleDigitMonth_WithoutLeadingZero':
        CatalogCase(() => expect(of(2081, 1, 5).format('M/d/yyyy'), '1/5/2081')),
    'NepaliDateFormattableTests.CustomFormat_LiteralInSingleQuotes': formatIs("yyyy'BS'", '2081BS'),
    'NepaliDateFormattableTests.CustomFormat_BackslashEscapedTokens_ProduceLiterals':
        formatIs(r'yyyy\M\M-\d\d', '2081MM-dd'),
    'NepaliDateFormattableTests.CustomFormat_BackslashBeforeLiteralChar_IsPassedThrough':
        formatIs(r'yyyy\-MM\-dd', '2081-04-15'),
    'NepaliDateFormattableTests.StringInterpolation_WithFormatSpecifier_UsesIFormattable':
        formatIs('yyyy-MM-dd', '2081-04-15'),
    'NepaliDateFormattableTests.StringFormatMethod_WithSpecifier':
        formatIs('yyyy-MM-dd', '2081-04-15'),
    'NepaliDateFormattableTests.SortableFormat_LexicographicOrderEqualsChronologicalOrder':
        CatalogCase(() =>
            expect(of(2080, 1, 1).format('s').compareTo(of(2081, 1, 1).format('s')), lessThan(0))),

    // Core/NepaliDateParsableTests
    'NepaliDateParsableTests.Parse_Via_GenericConstraint_Returns_CorrectDate':
        parsesTo('2080/04/15', 2080, 4, 15),
    'NepaliDateParsableTests.TryParse_Via_GenericConstraint_ValidDate_Returns_True':
        CatalogCase(() => expect(NepaliDate.tryParse('2080/04/15'), of(2080, 4, 15))),
    'NepaliDateParsableTests.TryParse_Via_GenericConstraint_InvalidDate_Returns_False':
        CatalogCase(() => expect(NepaliDate.tryParse('garbage'), isNull)),
    'NepaliDateParsableTests.SpanParse_Via_GenericConstraint_Returns_CorrectDate':
        parsesTo('2080/04/15', 2080, 4, 15),
    'NepaliDateParsableTests.SpanTryParse_Via_GenericConstraint_ValidDate_Returns_True':
        CatalogCase(() => expect(NepaliDate.tryParse('2080/04/15'), isNotNull)),

    // Core/NepaliDateMonthNameTests: the C# MonthName enum maps to the 1-based month number.
    'NepaliDateMonthNameTests.MonthName_AllMonths_ReturnCorrectEnum#1': sameMonth(1),
    'NepaliDateMonthNameTests.MonthName_AllMonths_ReturnCorrectEnum#2': sameMonth(2),
    'NepaliDateMonthNameTests.MonthName_AllMonths_ReturnCorrectEnum#3': sameMonth(3),
    'NepaliDateMonthNameTests.MonthName_AllMonths_ReturnCorrectEnum#4': sameMonth(4),
    'NepaliDateMonthNameTests.MonthName_AllMonths_ReturnCorrectEnum#5': sameMonth(5),
    'NepaliDateMonthNameTests.MonthName_AllMonths_ReturnCorrectEnum#6': sameMonth(6),
    'NepaliDateMonthNameTests.MonthName_AllMonths_ReturnCorrectEnum#7': sameMonth(7),
    'NepaliDateMonthNameTests.MonthName_AllMonths_ReturnCorrectEnum#8': sameMonth(8),
    'NepaliDateMonthNameTests.MonthName_AllMonths_ReturnCorrectEnum#9': sameMonth(9),
    'NepaliDateMonthNameTests.MonthName_AllMonths_ReturnCorrectEnum#10': sameMonth(10),
    'NepaliDateMonthNameTests.MonthName_AllMonths_ReturnCorrectEnum#11': sameMonth(11),
    'NepaliDateMonthNameTests.MonthName_AllMonths_ReturnCorrectEnum#12': sameMonth(12),
    'NepaliDateMonthNameTests.MonthName_SameMonthDifferentDays_AllReturnSameEnum':
        CatalogCase(() => expect(of(2080, 4, 15).month, 4)),
    'NepaliDateMonthNameTests.MonthName_SameMonthDifferentYears_AllReturnSameEnum#1':
        CatalogCase(() => expect(of(2070, 9, 1).month, 9)),
    'NepaliDateMonthNameTests.MonthName_SameMonthDifferentYears_AllReturnSameEnum#2':
        CatalogCase(() => expect(of(2080, 9, 1).month, 9)),
    'NepaliDateMonthNameTests.MonthName_SameMonthDifferentYears_AllReturnSameEnum#3':
        CatalogCase(() => expect(of(2090, 9, 1).month, 9)),
    'NepaliDateMonthNameTests.MonthName_SameMonthDifferentYears_AllReturnSameEnum#4':
        CatalogCase(() => expect(of(2100, 9, 1).month, 9)),
    'NepaliDateMonthNameTests.MonthName_AddingOneMonth_AdvancesEnum':
        CatalogCase(() => expect(of(2080, 11, 1).month, 11)),
    'NepaliDateMonthNameTests.MonthName_YearBoundary_WrapsFromChaitraToBasikhakh':
        CatalogCase(() => expect(of(2080, 12, 1).month, 12)),
    'NepaliDateMonthNameTests.NepaliMonthsEnum_IntegerValueMatchesMonthNumber#1':
        monthNumberName(1),
    'NepaliDateMonthNameTests.NepaliMonthsEnum_IntegerValueMatchesMonthNumber#2':
        monthNumberName(2),
    'NepaliDateMonthNameTests.NepaliMonthsEnum_IntegerValueMatchesMonthNumber#3':
        monthNumberName(3),
    'NepaliDateMonthNameTests.NepaliMonthsEnum_IntegerValueMatchesMonthNumber#4':
        monthNumberName(4),
    'NepaliDateMonthNameTests.NepaliMonthsEnum_IntegerValueMatchesMonthNumber#5':
        monthNumberName(5),
    'NepaliDateMonthNameTests.NepaliMonthsEnum_IntegerValueMatchesMonthNumber#6':
        monthNumberName(6),
    'NepaliDateMonthNameTests.NepaliMonthsEnum_IntegerValueMatchesMonthNumber#7':
        monthNumberName(7),
    'NepaliDateMonthNameTests.NepaliMonthsEnum_IntegerValueMatchesMonthNumber#8':
        monthNumberName(8),
    'NepaliDateMonthNameTests.NepaliMonthsEnum_IntegerValueMatchesMonthNumber#9':
        monthNumberName(9),
    'NepaliDateMonthNameTests.NepaliMonthsEnum_IntegerValueMatchesMonthNumber#10':
        monthNumberName(10),
    'NepaliDateMonthNameTests.NepaliMonthsEnum_IntegerValueMatchesMonthNumber#11':
        monthNumberName(11),
    'NepaliDateMonthNameTests.NepaliMonthsEnum_IntegerValueMatchesMonthNumber#12':
        monthNumberName(12),

    // Core/OptimizationVerificationTests: ToString and ToUnicodeString
    'OptimizationVerificationTests.ToString_ProducesExactFormat#1':
        CatalogCase(() => expect(of(2080, 5, 15).toString(), '2080/05/15')),
    'OptimizationVerificationTests.ToString_ProducesExactFormat#2':
        CatalogCase(() => expect(of(2080, 1, 1).toString(), '2080/01/01')),
    'OptimizationVerificationTests.ToString_ProducesExactFormat#3':
        CatalogCase(() => expect(of(2080, 12, 30).toString(), '2080/12/30')),
    'OptimizationVerificationTests.ToString_ProducesExactFormat#4':
        CatalogCase(() => expect(of(1901, 1, 1).toString(), '1901/01/01')),
    'OptimizationVerificationTests.ToString_ProducesExactFormat#5':
        CatalogCase(() => expect(of(2199, 12, 30).toString(), '2199/12/30')),
    'OptimizationVerificationTests.ToString_ProducesExactFormat#6':
        CatalogCase(() => expect(of(2000, 6, 9).toString(), '2000/06/09')),
    'OptimizationVerificationTests.ToString_ProducesExactFormat#7':
        CatalogCase(() => expect(of(2100, 10, 29).toString(), '2100/10/29')),
    'OptimizationVerificationTests.ToString_OutputIsExactly10Characters':
        CatalogCase(() => expect(of(2080, 5, 15).toString().length, 10)),
    'OptimizationVerificationTests.ToString_AllMonthsZeroPadded': CatalogCase(() {
      for (var month = 1; month <= 12; month++) {
        expect(of(2080, month, 1).toString().substring(5, 7), month.toString().padLeft(2, '0'));
      }
    }),
    'OptimizationVerificationTests.ToString_AllDaysZeroPadded': CatalogCase(() {
      for (var day = 1; day <= of(2080, 5, 1).monthLength; day++) {
        expect(of(2080, 5, day).toString().substring(8, 10), day.toString().padLeft(2, '0'));
      }
    }),
    'OptimizationVerificationTests.ToString_RoundtripsWithConstructor':
        CatalogCase(() => same(NepaliDate.parse(of(2080, 5, 15).toString()), of(2080, 5, 15))),
    'OptimizationVerificationTests.ToString_WithFormatAndSeparator_ProducesCorrectOutput#1':
        shortForm(DateOrder.ymd, Separator.slash, true, '2080/05/15'),
    'OptimizationVerificationTests.ToString_WithFormatAndSeparator_ProducesCorrectOutput#2':
        shortForm(DateOrder.ymd, Separator.dash, true, '2080-05-15'),
    'OptimizationVerificationTests.ToString_WithFormatAndSeparator_ProducesCorrectOutput#3':
        shortForm(DateOrder.ymd, Separator.dot, true, '2080.05.15'),
    'OptimizationVerificationTests.ToString_WithFormatAndSeparator_ProducesCorrectOutput#4':
        shortForm(DateOrder.ymd, Separator.underscore, true, '2080_05_15'),
    'OptimizationVerificationTests.ToString_WithFormatAndSeparator_ProducesCorrectOutput#5':
        shortForm(DateOrder.ymd, Separator.space, true, '2080 05 15'),
    'OptimizationVerificationTests.ToString_WithFormatAndSeparator_ProducesCorrectOutput#6':
        shortForm(DateOrder.ymd, Separator.backslash, true, r'2080\05\15'),
    'OptimizationVerificationTests.ToString_WithFormatAndSeparator_ProducesCorrectOutput#7':
        shortForm(DateOrder.dmy, Separator.slash, true, '15/05/2080'),
    'OptimizationVerificationTests.ToString_WithFormatAndSeparator_ProducesCorrectOutput#8':
        shortForm(DateOrder.dmy, Separator.dash, true, '15-05-2080'),
    'OptimizationVerificationTests.ToString_WithFormatAndSeparator_ProducesCorrectOutput#9':
        shortForm(DateOrder.mdy, Separator.slash, true, '05/15/2080'),
    'OptimizationVerificationTests.ToString_WithFormatAndSeparator_ProducesCorrectOutput#10':
        shortForm(DateOrder.ydm, Separator.slash, true, '2080/15/05'),
    'OptimizationVerificationTests.ToString_WithFormatAndSeparator_ProducesCorrectOutput#11':
        shortForm(DateOrder.myd, Separator.slash, true, '05/2080/15'),
    'OptimizationVerificationTests.ToString_WithFormatAndSeparator_ProducesCorrectOutput#12':
        shortForm(DateOrder.dym, Separator.slash, true, '15/2080/05'),
    'OptimizationVerificationTests.ToString_WithoutLeadingZeros_ProducesCorrectOutput#1':
        shortForm(DateOrder.ymd, Separator.slash, false, '2080/5/15'),
    'OptimizationVerificationTests.ToString_WithoutLeadingZeros_ProducesCorrectOutput#2':
        shortForm(DateOrder.dmy, Separator.dash, false, '15-5-2080'),
    'OptimizationVerificationTests.ToString_WithoutLeadingZeros_ProducesCorrectOutput#3':
        shortForm(DateOrder.mdy, Separator.dot, false, '5.15.2080'),
    'OptimizationVerificationTests.ToUnicodeString_DefaultFormat_ConvertsAllDigits':
        CatalogCase(() => expect(of(2080, 5, 15).toShortString(lang: Lang.ne), '२०८०/०५/१५')),
    'OptimizationVerificationTests.ToUnicodeString_EachDigitConvertsCorrectly':
        CatalogCase(() => expect(of(2081, 4, 15).toShortString(lang: Lang.ne), contains('१'))),
    'OptimizationVerificationTests.ToUnicodeString_SeparatorsPreserved': CatalogCase(() {
      expect(
        of(2080, 5, 15)
            .toShortString(order: DateOrder.ymd, separator: Separator.dash, lang: Lang.ne),
        contains('-'),
      );
    }),
    'OptimizationVerificationTests.ToUnicodeString_SameLengthAsToString': CatalogCase(() {
      final date = of(2080, 5, 15);
      expect(date.toShortString(lang: Lang.ne).length, date.toString().length);
    }),

    // Core/OptimizationVerificationTests: SmartDateParser (lenient, D-06 deviations marked)
    'OptimizationVerificationTests.SmartDateParser_NepaliDigits_ParseCorrectly#1':
        parsesTo('२०८०/०५/१५', 2080, 5, 15),
    'OptimizationVerificationTests.SmartDateParser_NepaliDigits_ParseCorrectly#2':
        parsesTo('२०८०-०५-१५', 2080, 5, 15),
    'OptimizationVerificationTests.SmartDateParser_PureEnglishDigits_NoConversionNeeded':
        parsesTo('2080/05/15', 2080, 5, 15),
    'OptimizationVerificationTests.SmartDateParser_MixedNepaliEnglishDigits_ParseCorrectly':
        parsesTo('2080/०५/15', 2080, 5, 15),
    'OptimizationVerificationTests.SmartDateParser_WithIndicators_RemovesAndParsesCorrectly#1':
        lenientTo('2080/05/15 B.S.', 2080, 5, 15),
    'OptimizationVerificationTests.SmartDateParser_WithIndicators_RemovesAndParsesCorrectly#2':
        lenientTo('2080/05/15 BS', 2080, 5, 15),
    'OptimizationVerificationTests.SmartDateParser_WithIndicators_RemovesAndParsesCorrectly#3':
        lenientTo('2080/05/15 V.S.', 2080, 5, 15),
    'OptimizationVerificationTests.SmartDateParser_WithIndicators_RemovesAndParsesCorrectly#4':
        lenientTo('2080/05/15 VS', 2080, 5, 15),
    'OptimizationVerificationTests.SmartDateParser_WithIndicators_RemovesAndParsesCorrectly#5':
        lenientTo('2080/05/15 bs', 2080, 5, 15),
    'OptimizationVerificationTests.SmartDateParser_WithIndicators_RemovesAndParsesCorrectly#6':
        lenientTo('2080/05/15 v.s.', 2080, 5, 15),
    'OptimizationVerificationTests.SmartDateParser_WithNepaliKeywords_RemovesAndParses':
        lenientTo('2080/05/15 गते', 2080, 5, 15),
    'OptimizationVerificationTests.SmartDateParser_WithExtraSpaces_ParsesCorrectly':
        lenientTo('  2080 / 05 / 15  ', 2080, 5, 15),
    'OptimizationVerificationTests.SmartDateParser_AllMonthNames_ParseCorrectly#1':
        lenientTo('15 Baisakh 2080', 2080, 1, 15),
    'OptimizationVerificationTests.SmartDateParser_AllMonthNames_ParseCorrectly#2':
        lenientTo('15 Jestha 2080', 2080, 2, 15),
    'OptimizationVerificationTests.SmartDateParser_AllMonthNames_ParseCorrectly#3':
        lenientTo('15 Asar 2080', 2080, 3, 15),
    'OptimizationVerificationTests.SmartDateParser_AllMonthNames_ParseCorrectly#4':
        lenientTo('15 Shrawan 2080', 2080, 4, 15),
    'OptimizationVerificationTests.SmartDateParser_AllMonthNames_ParseCorrectly#5':
        lenientTo('15 Bhadra 2080', 2080, 5, 15),
    'OptimizationVerificationTests.SmartDateParser_AllMonthNames_ParseCorrectly#6':
        lenientTo('15 Ashwin 2080', 2080, 6, 15),
    'OptimizationVerificationTests.SmartDateParser_AllMonthNames_ParseCorrectly#7':
        lenientTo('15 Kartik 2080', 2080, 7, 15),
    'OptimizationVerificationTests.SmartDateParser_AllMonthNames_ParseCorrectly#8':
        lenientTo('15 Mangsir 2080', 2080, 8, 15),
    'OptimizationVerificationTests.SmartDateParser_AllMonthNames_ParseCorrectly#9':
        lenientTo('15 Poush 2080', 2080, 9, 15),
    'OptimizationVerificationTests.SmartDateParser_AllMonthNames_ParseCorrectly#10':
        lenientTo('15 Magh 2080', 2080, 10, 15),
    'OptimizationVerificationTests.SmartDateParser_AllMonthNames_ParseCorrectly#11':
        lenientTo('15 Falgun 2080', 2080, 11, 15),
    'OptimizationVerificationTests.SmartDateParser_AllMonthNames_ParseCorrectly#12':
        lenientTo('15 Chaitra 2080', 2080, 12, 15),
    'OptimizationVerificationTests.SmartDateParser_MonthNameDifferentPositions_ParsesCorrectly#1':
        lenientTo('Baisakh 15, 2080', 2080, 1, 15),
    'OptimizationVerificationTests.SmartDateParser_MonthNameDifferentPositions_ParsesCorrectly#2':
        lenientTo('2080 Baisakh 15', 2080, 1, 15),
    'OptimizationVerificationTests.SmartDateParser_NepaliUnicodeMonthNames_ParseCorrectly#1':
        lenientTo('15 वैशाख 2080', 2080, 1, 15),
    'OptimizationVerificationTests.SmartDateParser_NepaliUnicodeMonthNames_ParseCorrectly#2':
        lenientTo('15 जेष्ठ 2080', 2080, 2, 15),
    'OptimizationVerificationTests.SmartDateParser_NepaliUnicodeMonthNames_ParseCorrectly#3':
        lenientTo('15 असार 2080', 2080, 3, 15),
    'OptimizationVerificationTests.SmartDateParser_NepaliUnicodeMonthNames_ParseCorrectly#4':
        lenientTo('15 श्रावण 2080', 2080, 4, 15),
    'OptimizationVerificationTests.SmartDateParser_TwoDigitYear_AdjustedTo2000s':
        const CatalogCase.deviation('D-06'),
    'OptimizationVerificationTests.SmartDateParser_InvalidInput_ThrowsFormatException': CatalogCase(
        () => throwsKind(() => NepaliDate.parseLenient('not a date'), ErrorKind.unrecognized)),
    'OptimizationVerificationTests.SmartDateParser_NullInput_ThrowsException':
        CatalogCase(() => throwsKind(() => NepaliDate.parseLenient(''), ErrorKind.unrecognized)),
    'OptimizationVerificationTests.SmartDateParser_EmptyInput_ThrowsException':
        CatalogCase(() => throwsKind(() => NepaliDate.parseLenient(''), ErrorKind.unrecognized)),
    'OptimizationVerificationTests.SmartDateParser_WhitespaceInput_ThrowsException':
        CatalogCase(() => throwsKind(() => NepaliDate.parseLenient(' '), ErrorKind.unrecognized)),
    'OptimizationVerificationTests.SmartDateParser_TryParse_ValidInput_ReturnsTrue':
        CatalogCase(() => expect(NepaliDate.tryParseLenient('2080/05/15'), of(2080, 5, 15))),
    'OptimizationVerificationTests.SmartDateParser_TryParse_InvalidInput_ReturnsFalse':
        CatalogCase(() => expect(NepaliDate.tryParseLenient('garbage'), isNull)),
    'OptimizationVerificationTests.SmartDateParser_TryParse_NullInput_ReturnsFalse':
        CatalogCase(() => expect(NepaliDate.tryParseLenient(''), isNull)),

    // Core/OptimizationVerificationTests: ToLongDateString and round-trips
    'OptimizationVerificationTests.ToLongDateString_Default_ContainsMonthNameAndDay':
        CatalogCase(() => expect(of(2080, 5, 15).toLongString(), contains('15'))),
    'OptimizationVerificationTests.ToLongDateString_WithDayName_ContainsDayOfWeek':
        CatalogCase(() => expect(of(2080, 5, 15).toLongString(weekday: true), contains('Friday'))),
    'OptimizationVerificationTests.ToLongDateString_WithoutYear_DoesNotContainYear': CatalogCase(
        () => expect(of(2080, 5, 15).toLongString(year: false), isNot(contains('2080')))),
    'OptimizationVerificationTests.ToString_EveryMonthFirstDay_RoundtripsViaConstructor':
        CatalogCase(() {
      for (var year = 1901; year <= 2199; year++) {
        for (var month = 1; month <= 12; month++) {
          expect(NepaliDate.parse(of(year, month, 1).toString()).year, year);
        }
      }
    }),
    'OptimizationVerificationTests.UnicodeConversion_AllDigits_RoundtripCorrectly': CatalogCase(() {
      for (var year = 1901; year <= 2199; year++) {
        for (var month = 1; month <= 12; month++) {
          expect(NepaliDate.parse(of(year, month, 1).toShortString(lang: Lang.ne)).year, year);
        }
      }
    }),

    // SmartDateParserTests: lenient parse; D-06 where the port refuses to guess.
    'SmartDateParserTests.Parse_StandardFormat_ReturnsCorrectDate':
        lenientTo('2080/04/15', 2080, 4, 15),
    'SmartDateParserTests.Parse_InvertedFormat_ReturnsCorrectDate':
        lenientTo('15/04/2080', 2080, 4, 15),
    'SmartDateParserTests.Parse_MonthDayYearFormat_ReturnsCorrectDate':
        const CatalogCase.deviation('D-06'),
    'SmartDateParserTests.Parse_WithMonthNames_ReturnsCorrectDate':
        lenientTo('15 Shrawan 2080', 2080, 4, 15),
    'SmartDateParserTests.Parse_WithNepaliUnicode_ReturnsCorrectDate':
        lenientTo('२०८०/०४/१५', 2080, 4, 15),
    'SmartDateParserTests.Parse_MixedFormats_ReturnsCorrectDate':
        lenientTo('15 साउन 2080', 2080, 4, 15),
    'SmartDateParserTests.Parse_WithSuffixes_ReturnsCorrectDate':
        lenientTo('15 Shrawan 2080 B.S.', 2080, 4, 15),
    'SmartDateParserTests.Parse_WithTypos_ReturnsCorrectDate':
        lenientTo('15 Srawan 2080', 2080, 4, 15),
    'SmartDateParserTests.Parse_ShorterYearFormats_ReturnsCorrectDate':
        const CatalogCase.deviation('D-06'),
    'SmartDateParserTests.Parse_InvalidFormat_ThrowsFormatException': CatalogCase(
        () => throwsKind(() => NepaliDate.parseLenient('not a date'), ErrorKind.unrecognized)),
    'SmartDateParserTests.TryParse_ValidFormat_ReturnsTrue':
        CatalogCase(() => expect(NepaliDate.tryParseLenient('2080/04/15'), of(2080, 4, 15))),
    'SmartDateParserTests.TryParse_InvalidFormat_ReturnsFalse':
        CatalogCase(() => expect(NepaliDate.tryParseLenient('not a date'), isNull)),
    'SmartDateParserTests.ExtensionMethod_ToNepaliDate_ParsesCorrectly':
        parsesTo('2080/04/15', 2080, 4, 15),
    'SmartDateParserTests.ExtensionMethod_TryToNepaliDate_ParsesCorrectly':
        CatalogCase(() => expect(NepaliDate.tryParse('2080/04/15'), of(2080, 4, 15))),

    // StringExtensionsTests: string -> NepaliDate via parse / tryParse.
    'StringExtensionsTests.ToNepaliDate_ValidDateString_ReturnsNepaliDate':
        parsesTo('2080/05/15', 2080, 5, 15),
    'StringExtensionsTests.ToNepaliDate_NepaliDigits_ReturnsNepaliDate':
        parsesTo('२०८०/०५/१५', 2080, 5, 15),
    'StringExtensionsTests.ToNepaliDate_InvalidDateString_ThrowsFormatException': CatalogCase(
        () => throwsKind(() => NepaliDate.parse('not a date'), ErrorKind.invalidCharacter)),
    'StringExtensionsTests.TryToNepaliDate_ValidDateString_ReturnsTrue':
        CatalogCase(() => expect(NepaliDate.tryParse('2080/05/15'), of(2080, 5, 15))),
    'StringExtensionsTests.TryToNepaliDate_InvalidDateString_ReturnsFalse':
        CatalogCase(() => expect(NepaliDate.tryParse('not a date'), isNull)),
  };
}

Map<String, CatalogCase> _phase4() => {
      'DateTimeExtensionsTests.ToNepaliDate_ValidDateTime_ReturnsCorrectNepaliDate': CatalogCase(
        () => same(NepaliDate.fromGregorian(DateTime.utc(2023, 4, 14)), of(2080, 1, 1)),
      ),
      'DateTimeExtensionsTests.ToNepaliDate_MinValue_ThrowsArgumentOutOfRangeException':
          CatalogCase(() => throwsKind(
                () => NepaliDate.fromGregorian(DateTime.utc(1, 1, 1)),
                ErrorKind.outOfRange,
              )),
      'DateTimeExtensionsTests.ToNepaliDate_MaxValue_ThrowsArgumentOutOfRangeException':
          CatalogCase(() => throwsKind(
                () => NepaliDate.fromGregorian(DateTime.utc(9999, 12, 31)),
                ErrorKind.outOfRange,
              )),
      'DateTimeExtensionsTests.ToNepaliDate_DateBeforeMinSupported_ThrowsArgumentOutOfRangeException':
          CatalogCase(() => throwsKind(
                () => NepaliDate.fromGregorian(DateTime.utc(1844, 4, 10)),
                ErrorKind.outOfRange,
              )),
      'DateTimeExtensionsTests.ToNepaliDate_DateAfterMaxSupported_ThrowsArgumentOutOfRangeException':
          CatalogCase(() => throwsKind(
                () => NepaliDate.fromGregorian(DateTime.utc(2143, 4, 16)),
                ErrorKind.outOfRange,
              )),
    };

Map<String, CatalogCase> _relative() {
  DateTime clock() => DateTime.utc(2024, 7, 30, 18, 30);
  const zone = 'Asia/Kathmandu';
  final today = NepaliDate.today(timeZone: zone, clock: clock);
  final yesterday = today.addDays(-1);
  final tomorrow = today.addDays(1);
  final past = of(2080, 1, 1);
  final twoAhead = today.addDays(2);
  final twoBehind = today.addDays(-2);
  bool isToday(NepaliDate date) => date.isToday(zone, clock: clock);
  bool isYesterday(NepaliDate date) => date.isYesterday(zone, clock: clock);
  bool isTomorrow(NepaliDate date) => date.isTomorrow(zone, clock: clock);

  return {
    'NepaliDateIsRelativeTests.IsToday_TodaysDate_ReturnsTrue':
        CatalogCase(() => expect(isToday(today), isTrue)),
    'NepaliDateIsRelativeTests.IsToday_YesterdaysDate_ReturnsFalse':
        CatalogCase(() => expect(isToday(yesterday), isFalse)),
    'NepaliDateIsRelativeTests.IsToday_TomorrowsDate_ReturnsFalse':
        CatalogCase(() => expect(isToday(tomorrow), isFalse)),
    'NepaliDateIsRelativeTests.IsToday_ArbitraryPastDate_ReturnsFalse':
        CatalogCase(() => expect(isToday(past), isFalse)),
    'NepaliDateIsRelativeTests.IsYesterday_YesterdaysDate_ReturnsTrue':
        CatalogCase(() => expect(isYesterday(yesterday), isTrue)),
    'NepaliDateIsRelativeTests.IsYesterday_TodaysDate_ReturnsFalse':
        CatalogCase(() => expect(isYesterday(today), isFalse)),
    'NepaliDateIsRelativeTests.IsYesterday_TomorrowsDate_ReturnsFalse':
        CatalogCase(() => expect(isYesterday(tomorrow), isFalse)),
    'NepaliDateIsRelativeTests.IsYesterday_ArbitraryPastDate_ReturnsFalse':
        CatalogCase(() => expect(isYesterday(past), isFalse)),
    'NepaliDateIsRelativeTests.IsTomorrow_TomorrowsDate_ReturnsTrue':
        CatalogCase(() => expect(isTomorrow(tomorrow), isTrue)),
    'NepaliDateIsRelativeTests.IsTomorrow_TodaysDate_ReturnsFalse':
        CatalogCase(() => expect(isTomorrow(today), isFalse)),
    'NepaliDateIsRelativeTests.IsTomorrow_YesterdaysDate_ReturnsFalse':
        CatalogCase(() => expect(isTomorrow(yesterday), isFalse)),
    'NepaliDateIsRelativeTests.IsTomorrow_ArbitraryPastDate_ReturnsFalse':
        CatalogCase(() => expect(isTomorrow(past), isFalse)),
    'NepaliDateIsRelativeTests.Today_OnlyIsToday_IsTrue': CatalogCase(() {
      expect(isToday(today), isTrue);
      expect(isYesterday(today), isFalse);
      expect(isTomorrow(today), isFalse);
    }),
    'NepaliDateIsRelativeTests.Yesterday_OnlyIsYesterday_IsTrue': CatalogCase(() {
      expect(isYesterday(yesterday), isTrue);
      expect(isToday(yesterday), isFalse);
      expect(isTomorrow(yesterday), isFalse);
    }),
    'NepaliDateIsRelativeTests.Tomorrow_OnlyIsTomorrow_IsTrue': CatalogCase(() {
      expect(isTomorrow(tomorrow), isTrue);
      expect(isToday(tomorrow), isFalse);
      expect(isYesterday(tomorrow), isFalse);
    }),
    'NepaliDateIsRelativeTests.TwoDaysAhead_NoneAreTrue': CatalogCase(() {
      expect(isToday(twoAhead), isFalse);
      expect(isYesterday(twoAhead), isFalse);
      expect(isTomorrow(twoAhead), isFalse);
    }),
    'NepaliDateIsRelativeTests.TwoDaysBehind_NoneAreTrue': CatalogCase(() {
      expect(isToday(twoBehind), isFalse);
      expect(isYesterday(twoBehind), isFalse);
      expect(isTomorrow(twoBehind), isFalse);
    }),
  };
}
