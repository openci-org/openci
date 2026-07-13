import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:lume_dart/lume_dart.dart';

class LumeJsonToTypeConverter extends JsonConverter {
  const LumeJsonToTypeConverter();

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
      return List<T>.from(json.map((item) => _convertToType<T>(item)));
    }
    if (T == LumeVM) {
      return LumeVM.fromJson(Map<String, dynamic>.from(json as Map));
    }
    return json;
  }
}
