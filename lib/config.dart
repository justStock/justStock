// Runtime/compile-time config toggles

// Build-time override: flutter build ... --dart-define=BYPASS_OTP=false
const bool kBypassOtp = bool.fromEnvironment('BYPASS_OTP', defaultValue: true);

