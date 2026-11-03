# 0007: one tag, two packages, pub.dev trusted publishing and a scheduled check

Status: accepted.

## Context

The two packages release together on one lockstep line (hub ADR-0004, hub ADR-0007). pub.dev can
publish from CI with OpenID Connect and does not accept a stored API token for a new package. The
GitHub repository does not exist yet; the owner creates it before the first release.

## Decision

- The version lives in both `pubspec.yaml` files and in the changelog, and one tag `vX.Y.Z` releases
  both. The manifests join the hub's `spec/versions.json` line.
- `release.yml` runs on a `v*` tag and on a manual dry run. It runs every gate, checks that the two
  manifests and the changelog agree with the tag, builds the two archives, and only then publishes.
  Publishing uses `dart pub publish` with `id-token: write` and the `production` environment, whose
  tag rule accepts `v*`. It publishes `nepdate` first and `nepdate_patro` second, and skips a package
  whose exact version is already on pub.dev, so a retried run is safe.
- The job attaches SHA-256 sums to the GitHub release for both archives, and the release notes come
  from the changelog, never from the commit log.
- `verify-published.yml` runs after the release, weekly on a schedule and by hand. It resolves
  `latest`, checks the pub.dev metadata with HEAD requests, then creates a clean project on Linux,
  macOS and Windows, installs the published packages, and runs one conversion, one parse and one
  patro lookup. A scheduled failure opens one issue labelled `published-check`.
- The runbook in `docs/runbooks/release.md` lists the owner steps in order: create the repository,
  protect `main`, create the `production` environment with its tag rule, enable automated publishing
  for both packages on pub.dev, and add the shared-sync app key. The first version is published
  only through this pipeline, after the owner has enabled it.
- `scripts/version.dart` reads and checks the version, `scripts/release_check.dart` compares the tag,
  the manifests and the changelog, and `scripts/verify_published.dart` is the installed check.

## Consequences

No long-lived registry token exists in the repository. A retried release does not fail on an
already-published version. The publish is gated on a green build and on a human approving the
`production` environment.
