import 'package:openci_shared/openci_shared.dart';

Future<String> fetchJobSecrets({
  required OpenCIApiService api,
  required String jobId,
}) async {
  final bool isSuccessful;
  final int statusCode;
  final Map<String, dynamic>? body;
  try {
    final response = await api.getJobSecrets(jobId);
    isSuccessful = response.isSuccessful;
    statusCode = response.statusCode;
    body = response.body;
  } catch (error, stackTrace) {
    // Conversion and transport errors can include the response or credentials.
    Error.throwWithStackTrace(
      StateError('Failed to fetch job secrets: ${error.runtimeType}.'),
      stackTrace,
    );
  }

  if (!isSuccessful) {
    throw StateError('Failed to fetch job secrets: HTTP $statusCode.');
  }

  final secretsContent = body?['secretsContent'];
  if (body?['success'] != true || secretsContent is! String) {
    throw StateError(
      'Invalid job secrets response: '
      '"success" must be true and "secretsContent" must be a string.',
    );
  }

  return secretsContent;
}
