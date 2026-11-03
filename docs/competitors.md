# Competitors on pub.dev

`shared/spec/BENCHMARK.md` section 7 selects the libraries to compare against. Candidate search:
pub.dev search for "bikram sambat" and "nepali date", then the package page of every hit that is a
date library rather than a widget. Usage was read on 2026-11-03 from the pub.dev package score
endpoint (`downloadCount30Days` and `likeCount`). The usage floor for Dart is 1,000 downloads in
the last 30 days, fixed in [ADR-0008](adr/0008-benchmarks-and-competitors.md) before ranking.

The maturity bar is the same for every language: first release at least 12 months ago, a release or
a commit in the last 36 months, a licence, not archived, it builds on the current toolchain, and it
passes the usage floor.

| Package | Version | Last release | First release | Downloads, 30 days | Likes | Licence | Passes | Selected |
|---|---|---|---:|---:|---:|---|---|---|
| [`nepali_utils`](https://pub.dev/packages/nepali_utils) | 3.0.8 | 2025-04-07 | 2019-05-15 | 3,459 | 54 | MIT | yes | yes |
| [`bikram_sambat`](https://pub.dev/packages/bikram_sambat) | 1.2.0 | 2026-07-14 | 2025-04-29 | 111 | 3 | MIT | no: usage | no |
| [`nepali_calendar_plus`](https://pub.dev/packages/nepali_calendar_plus) | 0.1.1 | 2026-10-06 | 2025-01-29 | 282 | 9 | MIT | no: usage | no |
| [`nepali_kit`](https://pub.dev/packages/nepali_kit) | 1.1.0 | 2026-10-03 | 2026-09-30 | 471 | 1 | MIT | no: usage, too new | no |
| [`nepali_calx`](https://pub.dev/packages/nepali_calx) | 1.0.0 | 2026-10-06 | 2026-10-06 | 186 | 1 | MIT | no: usage, too new | no |
| [`custom_nepali_calendar`](https://pub.dev/packages/custom_nepali_calendar) | 4.0.1 | 2026-08-27 | 2026-08-02 | 163 | 2 | MIT | no: usage, too new | no |
| [`clean_nepali_calendar`](https://pub.dev/packages/clean_nepali_calendar) | 3.0.0 | 2026-06-29 | 2020-03-21 | 93 | 31 | BSD-3-Clause | no: usage | no |
| [`nepali_date_converter`](https://pub.dev/packages/nepali_date_converter) | 1.0.3 | 2025-04-03 | 2025-03-21 | 60 | 2 | MIT | no: usage | no |
| [`nepali_calendar`](https://pub.dev/packages/nepali_calendar) | 0.0.4 | 2020-03-03 | 2019-04-19 | 15 | 7 | unknown | no: usage, licence, not Dart 3, unmaintained | no |
| [`nepali_date_picker`](https://pub.dev/packages/nepali_date_picker) | 8.0.0 | 2026-09-07 | 2018-12-23 | 1,302 | 93 | BSD-3-Clause | yes | no: a picker, conversions come from `nepali_utils` |

`nepali_date_picker` clears the usage floor but is a Flutter widget that depends on `nepali_utils`
for every conversion. Comparing it on B1 and B2 would measure its dependency, so it is a candidate
that is not selected, not a library to rank.

## Selected: nepali_utils 3.0.8

`nepali_utils` is a pure Dart utility package with a `NepaliDateTime` type and a
`DateTime.toNepaliDateTime()` extension. It is the date library the picker ecosystem uses, it has
the widest use of any candidate, and it keeps the same 1913-04-13 epoch as the older Nepali
libraries. It passes every bar.

Agreement on the 64 benchmark dates is measured in `bench/bin/agreement.dart` and shown in the
benchmark table. It agrees on 61 of 64 BS to AD conversions and 31 of 64 AD to BS conversions, so
it is listed but never ranked first, as section 4 requires.

The newer `bikram_sambat` package is the second candidate that is a converter, but its usage is far
below the fixed floor, so it is listed and not measured. Adding it later is a data change in
`docs/competitors.md`, not a new rule.
