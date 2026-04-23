# openci_vm_cli

[![pub package](https://img.shields.io/pub/v/openci_vm_cli.svg)](https://pub.dev/packages/openci_vm_cli)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

CLI tool that runs inside [OpenCI](https://openci.org) VMs to handle iOS code signing, building, and exporting IPAs.

Part of the [OpenCI](https://github.com/openci-org/openci) open-source CI/CD platform.

## Installation

```bash
dart pub global activate openci_vm_cli
```

## Commands

### `ios-sign`

Automates the entire iOS code signing and build process:

1. Generates App Store Connect JWT
2. Creates or reuses a Distribution certificate
3. Creates a Provisioning Profile
4. Sets up a temporary Keychain
5. Imports the certificate
6. Installs the Provisioning Profile
7. Configures Xcode project for manual signing
8. Generates `ExportOptions.plist`
9. Builds an `.xcarchive`
10. Exports an `.ipa`

#### Usage

```bash
openci_vm ios-sign \
  --bundle-id "com.example.app" \
  --apple-team-id "ABCD1234EF" \
  --scheme "Runner" \
  --workspace "ios/Runner.xcworkspace" \
  --xcodeproj "ios/Runner.xcodeproj"
```

#### Required Environment Variables

| Variable          | Description                                    |
| ----------------- | ---------------------------------------------- |
| `ASC_KEY_ID`      | App Store Connect API Key ID                   |
| `ASC_ISSUER_ID`   | App Store Connect Issuer ID                    |
| `ASC_PRIVATE_KEY` | App Store Connect API Private Key (PEM format) |

#### Optional Environment Variables (Certificate Caching)

| Variable                            | Description                         |
| ----------------------------------- | ----------------------------------- |
| `DISTRIBUTION_CERTIFICATE_P12`      | Base64-encoded `.p12` certificate   |
| `DISTRIBUTION_CERTIFICATE_ID`       | ASC certificate ID                  |
| `DISTRIBUTION_CERTIFICATE_PASSWORD` | `.p12` password (default: `openci`) |

#### Options

| Option                | Required | Description                                    |
| --------------------- | -------- | ---------------------------------------------- |
| `--bundle-id`         | ✅       | iOS Bundle Identifier (e.g. `com.example.app`) |
| `--apple-team-id`     | ✅       | Apple Developer Team ID                        |
| `--scheme`            | ✅       | Xcode scheme name                              |
| `--workspace`         | ✅       | Path to `.xcworkspace`                         |
| `--xcodeproj`         | ✅       | Path to `.xcodeproj`                           |
| `--working-directory` | ❌       | Working directory (default: `.`)               |

## Requirements

- macOS with Xcode installed
- `openssl` (pre-installed on macOS)
- App Store Connect API key with appropriate permissions

## License

Apache License 2.0 — see [LICENSE](LICENSE) for details.
