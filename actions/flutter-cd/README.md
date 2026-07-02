# Flutter CD

Build and deploy Flutter applications.

Zero external dependencies — uses only standard macOS tools (`openssl`, `curl`, `security`, `xcodebuild`, `python3`).

This action is maintained in the OpenCI monorepo. Workflows in this repository should reference it with `uses: ./actions/flutter-cd`.

From another public repository, use the subdirectory action path and pin an
OpenCI commit SHA:

```yaml
- uses: openci-org/openci/actions/flutter-cd@<commit-sha>
  with:
    platform: "macos"
    working-directory: "apps/dashboard"
```

## Usage

### Web — Production Deploy

```yaml
- uses: ./actions/flutter-cd
  with:
    platform: "web"
    working-directory: "apps/dashboard"
    firebase-service-account: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
```

### Web — Preview Deploy (for PRs)

```yaml
- uses: ./actions/flutter-cd
  with:
    platform: "web"
    working-directory: "apps/dashboard"
    firebase-service-account: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
    preview: "true"
```

### iOS — Build & Upload to TestFlight with Beta Distribution

```yaml
- uses: ./actions/flutter-cd
  with:
    platform: "ios"
    working-directory: "apps/dashboard"
    swift-package-manager: "enabled"
    certificate-private-key: ${{ secrets.OPENCI_CERTIFICATE_PRIVATE_KEY }}
    asc-key-id: ${{ secrets.ASC_KEY_ID }}
    asc-issuer-id: ${{ secrets.ASC_ISSUER_ID }}
    asc-private-key: ${{ secrets.ASC_PRIVATE_KEY }}
    testflight-beta-group-names: "App Store Connect ユーザ"
    testflight-max-wait-minutes: "20"
```

### iOS — Build for Firebase App Distribution

```yaml
- uses: ./actions/flutter-cd
  id: ios-build
  with:
    platform: "ios"
    working-directory: "apps/dashboard"
    swift-package-manager: "enabled"
    distribution-method: "ad-hoc"
    certificate-private-key: ${{ secrets.OPENCI_CERTIFICATE_PRIVATE_KEY }}
    asc-key-id: ${{ secrets.ASC_KEY_ID }}
    asc-issuer-id: ${{ secrets.ASC_ISSUER_ID }}
    asc-private-key: ${{ secrets.ASC_PRIVATE_KEY }}
```

### macOS — Build, Sign & Notarize

```yaml
- uses: ./actions/flutter-cd
  with:
    platform: "macos"
    working-directory: "apps/dashboard"
    swift-package-manager: "enabled"
    certificate-private-key: ${{ secrets.OPENCI_DEVELOPER_ID_PRIVATE_KEY }}
    asc-key-id: ${{ secrets.ASC_KEY_ID }}
    asc-issuer-id: ${{ secrets.ASC_ISSUER_ID }}
    asc-private-key: ${{ secrets.ASC_PRIVATE_KEY }}
    developer-id-certificate-p12: ${{ secrets.DEVELOPER_ID_CERTIFICATE_P12 }}
    developer-id-certificate-password: ${{ secrets.DEVELOPER_ID_CERTIFICATE_PASSWORD }}
    macos-provisioning-profile: "true"
    build-args: "--dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }}"
    artifact-name: "OpenCI-dashboard-macos"
```

## Inputs

| Input                                    | Description                                                                                                                                                                                                         | Required | Default                             |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ----------------------------------- |
| `platform`                               | Target platform (`web`, `ios`, `macos`)                                                                                                                                                                             | Yes      | -                                   |
| `working-directory`                      | Flutter project directory                                                                                                                                                                                           | No       | `.`                                 |
| `build-args`                             | Additional arguments for `flutter build`                                                                                                                                                                            | No       | `""`                                |
| `swift-package-manager`                  | Flutter Swift Package Manager mode for Apple builds: `inherit`, `enabled`, or `disabled`. `inherit` leaves the current Flutter setting unchanged. `auto`, `true`, and `false` are accepted as aliases. (ios, macos) | No       | `"inherit"`                         |
| `patch-flutter-ios-distribution-signing` | Patch Flutter issue `#176636` so iOS builds can use Apple Distribution certificates when Flutter falls back to identity discovery (ios)                                                                             | No       | `"true"`                            |
| `firebase-service-account`               | GCP service account JSON for Firebase deploy (web)                                                                                                                                                                  | No       | `""`                                |
| `preview`                                | Deploy to Firebase Hosting preview channel (web)                                                                                                                                                                    | No       | `"false"`                           |
| `certificate-private-key`                | RSA private key PEM used to create/reuse signing certificates (ios, macos)                                                                                                                                          | No       | `""`                                |
| `asc-key-id`                             | App Store Connect API Key ID (ios, macos)                                                                                                                                                                           | No       | `""`                                |
| `asc-issuer-id`                          | App Store Connect API Issuer ID (ios, macos)                                                                                                                                                                        | No       | `""`                                |
| `asc-private-key`                        | ASC API Private Key content, .p8 PEM (ios, macos)                                                                                                                                                                   | No       | `""`                                |
| `developer-id-certificate-p12`           | Base64-encoded Developer ID Application `.p12` certificate to import directly (macos)                                                                                                                               | No       | `""`                                |
| `developer-id-certificate-password`      | Password for `developer-id-certificate-p12` (macos)                                                                                                                                                                 | No       | `""`                                |
| `scheme`                                 | Xcode scheme name (ios)                                                                                                                                                                                             | No       | `"Runner"`                          |
| `build-number`                           | Override the build number from pubspec.yaml (ios, macos)                                                                                                                                                            | No       | `""`                                |
| `distribution-method`                    | iOS export method (`app-store`, `ad-hoc`)                                                                                                                                                                           | No       | `"app-store"`                       |
| `upload-to-app-store-connect`            | Upload the generated iOS IPA to App Store Connect; defaults to true for `app-store` and false for `ad-hoc`                                                                                                          | No       | `""`                                |
| `testflight-beta-group-names`            | Comma-separated list of TestFlight beta group names to distribute the build to (ios)                                                                                                                                | No       | `""`                                |
| `testflight-max-wait-minutes`            | Maximum number of minutes to wait for the build to finish processing before distributing to beta groups. Set to 0 to skip waiting and distribution. (ios)                                                         | No       | `"20"`                              |
| `macos-app-path`                         | Path to the built `.app`, relative to `working-directory`; auto-detected when omitted (macos)                                                                                                                       | No       | `""`                                |
| `macos-entitlements-path`                | Path to the macOS entitlements plist, relative to `working-directory` (macos)                                                                                                                                       | No       | `macos/Runner/Release.entitlements` |
| `macos-provisioning-profile`             | Create and embed a `MAC_APP_DIRECT` provisioning profile and sign with profile-derived entitlements. Use this for Developer ID apps that need capabilities such as Keychain Sharing (macos)                         | No       | `"false"`                           |
| `artifact-name`                          | Base name for the packaged artifact zip (macos)                                                                                                                                                                     | No       | `.app` name + `-macos`              |
| `output-directory`                       | Directory for packaged artifacts, relative to `working-directory` (macos)                                                                                                                                           | No       | `build/openci-artifacts`            |

## What it does

### Web (`platform: web`)

1. Builds the Flutter web app (`flutter build web`)
2. Finds `firebase.json` in the repository
3. Copies build output to the Firebase public directory
4. Installs `firebase-tools` if not available (auto-installs Node.js if needed)
5. Deploys to Firebase Hosting (live or preview channel)

### iOS (`platform: ios`)

1. Handles code signing entirely via shell scripts (no external CLI dependencies):
   - **JWT**: Generates an ASC API token using `openssl`
   - **Certificate**: Creates a Distribution certificate via ASC API (CSR → certificate), or validates and reuses an existing one
   - **Provisioning Profile**: Creates an App Store provisioning profile via ASC API
   - **Keychain**: Sets up a temporary keychain and imports the certificate
   - **Flutter Tool Patch**: Applies a temporary Flutter issue `#176636` workaround unless `patch-flutter-ios-distribution-signing` is `false`
   - **Xcode Config**: Modifies `project.pbxproj` for manual signing
2. Optionally sets Flutter's Swift Package Manager mode when `swift-package-manager` is `enabled` or `disabled`, then runs `flutter pub get`
3. Runs `flutter build ipa` and exports the IPA
4. Exposes the generated IPA via `ipa-path` and `artifact-directory` outputs
5. Uploads to App Store Connect by default for `app-store` distribution
6. Cleans up temporary keychain and credentials

### macOS (`platform: macos`)

1. Imports a provided Developer ID Application `.p12`, or creates/reuses one via App Store Connect when only `certificate-private-key` is provided
2. Imports the certificate into a temporary keychain
3. Optionally sets Flutter's Swift Package Manager mode when `swift-package-manager` is `enabled` or `disabled`, then runs `flutter pub get`
4. Runs `flutter build macos --release`
5. When `macos-provisioning-profile` is `true`, creates a `MAC_APP_DIRECT` provisioning profile, embeds it into the `.app`, and signs with the profile's entitlements
6. Signs nested macOS code without app entitlements, then signs the top-level `.app` with hardened runtime and the app entitlements
7. Packages the `.app` with `ditto`, submits it to Apple's notary service, and staples the ticket
8. Writes the final notarized zip to `output-directory` and exposes `artifact-path`

## License

MIT
