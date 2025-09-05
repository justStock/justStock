import 'dart:convert';
import 'package:http/http.dart' as http;
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
    final uri = Uri.parse('$baseUrl/auth/send-otp');
    final res = await _client.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'phone': phoneE164}));
    if (res.statusCode != 200) {
      throw Exception('Failed to send OTP: ${res.statusCode}');
    }
    final json = jsonDecode(res.body);
    return OtpSession(id: json['sessionId'], debugCode: (json['debug'] ?? '').toString());
  }

  @override
  Future<bool> verifyOtp({required String sessionId, required String code}) async {
    final uri = Uri.parse('$baseUrl/auth/verify-otp');
    final res = await _client.post(uri,
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({'sessionId': sessionId, 'code': code}));
    if (res.statusCode != 200) return false;
    // Optionally store token for authenticated calls
    // final json = jsonDecode(res.body);
    // final token = json['token'];
    return true;
  }
}

