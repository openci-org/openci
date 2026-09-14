import 'package:chopper/chopper.dart';

part 'loki_api_service.chopper.dart';

@ChopperApi()
abstract class LokiApiService extends ChopperService {
  static LokiApiService create([ChopperClient? client]) =>
      _$LokiApiService(client);

  @POST(
    path: '/loki/api/v1/push',
    headers: {'content-type': 'application/json; charset=utf-8'},
  )
  Future<Response<void>> push(@Body() Map<String, dynamic> body);
}
