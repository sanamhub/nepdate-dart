# Benchmarks

B1 to B8 of `shared/spec/BENCHMARK.md` on the machine and inputs the specification names, against
`nepali_utils` 3.0.8 from pub.dev and the C# NepDate 2.0.7 baseline from the hub.

**These numbers are preliminary.** The machine was shared with other work when they were taken and
the process was not pinned to one performance core. The quiet rerun pins logical CPU 2 (affinity
mask `0x4`) and replaces this table. Claim only what the table shows.

## Machine and versions

| Item | Value |
|---|---|
| CPU | 12th Gen Intel Core i5-12500H (4 performance + 8 efficiency cores, 16 threads, base 3.1 GHz) |
| RAM | 31.7 GB |
| OS | Windows 11 Home 10.0.26300 |
| Power plan | Ultimate Performance, on AC |
| Dart SDK | 3.13.7 stable, AOT executable from `dart compile exe` |
| Harness | `benchmark_harness` 2.3.1, `warmup` and `exercise` overridden to time one pass over 64 inputs |
| Competitor | `nepali_utils` 3.0.8 (the one package that passes the bar in [competitors.md](competitors.md)) |
| C# column | .NET 10 column of the hub's `docs/benchmarks/dotnet.md`, same machine, BenchmarkDotNet |
| Date of run | 2026-11-03 |
| Affinity | not pinned: this is why the table is preliminary |

## Command

From the repository root:

```sh
dart pub get
dart compile exe bench/bin/bench.dart -o .dart_tool/bench.exe
.dart_tool/bench.exe
dart run bench/bin/agreement.dart
```

The harness divides the time of one pass over the 64 inputs by 64 and prints nanoseconds per
operation. The result of every operation is added to a global `sink`, so the compiler cannot remove
the work. The Dart VM has no per-operation allocation counter, so bytes per operation are not
measured and are not guessed.

## Results

Time is nanoseconds per single operation. B8 is one whole month grid of 29 to 32 days. "Agrees" is
how many of the 64 dates match `shared/data`.

| ID | Operation | `nepdate` ns/op | bytes/op | `nepali_utils` ns/op | agrees | C# NepDate ns/op |
|---|---|---:|---|---:|---|---:|
| B1 | BS to AD | 67.37 | not measured | 33,526.70 | 61 of 64 | 13.50 |
| B2 | AD to BS | 121.59 | not measured | 79,675.04 | 31 of 64 | 20.10 |
| B3 | add 1000 days | 19.35 | not measured | not measured | | 19.05 |
| B4 | add 13 months, Clamp | 17.11 | not measured | not measured | | 20.19 |
| B5 | long format, Nepali, weekday | 854.73 | not measured | not measured | | 150.41 |
| B6 | strict parse `YYYY/MM/DD` | 102.36 | not measured | not measured | | 22.42 |
| B7 | patro info | 42.48 | not measured | not measured | | 48.21 |
| B8 | patro month grid | 1,698.46 | not measured | not measured | | 3,112.76 |

## Reading the table

- `nepali_utils` is about 500 times slower on B1 and 655 times slower on B2, and it disagrees with
  the shared data on 3 of 64 BS to AD dates and 33 of 64 AD to BS dates. A fast wrong answer is
  listed, never ranked first, so its two rows carry the agreement count and it is not ranked.
- The core operations B1 to B4 are within about 5 times the C# numbers on this preliminary run, and
  B7 is faster. B5, B6 and B8 are behind C#, which builds and formats strings with a mature BCL;
  the Dart implementation allocates a `StringBuffer` for B5 and `info` objects for B8.
- B1 and B2 call `toDateTime` and `fromGregorian`, which cross the `DateTime` boundary. A date that
  stays in BS (B3, B4) does not allocate a `DateTime`.
- The numbers are not a target table: `shared/spec/BENCHMARK.md` section 6 has no Dart row. The
  rerun reports the same operations and the same competitor, and no feature is dropped for a
  number.

The competitor's usage and maturity evidence, including the 1,000 downloads in 30 days floor, is in
[competitors.md](competitors.md). The decision is [ADR-0008](adr/0008-benchmarks-and-competitors.md).
