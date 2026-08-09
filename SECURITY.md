# Security policy

## Supported versions

Security fixes are provided for the latest published minor release. Versions
before 0.3.0 use unauthenticated or fail-open storage behavior and should be
migrated.

## Reporting

Report vulnerabilities privately through the repository's GitHub Security
Advisories. Do not open a public issue containing keys, ciphertext, file paths,
or user data. Include the affected version, platform, impact, and a minimal
reproduction using synthetic data.

## Key-management requirements

- Generate at least 32 bytes of high-entropy random key material.
- Store it in platform-backed secure storage.
- Never commit, log, transmit in support tickets, or bundle the key in the app.
- Back up keys under the application's recovery policy before rotation.
- Use the explicit legacy settings during rotation and validate all migrated
  records before retiring the previous key.
