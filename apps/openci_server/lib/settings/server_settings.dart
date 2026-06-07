import 'dart:io';

({InternetAddress ip, int port}) loadServerSettings({
  Map<String, String>? environment,
}) {
  final env = environment ?? Platform.environment;
  final ip = env['HOST'] == 'any'
      ? InternetAddress.anyIPv4
      : InternetAddress.loopbackIPv4;

  final parsedPort = int.tryParse(env['PORT'] ?? '');
  final port = (parsedPort != null && parsedPort >= 1 && parsedPort <= 65535)
      ? parsedPort
      : 8080;

  return (ip: ip, port: port);
}
