// ignore_for_file: avoid_print

import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:openci_build_job_processor/src/lume/lume_api_service.dart';
import 'package:openci_build_job_processor/src/lume/lume_json_converter.dart';

class LumeService {
  LumeService({ChopperClient? client}) {
    _client =
        client ??
        ChopperClient(
          services: [LumeApiService.create()],
          converter: const LumeJsonToTypeConverter(),
        );
    _api = _client.getService<LumeApiService>();
  }

  late final ChopperClient _client;
  late final LumeApiService _api;

  Future<String?> findAvailableLumeUrl(List<String> lumeServerUrls) async {
    for (final url in lumeServerUrls) {
      try {
        final runningVmCount = await _getRunningVmCount(url);
        if (runningVmCount < 2) {
          return url;
        }
      } catch (e) {
        print('Failed to check VM count on $url: $e');
      }
    }
    return null;
  }

  Future<int> _getRunningVmCount(String lumeUrl) async {
    final url = '$lumeUrl/lume/vms';
    final response = await _api.getVms(url);

    if (!response.isSuccessful) {
      throw StateError(
        'Lume serve returned status ${response.statusCode} for $lumeUrl',
      );
    }

    final vms = response.body;
    if (vms == null) {
      return 0;
    }

    return vms.where((vm) => vm.status.toLowerCase() == 'running').length;
  }
}
