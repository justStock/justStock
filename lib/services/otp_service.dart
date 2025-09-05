import 'dart:math';
import 'package:flutter/foundation.dart';

class OtpSession {
  final String id;
  final String debugCode; // For development only
  OtpSession({required this.id, required this.debugCode});
}

abstract class OtpService {
  Future<OtpSession> sendOtp({required String phoneE164});
  Future<bool> verifyOtp({required String sessionId, required String code});
}

/// Default dev-only implementation that simulates sending SMS.
/// It prints the OTP in the debug console so you can test end-to-end
/// without a real SMS provider. Replace with a real provider for production.
class MockOtpService implements OtpService {
  static final Map<String, String> _store = {};
  final _rand = Random.secure();

  @override
  Future<OtpSession> sendOtp({required String phoneE164}) async {
    // generate 6-digit code
    final code = (_rand.nextInt(900000) + 100000).toString();
    final id = '${DateTime.now().millisecondsSinceEpoch}-${_rand.nextInt(0xFFFFFFFF)}';
    _store[id] = code;
    debugPrint('Mock OTP for $phoneE164 => $code (session: $id)');
    await Future.delayed(const Duration(milliseconds: 500));
    return OtpSession(id: id, debugCode: code);
  }

  @override
  Future<bool> verifyOtp({required String sessionId, required String code}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _store[sessionId] == code;
  }
}

// To integrate a real SMS provider (e.g., Firebase Phone Auth, Twilio, Fast2SMS),
// create another class implementing OtpService and wire it in AuthPage.
// Example API sketch:
// class FirebaseOtpService implements OtpService { ... }
