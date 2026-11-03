# 0010: the development toolchain requires Dart 3.11

Status: accepted.

## Context

ADR-0001 set the workspace and both packages to Dart `^3.6.0` and made the oldest supported SDK a
CI gate. The dev dependencies have since moved: `lints` 6.1 requires Dart 3.8, `coverage` 1.16
requires 3.9, `benchmark_harness` 2.4 requires 3.10, and `test` 1.33 requires 3.11 through the
analyzer it resolves. A pub workspace resolves one set of dependencies, so the workspace cannot be
installed on an SDK older than the strictest dev dependency.

Bumping the packages themselves to 3.11 would also switch the formatter to the tall style, which
rewrites the generated calendar tables and the C# catalogue tests for reasons unrelated to this
change. It would also raise the requirement for users of both pub.dev packages, who never install
the dev toolchain.

## Decision

- The workspace root declares `sdk: ^3.11.0`, and `bench` declares `sdk: ^3.10.0` for
  `benchmark_harness` 2.4.
- `packages/nepdate` and `packages/nepdate_patro` keep `sdk: ^3.6.0`. Their language version stays
  3.6, so the analyzer rejects post-3.6 syntax and the published packages keep serving Dart 3.6.
- The oldest-SDK CI job runs 3.11.0, the oldest SDK that can resolve the workspace. The
  published-package check keeps installing on 3.6.2 and stable, so the published floor stays tested.

## Consequences

Contributors need Dart 3.11 or newer; users of either package still need 3.6. The root and bench
Dart files are formatted in the tall style that language version 3.11 selects; the package sources
and generated tables keep their existing format. Test 1.33 pulls analyzer 14.6 and
_fe_analyzer_shared 110, which were under the 14-day age gate when the lock was made, so the root
manifest overrides them to 14.5.0 and 109.0.0. Remove the two overrides on the next lock refresh
after 2026-11-03.
