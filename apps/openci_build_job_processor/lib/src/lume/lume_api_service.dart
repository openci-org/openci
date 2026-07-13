import 'package:chopper/chopper.dart';
import 'package:lume_dart/lume_dart.dart';

part 'lume_api_service.chopper.dart';

@ChopperApi()
abstract class LumeApiService extends ChopperService {
  static LumeApiService create([ChopperClient? client]) =>
      _$LumeApiService(client);

  @GET(path: '{fullUrl}')
  Future<Response<List<LumeVM>>> getVms(@Path('fullUrl') String fullUrl);

  @POST(path: '{fullUrl}')
  Future<Response<dynamic>> cloneVm(
    @Path('fullUrl') String fullUrl,
    @Body() Map<String, dynamic> body,
  );

  @POST(path: '{fullUrl}')
  Future<Response<dynamic>> runVm(
    @Path('fullUrl') String fullUrl,
    @Body() Map<String, dynamic> body,
  );

  @POST(path: '{fullUrl}')
  Future<Response<dynamic>> stopVm(
    @Path('fullUrl') String fullUrl,
    @Body() Map<String, dynamic> body,
  );

  @DELETE(path: '{fullUrl}')
  Future<Response<dynamic>> deleteVm(@Path('fullUrl') String fullUrl);
}
