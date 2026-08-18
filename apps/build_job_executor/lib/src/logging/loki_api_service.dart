import 'package:chopper/chopper.dart';

part 'loki_api_service.chopper.dart';

@ChopperApi(baseUrl: '/loki/api/v1')
abstract class LokiApiService extends ChopperService {
  static LokiApiService create([ChopperClient? client]) =>
      _$LokiApiService(client);

  @POST(path: '/push', timeout: Duration(seconds: 5))
  Future<Response<void>> pushLogs(@Body() Map<String, dynamic> body);
}

/// Loki の Push API 向け標準ペロード (`Map<String, dynamic>`) を作成するヘルパー関数
Map<String, dynamic> createLokiPayload({
  required Map<String, String> labels,
  required String message,
  DateTime? timestamp,
}) {
  final nanos =
      ((timestamp ?? DateTime.now()).toUtc().microsecondsSinceEpoch * 1000)
          .toString();
  return {
    'streams': [
      {
        'stream': labels,
        'values': [
          [nanos, message],
        ],
      },
    ],
  };
}
