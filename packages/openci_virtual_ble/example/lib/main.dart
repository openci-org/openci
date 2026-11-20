import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:openci_virtual_ble/openci_virtual_ble.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = File('${Directory.systemTemp.path}/openci-virtual-ble.json');
  final endpoint = await config.exists()
      ? jsonDecode(await config.readAsString())['endpoint'] as String
      : '';
  // BleExample manages its state with setState.
  // ignore: riverpod_lint/missing_provider_scope
  runApp(BleExample(endpoint: endpoint));
}

class BleExample extends StatefulWidget {
  const BleExample({super.key, required this.endpoint});
  final String endpoint;
  @override
  State<BleExample> createState() => _BleExampleState();
}

class _BleExampleState extends State<BleExample> {
  late final _address = TextEditingController(text: widget.endpoint);
  late final _client = VirtualBleClient(
    onPeerValue: (bytes) => setState(() => _peer = utf8.decode(bytes)),
    onWrite: (bytes) => setState(() => _received = bytes),
    onDisconnect: (reason) {
      if (mounted) {
        setState(() {
          _peer = null;
          _status = reason;
        });
      }
    },
  );
  String? _peer;
  String _role = '';
  String _status = '';
  Uint8List? _received;
  Uint8List? _sent;
  bool _busy = false;

  static String _hex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  Future<void> _connect() async {
    final uri = Uri.tryParse(_address.text.trim());
    if (uri == null || !const ['/A', '/B'].contains(uri.path)) {
      setState(() => _status = 'Enter the /A or /B WebSocket URL');
      return;
    }
    setState(() {
      _busy = true;
      _role = uri.path.substring(1);
    });
    try {
      await _client.connect(uri, value: Uint8List.fromList(utf8.encode(_role)));
      if (mounted) setState(() => _status = 'Connected as $_role');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = error.toString();
        _role = '';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    final random = Random.secure();
    final bytes = _role == 'B'
        ? _received!
        : Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
    try {
      await _client.write(bytes);
      if (mounted) setState(() => _sent = bytes);
    } catch (error) {
      if (mounted) setState(() => _status = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _address.dispose();
    unawaited(_client.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Virtual BLE')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Peer WebSocket URL',
              ),
            ),
            ElevatedButton(
              onPressed: !_busy && _role.isEmpty ? _connect : null,
              child: const Text('Connect'),
            ),
            if (_status.isNotEmpty) Text(_status),
            if (_peer != null) Text('Peer: $_peer'),
            if (_received != null) const Text('Received'),
            if (_received != null)
              Text(_hex(_received!), key: const ValueKey('received')),
            ElevatedButton(
              onPressed:
                  !_busy && _peer != null && (_role == 'A' || _received != null)
                  ? _send
                  : null,
              child: Text(
                _role == 'B' ? 'Echo received value' : 'Send fresh value',
              ),
            ),
            if (_sent != null) const Text('Write acknowledged'),
            if (_sent != null)
              Text(_hex(_sent!), key: const ValueKey('acknowledged')),
          ],
        ),
      ),
    ),
  );
}
