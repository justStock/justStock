import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  String _key({required String category, required String action, String? stock}) {
    // category: nifty|banknifty|sensex|commodity|stock
    // action: fo|call|put
    // for stock, include stock name in key
    final normStock = (stock ?? '').trim().toUpperCase();
    return stock == null || stock.isEmpty
        ? 'advice:$category:$action'
        : 'advice:$category:$normStock:$action';
  }

  Future<void> setAdvice({required String category, required String action, String? stock, required String text}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(category: category, action: action, stock: stock), text);
  }

  Future<String?> getAdvice({required String category, required String action, String? stock}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(category: category, action: action, stock: stock));
  }
}

