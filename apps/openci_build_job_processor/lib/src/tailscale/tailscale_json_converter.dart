import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:openci_build_job_processor/src/tailscale/tailscale_models.dart';

class TailscaleJsonConverter extends JsonConverter {
  const TailscaleJsonConverter();

  @override
  FutureOr<Response<BodyType>> convertResponse<BodyType, InnerType>(
    Response response,
  ) async {
    final jsonResponse = await super.convertResponse<dynamic, dynamic>(
      response,
    );
    final body = jsonResponse.body;
    final convertedBody = _convertToType(body);
    return jsonResponse.copyWith<BodyType>(body: convertedBody as BodyType);
  }

  TailscaleDevicesResponse? _convertToType(dynamic json) {
    if (json == null) return null;
    return TailscaleDevicesResponse.fromJson(
      Map<String, dynamic>.from(json as Map),
    );
  }
}
