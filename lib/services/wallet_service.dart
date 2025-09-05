import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletService {
  WalletService._();
  static final WalletService instance = WalletService._();

  static const _kBalanceKey = 'wallet:balance';
  final ValueNotifier<double> balance = ValueNotifier<double>(0);
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final b = prefs.getDouble(_kBalanceKey);
    // Default starting balance per requirement (e.g., 1000 rs)
    final initial = (b == null) ? 1000.0 : b;
    balance.value = initial;
    _loaded = true;
  }

  Future<void> _save(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kBalanceKey, value);
  }

  Future<bool> pay(double amount) async {
    await ensureLoaded();
    if (amount <= 0) return false;
    if (balance.value < amount) return false;
    final newBal = balance.value - amount;
    balance.value = newBal;
    await _save(newBal);
    return true;
  }

  Future<void> add(double amount) async {
    await ensureLoaded();
    if (amount <= 0) return;
    final newBal = balance.value + amount;
    balance.value = newBal;
    await _save(newBal);
  }
}

