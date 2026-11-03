# 0008: the B1 to B8 harness and the competitor bar for pub.dev

Status: accepted.

## Context

`shared/spec/BENCHMARK.md` fixes the operations, the 64 inputs and the measurement rules, but its
usage table covers other registries, not pub.dev. Dart is a later port. The rule is that a
competitor is a Bikram Sambat library people use, old and maintained enough to be fair.

## Decision

- Operations B1 to B8 are implemented in `bench/bin/bench.dart` with `package:benchmark_harness`.
  Each `run()` passes over all 64 inputs; the report divides by 64 and prints nanoseconds per
  operation. Warmup is the harness's own. The Dart VM has no per-operation allocation counter, so
  the bytes column says "not measured".
- The 64 dates are the serial formula of section 2. B7 and B8 use the same formula over the patro
  coverage.
- The pub.dev usage measure is `downloadCount30Days` from the package score endpoint, with a floor
  of 1,000 in the last 30 days. The other bars are section 7: first release at least 12 months ago,
  a release or commit in the last 36 months, a licence, not archived, and it builds on the current
  toolchain. The floor is fixed here before the candidates are ranked.
- `bench/bin/agreement.dart` compares the selected competitor's B1 and B2 answers with
  `shared/data` on the same 64 dates. The count goes in the report and a wrong answer is never
  ranked first.
- `docs/competitors.md` lists every candidate found, its usage on the date it was read, the bar it
  fails, and whether it was selected. `docs/benchmarks.md` holds the table and says the numbers are
  preliminary while the machine is shared.

## Consequences

One mature competitor passes the bar, so the table has one competitor row, not three filled with
libraries that fail it. A later release can add a library if its usage grows past the fixed floor.
