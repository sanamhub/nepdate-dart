# AGENTS.md: rules for automated contributors (Dart port)

You are working on a finished design. Follow it; do not redesign it. This port exists so Dart and
Flutter code gets the same dates, rules and data as every other NepDate port.

## 0. Before writing any code

1. Read `README.md`, this file, every ADR in `docs/adr/`, and `docs/API.md`.
2. Read the spec sections your change touches in `shared/spec/` (`API.md`, `ALGORITHM.md`,
   `FORMATTING.md`, `PARSING.md`, `PATRO.md`, `PARITY.md`).
3. Run `dart run tool/ci.dart` once before you change anything, so you know what green looks like.

## 1. Sources of truth (in priority order)

1. `shared/spec/*.md` and `shared/spec/vectors/*`: behaviour. Vectors win over prose (report the
   disagreement).
2. `docs/adr/*`: decisions. 3. `docs/API.md`: the public surface.

`shared/` is a read-only copy of the hub. **Never edit it.** Report a data or spec problem as a hub
issue. Never use the C# NepDate docs as a source (`shared/spec/PARITY.md` section 1).

## 2. Hard rules

- **Pure Dart, no dependencies, every platform.** The libraries import `dart:core` and
  `dart:collection` only: no `dart:io`, no `dart:ffi`, no `dart:html`, no package.
- **Dart `^3.6.0`.** Do not use a language feature newer than 3.6 (null-aware elements, dot
  shorthands, and the like). CI runs the oldest SDK to catch it.
- **Immutable values.** A date, a range, a fiscal year and a calendar answer never change after
  they are built, and an invalid date cannot be built (D-01).
- **One error type.** Calendar and parse failures throw `NepDateException` with an `ErrorKind`. A
  bad argument that has no calendar meaning throws `ArgumentError`.
- **Tables** come from `tool/generate.dart`. Do not edit `*.g.dart` by hand. No data is read at
  run time.
- **Core isolation:** the `nepdate` package holds no tithi, holiday or event data and does not
  import `nepdate_patro` (hub ADR-0004).
- **Parity:** tests skip a row only for a deviation in `shared/spec/PARITY.md`, with a comment
  naming the D number. Do not weaken or delete a test to make CI pass.
- **Every public member has a doc comment**, and every example in `docs/API.md` and in a doc
  comment marked with `// =>` runs in CI.
- **Dependencies, dev tools included,** are pinned and at least 14 days old
  (`dart run tool/check_dependency_age.dart`).
- No features outside the spec. Secrets never go in code, logs or commits.

## 3. How to work

- Test first, see it fail, then implement.
- Run `dart run tool/ci.dart` before saying you are done.
- Never claim a benchmark number you did not measure. Numbers from another machine say which.
- Pull request description: what changed and why, how it was tested, and 2 to 3 bullets on what to
  look at first.

## 4. Writing

Docs are plain prose, short sentences, no em dashes. A doc comment says what the member returns and
which `ErrorKind` it can throw. Commits and pull requests carry no generated attribution lines.
