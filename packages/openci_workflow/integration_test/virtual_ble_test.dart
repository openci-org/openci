import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

void main() {
  Future<VirtualBleSession> startRadio() async {
    final ci = await OpenCI.init(
      workflowName: 'Virtual BLE test',
      ciTriggers: [],
    );
    final radio = await ci.startVirtualBle(
      serviceUuid: 'BE110001-5D9F-4810-8692-47717E010001',
      characteristicUuid: 'BE110002-5D9F-4810-8692-47717E010001',
    );
    addTearDown(radio.dispose);
    return radio;
  }

  test(
    'allows a slow simulator to connect before timing GATT publication',
    () async {
      final radio = await startRadio();
      const peer = VirtualBlePeer.a;
      const publicationTimeout = Duration(seconds: 3);
      final published = expectLater(
        radio.waitForPeer(
          peer,
          connectionTimeout: const Duration(minutes: 1),
          timeout: publicationTimeout,
        ),
        completes,
      );
      // Let a full publication window elapse before the simulator connects.
      await expectLater(
        radio.waitForPeer(peer, timeout: publicationTimeout),
        throwsA(
          isA<TimeoutException>().having(
            (error) => error.message,
            'message',
            contains('peer A did not publish'),
          ),
        ),
      );
      final socket = await WebSocket.connect(radio.endpoint(peer).toString());
      addTearDown(socket.close);
      socket.add(
        jsonEncode({
          'type': 'card',
          'value': base64Encode([1]),
        }),
      );
      await published;
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'a missing publication resolves on disconnect or session disposal',
    () async {
      final radio = await startRadio();
      await expectLater(
        radio.waitForPeer(VirtualBlePeer.a, connectionTimeout: Duration.zero),
        throwsA(
          isA<TimeoutException>().having(
            (error) => error.message,
            'message',
            contains('peer A did not connect'),
          ),
        ),
      );
      final b = await WebSocket.connect(
        radio.endpoint(VirtualBlePeer.b).toString(),
      );
      final disconnected = expectLater(
        radio.waitForPeer(VirtualBlePeer.b),
        throwsStateError,
      );
      await b.close();
      await disconnected;
      final stopped = expectLater(
        radio.waitForPeer(
          VirtualBlePeer.a,
          connectionTimeout: const Duration(minutes: 1),
        ),
        throwsStateError,
      );
      await radio.dispose();
      await stopped;
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'two WebSocket clients read and write through Bumble GATT',
    () async {
      final radio = await startRadio();
      final aUri = radio.endpoint(VirtualBlePeer.a);
      final a = await WebSocket.connect(aUri.toString());
      final b = await WebSocket.connect(
        radio.endpoint(VirtualBlePeer.b).toString(),
      );
      addTearDown(a.close);
      addTearDown(b.close);
      final aFrames = StreamIterator(
        a.map((event) => jsonDecode(event as String)),
      );
      final bFrames = StreamIterator(
        b.map((event) => jsonDecode(event as String)),
      );
      addTearDown(aFrames.cancel);
      addTearDown(bFrames.cancel);
      Future<Map<String, dynamic>> next(StreamIterator<dynamic> frames) async {
        expect(
          await frames.moveNext().timeout(const Duration(seconds: 10)),
          isTrue,
        );
        return frames.current as Map<String, dynamic>;
      }

      Map<String, String> frame(String type, List<int> bytes) => {
        'type': type,
        'value': base64Encode(bytes),
      };
      final aValue = List.generate(99, (i) => i);
      final bValue = aValue.reversed.toList();
      final bReady = radio.waitForPeer(VirtualBlePeer.b);
      b.add(jsonEncode(frame('card', bValue)));
      await bReady;
      await radio.waitForPeer(VirtualBlePeer.b);
      a.add(jsonEncode(frame('card', aValue)));
      expect(await next(aFrames), frame('peer', bValue));
      expect(await next(bFrames), frame('peer', aValue));
      await expectLater(
        WebSocket.connect(aUri.toString()),
        throwsA(isA<WebSocketException>()),
      );

      for (final (sender, receiver, sent, received, value) in [
        (a, b, aFrames, bFrames, List.generate(512, (index) => index % 256)),
        (b, a, bFrames, aFrames, [254, 2, 0]),
      ]) {
        var accepted = false;
        final response = next(sent).then((message) {
          accepted = true;
          return message;
        });
        sender.add(jsonEncode(frame('write', value)));
        expect(await next(received), frame('incoming', value));
        expect(accepted, isFalse);
        receiver.add(jsonEncode({'type': 'reply'}));
        expect(await response, {'type': 'accepted'});
      }
      await Future.wait([radio.dispose(), radio.dispose()]);
      await expectLater(
        WebSocket.connect(aUri.toString()),
        throwsA(isA<SocketException>()),
      );
      await expectLater(radio.waitForPeer(VirtualBlePeer.a), throwsStateError);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
