class BillingProxyConfig {
  const BillingProxyConfig._(this.serverUri, this.internalToken);

  final Uri serverUri;
  final String internalToken;

  static BillingProxyConfig? fromEnvironment(Map<String, String> environment) {
    if (environment['SERVER_ACCESS_MODE'] != 'cloud') return null;
    final enabled = environment['BILLING_ENABLED'];
    if (enabled == null || enabled == 'false') return null;
    if (enabled != 'true') {
      throw const FormatException('BILLING_ENABLED must be true or false.');
    }
    final uri = Uri.tryParse(environment['GENUINECI_SERVER_URL']?.trim() ?? '');
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const FormatException(
        'GENUINECI_SERVER_URL must be a server origin.',
      );
    }
    final token = environment['BILLING_INTERNAL_TOKEN']?.trim() ?? '';
    if (token.length < 32 || token.contains(RegExp(r'\s'))) {
      throw const FormatException(
        'BILLING_INTERNAL_TOKEN must be a shared token of at least 32 characters.',
      );
    }
    return BillingProxyConfig._(uri, token);
  }
}
