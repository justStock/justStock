import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home/home_page.dart';
import 'screens/wallet/wallet_page.dart';
import 'screens/advice/advice_page.dart';
import 'services/otp_service.dart';
import 'services/otp_service_rest.dart';
import 'screens/auth/otp_page.dart';
import 'package:video_player/video_player.dart';
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

class _SplashScreenState extends State<SplashScreen> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('lib/loader.mp4')
      ..setLooping(false)
      ..setVolume(0.0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        _controller.addListener(_onVideoEvent);
        _controller.play();
      });
  }

  void _onVideoEvent() {
    if (_navigated) return;
    final v = _controller.value;
    if (v.isInitialized && !v.isPlaying) {
      // Consider finished when playback stops after reaching (near) duration
      final finished = v.position >= v.duration - const Duration(milliseconds: 200);
      if (finished) {
        _navigated = true;
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AuthPage.routeName);
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoEvent);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _initialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(),
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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  late final OtpService _otpService;

  get children => null;

  @override
  void dispose() {
    _nameController.dispose();
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
    final name = _nameController.text.trim();
    final phoneRaw = _phoneController.text.trim();
    final phoneE164 = '+91' + phoneRaw;

    if (kBypassOtp) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        HomePage.routeName,
        arguments: HomeArgs(name: name),
      );
      return;
    }

    final session = await _otpService.sendOtp(phoneE164: phoneE164);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpPage(
          name: name,
          phoneE164: phoneE164,
          session: session,
          service: _otpService,
        ),
      ),
    );
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
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Name is required';
                  if (v.length < 2) return 'Enter a valid name';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _continue,
                icon: const Icon(Icons.login),
                label: const Text('Continue'),
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
