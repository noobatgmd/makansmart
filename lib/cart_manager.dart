// Updated cart_manager.dart
import 'package:flutter/foundation.dart';
import 'package:makansmart/cart_items.dart';
import 'package:makansmart/firebase_service.dart';

class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final FirebaseService _firebaseService = FirebaseService();

  List<CartItem> _cartItems = [];
  String _currentFoodCourt = '';
  bool _isLoading = false;
  bool _isInitialized = false;

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  String get currentFoodCourt => _currentFoodCourt;
  bool get isLoading => _isLoading;

  double get cartTotal {
    return _cartItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  int get cartItemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get hasItems => _cartItems.isNotEmpty;

  // Initialize cart by loading from Firebase
  Future<void> initializeCart() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.ensureUserAuthenticated();
      await _loadCartFromFirebase();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load cart from Firebase
  Future<void> _loadCartFromFirebase() async {
    try {
      final cartData = await _firebaseService.getCartFromFirebase();
      if (cartData != null) {
        _cartItems = List<CartItem>.from(cartData['items']);
        _currentFoodCourt = cartData['foodCourtName'] ?? '';
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart from Firebase: $e');
    }
  }

  // Save cart to Firebase
  Future<void> _saveCartToFirebase() async {
    try {
      if (_cartItems.isNotEmpty) {
        await _firebaseService.saveCartToFirebase(
          _cartItems,
          _currentFoodCourt,
        );
      } else {
        await _firebaseService.clearCartFromFirebase();
      }
    } catch (e) {
      print('Error saving cart to Firebase: $e');
    }
  }

  Future<void> setFoodCourt(String foodCourtName) async {
    if (_currentFoodCourt != foodCourtName) {
      // Only clear cart if switching to a different food court
      if (_currentFoodCourt.isNotEmpty && _cartItems.isNotEmpty) {
        await clearCart();
      }
      _currentFoodCourt = foodCourtName;
      notifyListeners();
      await _saveCartToFirebase();
    }
  }

  Future<void> addToCart(CartItem newItem) async {
    // Check if item already exists in cart
    final existingIndex = _cartItems.indexWhere(
      (item) => item.name == newItem.name,
    );

    if (existingIndex != -1) {
      // Update quantity if item exists
      _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
        quantity: _cartItems[existingIndex].quantity + 1,
      );
    } else {
      // Add new item to cart
      _cartItems.add(newItem);
    }

    notifyListeners();
    await _saveCartToFirebase();
  }

  Future<void> removeFromCart(String itemName) async {
    _cartItems.removeWhere((item) => item.name == itemName);
    notifyListeners();
    await _saveCartToFirebase();
  }

  Future<void> updateQuantity(String itemName, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(itemName);
      return;
    }

    final index = _cartItems.indexWhere((item) => item.name == itemName);
    if (index != -1) {
      _cartItems[index] = _cartItems[index].copyWith(quantity: newQuantity);
      notifyListeners();
      await _saveCartToFirebase();
    }
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    notifyListeners();
    await _firebaseService.clearCartFromFirebase();
  }

  // Get quantity of a specific item
  int getItemQuantity(String itemName) {
    final item = _cartItems.firstWhere(
      (item) => item.name == itemName,
      orElse: () => CartItem(
        name: '',
        imagePath: '',
        emoji: '',
        price: 0,
        description: '',
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  // Sync cart with Firebase (useful for manual refresh)
  Future<void> syncWithFirebase() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadCartFromFirebase();
    } catch (e) {
      print('Error syncing cart with Firebase: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create order from current cart
  Future<String?> createOrder({
    required bool isInFoodCourt,
    required String deliveryLocation,
    Map<String, String>? paymentDetails,
  }) async {
    if (_cartItems.isEmpty) return null;

    try {
      final orderId = await _firebaseService.saveOrder(
        items: _cartItems,
        total: cartTotal,
        foodCourtName: _currentFoodCourt,
        isInFoodCourt: isInFoodCourt,
        deliveryLocation: deliveryLocation,
        paymentDetails: paymentDetails,
      );

      if (orderId != null) {
        // Clear cart after successful order
        await clearCart();
      }

      return orderId;
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }
}
