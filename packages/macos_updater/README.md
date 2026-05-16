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
await updater.checkForUpdates();
```

## Native setup

The host app must configure Sparkle in its macOS bundle:

- `SUFeedURL`
- `SUPublicEDKey`
- `SUEnableInstallerLauncherService` for sandboxed apps
- Sparkle sandbox mach-lookup exceptions in entitlements

Update archives must be signed with Sparkle's EdDSA key and listed in an
appcast feed.
