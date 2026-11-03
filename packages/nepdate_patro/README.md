<p align="center">
  <img src="https://raw.githubusercontent.com/sanamhub/nepdate-dart/main/docs/assets/nepdate-dart-128.png" width="128" alt="NepDate for Dart logo">
</p>

<h1 align="center">nepdate_patro</h1>

The Nepali patro for Dart and Flutter: tithi, public holidays and events for every Bikram Sambat day
from 2077-01-01 to 2084-08-20. It depends on [`nepdate`](https://pub.dev/packages/nepdate) for the
date type; the core package has none of this data. Pure Dart, every platform including the web.

Part of the NepDate family: the shared data and spec live in the hub
[`sanamhub/nepdate`](https://github.com/sanamhub/nepdate); the C# original is
[NepDate](https://github.com/RajuPrasai/NepDate).

> **Status:** 0.2.0-rc.1 is the first release. The API may still change before 0.2.0. The patro
> data is informational, not an official calendar.

## Install

```sh
dart pub add nepdate nepdate_patro
```

In a Flutter app, use `flutter pub add nepdate nepdate_patro`.

## Example

```dart
import 'package:nepdate/nepdate.dart';
import 'package:nepdate_patro/nepdate_patro.dart';

final day = info(NepaliDate.fromBs(2081, 2, 15));
day.isPublicHoliday; // => true
day.tithi?.english; // => Panchami
day.events.single.english; // => Republic Day
coverage().start.toString(); // => 2077/01/01
publicHolidays().length; // => 294
```

`info` never throws: a day without data, and any day outside the coverage, gets an empty
`CalendarInfo`. The data is compiled into constant tables, so nothing is read or parsed at run time.

## More

| Topic | Where |
|---|---|
| Every API group, with examples | [README](https://github.com/sanamhub/nepdate-dart#readme) |
| Every public type and member | [docs/API.md](https://github.com/sanamhub/nepdate-dart/blob/main/docs/API.md) |
| What changed in each version | [CHANGELOG.md](https://github.com/sanamhub/nepdate-dart/blob/main/CHANGELOG.md) |
| The repository | [sanamhub/nepdate-dart](https://github.com/sanamhub/nepdate-dart) |
| A wrong date, holiday or tithi | the hub's [data error form](https://github.com/sanamhub/nepdate/issues/new/choose) |

## License

MIT, see `LICENSE`. The data comes from [NepDate](https://github.com/RajuPrasai/NepDate) by Raju
Prasai and contributors under the MIT License, see `NOTICE`. Not affiliated with the Government of
Nepal.
