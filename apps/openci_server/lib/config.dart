import 'dart:io';

final ip = Platform.environment['HOST'] == 'any'
    ? InternetAddress.anyIPv4
    : InternetAddress.loopbackIPv4;

final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
