import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  CartProvider(this._cartService) {
    _init();
  }

  final CartService _cartService;
  List<CartItemModel> _items = [];
  bool _loading = false;

  List<CartItemModel> get items => _items;
  bool get loading => _loading;
  int get count => _items.fold(0, (sum, e) => sum + e.quantity);

  int get total => _items.fold(0, (sum, e) => sum + e.subtotal);

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  Future<void> _init() async {
    _loading = true;
    notifyListeners();
    _items = await _cartService.getCart();
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _items = await _cartService.getCart();
    notifyListeners();
  }

  Future<bool> addToCart(CartItemModel item) async {
    // Check stock for physical products
    if (item.type == 'physical' && item.stock <= 0) {
      return false;
    }
    await _cartService.addToCart(item);
    _items = await _cartService.getCart();
    notifyListeners();
    return true;
  }

  Future<void> updateQuantity(String cartKey, int qty) async {
    final item = _items.firstWhere((e) => e.cartKey == cartKey, orElse: () => _items.first);
    if (item.type == 'physical' && qty > item.stock) return;
    await _cartService.updateQuantity(cartKey, qty);
    _items = await _cartService.getCart();
    notifyListeners();
  }

  Future<void> removeItem(String cartKey) async {
    await _cartService.removeItem(cartKey);
    _items = await _cartService.getCart();
    notifyListeners();
  }

  Future<void> clearCart() async {
    await _cartService.clearCart();
    _items = [];
    notifyListeners();
  }
}
