import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;

Response<T> createMockResponse<T>(T body, {int statusCode = 200}) {
  return Response<T>(http.Response('', statusCode), body);
}
