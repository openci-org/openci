# CHANGELOG

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
