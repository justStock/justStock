import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/otp_service.dart';
import '../home/home_page.dart';

class OtpPage extends StatefulWidget {
  final String? name;
  final String phoneE164;
  final OtpSession session;
  final OtpService service;

  const OtpPage({super.key, this.name, required this.phoneE164, required this.session, required this.service});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _codeController = TextEditingController();
  bool _verifying = false;
  int _seconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) return;
      setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;
    setState(() => _verifying = true);
    final ok = await widget.service.verifyOtp(sessionId: widget.session.id, code: code);
    if (!mounted) return;
    setState(() => _verifying = false);
    if (ok) {
      final homeName = (widget.name?.trim().isNotEmpty ?? false) ? widget.name!.trim() : 'Trader';
      Navigator.of(context).pushReplacementNamed(
        HomePage.routeName,
        arguments: HomeArgs(name: homeName),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP, try again')));
    }
  }

  Future<void> _resend() async {
    if (_seconds > 0) return;
    final s = await widget.service.sendOtp(phoneE164: widget.phoneE164);
    setState(() {
      _seconds = 60;
    });
    // Replace old session with new
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => OtpPage(name: widget.name, phoneE164: widget.phoneE164, session: s, service: widget.service),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Code sent to ${widget.phoneE164}', textAlign: TextAlign.center),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Debug OTP: ${widget.session.debugCode}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700)),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter 6-digit OTP',
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _codeController.text.trim().length == 6 && !_verifying ? _verify : null,
              child: _verifying ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Verify'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _seconds == 0 ? _resend : null,
              child: Text(_seconds == 0 ? 'Resend OTP' : 'Resend in $_seconds s'),
            ),
          ],
        ),
      ),
    );
  }
}
