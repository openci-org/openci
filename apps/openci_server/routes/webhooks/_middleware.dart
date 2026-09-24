import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/auth/internal_api_middleware.dart';

Handler middleware(Handler handler) => handler.use(internalApiMiddleware());
