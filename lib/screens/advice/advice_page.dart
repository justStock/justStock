import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/wallet_service.dart';
import '../../services/admin_service.dart';

class AdviceArgs {
  final String category; // 'nifty' | 'banknifty' | 'sensex' | 'commodity' | 'stock'
  final String? presetStock; // optional prefilled stock (from admin)
  const AdviceArgs({required this.category, this.presetStock});
}

class AdvicePage extends StatefulWidget {
  static const routeName = '/advice';
  const AdvicePage({super.key});

  @override
  State<AdvicePage> createState() => _AdvicePageState();
}

class _AdvicePageState extends State<AdvicePage> {
  final _wallet = WalletService.instance;
  final _admin = AdminService.instance;
  String _action = 'fo'; // 'fo' | 'call' | 'put'
  final _stockController = TextEditingController();
  String? _advice;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _wallet.ensureLoaded();
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }
  

  Future<void> _payAndFetch() async {
    final args = ModalRoute.of(context)?.settings.arguments as AdviceArgs?;
    if (args == null) return;
    final category = args.category;
    final isStock = category == 'stock';
    final stockName = isStock ? _stockController.text.trim() : null;
    if (isStock && (stockName == null || stockName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter stock name')));
      return;
    }
    setState(() => _loading = true);
    final ok = await _wallet.pay(100);
    if (!ok) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance')));
      }
      return;
    }
    final text = await _admin.getAdvice(category: category, action: _action, stock: stockName ?? args.presetStock);
    if (mounted) {
      setState(() {
        _advice = text ?? 'Admin advice not set yet for this selection.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as AdviceArgs?;
    final category = args?.category ?? 'nifty';
    final isStock = category == 'stock';
    if (args?.presetStock != null && _stockController.text.isEmpty) {
      _stockController.text = args!.presetStock!;
    }

    final title = switch (category) {
      'nifty' => 'NIFTY',
      'banknifty' => 'BANKNIFTY',
      'sensex' => 'SENSEX',
      'commodity' => 'Commodity',
      'stock' => 'Stock',
      _ => category,
    };

    return Scaffold(
      appBar: AppBar(title: Text('$title Advice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ValueListenableBuilder<double>(
            valueListenable: _wallet.balance,
            builder: (context, bal, _) => Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined),
                const SizedBox(width: 8),
                Text('Wallet: \u20B9${bal.toStringAsFixed(2)}'),
                const Spacer(),
                TextButton(onPressed: () => _wallet.add(500), child: const Text('Add 500')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Choose Option', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Futures & Options'), selected: _action == 'fo', onSelected: (_) => setState(() => _action = 'fo')),
              ChoiceChip(label: const Text('Call'), selected: _action == 'call', onSelected: (_) => setState(() => _action = 'call')),
              ChoiceChip(label: const Text('Put'), selected: _action == 'put', onSelected: (_) => setState(() => _action = 'put')),
            ],
          ),
          if (isStock) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _stockController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Stock Name (e.g., RELIANCE, TCS)'),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _payAndFetch,
            child: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Pay \u20B9100 and See Result'),
          ),
          if (_advice != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Admin Advice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(_advice!),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

