# Security policy

## Supported versions

Only the latest release receives fixes.

## Reporting a vulnerability

Report privately through
[GitHub security advisories](https://github.com/sanamhub/nepdate-dart/security/advisories/new).
Do not open a public issue.

Include the input that triggers it, the Dart version, the platform and the package version. Expect
a first reply within a week.

A wrong calendar result, where nepdate-dart and the shared data give the same wrong answer, belongs
to the hub: [sanamhub/nepdate security policy](https://github.com/sanamhub/nepdate/security/policy).

## Code scanning

The workflows are scanned with CodeQL. CodeQL does not support Dart, so the library code is not
scanned by it. The library has no dependencies, does no input or output and uses no native code, so
what stands in for CodeQL is `dart analyze` with the strict language modes, the shared test vectors
and the scheduled mutation run described in
[docs/adr/0006-tests-and-quality-gates.md](docs/adr/0006-tests-and-quality-gates.md).
