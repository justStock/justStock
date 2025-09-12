// Runtime/compile-time config toggles

// Build-time override: flutter build ... --dart-define=BYPASS_OTP=true
// Set default to false to use real OTP by default
const bool kBypassOtp = bool.fromEnvironment('BYPASS_OTP', defaultValue: false);

// Backend base URL for REST OTP (device must reach this IP/host)
// Example for local LAN: --dart-define=BACKEND_URL=http://192.168.1.10:4000/api
// For the provided API, default to localhost:4000/api
const String kBackendBaseUrl = String.fromEnvironment('BACKEND_URL', defaultValue: 'http://localhost:4000/api');

// Use REST OTP service when not bypassing
const bool kUseRestOtp = bool.fromEnvironment('USE_REST_OTP', defaultValue: true);
