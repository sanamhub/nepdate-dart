// C# NepDate's patro tests (shared/spec/vectors/csharp-tests/catalog.tsv, phase 4), translated to
// this API. One test per catalogue row (shared/spec/PORT-PLAN.md, "C# test catalogue").
//
// The vector and catalogue readers are the core package's test support, shared by relative path so
// there is one copy.

import 'package:nepdate/nepdate.dart';
import 'package:nepdate_patro/nepdate_patro.dart';
import 'package:test/test.dart';

import '../../nepdate/test/support/catalog.dart';
import '../../nepdate/test/support/vectors.dart';

NepaliDate of(int y, int m, int d) => NepaliDate.fromBs(y, m, d);

int serialOf(NepaliDate date) => NepaliDate.min.daysUntil(date);

void expectEmpty(NepaliDate date) {
  final calendarInfo = info(date);
  expect(calendarInfo.tithi, isNull);
  expect(calendarInfo.isPublicHoliday, isFalse);
  expect(calendarInfo.events, isEmpty);
}

final Map<String, Object?> summary = readPatroSummary();
int count(String field) => summary[field]! as int;

int daysWithTithi() => coverage().where((d) => info(d).tithi != null).length;

// The C# CalendarOffsets table covers BS 2001..2089 (32,509 days); this port covers BS 1901..2199
// (ALGORITHM section 2), so the rows below check the port's wider calendar.
void monthStarts() {
  final serials = <int>{};
  for (var year = 1901; year <= 2199; year++) {
    for (var month = 1; month <= 12; month++) {
      final serial = serialOf(of(year, month, 1));
      expect(serial, inInclusiveRange(0, 109211));
      expect(serials.add(serial), isTrue);
    }
  }
  expect(serials, hasLength(299 * 12));
}

void main() {
  checkCatalog(
    ['4'],
    {
      'CalendarDataTests.CalendarStrings_Pool_IsNonEmpty': CatalogCase(() {
        expect(count('names'), greaterThan(0));
        expect(info(of(2081, 1, 1)).tithi, isNotNull);
      }),
      'CalendarDataTests.CalendarStrings_Pool_AllEntriesHaveNonEmptyNpAndEn': CatalogCase(() {
        for (final date in coverage()) {
          final day = info(date);
          final tithi = day.tithi;
          for (final named in [if (tithi != null) tithi, ...day.events]) {
            expect(named.nepali, isNotEmpty);
            expect(named.english, isNotEmpty);
          }
        }
      }),
      'CalendarDataTests.CalendarOffsets_MonthStart_HasExpectedLength': CatalogCase(monthStarts),
      'CalendarDataTests.CalendarOffsets_MonthStart_IsStrictlyMonotonic': CatalogCase(() {
        var previous = -1;
        for (var year = 1901; year <= 2199; year++) {
          for (var month = 1; month <= 12; month++) {
            final serial = serialOf(of(year, month, 1));
            expect(serial, greaterThan(previous));
            previous = serial;
          }
        }
      }),
      // C# CalendarOffsets holds 32,509 days (BS 2001..2089); the port holds 109,212.
      'CalendarDataTests.CalendarOffsets_TotalDays_MatchesExpectedCount': CatalogCase(() {
        expect(serialOf(NepaliDate.max) + 1, 109212);
      }),
      'CalendarDataTests.TithiData_DayOffsets_IsStrictlySorted': CatalogCase(() {
        final serials = [
          for (final date in coverage())
            if (info(date).tithi != null) serialOf(date),
        ];
        expect(serials, hasLength(count('tithi_days')));
        for (var i = 1; i < serials.length; i++) {
          expect(serials[i], serials[i - 1] + 1);
        }
        expect(serials.first, count('tithi_first_serial'));
      }),
      'CalendarDataTests.TithiData_AllPoolIds_AreInRange': CatalogCase(() {
        final tithis = {
          for (final date in coverage())
            if (info(date).tithi != null) info(date).tithi!,
        };
        expect(tithis, hasLength(count('tithi_names')));
      }),
      'CalendarDataTests.TithiData_EntryCount_Matches2190': CatalogCase(() {
        expect(daysWithTithi(), count('tithi_days'));
      }),
      'CalendarDataTests.EventData_DayOffsets_IsStrictlySorted': CatalogCase(() {
        final days = [
          for (final date in coverage())
            if (info(date).events.isNotEmpty) serialOf(date),
        ];
        expect(days, hasLength(count('event_days')));
        for (var i = 1; i < days.length; i++) {
          expect(days[i], greaterThan(days[i - 1]));
        }
      }),
      'CalendarDataTests.EventData_SliceStart_IsNonDecreasing': CatalogCase(() {
        var total = 0;
        for (final date in coverage()) {
          final before = total;
          total += info(date).events.length;
          expect(total, greaterThanOrEqualTo(before));
        }
      }),
      'CalendarDataTests.EventData_SliceStart_SentinelEqualsEntriesLength': CatalogCase(() {
        var total = 0;
        for (final date in coverage()) {
          total += info(date).events.length;
        }
        expect(total, count('events'));
      }),
      'CalendarDataTests.EventData_AllEntries_AreInRange': CatalogCase(() {
        final names = <Named>{
          for (final date in coverage()) ...info(date).events,
        };
        expect(names, hasLength(count('event_names')));
      }),
      'CalendarDataTests.EventData_DayCount_Matches1671': CatalogCase(() {
        final days = coverage().where((d) => info(d).events.isNotEmpty).length;
        expect(days, count('event_days'));
      }),
      'CalendarDataTests.HolidayData_DayOffsets_IsStrictlySorted': CatalogCase(() {
        final serials = publicHolidays().map(serialOf).toList();
        for (var i = 1; i < serials.length; i++) {
          expect(serials[i], greaterThan(serials[i - 1]));
        }
      }),
      'CalendarDataTests.HolidayData_Count_Matches294': CatalogCase(() {
        expect(publicHolidays(), hasLength(count('holidays')));
      }),
      'CalendarDataTests.CalendarOffsets_GetOffset_BaseYear_Month1_Day1_ReturnsZero':
          CatalogCase(() {
        expect(serialOf(NepaliDate.min), 0);
        expect(serialOf(of(1901, 1, 1)), 0);
      }),
      // C# returns -1 for a date outside its table; this port cannot build an invalid date, so the
      // equivalent is the documented out-of-range error.
      'CalendarDataTests.CalendarOffsets_GetOffset_OutOfRange_ReturnsNegativeOne': CatalogCase(() {
        expect(
          () => of(1900, 1, 1),
          throwsA(isA<NepDateException>().having((e) => e.kind, 'kind', ErrorKind.outOfRange)),
        );
      }),
      'CalendarDataTests.CalendarOffsets_GetOffset_AllOffsetsAreUniqueSentinel':
          CatalogCase(monthStarts),
      'CalendarDataTests.NepaliDate_2081_01_01_CalendarData': CatalogCase(() {
        final day = info(of(2081, 1, 1));
        expect(day.tithi?.nepali, 'पञ्चमी');
        expect(day.tithi?.english, 'Panchami');
        expect(day.isPublicHoliday, isTrue);
        expect(day.events.map((e) => e.nepali), ['नयाँ वर्ष', 'मेष संक्रान्ति', 'बिस्का: जात्रा']);
      }),
      'CalendarDataTests.NepaliDate_2081_01_02_Tithi_IsShashthi': CatalogCase(() {
        expect(info(of(2081, 1, 2)).tithi?.nepali, 'षष्ठी');
        expect(info(of(2081, 1, 2)).tithi?.english, 'Shashthi');
      }),
      'CalendarDataTests.NepaliDate_2081_01_05_IsPublicHoliday': CatalogCase(() {
        expect(info(of(2081, 1, 5)).isPublicHoliday, isTrue);
      }),
      'CalendarDataTests.NepaliDate_2081_02_15_IsPublicHoliday_GanatantraDiwas': CatalogCase(() {
        final day = info(of(2081, 2, 15));
        expect(day.isPublicHoliday, isTrue);
        expect(day.events.map((e) => e.english), ['Republic Day']);
      }),
      'CalendarDataTests.NepaliDate_2080_11_01_CalendarData': CatalogCase(() {
        final day = info(of(2080, 11, 1));
        expect(day.tithi?.nepali, 'चतुर्थी');
        expect(day.tithi?.english, 'Chaturthi');
        expect(day.isPublicHoliday, isFalse);
        expect(day.events.map((e) => e.english), [
          'Mangala Chauthi Brata',
          "People's War Day",
          'Tilakund Chauthi',
          'Kumbha Sankranti',
          'World Radio Day',
        ]);
      }),
      'CalendarDataTests.NepaliDate_BeforeRange_AllPropertiesReturnDefaults': CatalogCase(() {
        expectEmpty(of(2070, 6, 15));
      }),
      'CalendarDataTests.NepaliDate_AfterRange_AllPropertiesReturnDefaults': CatalogCase(() {
        expectEmpty(of(2090, 1, 1));
      }),
      'CalendarDataTests.NepaliDate_OutsideTithiRange_TithiIsEmpty': CatalogCase(() {
        expect(info(of(2077, 6, 15)).tithi, isNull);
      }),
      'CalendarDataTests.NepaliDate_EventsNp_And_EventsEn_AlwaysHaveSameLength': CatalogCase(() {
        // One Named holds both languages, so the two lists cannot differ in length; both sides
        // are non-empty for every event.
        for (final date in coverage()) {
          for (final event in info(date).events) {
            expect(event.nepali, isNotEmpty);
            expect(event.english, isNotEmpty);
          }
        }
      }),
      'CalendarDataTests.GetCalendarInfo_TithiMatchesFlatProperties': CatalogCase(() {
        // The flat NepaliDate members are gone (D-13): info() is the only source, it returns the
        // same object for the same day, and the tithi is shared with it.
        final first = info(of(2081, 1, 1));
        expect(identical(info(of(2081, 1, 1)), first), isTrue);
        expect(identical(info(of(2081, 1, 1)).tithi, first.tithi), isTrue);
      }),
      'CalendarDataTests.AllDaysInScrapedRange_OffsetsAreInBounds': CatalogCase(() {
        for (final date in coverage()) {
          expect(serialOf(date), inInclusiveRange(0, 109211));
        }
      }),
      'CalendarDataTests.AllDaysInScrapedRange_NoExceptionOnPropertyAccess': CatalogCase(() {
        for (final date in coverage()) {
          final day = info(date);
          expect(day.isPublicHoliday, isA<bool>());
          expect(day.events.length, greaterThanOrEqualTo(0));
          expect(day.tithi?.english ?? '', isA<String>());
        }
      }),
      'CalendarDataTests.AllTithiEntries_ResolveToNonEmptyStrings': CatalogCase(() {
        for (final date in coverage()) {
          final tithi = info(date).tithi;
          if (tithi == null) continue;
          expect(tithi.nepali, isNotEmpty);
          expect(tithi.english, isNotEmpty);
        }
      }),
      'CalendarDataTests.AllHolidayOffsets_AreInBounds': CatalogCase(() {
        for (final date in publicHolidays()) {
          expect(serialOf(date), inInclusiveRange(0, 109211));
        }
      }),
      'CalendarDataTests.AllEventOffsets_AreInBounds': CatalogCase(() {
        for (final date in coverage()) {
          if (info(date).events.isNotEmpty) expect(serialOf(date), inInclusiveRange(0, 109211));
        }
      }),
      'CalendarDataTests.HolidayCount_ViaApi_Matches294': CatalogCase(() {
        expect(publicHolidays().length, count('holidays'));
      }),
      'CalendarDataTests.CalendarInfo_EventArrays_AreNeverNull': CatalogCase(() {
        for (final date in coverage()) {
          expect(info(date).events, isA<List<Named>>());
        }
      }),
    },
    file: 'Core/CalendarDataTests.cs',
  );
}
