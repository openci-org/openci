// ignore_for_file: avoid_print

import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:lume_dart/lume_dart.dart';
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
        final runningVmCount = await getRunningVmCount(url);
        if (runningVmCount < 2) {
          return url;
        }
      } catch (e) {
        print('Failed to check VM count on $url: $e');
      }
    }
    return null;
  }

  static const _defaultTimeout = Duration(seconds: 30);

  Future<int> getRunningVmCount(String lumeUrl) async {
    final url = '$lumeUrl/lume/vms';
    final response = await _api.getVms(url).timeout(_defaultTimeout);

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

  Future<void> cloneVm(
    String lumeUrl,
    String sourceName,
    String targetName,
  ) async {
    final url = '$lumeUrl/lume/vms/clone';
    final response = await _api
        .cloneVm(url, {'name': sourceName, 'newName': targetName})
        .timeout(_defaultTimeout);

    if (!response.isSuccessful) {
      throw StateError(
        'Failed to clone VM on $lumeUrl: ${response.statusCode} - ${response.error}',
      );
    }
  }

  Future<void> runVm(String lumeUrl, String vmName) async {
    final url = '$lumeUrl/lume/vms/$vmName/run';
    final response = await _api
        .runVm(url, {'noDisplay': true})
        .timeout(_defaultTimeout);

    if (!response.isSuccessful) {
      throw StateError(
        'Failed to run VM on $lumeUrl: ${response.statusCode} - ${response.error}',
      );
    }
  }

  Future<void> stopVm(String lumeUrl, String vmName) async {
    final url = '$lumeUrl/lume/vms/$vmName/stop';
    final response = await _api.stopVm(url, {}).timeout(_defaultTimeout);

    if (!response.isSuccessful) {
      throw StateError(
        'Failed to stop VM on $lumeUrl: ${response.statusCode} - ${response.error}',
      );
    }
  }

  Future<void> deleteVm(String lumeUrl, String vmName) async {
    final url = '$lumeUrl/lume/vms/$vmName';
    final response = await _api.deleteVm(url).timeout(_defaultTimeout);

    if (!response.isSuccessful) {
      throw StateError(
        'Failed to delete VM on $lumeUrl: ${response.statusCode} - ${response.error}',
      );
    }
  }

  Future<LumeVM> waitForVmToBeReady(
    String lumeUrl,
    String vmName, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final url = '$lumeUrl/lume/vms';
    final stopTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(stopTime)) {
      try {
        final response = await _api.getVms(url).timeout(_defaultTimeout);
        if (response.isSuccessful && response.body != null) {
          final vms = response.body!;
          final index = vms.indexWhere((v) => v.name == vmName);
          if (index != -1) {
            final vm = vms[index];
            if (vm.status.toLowerCase() == 'running' &&
                vm.ipAddress != null &&
                vm.sshAvailable == true) {
              return vm;
            }
          }
        }
      } catch (e) {
        // Ignore transient API or connection errors while booting
        print('Warning while waiting for VM: $e');
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    throw TimeoutException(
      'Timeout waiting for Lume VM "$vmName" to boot and become SSH available on $lumeUrl.',
    );
  }
}
