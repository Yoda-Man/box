# Dependency policy and inventory

Boxx is a library, so consumer applications resolve the final transitive graph.
Each release CI run preserves its generated `pubspec.lock` as a short-lived
artifact and scans it with OSV-Scanner. Dependabot checks the Pub ecosystem
weekly.

## Direct runtime dependencies

| Package | Purpose | License |
|---|---|---|
| `crypto` | SHA-256 storage identifiers | BSD-3-Clause |
| `encrypt` | Fernet and legacy AES compatibility | BSD-3-Clause |
| `idb_shim` | IndexedDB access | BSD-2-Clause |
| `path` | Cross-platform path construction | BSD-3-Clause |
| `path_provider` | Application storage location | BSD-3-Clause |
| `pointycastle` | PBKDF2 and authenticated AES-GCM | BSD-3-Clause |
| `web` | Browser BroadcastChannel interoperability | BSD-3-Clause |

Before release, maintainers must review the resolved graph, OSV result,
publisher changes, package retractions, and license changes. Major dependency
upgrades require the full native/browser matrix and storage compatibility tests.
No dependency with an unknown, copyleft-incompatible, or non-redistributable
license may be introduced without an explicit legal review.
