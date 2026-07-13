import 'package:chopper/chopper.dart';

import 'tailscale_models.dart';

part 'tailscale_api.chopper.dart';

@ChopperApi(baseUrl: 'https://api.tailscale.com/api/v2')
abstract class TailscaleApi extends ChopperService {
  static TailscaleApi create([ChopperClient? client]) => _$TailscaleApi(client);

  @GET(path: '/tailnet/{tailnet}/devices')
  Future<Response<TailscaleDevicesResponse>> getDevices({
    @Path('tailnet') required String tailnet,
    @Header('Authorization') required String authorization,
    @Header('Accept') String accept = 'application/json',
  });
}
