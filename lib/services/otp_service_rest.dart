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

  // Helper: convert '+919876543210' -> '9876543210' (last 10 digits for India)
  String _digitsOnly(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) return digits.substring(digits.length - 10);
    return digits;
  }

  @override
  Future<OtpSession> sendOtp({required String phoneE164}) async {
    // Your backend expects { phone: 9226805459 } at /api/auth/requestOtp
    final phoneDigits = _digitsOnly(phoneE164);
    final uri = Uri.parse('$baseUrl/api/auth/requestOtp');
    final body = {'phone': phoneDigits};
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

    // Your API may return just a message or may include the OTP for dev.
    // We treat the "session" id as the phone itself so we can verify with it later.
    String debugCode = '';
    try {
      final json = jsonDecode(res.body);
      debugCode = (json['otp'] ?? json['debug'] ?? '').toString();
    } catch (_) {
      // non-JSON or no otp, that's fine in production
    }
    return OtpSession(id: phoneDigits, debugCode: debugCode);
  }

  @override
  Future<bool> verifyOtp({required String sessionId, required String code}) async {
    // Your backend expects { phone: 9226805459, otp: "443020" }
    final uri = Uri.parse('$baseUrl/api/auth/verifyOtp');
    final body = {'phone': sessionId, 'otp': code};
    if (kDebugMode) debugPrint('POST $uri body=$body');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      if (kDebugMode) debugPrint('Verify failed: ${res.statusCode} ${res.body}');
      return false;
    }

    // Optionally parse token/user info if your API returns it.
    return true;
  }
}
