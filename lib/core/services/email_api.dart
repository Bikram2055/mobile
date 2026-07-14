import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Error carrying a user-friendly message from the email backend.
class EmailApiException implements Exception {
  EmailApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thin HTTP client for the `server/` email backend.
///
/// Authenticated calls (welcome, connection request) pass a Firebase ID token
/// which the server verifies. OTP calls are unauthenticated by nature (the user
/// is locked out) and are rate-limited server-side.
class EmailApiClient {
  EmailApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? AppConfig.emailApiBaseUrl).replaceAll(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  bool get isConfigured => _baseUrl.isNotEmpty;

  Future<void> _post(
    String path, {
    Map<String, dynamic>? body,
    String? idToken,
  }) async {
    if (!isConfigured) {
      throw EmailApiException('Email service is not set up yet.');
    }

    late final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              if (idToken != null) 'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode(body ?? const <String, dynamic>{}),
          )
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      throw EmailApiException('Could not reach the email service. Check your connection.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    var message = 'Request failed (${response.statusCode}).';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is String) {
        message = decoded['error'] as String;
      }
    } catch (_) {
      // Keep the default message.
    }
    throw EmailApiException(message);
  }

  /// Sends the welcome email to the currently signed-in user.
  Future<void> sendWelcome(String idToken) => _post('/welcome', idToken: idToken);

  /// Notifies [toUserId] that the signed-in user requested to connect.
  Future<void> sendConnectionRequest({
    required String idToken,
    required String toUserId,
  }) =>
      _post('/connection-request', idToken: idToken, body: {'toUserId': toUserId});

  /// Requests a password-reset OTP by email.
  Future<void> requestOtp(String email) =>
      _post('/request-otp', body: {'email': email});

  /// Verifies the OTP and sets a new password.
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) =>
      _post('/reset-password', body: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });
}
