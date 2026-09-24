import 'package:email_validator/email_validator.dart';

enum ServerAccessMode { selfHosted, cloud }

enum ServerAccessDecision {
  allowed,
  emailVerificationRequired,
  accessDenied,
}

class ServerAccessPolicy {
  ServerAccessPolicy._(this.mode, Set<String> allowedEmails)
    : _allowedEmails = Set.unmodifiable(allowedEmails);

  factory ServerAccessPolicy.fromEnvironment(Map<String, String> environment) {
    final mode = _parseAccessMode(environment['SERVER_ACCESS_MODE']);
    final emails = mode == ServerAccessMode.selfHosted
        ? _parseAllowedEmails(environment['ALLOWED_USER_EMAILS'])
        : <String>{};
    return ServerAccessPolicy._(mode, emails);
  }

  final ServerAccessMode mode;
  final Set<String> _allowedEmails;

  ServerAccessDecision evaluate({String? email, bool? emailVerified}) {
    if (mode == ServerAccessMode.cloud) return ServerAccessDecision.allowed;
    if (email == null || !EmailValidator.validate(email)) {
      return ServerAccessDecision.accessDenied;
    }
    if (!_allowedEmails.contains(email.toLowerCase())) {
      return ServerAccessDecision.accessDenied;
    }
    if (emailVerified != true) {
      return ServerAccessDecision.emailVerificationRequired;
    }
    return ServerAccessDecision.allowed;
  }
}

ServerAccessMode _parseAccessMode(String? value) => switch (value) {
  null || 'self_hosted' => ServerAccessMode.selfHosted,
  'cloud' => ServerAccessMode.cloud,
  _ => throw const FormatException(
    'SERVER_ACCESS_MODE must be self_hosted or cloud.',
  ),
};

Set<String> _parseAllowedEmails(String? value) {
  if (value == null || value.trim().isEmpty) return <String>{};
  return value.split(',').map(_parseAllowedEmail).toSet();
}

String _parseAllowedEmail(String value) {
  final email = value.trim().toLowerCase();
  // Allowlist entries must identify individual mailboxes, not wildcards.
  if (email.contains('*') || !EmailValidator.validate(email)) {
    throw const FormatException(
      'ALLOWED_USER_EMAILS must contain comma-separated email addresses.',
    );
  }
  return email;
}
