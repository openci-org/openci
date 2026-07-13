// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'lume_api_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$LumeApiService extends LumeApiService {
  _$LumeApiService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = LumeApiService;

  @override
  Future<Response<List<LumeVM>>> getVms(String fullUrl) {
    final Uri $url = Uri.parse('${fullUrl}');
    final Request $request = Request('GET', $url, client.baseUrl);
    return client.send<List<LumeVM>, LumeVM>($request);
  }
}
