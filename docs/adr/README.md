# Architecture decisions

| ADR | Decision |
|---|---|
| [0001](0001-workspace-and-toolchain.md) | One repository, two packages, a pub workspace and pure Dart |
| [0002](0002-dates-and-arithmetic.md) | Immutable dates, a serial day model, integer arithmetic and overflow modes |
| [0003](0003-errors-parsing-and-clock.md) | One error type, deterministic parsers, an injectable clock and explicit zones |
| [0004](0004-generated-tables-and-patro.md) | Tables generated from `shared/data`, core isolation and the patro layout |
| [0005](0005-serialization.md) | `toJson` and `fromJson` as the only serialization hook |
| [0006](0006-tests-and-quality-gates.md) | Vector tests, the C# catalogue, coverage, docs examples and the CI gate |
| [0007](0007-release-and-publishing.md) | One tag, two packages, pub.dev trusted publishing and a scheduled published check |
| [0008](0008-benchmarks-and-competitors.md) | The B1 to B8 harness and the competitor bar for pub.dev |
| [0009](0009-mutation-testing.md) | Mutation testing on a schedule, not on every pull request |
| [0010](0010-minimum-dart-sdk.md) | The development toolchain requires Dart 3.11 |

New decisions add the next number. A decision that changes a published behaviour also updates
`shared/spec` through the hub, never in this repository alone.
