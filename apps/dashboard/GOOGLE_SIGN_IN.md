# Google registration rollout

Every connection offers Google registration and Google sign-in, including Cloud,
self-hosted projects, and the local Auth emulator. Existing
email/password users can still sign in from the same page, including from the
CLI. There is no email/password registration action in any connection mode.

The `requireGoogleSignup` Identity Platform blocking function rejects non-Google
**user creation**, including direct password sign-up API requests. It is not a
sign-in hook. Keep the Email/Password provider enabled for existing users. Admin
SDK provisioning is an administrative path, not public registration.

## Before merging or deploying

1. Enable Google in each Firebase project's Authentication providers and
   configure the OAuth consent screen. The project must use Identity Platform
   for the blocking function. Deploy `requireGoogleSignup` to each self-hosted
   project as well to enforce the restriction outside the dashboard UI.
   Set `OPENCI_API_SERVICE_ACCOUNT` to a service account in that project instead
   of the default Cloud service account.
2. Add the dashboard's hostname and any exact preview/test hostnames used for
   OAuth to that project's Authentication authorized domains. For Cloud this
   includes `dashboard.openci.org`. Keep the existing authorized domains.
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

   Native OAuth always uses the client configuration embedded in the app build,
   matching its callback URL schemes. When using the distributed native app
   with a self-hosted Firebase project, allow that app's Google OAuth client IDs
   under the project's Google provider's **Allowed client IDs**. On Android this
   includes the web/server client used by the app's `google-services.json`.
   The Google credential is exchanged only with the selected Firebase project.
   Alternatively, build the app with your own native Firebase/OAuth configuration.

   On Web, the local Auth emulator supplies its mock Google popup. Native local
   development uses the app's Google account picker and OAuth configuration,
   while the Firebase credential exchange still goes to the Auth emulator.

6. Verify Google sign-in on Web, iOS, macOS, and Android before deploying the
   creation restriction. Deploy the dashboard and `requireGoogleSignup` in a
   coordinated rollout. Older clients will no longer be able to create password
   accounts once the function is deployed.

## Verification

- A first Google sign-in creates and selects one initial team.
- Cloud, self-hosted, and local connections all show Google registration and no
  password registration action; account and team creation use the selected connection.
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
- [Allow external Google OAuth client IDs](https://docs.cloud.google.com/identity-platform/docs/web/google#configure-google-as-a-provider)
- [Authentication emulator](https://firebase.google.com/docs/emulator-suite/connect_auth)
- [Blocking authentication events](https://firebase.google.com/docs/auth/extend-with-blocking-functions)
