import 'package:chopper/chopper.dart';
import 'package:openci_shared/openci_shared.dart';
import '../firebase.dart';

ChopperClient createChopperClient({
  required String baseUrl,
  required AuthManager authManager,
}) {
  return createOpenCiChopperClient(
    baseUrl: baseUrl,
    tokenProvider: () => authManager.getIdToken(),
    services: [OpenCiApiService.create()],
  );
}
