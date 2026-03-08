import 'dart:convert';
import 'dart:io';

import 'package:relic/relic.dart';
import 'package:socks5_proxy/socks_client.dart';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final socksPort =
      int.tryParse(Platform.environment['SOCKS_PORT'] ?? '') ?? 1055;

  final httpClient = HttpClient();
  SocksTCPClient.assignToHttpClient(httpClient, [
    ProxySettings(InternetAddress.loopbackIPv4, socksPort),
  ]);

  final app =
      RelicApp()
        ..get('/health', (_) {
          return Response.ok(
            body: Body.fromString(jsonEncode({'status': 'ok'})),
          );
        })
        ..get('/peers', (_) async {
          final result = await Process.run('/app/tailscale', [
            'status',
            '--json',
          ]);
          if (result.exitCode != 0) {
            return Response(500, body: Body.fromString('${result.stderr}'));
          }

          final status =
              jsonDecode(result.stdout as String) as Map<String, dynamic>;
          final peers = status['Peer'] as Map<String, dynamic>? ?? {};

          final machines =
              peers.values.map((peer) {
                return {
                  'hostname': peer['HostName'],
                  'dns': peer['DNSName'],
                  'ips': peer['TailscaleIPs'],
                  'os': peer['OS'],
                  'online': peer['Online'],
                };
              }).toList();

          return Response.ok(body: Body.fromString(jsonEncode(machines)));
        })
        ..any('/lume/:ip/**', (Request req) async {
          final ip = req.pathParameters.raw[#ip] ?? '';
          final requestPath = req.url.path;
          final match = RegExp(r'/lume/[^/]+/(.*)').firstMatch(requestPath);
          final subpath = match?.group(1) ?? '';
          final url = 'http://$ip:3000/$subpath';

          try {
            final proxyReq = await httpClient.openUrl(
              req.method.name,
              Uri.parse(url),
            );

            if (req.method != Method.get && req.method != Method.head) {
              if (!req.isEmpty) {
                proxyReq.add(utf8.encode(await req.readAsString()));
              }
            }

            final proxyRes = await proxyReq.close();
            final body = await proxyRes.transform(utf8.decoder).join();

            return Response(proxyRes.statusCode, body: Body.fromString(body));
          } catch (e) {
            return Response(
              502,
              body: Body.fromString(jsonEncode({'error': '$e'})),
            );
          }
        });

  await app.serve(address: InternetAddress.anyIPv4, port: port);
  stdout.writeln('Tailscale proxy listening on port $port');
}
