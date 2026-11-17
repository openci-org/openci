# Google registration rollout

OpenCI Cloud offers Google registration and Google sign-in. Existing
email/password users can still sign in from the same page, including from the
CLI. Self-hosted connections and the local Auth emulator keep their existing
registration UI; their Firebase projects control their own provider policy.

The `requireGoogleSignup` Identity Platform blocking function rejects non-Google
**user creation**, including direct password sign-up API requests. It is not a
sign-in hook. Keep the Email/Password provider enabled for existing users. Admin
SDK provisioning is an administrative path, not public registration.

## Before merging or deploying

1. Enable Google in the Cloud project's Firebase Authentication providers and
   configure the OAuth consent screen. The project must use Identity Platform
   for the blocking function.
2. Add `dashboard.openci.org` and any exact preview/test hostnames used for OAuth
   to Authentication's authorized domains. Keep the existing authorized domains.
3. Regenerate `lib/firebase_options.dart` using FlutterFire after enabling Google.
   Both the `ios` and `macos` options must contain their own `iosClientId`.
   Refresh the `FIREBASE_OPTIONS_DART_BASE64` build secret with this file.
4. Download fresh native Firebase configuration files. Refresh the existing
   iOS plist and Android `google-services.json` build secrets. Register Android
   signing SHA fingerprints, including Play App Signing's certificate.
5. Before native development builds, run one of the commands below from this
   directory. The iOS and macOS release workflows run the corresponding command
   automatically and fail before publishing if OAuth configuration is missing.

   ```sh
   dart run tool/configure_google_sign_in.dart ios
   dart run tool/configure_google_sign_in.dart macos
   ```

   This derives the native client ID and callback URL scheme from Firebase
   options into ignored `GoogleSignIn.xcconfig` files. macOS signing includes
   Google Sign-In's keychain access group.

6. Verify Google sign-in on Web, iOS, macOS, and Android before deploying the
   creation restriction. Deploy the dashboard and `requireGoogleSignup` in a
   coordinated rollout. Older clients will no longer be able to create password
   accounts once the function is deployed.

## Verification

- A first Google sign-in creates and selects one initial team.
- A returning Google user keeps the same UID and existing teams.
- An existing password user can still sign in, including through the CLI.
- Closing Google's account picker leaves the login page usable.
- Signing up directly with email/password is rejected after the blocking
  function is deployed; existing email/password sign-in still succeeds.
- Provider conflicts direct existing users to their original login. Explicit
  account linking and migration emails are separate work.

The CLI currently supports password login only. New Google-only accounts cannot
use CLI login until browser-based CLI authentication is added; this rollout does
not add a password to Google accounts.

If rolling back, restore the old registration UI and **unregister** the creation
hook in Identity Platform before deleting its function. Deleting a registered
blocking function alone can prevent all new registrations.

References:

- [Flutter Google authentication](https://firebase.google.com/docs/auth/flutter/federated-auth#google)
- [Native Google Sign-In setup](https://pub.dev/packages/google_sign_in_ios)
- [Blocking authentication events](https://firebase.google.com/docs/auth/extend-with-blocking-functions)
