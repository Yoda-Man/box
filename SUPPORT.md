# Support runbook

## Ownership and intake

- Code owner: `@Yoda-Man` (see `.github/CODEOWNERS`).
- General defects and support requests: GitHub Issues.
- Suspected vulnerabilities: follow `SECURITY.md`; do not disclose keys or
  stored values in a public issue.
- A release requires code-owner approval and a green CI run.

## Information to collect

Collect Boxx version, Flutter/Dart versions, platform and OS/browser version,
namespace name, encryption mode, exception type, diagnostic operation, stack
trace, and minimal reproduction. Never request encryption keys or record
contents.

## Failure triage

| Symptom | Likely cause | Response |
|---|---|---|
| `BoxxConfigurationException` | Missing/short key, empty key/name, incompatible options | Correct configuration before retrying. |
| `BoxxEncryptionException` | Wrong key, tampering, or damaged ciphertext | Stop writes, verify key provenance, restore backup or roll back key rotation. |
| `BoxxCorruptDataException` | Truncated/unknown record or mode mismatch | Preserve the backing store, reproduce on a copy, and restore or migrate. |
| `BoxxStorageException` | Permissions, quota, filesystem, or IndexedDB failure | Inspect the wrapped cause and platform capacity/permissions. |
| `BoxxTypeMismatchException` | Caller requested the wrong type or encountered ambiguous legacy data | Correct the requested type or run application-specific migration validation. |
| `BoxxDisposedException` | Lifecycle error | Stop using the disposed instance and construct a new one. |

## Recovery procedure

1. Stop application writes to the affected namespace.
2. Preserve a copy of the application documents `boxx/` directory or browser
   IndexedDB database before attempting repair.
3. Confirm the current and legacy encryption settings without copying keys into
   tickets or logs.
4. Reproduce against the preserved copy with the same package version.
5. For pre-0.3.0 data, configure `legacyMode` and `legacyEncryptionKey`, read and
   validate every known application key explicitly, then back up the migrated
   store. Legacy keys are not enumerated because old filenames are lossy.
6. If authentication fails, do not bypass it. Restore a known-good backup or
   correct the key.

`clear()` is destructive and has no undo. It must not be used as a diagnostic
step unless the user has explicitly accepted data loss.

## Monitoring integration

Production applications should connect `diagnostics` to their error-reporting
system and alert on repeated `initialize`, `put`, `get`, or `clear` failures.
Record package/app versions and platform metadata, but exclude namespace keys,
encryption keys, and values. A sudden increase in encryption or corruption
errors is an incident and should freeze releases and key rotation.

## Compatibility boundaries

- Values must be JSON-encodable.
- Native stream events cover writes in the current Dart isolate.
- Web stream events additionally cover same-origin tabs with BroadcastChannel.
- External native process changes are observed on the next read, not as events.
- Legacy type ambiguity cannot be reversed automatically.
