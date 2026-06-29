import 'cloud_function_caller.dart';

Future<void> sendHeartbeat({
  required ApiClient apiClient,
  required String workerId,
  required String version,
  required String status,
}) async {
  await apiClient.sendHeartbeat(
    workerId: workerId,
    version: version,
    status: status,
  );
}
