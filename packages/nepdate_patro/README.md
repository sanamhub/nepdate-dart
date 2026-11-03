# nepdate_patro

The Nepali patro for Dart and Flutter: tithi, public holidays and events for every Bikram Sambat day
from 2077-01-01 to 2084-08-20. It depends on [`nepdate`](https://pub.dev/packages/nepdate) for the
date type; the core package has none of this data. Pure Dart, every platform including the web.

```sh
dart pub add nepdate_patro
```

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

The full reference is [`docs/API.md`](https://github.com/sanamhub/nepdate-dart/blob/main/docs/API.md),
and the repository is [sanamhub/nepdate-dart](https://github.com/sanamhub/nepdate-dart).

The data comes from [NepDate](https://github.com/RajuPrasai/NepDate) by Raju Prasai. MIT licensed;
see `LICENSE` and `NOTICE`.
