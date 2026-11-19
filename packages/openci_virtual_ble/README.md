# OpenCI virtual BLE simulator client

This Flutter plugin connects a Debug iOS Simulator to a peer URL returned by the
`openci_workflow` SDK. Its native transport uses `URLSessionWebSocketTask`.
The host runs the Bumble GATT devices. Both simulators run on the same Mac.

Install the plugin as a development dependency in the Flutter app.

```sh
flutter pub add --dev openci_virtual_ble
```

Run the app's Patrol target with `ci.patrol.testWithVirtualBle()` from
`openci_workflow`. Each simulator
receives its WebSocket URL in the `endpoint` field of `tmp/openci-virtual-ble.json`
inside the app's data container. Pass that URL and the bytes to publish to
`VirtualBleClient.connect()`. Use `onPeerValue` for discovery, `onWrite` for
incoming data, and `write()` to send a value and await acknowledgement.
[OpenCI workflow SDK](https://pub.dev/packages/openci_workflow)

Apps that own their BLE protocol in Swift can import `openci_virtual_ble` and
use `VirtualBleConnection` under `#if DEBUG && targetEnvironment(simulator)`.

The example builds one Flutter app with Patrol. B publishes a readable value,
then A reads it and sends a fresh 16-byte value. B displays the bytes it
received and echoes them with a second GATT write. Patrol checks the received
and acknowledged values on both screens.

From the OpenCI repository root with Flutter 3.47.8, Python 3.13, Xcode and
an iOS Simulator runtime:

```sh
flutter pub get
dart run openci/virtual_ble_ci.dart
```

Each run creates its own two simulators and removes them after the test.
The workflow uses `ci.patrol.testWithVirtualBle()` to run the prebuilt Patrol
target on each device and collect its UI evidence. The per-device logs,
XCTest result bundles, and evidence are kept under
`example/build/virtual_ble/round-trip-*/`. The example uses this local plugin
and the workflow uses the SDK from the same checkout.
