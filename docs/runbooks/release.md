# Release runbook

One tag releases both packages on the hub's lockstep line. The first release is `0.2.0-rc.1`; until
that tag the changelog has only an `Unreleased` section and nothing is published.

## Owner steps, in order

These are done once, before the first release. They need the repository and the pub.dev publisher.

1. Create the GitHub repository `sanamhub/nepdate-dart` with `main` as the default branch. The
   repository is public.
2. Push the hub branch `feat/nepdate-dart`. The port's `shared/VERSION` names its head, and
   `shared-check` downloads that commit from `sanamhub/nepdate`, so the branch must exist on GitHub
   even before it is merged for the first release.
3. Protect `main`: require a pull request, require the `ci` check, require one review, require
   conversation resolution, and disallow force pushes and deletion.
4. Create the `production` environment with a tag rule that accepts `v*` and a required reviewer.
   Only this environment can publish.
5. On pub.dev, verify the publisher `sanamhub` and add both packages to it. Enable automated
   publishing for `nepdate` and for `nepdate_patro` with the repository `sanamhub/nepdate-dart`,
   workflow `release.yml`, environment `production`, and the tag pattern `v{{version}}`. The
   `id-token: write` permission in the workflow only works after this step.
6. Add the `SYNC_APP_PRIVATE_KEY` secret for the shared-sync workflow. The app is the one the other
   ports use; its private key goes in the repository secret, never in a file.
7. Confirm the CodeQL setup. Dart is not a CodeQL language, so the workflow scans Actions only and
   `SECURITY.md` says so. Do not add a fake Dart CodeQL job.
8. Create the `published-check` label, which the scheduled verify job uses for its issue.

## Cutting a release

1. Bump the version in `packages/nepdate/pubspec.yaml` and `packages/nepdate_patro/pubspec.yaml`,
   and move the `Unreleased` entries under `## 0.2.0-rc.1` in `CHANGELOG.md` and in both package
   changelogs. The two versions must be equal, and pub.dev reads the package changelog.
2. Run the full gate locally: `dart run tool/ci.dart`.
3. Open a pull request, wait for `ci`, `shared-check` and `dependency-review`, and merge it.
4. Tag the merge commit and push the tag:

   ```sh
   git tag v0.2.0-rc.1
   git push origin v0.2.0-rc.1
   ```

5. `release.yml` runs the gates, checks the tag against both manifests and the changelog, builds the
   archives, uploads SHA-256 sums, and waits for the `production` environment. Approve it.
6. The publish job publishes `nepdate`, then `nepdate_patro`. It skips a version that pub.dev already
   serves, so a retried run is safe.
7. `verify-published.yml` runs on Linux, macOS and Windows after publishing. It installs the exact
   version from pub.dev in a clean project, runs a conversion, a parse and a patro lookup, and only
   then does the GitHub release appear.
8. Update the hub's `spec/versions.json` and `spec/packages.json` on the hub release branch, and the
   site's version table follows from them.

## Scheduled checks

`verify-published.yml` runs every Monday at 06:41 UTC to install the newest version on Linux, and
every day at 03:29 UTC to check that pub.dev still lists the version and serves both archives,
without downloading them. A failure opens or updates one issue labelled `published-check`. A green
run needs no action.

## If a release fails

- A gate failure: fix it on `main` and push a new tag. Never move a published tag.
- An already-published version: expected on a retry, the job prints a line and continues.
- OIDC failure: the publisher or the environment is not configured. Repeat owner step 4.
- A bad artifact after publishing: pub.dev does not allow deleting a version. Yank it on pub.dev,
  add a changelog entry, and publish the next patch.

## The first pull request

The first release is the tag flow above. A manual `dart pub publish` is never the first publish of
either package; the owner enables automated publishing first, and the tag pipeline does the rest.
