import 'dart:async';

import 'package:chopper/chopper.dart';

import '../models/build_job.dart';
import '../models/team.dart';
import '../models/user_device.dart';

class JsonToTypeConverter extends JsonConverter {
  const JsonToTypeConverter();

  @override
  FutureOr<Response<BodyType>> convertResponse<BodyType, InnerType>(
    Response response,
  ) async {
    final jsonResponse = await super.convertResponse<dynamic, dynamic>(
      response,
    );
    final body = jsonResponse.body;

    final convertedBody = _convertToType<InnerType>(body);

    return jsonResponse.copyWith<BodyType>(body: convertedBody as BodyType);
  }

  dynamic _convertToType<T>(dynamic json) {
    if (json == null) return null;

    if (json is List) {
      return json.map((item) => _convertToType<T>(item)).toList();
    }

    if (T == Team) {
      return Team.fromJson(Map<String, dynamic>.from(json as Map));
    }
    if (T == BuildJob) {
      return BuildJob.fromJson(Map<String, dynamic>.from(json as Map));
    }
    if (T == UserDevice) {
      return UserDevice.fromJson(Map<String, dynamic>.from(json as Map));
    }

    return json;
  }
}
