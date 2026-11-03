# 0009: mutation testing on a schedule

Status: accepted.

## Context

Line coverage says a line ran, not that a wrong answer would be caught. A mutation run is slow: every
mutant runs the whole test suite, and the calendar arithmetic has roughly 800 mutation points. That
is not a pull-request gate.

## Decision

- `mutation_test` 1.7.1 runs in `mutation.yml` on a weekly schedule and by hand, never on every pull
  request. The configuration is `mutation.xml`: the eight hand-written library files, the comment
  exclusion, the command `dart test packages/nepdate packages/nepdate_patro`, and a failure
  threshold of 50 percent.
- The generated tables are not mutated. They are data, and mutating a constant only produces a
  failure without saying anything about the tests.
- The workflow writes the workspace lcov file first, so the tool skips lines the tests never reach,
  and keeps the HTML report as an artifact for 30 days.
- `docs/mutation/floor.json` records the measured score and the date it was read. A survivor that
  cannot be killed is explained in `docs/mutation/equivalent.md` before the threshold moves.
- The tool is a pinned workspace dev dependency, at least 14 days old when the lock is made, like
  every other dev tool.

## Consequences

A pull request stays fast, and the weekly signal still catches a test that asserts too little. The
first run fills in `floor.json`; until then the file says the score is not measured yet.
