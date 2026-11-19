# OpenCI virtual BLE simulator client

This Flutter plugin connects a Debug iOS Simulator to a peer URL returned by the
`openci_workflow` SDK. Its native transport uses `URLSessionWebSocketTask`.
The host runs the Bumble GATT devices. Both simulators run on the same Mac.

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
The per-device XCTest logs, result bundles, and UI evidence are kept under
`example/build/virtual_ble/round-trip-*/`. The example uses this local plugin
and the workflow uses the SDK from the same checkout.
