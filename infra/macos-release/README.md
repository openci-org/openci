# OpenCI macOS releases

The `Dashboard macOS CD` OpenCI workflow runs on matching pushes to `develop`.
It uses Flutter 3.47.8 on a disposable macOS VM. PRs never publish releases.
The app's existing target requires macOS 26 or later; the generated appcast
records the built app's minimum OS requirement.
The `macOS release checks` workflow runs the tests and an unsigned build on PRs
without accessing Apple signing or Storage publishing credentials.

## Storage

Terraform in this directory manages the dedicated `openci-b1b91-releases`
bucket in `asia-northeast1`, its public read permission, and a publisher service
account with object administration on this bucket only. The bucket uses uniform
access and seven-day soft delete, and cannot be destroyed through Terraform.
State is stored under the separate `macos-release/production` prefix in the
existing private Terraform state bucket. Credentials never enter Terraform state.

The stable feed is:

https://storage.googleapis.com/openci-b1b91-releases/macos/stable/appcast.xml

Archives have immutable names under `macos/stable/releases/<run-number>/`.
The feed has `no-cache` metadata. After each upload, CD verifies its metadata
and checks the unauthenticated download URL before replacing the feed.
Generation preconditions and recorded build numbers prevent old/concurrent runs
from overwriting a newer feed. A failed build/upload preserves the last release.
Old published archives remain available for already-running downloads.
For the first release, CD also accepts the empty OpenCI RSS template without a
stored build number. It reads that specific object generation and checks that
it contains no release items before publishing. A populated feed needs its
recorded build number.

Only signed public release artifacts belong in this bucket. Do not store
source trees, logs, signing files, service-account keys, or private metadata.

## Team secrets

Use the **openci** team (`0addadaa-fe73-4595-b0c4-6f978a6d48e6`) in project
`openci-b1b91`. The selected local CLI team may belong to a customer; verify it
before registering credentials. Values are injected through secret references in
`openci/dashboard_macos_cd.dart` and must never be interpolated in shell commands.

Required names:

- `FIREBASE_OPTIONS_DART_BASE64`
- `OPENCI_GENERATED_ASC_ISSUER_ID`
- `OPENCI_GENERATED_ASC_KEY_ID`
- `OPENCI_GENERATED_P8_BASE64`
- `MACOS_CERTIFICATE_PRIVATE_KEY` (PEM RSA key used to fetch/create Developer ID signing files)
- `SPARKLE_PRIVATE_ED_KEY` (Sparkle-exported private key; do not Base64-encode it again)
- `MACOS_RELEASE_SERVICE_ACCOUNT_JSON_BASE64` (publisher service-account JSON as Base64)

The App Store Connect key needs access to Developer ID certificates/profiles and
Apple notarization. The pipeline fetches `MAC_APP_DIRECT` signing files, archives
and exports with Xcode's Developer ID distribution, waits for notarization,
staples and validates the ticket, then runs Gatekeeper validation. The final ZIP
is created **after** stapling and signed by Sparkle's resolved `generate_appcast`.
Key files and the signing keychain are removed afterward; the build VM is deleted.
Codemagic 0.69.1 accepts only iOS archive methods in its custom export options.
The release script uses Codemagic to apply the profiles, then sets `developer-id`
in the generated export plist with Apple's PlistBuddy before Xcode exports it.
Fetched profiles are installed in Xcode's standard user profile directory on the
disposable VM. The archive receives the profile's Apple team ID globally so Swift
package resource bundles can use the same signing identity as the app.

### First Developer ID certificate

The ASC key created by `openci setup asc-keys` has the `APP_MANAGER` role.
It can fetch the existing Developer ID certificate, but Apple rejects a new
Developer ID certificate request with HTTP 403 because issuance requires the
Account Holder. Codemagic CLI supports macOS signing; changing CLI tools does
not change the Apple account's certificate permissions.

Before the first release, create a public CSR from the existing
`MACOS_CERTIFICATE_PRIVATE_KEY` without writing that private key to logs or
temporary credential exports. As Account Holder, use Apple's Certificates,
Identifiers & Profiles portal to issue a **Developer ID Application** certificate
from that CSR. Verify its public key matches the CSR. CD can then fetch and reuse
the certificate and create the matching `MAC_APP_DIRECT` provisioning profile.
`--create` remains enabled for missing signing resources; a missing certificate
still stops the release if the API key cannot issue it.

See [Apple's Developer ID certificate instructions](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/).

## Sparkle

`AppInfo.xcconfig` contains the feed URL and public EdDSA key. The private key
stays in team secrets and the operator's Keychain. The plugin starts only after
Flutter configures it. A `OPENCI_MACOS_UPDATE_FEED_URL` Dart define is an optional
override, not a requirement for the default feed. Automatic checking/installing
is initially enabled, and Sparkle respects saved user preferences. Sandboxed
builds enable the installer XPC service and existing mach-lookup entitlements.

Existing releases referring to the deleted Firebase bucket cannot discover this
new feed. Those installations need one manual download of a new signed release.
Do not change the new feed URL or public key casually after distribution.

## Validation

Run `flutter test` in `packages/macos_updater`, `dart test` in `openci`, static
analysis for both packages and the dashboard, and `terraform validate` here.
Before the first release is considered verified, install its signed ZIP on a
separate Mac, publish the next build, and verify update discovery, signature
validation, installation and relaunch. Test malformed signatures and failed
downloads without replacing the working app.

For a local compile check that reads no signing credentials and does not
notarize or publish, run from the repository root:

```sh
dart run openci/tool/release_macos.dart --build-number=1 --validate-only
```

The compiled unsigned app is under
`build/macos-release-validation/Build/Products/Release/OpenCI.app`.
