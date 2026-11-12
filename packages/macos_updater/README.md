# macos_updater

A macOS-only Flutter plugin that bridges Flutter to Sparkle 2.

This package intentionally does not abstract other desktop platforms. It keeps
the Dart API small and lets Sparkle own update UI, download, verification, and
installation behavior on macOS.

## API

```dart
final updater = MacosUpdater();

await updater.setFeedUrl('https://example.com/appcast.xml');
await updater.setScheduledCheckInterval(const Duration(hours: 24));
await updater.start();
await updater.checkForUpdates();
```

## Native setup

The host app must configure Sparkle in its macOS bundle:

- `SUFeedURL`
- `SUPublicEDKey`

For sandboxed apps, also set `SUEnableInstallerLauncherService` and Sparkle's
sandbox mach-lookup exceptions in entitlements. Leave them unset for
non-sandboxed Developer ID apps.

Update archives must be signed with Sparkle's EdDSA key and listed in an
appcast feed.

Call `start()` after applying any overrides. Without an override, the native
updater reads `SUFeedURL` from the app's Info.plist. Merely registering the
plugin does not start Sparkle, so debug builds can leave the updater stopped.
`checkForUpdates()` also starts the updater if necessary.

`SUEnableAutomaticChecks` and `SUAutomaticallyUpdate` control the initial
automatic-check and automatic-install defaults. Sparkle continues to respect
the user's saved preferences.
