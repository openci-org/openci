Uri buildWebSocketUri(
  String baseUrl,
  String path, {
  Map<String, String>? queryParameters,
}) {
  final uri = Uri.parse(baseUrl);
  final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
  return Uri(
    scheme: wsScheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: path,
    queryParameters: queryParameters != null && queryParameters.isNotEmpty
        ? queryParameters
        : null,
  );
}
