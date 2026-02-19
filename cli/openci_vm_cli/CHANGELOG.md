# CHANGELOG

## 1.0.10

- Feature: Auto-save newly created distribution certificates to GCP Secret Manager
  - Certificates are automatically stored and reused on subsequent builds
  - Uses existing secret paths from worker CLI when available, falls back to creating new secrets
- Change: Rename certificate env vars with `OPENCI_` prefix (`OPENCI_DISTRIBUTION_CERTIFICATE_P12`, `OPENCI_DISTRIBUTION_CERTIFICATE_PASSWORD`, `OPENCI_DISTRIBUTION_CERTIFICATE_ID`)

## 1.0.9

- Fix: `android-deploy` fails with "Only releases with status draft may be created on draft app" error
  - Auto-fallback: when deploying to a draft app (never published), automatically retry with `status: draft` instead of failing
  - Re-creates edit session and re-uploads artifact on fallback
  - Shows a note guiding users to publish the release from Google Play Console

## 1.0.8

- Feature: `android-deploy` command to deploy AAB to Google Play Console
  - Upload AAB to any release track (internal, alpha, beta, production)
  - Google Play Developer API integration via service account authentication
  - Support service account JSON via `--service-account-json` flag or `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` environment variable
  - Optional release notes and release name support

## 1.0.7

- Fix: `exportArchive Failed to Use Accounts` error during IPA export
  - Pass ASC API key authentication to `xcodebuild -exportArchive` (`-authenticationKeyPath`, `-authenticationKeyID`, `-authenticationKeyIssuerID`)
  - Auto-detect existing `AuthKey_<keyId>.p8` in working directory before creating a new one
  - Support both raw PEM and base64-encoded `ASC_PRIVATE_KEY` environment variable
- Fix: Deprecated `app-store` method replaced with `app-store-connect` in ExportOptions.plist

## 1.0.6

- Fix: xcodebuild output flooding Firestore logs causing `Transport became inactive` gRPC error
  - Added `-quiet` flag to `xcodebuild archive` and `xcodebuild -exportArchive`
  - Build output is now written only to the local log file, not stdout

## 1.0.5

- Fix: `.p12` creation failing on LibreSSL (macOS default) with `unknown option '-legacy'`
  - Try without `-legacy` flag first (LibreSSL), fall back to with `-legacy` (OpenSSL 3.x)

## 1.0.4

- Fix: Disable Sentry dSYM auto-upload during archive to prevent build failure when `sentry-cli` is not authenticated

## 1.0.3

- Feature: Save full build output to a timestamped log file (`build/openci_ios_sign_<timestamp>.log`)
  - Captures stdout, stderr, and all command output to prevent log truncation
  - Log file path is displayed at build start

## 1.0.2

- Fix: Xcode picking up stale provisioning profiles instead of the newly created one
  - Delete old OpenCI provisioning profiles from local storage before installing new one
  - Pass `PROVISIONING_PROFILE` and `PROVISIONING_PROFILE_SPECIFIER` to `xcodebuild archive` to ensure correct profile is used
  - Set `PROVISIONING_PROFILE_SPECIFIER` to profile name (not UUID) in `project.pbxproj`

## 1.0.1

- Fix: `.p12` import failing on macOS with "MAC verification failed" error
  - Added `-legacy -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg SHA1` flags to `openssl pkcs12` for OpenSSL 3.x compatibility with macOS `security import`

## 1.0.0

- Initial release
- `ios-sign` command: Automate iOS code signing, building, and IPA export
  - App Store Connect API integration (JWT, certificates, provisioning profiles)
  - Automatic certificate creation via CSR + ASC API
  - Certificate caching support via environment variables
  - Temporary keychain management
  - Xcode project configuration for manual signing
  - Archive build and IPA export
