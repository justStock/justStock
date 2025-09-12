import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'otp_service.dart';
import '../config.dart';

class RestOtpService implements OtpService {
  final String baseUrl;
  final http.Client _client;
  RestOtpService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? kBackendBaseUrl,
        _client = client ?? http.Client();

  @override
  Future<OtpSession> sendOtp({required String phoneE164}) async {
    final uri = Uri.parse('$baseUrl/auth/requestOtp');
    final phonePlain = phoneE164.replaceAll(RegExp(r'[^0-9]'), '');
    final body = {'phone': phonePlain};
    if (kDebugMode) debugPrint('POST $uri body=$body');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      final msg = res.body.isNotEmpty ? res.body : res.reasonPhrase ?? 'Unknown error';
      throw Exception('Failed to send OTP (${res.statusCode}): $msg');
    }
    // Backend ties OTP to phone; use phone as the session id
    String debugCode = '';
    try {
      final json = jsonDecode(res.body);
      debugCode = (json['debug'] ?? json['otp'] ?? '').toString();
    } catch (_) {}
    return OtpSession(id: phoneE164, debugCode: debugCode);
  }

  @override
  Future<bool> verifyOtp({required String sessionId, required String code}) async {
    final uri = Uri.parse('$baseUrl/auth/verifyOtp');
    final phonePlain = sessionId.replaceAll(RegExp(r'[^0-9]'), '');
    final body = {'phone': phonePlain, 'otp': code};
    if (kDebugMode) debugPrint('POST $uri body=$body');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) return false;
    // Optionally parse token or user data here
    return true;
  }
}
