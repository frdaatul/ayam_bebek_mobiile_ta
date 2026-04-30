import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartModel {
  static List<Map<String, dynamic>> cartItems = [];
  static const String _storageKey = 'cart_items_data';

  // Load keranjang saat aplikasi pertama kali jalan
  static Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartString = prefs.getString(_storageKey);
    
    if (cartString != null && cartString.isNotEmpty) {
      try {
        final List<dynamic> decodedList = json.decode(cartString);
        cartItems = decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
      } catch (e) {
        cartItems = [];
      }
    }
  }

  // Simpan keranjang ke penyimpanan lokal
  static Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(cartItems);
    await prefs.setString(_storageKey, encodedData);
  }

  static void addItem(Map<String, dynamic> product, {int quantity = 1}) {
    int index = cartItems.indexWhere((item) => item['id'] == product['id']);

    if (index != -1) {
      cartItems[index]['quantity'] = (cartItems[index]['quantity'] ?? 1) + quantity;
    } else {
      Map<String, dynamic> newItem = Map<String, dynamic>.from(product);
      newItem['quantity'] = quantity;
      cartItems.add(newItem);
    }
    saveCart(); // Simpan setiap kali ada perubahan
  }

  static void updateQuantity(int index, int delta) {
    if (index >= 0 && index < cartItems.length) {
      int newQty = (cartItems[index]['quantity'] ?? 1) + delta;
      if (newQty > 0) {
        cartItems[index]['quantity'] = newQty;
        saveCart(); // Simpan setiap kali ada perubahan
      }
    }
  }

  static void removeItem(int index) {
    if (index >= 0 && index < cartItems.length) {
      cartItems.removeAt(index);
      saveCart(); // Simpan setiap kali ada perubahan
    }
  }

  static List<Map<String, dynamic>> getItems() {
    return cartItems;
  }

  static int getTotalPrice() {
    int total = 0;
    for (var item in cartItems) {
      final rawPrice = item["price"];
      final qty = item["quantity"] ?? 1;
      if (rawPrice != null) {
        int unitPrice = double.tryParse(rawPrice.toString())?.toInt() ?? 0;
        total += unitPrice * (qty as int);
      }
    }
    return total;
  }

  static void clear() {
    cartItems = [];
    saveCart();
  }
}