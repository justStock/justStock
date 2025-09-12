import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'screens/home/home_page.dart';
import 'screens/wallet/wallet_page.dart';
import 'screens/advice/advice_page.dart';
import 'services/otp_service.dart';
import 'services/otp_service_rest.dart';
import 'screens/auth/otp_page.dart';
import 'config.dart';
import 'screens/market/detail_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Build a teal-green advisory theme similar to the screenshot
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F5D50), // deep teal green
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'Just Stock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor:
            const Color(0xFFEFF6F3), // light mint background
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F5D50),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F5D50),
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F5D50),
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFE2F1EB), // unselected mint
          selectedColor: const Color(0xFFCBE9E0), // selected mint
          labelStyle: TextStyle(color: scheme.onSurface),
          selectedShadowColor: Colors.transparent,
          disabledColor: const Color(0xFFE8F3EF),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFFF5F7F6),
          indicatorColor: Color(0xFFCBE9E0),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        AuthPage.routeName: (_) => const AuthPage(),
        HomePage.routeName: (_) => const HomePage(),
        WalletPage.routeName: (_) => const WalletPage(),
        AdvicePage.routeName: (_) => const AdvicePage(),
        MarketDetailPage.routeName: (_) => const MarketDetailPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _navigated = false;
  Timer? _navTimer;
  bool _animReady = false;
  late final AnimationController _controller;
  late final Animation<double> _tilt;
  late final Animation<double> _bob;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    // Keep splash visible briefly so it’s noticeable on Android/iOS
    _navTimer = Timer(const Duration(milliseconds: 1000), _goNext);
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => const AuthPage(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    if (_animReady) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_animReady) {
      _controller =
          AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
            ..repeat(reverse: true);
      _tilt = Tween<double>(begin: -0.03, end: 0.03)
          .chain(CurveTween(curve: Curves.easeInOut))
          .animate(_controller);
      _bob = Tween<double>(begin: -6, end: 6)
          .chain(CurveTween(curve: Curves.easeInOut))
          .animate(_controller);
      _glow = Tween<double>(begin: 0.3, end: 0.85)
          .chain(CurveTween(curve: Curves.easeInOut))
          .animate(_controller);
      _animReady = true;
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated image with subtle wobble/bob and glow
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: _glow.value * 0.5,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.amber.withOpacity(0.35),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, _bob.value),
                        child: Transform.rotate(
                          angle: _tilt.value,
                          child: child,
                        ),
                      ),
                    ],
                  );
                },
                child: const Image(
                  image: AssetImage('lib/logo.png'),
                  width: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  static const routeName = '/auth';
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  late final OtpService _otpService;
  bool _sendingOtp = false;

  get children => null;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Choose OTP backend
    if (!kBypassOtp && kUseRestOtp) {
      _otpService = RestOtpService();
    } else {
      _otpService = MockOtpService();
    }
  }

  Future<void> _continue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phone = _phoneController.text.trim();
    if (kBypassOtp) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        HomePage.routeName,
        // No name collected; HomePage will default to 'Trader'
      );
      return;
    }
    setState(() => _sendingOtp = true);
    try {
      final session = await _otpService.sendOtp(phoneE164: phone);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpPage(
            // name omitted; OtpPage will handle default
            phoneE164: phone,
            session: session,
            service: _otpService,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login / Register'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text('Welcome to Just Stock', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Phone number is required';
                  if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(v)) {
                    return 'Enter 10-digit Indian number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _sendingOtp ? null : _continue,
                icon: const Icon(Icons.sms),
                label: _sendingOtp
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send OTP'),
              ),
              const SizedBox(height: 8),
              Text(
                'By continuing you can login or create a new account.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Home-related classes moved to lib/screens/home/home_page.dart
