import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';

class CartService {
  static const String _cartKey = 'fomi_cart';

  Future<List<CartItemModel>> getCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cartKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCart(List<CartItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<void> addToCart(CartItemModel newItem) async {
    final cart = await getCart();
    final idx = cart.indexWhere((e) => e.cartKey == newItem.cartKey);
    if (idx >= 0) {
      final existing = cart[idx];
      final maxQty = newItem.stock > 0 ? newItem.stock : 9999;
      cart[idx] = existing.copyWith(quantity: (existing.quantity + 1).clamp(1, maxQty));
    } else {
      cart.add(newItem);
    }
    await _saveCart(cart);
  }

  Future<void> updateQuantity(String cartKey, int qty) async {
    final cart = await getCart();
    final idx = cart.indexWhere((e) => e.cartKey == cartKey);
    if (idx >= 0) {
      if (qty <= 0) {
        cart.removeAt(idx);
      } else {
        cart[idx] = cart[idx].copyWith(quantity: qty);
      }
    }
    await _saveCart(cart);
  }

  Future<void> removeItem(String cartKey) async {
    final cart = await getCart();
    cart.removeWhere((e) => e.cartKey == cartKey);
    await _saveCart(cart);
  }

  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }
}
