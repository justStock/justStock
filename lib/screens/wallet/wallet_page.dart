import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/profile_service.dart';

class WalletArgs {
  final String name;
  final double? balance;
  const WalletArgs({required this.name, this.balance});
}

class WalletPage extends StatefulWidget {
  static const routeName = '/wallet';
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final ProfileService _profile = ProfileService.instance;

  @override
  void initState() {
    super.initState();
    _profile.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final args = ModalRoute.of(context)?.settings.arguments;
    final name = (args is WalletArgs && args.name.trim().isNotEmpty)
        ? args.name.trim()
        : 'Trader';
    final balance = (args is WalletArgs && args.balance != null)
        ? args.balance!
        : 25000.50; // placeholder balance
    final initial = name[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showImagePicker,
                  child: ValueListenableBuilder<String?>(
                    valueListenable: _profile.imagePath,
                    builder: (context, path, _) {
                      if (path != null && File(path).existsSync()) {
                        return CircleAvatar(
                          radius: 44,
                          backgroundImage: FileImage(File(path)),
                        );
                      }
                      return CircleAvatar(
                        radius: 44,
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        child: Text(initial, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Centered wallet balance
          Card(
            elevation: 0,
            color: cs.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text('Wallet Balance', style: TextStyle(color: cs.onPrimaryContainer.withOpacity(0.8))),
                  const SizedBox(height: 8),
                  Text(
                    '\u20B9${balance.toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Add Money')),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(onPressed: () {}, icon: const Icon(Icons.upload), label: const Text('Withdraw')),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Account Details'),
          Card(
            child: Column(
              children: const [
                ListTile(leading: Icon(Icons.badge_outlined), title: Text('Account Name'), subtitle: Text('Your advisory account')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.phone_iphone), title: Text('Phone'), subtitle: Text('Linked mobile number')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.email_outlined), title: Text('Email'), subtitle: Text('Add email for updates')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.account_balance), title: Text('Linked Bank'), subtitle: Text('Add bank to withdraw')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Other Details'),
          Card(
            child: Column(
              children: const [
                ListTile(leading: Icon(Icons.history), title: Text('Transactions')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.workspace_premium), title: Text('Plan: Basic')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.help_center_outlined), title: Text('Help & Support')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePicker() async {
    final context = this.context;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pickerButton(Icons.photo_library, 'Gallery', () => _pick(ImageSource.gallery)),
                _pickerButton(Icons.photo_camera, 'Camera', () => _pick(ImageSource.camera)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pickerButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            Navigator.of(context).pop();
            onTap();
          },
          child: CircleAvatar(radius: 28, child: Icon(icon)),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Future<void> _pick(ImageSource source) async {
    await _profile.setImageFromPicker(source);
    setState(() {});
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }
}

