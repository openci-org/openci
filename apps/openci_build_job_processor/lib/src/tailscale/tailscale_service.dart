import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;

import 'tailscale_api.dart';
import 'tailscale_device_extension.dart';
import 'tailscale_models.dart';

class TailscaleService {
  final String apiKey;
  final String tailnet;
  final TailscaleApi _api;

  TailscaleService({
    required this.apiKey,
    required this.tailnet,
    http.Client? client,
  }) : _api = TailscaleApi.create(
         ChopperClient(
           client: client,
           converter: const TailscaleJsonConverter(),
         ),
       );

  Future<List<String>> getActiveMacOsIps() async {
    final basicAuth = base64Encode(utf8.encode('$apiKey:'));

    final response = await _api.getDevices(
      tailnet: tailnet,
      authorization: 'Basic $basicAuth',
    );

    if (!response.isSuccessful) {
      throw HttpException(
        'Failed to fetch Tailscale devices: ${response.statusCode} - ${response.bodyString}',
      );
    }

    final data = response.body;
    if (data == null) {
      return [];
    }

    return data.getActiveMacOsIps();
  }
}
