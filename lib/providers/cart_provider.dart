import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];

  CartProvider() {
    _loadCart();
  }

  List<CartItem> get items => [..._items];

  int get itemCount => _items.length;

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString('cart_items');
      if (cartString != null) {
        final List<dynamic> decoded = jsonDecode(cartString);
        _items = decoded.map((item) => CartItem.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
      await prefs.setString('cart_items', encoded);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  void addItem(CartItem item) {
    _items.add(item);
    _saveCart();
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _saveCart();
    notifyListeners();
  }

  void updateItem(CartItem updatedItem) {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index >= 0) {
      _items[index] = updatedItem;
      _saveCart();
      notifyListeners();
    }
  }

  void updateItemDuration(String id, int newDurationMinutes) {
    if (newDurationMinutes < 15) return; // Prevent going below 15 mins
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index] = CartItem(
        id: _items[index].id,
        category: _items[index].category,
        durationMinutes: newDurationMinutes,
        isInstant: _items[index].isInstant,
        scheduledDate: _items[index].scheduledDate,
        scheduledTime: _items[index].scheduledTime,
        workerCount: _items[index].workerCount,
        workType: _items[index].workType,
        taskImagesBase64: _items[index].taskImagesBase64,
        taskAudioBase64: _items[index].taskAudioBase64,
        taskNotes: _items[index].taskNotes,
      );
      _saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }
}

