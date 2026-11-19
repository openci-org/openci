import 'dart:async';

import 'package:flutter/services.dart';

/// One app-side GATT peer. A write is acknowledged after [onWrite] completes.
class VirtualBleClient {
  VirtualBleClient({
    required this.onPeerValue,
    required this.onWrite,
    required this.onDisconnect,
  });

  final void Function(Uint8List) onPeerValue;
  final FutureOr<void> Function(Uint8List) onWrite;
  final void Function(String) onDisconnect;
  static const _channel = MethodChannel('org.openci/virtual_ble');
  static VirtualBleClient? _active;
  Completer<void>? _write;
  bool _peerAvailable = false;

  Future<void> connect(Uri endpoint, {required Uint8List value}) async {
    if (_active != null) {
      throw StateError('One virtual BLE connection per simulator app');
    }
    _active = this;
    _channel.setMethodCallHandler(_receive);
    try {
      await _channel.invokeMethod<void>('connect', endpoint.toString());
      await _channel.invokeMethod<void>('card', value);
    } catch (_) {
      await dispose();
      rethrow;
    }
  }

  Future<void> _receive(MethodCall call) async {
    switch (call.method) {
      case 'peer':
        _peerAvailable = true;
        onPeerValue(call.arguments as Uint8List);
      case 'incoming':
        await onWrite(call.arguments as Uint8List);
        await _channel.invokeMethod<void>('reply');
      case 'accepted':
        _write?.complete();
        _write = null;
      case 'gone':
        _disconnected('Peer disconnected');
      case 'disconnected':
        _disconnected(call.arguments as String);
    }
  }

  /// Writes to the remote characteristic and waits for its GATT response.
  Future<void> write(Uint8List value) async {
    if (_active != this || !_peerAvailable || _write != null) {
      throw StateError('Expected a connected, idle GATT peer');
    }
    final response = Completer<void>();
    _write = response;
    response.future.ignore();
    try {
      await _channel.invokeMethod<void>('write', value);
      await response.future.timeout(const Duration(seconds: 20));
    } catch (_) {
      await dispose();
      rethrow;
    }
  }

  void _disconnected(String reason) {
    _peerAvailable = false;
    _write?.completeError(StateError(reason));
    _write = null;
    onDisconnect(reason);
  }

  Future<void> dispose() async {
    if (_active != this) return;
    _channel.setMethodCallHandler(null);
    try {
      await _channel.invokeMethod<void>('close');
    } finally {
      _peerAvailable = false;
      _write?.completeError(StateError('Virtual BLE client closed'));
      _write = null;
      _active = null;
    }
  }
}
