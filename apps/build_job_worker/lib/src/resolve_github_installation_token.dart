import 'package:openci_shared/openci_shared.dart';

Future<String> resolveGitHubInstallationToken({
  required OpenCIApiService api,
  required String jobId,
}) async {
  final bool isSuccessful;
  final int statusCode;
  final Object? token;
  try {
    final response = await api.resolveInstallationToken(jobId);
    isSuccessful = response.isSuccessful;
    statusCode = response.statusCode;
    token = response.body?['token'];
  } catch (error, stackTrace) {
    // Conversion and transport errors can include the response or credentials.
    Error.throwWithStackTrace(
      StateError(
        'Failed to resolve GitHub installation token: ${error.runtimeType}.',
      ),
      stackTrace,
    );
  }

  if (!isSuccessful) {
    throw StateError(
      'Failed to resolve GitHub installation token: HTTP $statusCode.',
    );
  }
  if (token is! String || token.isEmpty) {
    throw StateError(
      'Invalid GitHub installation token response: '
      '"token" must be a non-empty string.',
    );
  }

  return token;
}
