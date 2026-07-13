import 'package:chopper/chopper.dart';
import 'package:lume_dart/lume_dart.dart';

part 'lume_api_service.chopper.dart';

@ChopperApi()
abstract class LumeApiService extends ChopperService {
  static LumeApiService create([ChopperClient? client]) =>
      _$LumeApiService(client);

  @GET(path: '{fullUrl}')
  Future<Response<List<LumeVM>>> getVms(@Path('fullUrl') String fullUrl);
}
