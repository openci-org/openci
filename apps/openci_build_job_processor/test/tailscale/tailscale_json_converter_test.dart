import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:openci_build_job_processor/src/tailscale/tailscale_json_converter.dart';
import 'package:openci_build_job_processor/src/tailscale/tailscale_models.dart';
import 'package:test/test.dart';

void main() {
  group('TailscaleJsonConverter', () {
    const converter = TailscaleJsonConverter();

    test('should convert valid json map to TailscaleDevicesResponse', () async {
      final payload = {
        'devices': [
          {
            'os': 'macos',
            'connectedToControl': true,
            'addresses': ['100.66.12.37'],
          },
        ],
      };

      final httpResponse = http.Response(
        jsonEncode(payload),
        200,
        headers: {'content-type': 'application/json'},
      );
      final chopperResponse = Response<dynamic>(
        httpResponse,
        jsonEncode(payload),
      );

      final converted = await converter
          .convertResponse<TailscaleDevicesResponse, TailscaleDevicesResponse>(
            chopperResponse,
          );

      expect(converted.body, isA<TailscaleDevicesResponse>());
      final devices = converted.body?.devices;
      expect(devices, hasLength(1));
      expect(devices?[0].os, 'macos');
      expect(devices?[0].connectedToControl, true);
      expect(devices?[0].addresses, ['100.66.12.37']);
    });

    test('should return null when body is null', () async {
      final httpResponse = http.Response(
        'null',
        200,
        headers: {'content-type': 'application/json'},
      );
      final chopperResponse = Response<dynamic>(httpResponse, null);

      final converted = await converter
          .convertResponse<TailscaleDevicesResponse?, TailscaleDevicesResponse>(
            chopperResponse,
          );

      expect(converted.body, isNull);
    });

    test('should throw TypeError when response body is not a map', () async {
      final httpResponse = http.Response(
        '"invalid_json_string"',
        200,
        headers: {'content-type': 'application/json'},
      );
      final chopperResponse = Response<dynamic>(
        httpResponse,
        'invalid_json_string',
      );

      expect(
        () =>
            converter.convertResponse<
              TailscaleDevicesResponse,
              TailscaleDevicesResponse
            >(chopperResponse),
        throwsA(isA<TypeError>()),
      );
    });

    test('should throw TypeError when map structure is invalid', () async {
      final payload = {'devices': 'not_a_list'};
      final httpResponse = http.Response(
        jsonEncode(payload),
        200,
        headers: {'content-type': 'application/json'},
      );
      final chopperResponse = Response<dynamic>(httpResponse, payload);

      expect(
        () =>
            converter.convertResponse<
              TailscaleDevicesResponse,
              TailscaleDevicesResponse
            >(chopperResponse),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
