import 'dart:convert';

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

  @GET(path: '/loki/api/v1/query_range')
  @FactoryConverter(response: _decodeQueryRangeResponse)
  Future<Response<Map<String, dynamic>>> queryRange({
    @Query('query') required String query,
    @Query('start') required String start,
    @Query('limit') required int limit,
    @Query('direction') required String direction,
  });

  static Response<Map<String, dynamic>> _decodeQueryRangeResponse(
    Response<dynamic> response,
  ) => response.copyWith<Map<String, dynamic>>(
    body: jsonDecode(response.bodyString) as Map<String, dynamic>,
  );
}
