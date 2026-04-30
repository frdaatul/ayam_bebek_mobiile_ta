import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteModel {
  static Set<int> favoriteProductIds = {};
  static const String _storageKey = 'favorite_products_data';

  // Load favorites from local storage
  static Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favString = prefs.getString(_storageKey);
    
    if (favString != null && favString.isNotEmpty) {
      try {
        final List<dynamic> decodedList = json.decode(favString);
        favoriteProductIds = decodedList.cast<int>().toSet();
      } catch (e) {
        favoriteProductIds = {};
      }
    }
  }

  // Save favorites to local storage
  static Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(favoriteProductIds.toList());
    await prefs.setString(_storageKey, encodedData);
  }

  static bool isFavorited(int productId) {
    return favoriteProductIds.contains(productId);
  }

  static void toggleFavorite(int productId) {
    if (favoriteProductIds.contains(productId)) {
      favoriteProductIds.remove(productId);
    } else {
      favoriteProductIds.add(productId);
    }
    saveFavorites();
  }
}
