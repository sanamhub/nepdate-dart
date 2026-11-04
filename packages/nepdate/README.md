<p align="center">
  <img src="https://raw.githubusercontent.com/sanamhub/nepdate-dart/main/docs/assets/nepdate-dart-128.png" width="128" alt="NepDate for Dart logo">
</p>

<h1 align="center">nepdate</h1>

Bikram Sambat (the Nepali calendar) dates for Dart and Flutter: conversion to and from Gregorian,
arithmetic, formatting, parsing, ranges and fiscal years. Pure Dart, no dependencies, every platform
including the web. BS 1901-01-01 to 2199-12-30 (AD 1844-04-11 to 2143-04-15).

Part of the NepDate family: the shared data and spec live in the hub
[`sanamhub/nepdate`](https://github.com/sanamhub/nepdate); the C# original is
[NepDate](https://github.com/RajuPrasai/NepDate).

> **Status:** 1.0.0-rc.1 is the release candidate on the 1.0 line. The API is stable from 1.0 (hub
> ADR-0009).

## Install

```sh
dart pub add nepdate
```

In a Flutter app, use `flutter pub add nepdate`.

## Example

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

## More

| Topic | Where |
|---|---|
| Every API group, with examples | [README](https://github.com/sanamhub/nepdate-dart#readme) |
| Every public type and member | [docs/API.md](https://github.com/sanamhub/nepdate-dart/blob/main/docs/API.md) |
| What changed in each version | [CHANGELOG.md](https://github.com/sanamhub/nepdate-dart/blob/main/CHANGELOG.md) |
| The repository | [sanamhub/nepdate-dart](https://github.com/sanamhub/nepdate-dart) |
| A wrong date, holiday or tithi | the hub's [data error form](https://github.com/sanamhub/nepdate/issues/new/choose) |

## License

MIT, see `LICENSE`. NepDate for Dart is a port of
[NepDate](https://github.com/RajuPrasai/NepDate), the C# library by Raju Prasai and contributors;
the calendar data comes from it under the MIT License, see `NOTICE`. Not affiliated with the
Government of Nepal.
