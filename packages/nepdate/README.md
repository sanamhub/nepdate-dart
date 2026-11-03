# nepdate

Bikram Sambat (the Nepali calendar) dates for Dart and Flutter: conversion to and from Gregorian,
arithmetic, formatting, parsing, ranges and fiscal years. Pure Dart, no dependencies, every platform
including the web.

```sh
dart pub add nepdate
```

```dart
import 'package:nepdate/nepdate.dart';

final date = NepaliDate.fromBs(2081, 4, 15);
date.toString(); // => 2081/04/15
date.toDateTime().toIso8601String(); // => 2024-07-30T00:00:00.000Z
date.toLongString(weekday: true); // => Tuesday, Shrawan 15, 2081
NepaliDate.parse('२०८१/०४/१५').toString(); // => 2081/04/15
date.addMonths(2).toString(); // => 2081/06/15
date.fiscalYear.label(); // => 2081/82
```

The package has no time zone database. `NepaliDate.today` takes `Asia/Kathmandu` (the default),
`UTC`, `GMT` or a fixed offset such as `+05:45`, and an optional clock for tests. For the device's
own zone, convert `DateTime.now()` with `NepaliDate.fromGregorian`.

The tithi, public holidays and events are the separate
[`nepdate_patro`](https://pub.dev/packages/nepdate_patro) package.

The full reference is [`docs/API.md`](https://github.com/sanamhub/nepdate-dart/blob/main/docs/API.md),
and the repository is [sanamhub/nepdate-dart](https://github.com/sanamhub/nepdate-dart).

NepDate for Dart is a port of [NepDate](https://github.com/RajuPrasai/NepDate), the C# library by
Raju Prasai. The data and the behaviour follow it with the deliberate deviations in the hub's
`spec/PARITY.md`. MIT licensed; see `LICENSE` and `NOTICE`.
