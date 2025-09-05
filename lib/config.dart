// Runtime/compile-time config toggles

// Build-time override: flutter build ... --dart-define=BYPASS_OTP=false
const bool kBypassOtp = bool.fromEnvironment('BYPASS_OTP', defaultValue: true);

// Backend base URL for REST OTP (device must reach this IP/host)
// Example for local LAN: --dart-define=BACKEND_URL=http://192.168.1.10:3000
const String kBackendBaseUrl = String.fromEnvironment('BACKEND_URL', defaultValue: 'http://localhost:3000');

// Use REST OTP service when not bypassing
const bool kUseRestOtp = bool.fromEnvironment('USE_REST_OTP', defaultValue: true);
