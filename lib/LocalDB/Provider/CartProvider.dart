import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:quds_yaghmour/LocalDB/Models/product-model-vansale.dart';
import '../DataBase/DataBase.dart';
import '../Models/CartModel.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _cartItems = [];
  CartDatabaseHelper _dbHelper = CartDatabaseHelper();

  List<CartItem> get cartItems => _cartItems;

  CartProvider() {
    _init();
  }

  Future<void> _init() async {
    _cartItems = await _dbHelper.getCartItems();
    notifyListeners();
  }

  double calculateTotal() {
    double total = 0;
    for (CartItem item in _cartItems) {
      total += item.price * item.quantity;
    }
    return total;
  }

  // Future<void> addToCart(CartItem item) async {
  //   await _dbHelper.insertCartItem(item);
  //   _cartItems.add(item);
  //   // Refresh _cartItems with the latest data from the database
  //   _cartItems = await _dbHelper.getCartItems();
  //   notifyListeners();
  //   print("test");
  //   // Print cart items with product IDs as JSON
  //   List<int?> productIds = _cartItems.map((item) => item.productId).toList();
  //   print("jsonEncode(productIds)");
  //   print(jsonEncode(productIds));
  // }
  Future<void> addToCart(CartItem item) async {
    final existingIndex = _cartItems
        .indexWhere((cartItem) => cartItem.productId == item.productId);

    if (existingIndex != -1) {
      // Item already exists in the cart, increment the quantity
      _cartItems[existingIndex].quantity += item.quantity;
      await _dbHelper.updateCartItem(
          _cartItems[existingIndex]); // Update the item in the database
    } else {
      // Item does not exist in the cart, add it as a new item
      await _dbHelper.insertCartItem(item);
      _cartItems.add(item);
    }

    // Refresh _cartItems with the latest data from the database
    _cartItems = await _dbHelper.getCartItems();

    notifyListeners();
  }

  Future<void> removeFromCart(CartItem item) async {
    await _dbHelper.deleteCartItem(item.id!);
    _cartItems.remove(item);
    notifyListeners();
  }

  // void updateCartItemQuantity(int productId, double newQuantity) async {
  //   ProductVansale? cartItem =
  //       await _dbHelper.getProductVansaleItemByProductId(productId);
  //   if (cartItem != null) {
  //     double currentQuantity = double.parse(cartItem.quantity.toString());
  //     double updatedQuantity = currentQuantity - newQuantity;
  //     if (updatedQuantity < 0) {
  //       updatedQuantity = 0;
  //     }
  //     cartItem.quantity = updatedQuantity.toString();
  //     cartItem.id = productId.toString();
  //     await _dbHelper.updateProductVansaleItem(cartItem);
  //     _cartItems = await _dbHelper.getCartItems();
  //     notifyListeners();
  //   } else {
  //     print("Cart item with productId $productId not found in database.");
  //   }
  // }

  Future<void> clearCart() async {
    _cartItems.clear(); // Clear the cart items in memory
    await _dbHelper.clearCart(); // Clear the cart items from the local database
    notifyListeners(); // Notify the listeners about the change
  }

  void updateCartItem(CartItem item) async {
    await _dbHelper.updateCartItem(item);
    // Refresh _cartItems with the latest data from the database
    _cartItems = await _dbHelper.getCartItems();
    notifyListeners();
  }

  // Future<CartItem?> getCartItemByProductId(int productId) async {
  //   return await CartDatabaseHelper().getCartItemByProductId(productId);
  // }

  List<Map<String, dynamic>> getProductsArray() {
    List<Map<String, dynamic>> productsArray = [];

    for (CartItem item in _cartItems) {
      Map<String, dynamic> productData = {
        'product_id': item.productId,
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'discount': item.discount,
        'color': item.color,
        'ponus1': item.ponus1,
        'ponus2': item.ponus2,
        'notes': item.notes,
        'productBarcode': item.productBarcode,
      };
      productsArray.add(productData);
    }

    return productsArray;
  }
}
