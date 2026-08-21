/// {@template cli_config}
/// Configuration model for Genuine CI CLI.
/// {@endtemplate}
class CliConfig {
  /// {@macro cli_config}
  const CliConfig({
    this.serverUrl = defaultServerUrl,
    this.token,
    this.teamId,
  });

  /// Creates [CliConfig] from JSON map.
  factory CliConfig.fromJson(Map<String, dynamic> json) {
    return CliConfig(
      serverUrl: json['server_url'] as String? ?? defaultServerUrl,
      token: json['token'] as String?,
      teamId: json['team_id'] as String?,
    );
  }

  /// Default OpenCI Server URL.
  static const String defaultServerUrl = 'http://localhost:8080';

  /// The server URL.
  final String serverUrl;

  /// The authentication token or API key.
  final String? token;

  /// The target team ID.
  final String? teamId;

  /// Creates a copy of [CliConfig] with updated values.
  CliConfig copyWith({
    String? serverUrl,
    String? token,
    String? teamId,
  }) {
    return CliConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      token: token ?? this.token,
      teamId: teamId ?? this.teamId,
    );
  }

  /// Converts [CliConfig] to JSON map.
  Map<String, dynamic> toJson() => {
    'server_url': serverUrl,
    if (token != null) 'token': token,
    if (teamId != null) 'team_id': teamId,
  };
}
