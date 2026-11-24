# Benchmarks

B1 to B8 of `shared/spec/BENCHMARK.md` on the machine and inputs the specification names, against
`nepali_utils` 3.0.8 from pub.dev.

The run is quiet: the machine was idle, the process was pinned to logical CPU 2 (affinity mask
`0x4`) and the load was sampled before and during the run. This table replaces the earlier
preliminary one, which was taken on a shared machine without pinning.

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
| Date of run | 2026-11-16 |
| Affinity | logical CPU 2 (mask `0x4`), set with `start /affinity 4 /wait /b` |
| Idle gate before the run | 6.7 percent average, 18.2 peak (30 one-second samples) |
| Load during the run | 10.0 percent average, 12.6 peak over 26 one-second samples; 4.3 and 7.0 on the CPUs other than CPU 2 |

The machine was idle: no other build, test suite or benchmark ran during the run, and the load during
the run includes the benchmark's own pinned core and the sampler. The raw output is in
[`raw/2026-11-16/bench.txt`](raw/2026-11-16/bench.txt) and the samples in
[`raw/2026-11-16/cpu-samples.txt`](raw/2026-11-16/cpu-samples.txt).

## Command

From the repository root:

```sh
dart pub get
dart compile exe bench/bin/bench.dart -o .dart_tool/bench.exe
start "" /affinity 4 /wait /b .dart_tool\bench.exe > docs\raw\2026-11-16\bench.txt
dart run bench/bin/agreement.dart
```

The harness divides the time of one pass over the 64 inputs by 64 and prints nanoseconds per
operation. The result of every operation is added to a global `sink`, so the compiler cannot remove
the work. The Dart VM has no per-operation allocation counter, so bytes per operation are not
measured and are not guessed.

## Results

Time is nanoseconds per single operation. B8 is one whole month grid of 29 to 32 days. "Agrees" is
how many of the 64 dates match `shared/data`.

The comparison with C# NepDate, the original library, and the target check from `spec/BENCHMARK.md` section 6 are in the hub: [performance page](https://nepdate.com/docs/project/performance/).

| ID | Operation | `nepdate` ns/op | bytes/op | `nepali_utils` ns/op | agrees |
|---|---|---:|---|---:|---|
| B1 | BS to AD | 51.55 | not measured | 23,556.34 | 61 of 64 |
| B2 | AD to BS | 38.50 | not measured | 56,007.51 | 31 of 64 |
| B3 | add 1000 days | 10.42 | not measured | not measured | |
| B4 | add 13 months, Clamp | 8.62 | not measured | not measured | |
| B5 | long format, Nepali, weekday | 154.65 | not measured | not measured | |
| B6 | strict parse `YYYY/MM/DD` | 33.66 | not measured | not measured | |
| B7 | patro info | 3.66 | not measured | not measured | |
| B8 | patro month grid | 291.19 | not measured | not measured | |

## Reading the table

- `nepali_utils` is about 460 times slower on B1 and 1,450 times slower on B2, and it disagrees with
  the shared data on 3 of 64 BS to AD dates and 33 of 64 AD to BS dates. A fast wrong answer is
  listed, never ranked first, so its two rows carry the agreement count and it is not ranked.
- B1 and B2 call `toDateTime` and `fromGregorian`, which cross the `DateTime` boundary. A date that
  stays in BS (B3, B4) does not allocate a `DateTime`.

The competitor's usage and maturity evidence, including the 1,000 downloads in 30 days floor, is in
[competitors.md](competitors.md). The decision is [ADR-0008](adr/0008-benchmarks-and-competitors.md).
