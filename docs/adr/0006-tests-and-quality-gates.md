# 0006: vector tests, the C# catalogue, coverage, docs examples and the CI gate

Status: accepted.

## Context

The hub ships golden vectors recorded from C# NepDate 2.0.7, reference vectors derived from the
data, and a catalogue of every C# test method. A port that tests only its own examples can pass
while disagreeing on a boundary. The repository also needs one command that runs every gate, so a
green local run means what a green CI run means.

## Decision

- The test suite reads every file under `shared/spec/vectors` that applies to the port. A comment
  line is skipped, a `D-xx` note is handled by an explicit filter with a comment naming the
  decision, and `ERR` rows assert the error kind or the refusal. The shared readers live in
  `packages/nepdate/test/support`.
- The C# catalogue is covered by a test named after each `catalog.tsv` id (phases 1 to 4, including
  the D-14 clock rows). A row this API does not have is a skip naming the deviation. A helper fails
  when a phase row has no case or a case has no row, so the two cannot drift.
- `dart run tool/ci.dart` runs these gates in order: `dart format --set-exit-if-changed`,
  `dart analyze --fatal-infos`, `generate --check`, both test suites, line coverage of both
  packages with a 90% floor, dependency age, the docs examples, and core isolation. The last line
  is the summary.
- Examples in the README, `docs/API.md` and every doc comment marked with `// =>` are compiled and
  run by `tool/check_docs.dart`. The prose is checked for em dashes and dangling relative links at
  the same time. `public_member_api_docs` is an analyzer error, so a public member without a doc
  comment fails analysis.
- Formatting is `dart format` at a 100-column page width. Generated files are formatted after
  generation.
- Coverage, not a hard-coded test count, is the quantity gate: it fails below 90% of executable
  lines in either package.

## Consequences

A behaviour change shows up as a vector failure before it reaches a user. The catalogue keeps the
C# suite's intent visible. The docs cannot rot into examples that no longer compile. The one command
is slower than a single test run, which is the cost of making a green run trustworthy.
