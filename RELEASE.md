# Release and rollback procedure

## Release

1. Confirm the working tree is clean and CI passes analysis, native tests,
   browser tests, coverage, OSV advisory scanning, and publish validation.
2. Review dependency changes, publishers, OSV results, and licenses against
   `DEPENDENCIES.md`.
3. Update `pubspec.yaml`, `CHANGELOG.md`, compatibility notes, and migration
   guidance together.
4. Run `flutter pub publish --dry-run` locally.
5. Obtain code-owner approval.
6. Tag the reviewed commit as `vX.Y.Z` and publish that exact commit with
   `flutter pub publish`.
7. Verify the pub.dev package, documentation, and a clean consumer install.

## Rollback

Published pub.dev archives are immutable. If a release is unsafe:

1. Stop promotion and notify maintainers/support.
2. Retract the affected version on pub.dev when appropriate.
3. Restore the last known-good source, apply any forward-compatible data-format
   fix, and publish a new patch version. Do not reuse a version number.
4. Publish migration or recovery instructions before asking consumers to
   upgrade or downgrade.
5. Preserve affected stores and encryption keys; never advise `clear()` as a
   rollback.

Storage format or encryption changes require a migration test from the previous
published version and must be called out as breaking when data cannot round-trip.
