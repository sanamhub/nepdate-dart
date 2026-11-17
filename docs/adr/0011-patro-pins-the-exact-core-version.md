# 0011: the patro requires exactly the same core version

Status: accepted.

## Context

`nepdate` and `nepdate_patro` are released together under one version, and the patro reads internals
of the core that are not part of the public API. The patro used the caret constraint
`^1.0.0-rc.1`, which accepts any later 1.x core. A newer core could then run against an older patro,
a pair that was never tested. The other SDKs pin their patro package to the exact core version.

## Decision

- `nepdate_patro` depends on `nepdate: X.Y.Z`, an exact version constraint, for example
  `nepdate: 1.0.0-rc.1`. The pub workspace resolves it to the local package during development.
- `scripts/version.dart` fails when that constraint differs from the version of the two packages.
  The CI `version` job and the release workflow run it, so a version bump that misses the patro
  constraint fails before it merges and again before it publishes.

## Consequences

- A version bump changes both `version:` lines and the patro constraint in one commit.
- An app that upgrades `nepdate` must upgrade `nepdate_patro` to the same version. pub reports the
  conflict.
