import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final _log = Logger('AuthManager');

class AuthManager {
  static const String _apiKey = 'AIzaSyCJj_DPhFXk0RtAUmxp-jHuJ0a85-WlTDs';

  final String email;
  final String password;

  String? _idToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  AuthManager({required this.email, required this.password});

  /// Signs in to Firebase Auth using Email & Password.
  Future<void> signIn() async {
    _log.info('Signing in to Firebase Auth as $email...');
    
    // Check if emulator is being used
    final isEmulator = Platform.environment['FUNCTIONS_EMULATOR'] == 'true' ||
        Platform.environment['FIRESTORE_EMULATOR_HOST'] != null;

    if (isEmulator) {
      _log.info('Using emulator mode. Simulating authentication token.');
      _idToken = 'emulator-token';
      _refreshToken = 'emulator-refresh-token';
      _tokenExpiry = DateTime.now().add(const Duration(hours: 24));
      return;
    }

    final url = 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_apiKey';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode != 200) {
      throw HttpException('Firebase sign in failed: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _idToken = data['idToken'] as String?;
    _refreshToken = data['refreshToken'] as String?;
    final expiresInStr = data['expiresIn'] as String? ?? '3600';
    final expiresIn = int.tryParse(expiresInStr) ?? 3600;

    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    _log.info('Successfully signed in. Token expires in ${expiresIn}s');
  }

  /// Returns the current ID token, refreshing it if it's expired or close to expiry.
  Future<String> getIdToken() async {
    // If not signed in yet, sign in first.
    if (_idToken == null || _refreshToken == null || _tokenExpiry == null) {
      await signIn();
    }

    final isEmulator = Platform.environment['FUNCTIONS_EMULATOR'] == 'true' ||
        Platform.environment['FIRESTORE_EMULATOR_HOST'] != null;
    if (isEmulator) {
      return 'emulator-token';
    }

    // Refresh if within 5 minutes of expiry
    if (DateTime.now().add(const Duration(minutes: 5)).isAfter(_tokenExpiry!)) {
      await _refreshTokenValue();
    }

    return _idToken!;
  }

  Future<void> _refreshTokenValue() async {
    _log.info('Refreshing Firebase Auth ID token...');
    final url = 'https://securetoken.googleapis.com/v1/token?key=$_apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken,
      },
    );

    if (response.statusCode != 200) {
      _log.warning('Token refresh failed: ${response.statusCode}. Re-signing in...');
      // Fallback: Try signing in again with email and password
      await signIn();
      return;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _idToken = data['access_token'] as String?;
    _refreshToken = data['refresh_token'] as String?;
    final expiresInStr = data['expires_in'] as String? ?? '3600';
    final expiresIn = int.tryParse(expiresInStr) ?? 3600;

    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    _log.info('Token refreshed successfully. Next expiry in ${expiresIn}s');
  }
}
