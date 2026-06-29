import 'dart:async';

import 'package:chopper/chopper.dart';

import 'json_to_type_converter.dart';

class TokenAuthInterceptor implements Interceptor {
  final FutureOr<String?> Function() tokenProvider;

  const TokenAuthInterceptor({required this.tokenProvider});

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    try {
      final token = await tokenProvider();
      if (token == null || token.isEmpty) {
        return chain.proceed(chain.request);
      }
      final request = applyHeader(
        chain.request,
        'Authorization',
        'Bearer $token',
      );
      return chain.proceed(request);
    } catch (_) {
      return chain.proceed(chain.request);
    }
  }
}

ChopperClient createOpenCiChopperClient({
  required String baseUrl,
  required FutureOr<String?> Function() tokenProvider,
  List<ChopperService> services = const [],
}) {
  return ChopperClient(
    baseUrl: Uri.parse(baseUrl),
    converter: const JsonToTypeConverter(),
    interceptors: [
      TokenAuthInterceptor(tokenProvider: tokenProvider),
    ],
    services: services,
  );
}
