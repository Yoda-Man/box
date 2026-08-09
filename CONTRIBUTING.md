# Contributing

Run the same gates used by CI before opening a change:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/box_native_test.dart
flutter test --platform chrome test/box_web_test.dart
flutter pub publish --dry-run
```

Every storage-format, encryption, key-mapping, lifecycle, or platform change
must include a restart-based regression test. Tests must read from a new Boxx
instance so they exercise persisted data rather than in-memory state.
