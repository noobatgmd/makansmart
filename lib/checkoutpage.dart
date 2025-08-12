import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:makansmart/ordersuccesspage.dart';
import 'card_details_page.dart';
import 'package:makansmart/cart_items.dart';
import 'package:makansmart/cart_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Order History Manager Class - Add this to your checkout page
class OrderHistoryManager {
  static const String _lastOrderKey = 'last_order_data';
  static const String _lastOrderTotalKey = 'last_order_total';

  static Future<void> saveLastOrder(List<CartItem> items, double total) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert cart items to JSON
      List<Map<String, dynamic>> itemsJson = items
          .map(
            (item) => {
              'name': item.name,
              'description': item.description,
              'price': item.price,
              'quantity': item.quantity,
              'imagePath': item.imagePath,
              'emoji': item.emoji,
            },
          )
          .toList();

      await prefs.setString(_lastOrderKey, json.encode(itemsJson));
      await prefs.setDouble(_lastOrderTotalKey, total);

      print('Order saved successfully to history');
    } catch (e) {
      print('Error saving order to history: $e');
    }
  }

  static Future<Map<String, dynamic>?> getLastOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderData = prefs.getString(_lastOrderKey);
      final orderTotal = prefs.getDouble(_lastOrderTotalKey);

      if (orderData != null && orderTotal != null) {
        List<dynamic> itemsJson = json.decode(orderData);
        List<CartItem> items = itemsJson
            .map(
              (item) => CartItem(
                name: item['name'],
                description: item['description'] ?? '',
                price: item['price'].toDouble(),
                quantity: item['quantity'],
                imagePath: item['imagePath'] ?? '',
                emoji: item['emoji'] ?? '🍽️',
              ),
            )
            .toList();

        return {'items': items, 'total': orderTotal};
      }
    } catch (e) {
      print('Error loading last order: $e');
    }
    return null;
  }

  static Future<bool> hasLastOrder() async {
    final lastOrder = await getLastOrder();
    return lastOrder != null;
  }
}

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;

  const CheckoutPage({Key? key, required this.cartItems}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  Map<String, String>? _savedCardDetails;
  bool _isLoading = false;
  bool _isInFoodCourt = true; // Default to food court
  String _tableNumber = '';
  String _className = '';
  final TextEditingController _tableController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final CartManager _cartManager = CartManager();

  // Keep a local copy of cart items that we can modify
  late List<CartItem> _currentCartItems;

  @override
  void initState() {
    super.initState();
    _currentCartItems = List.from(widget.cartItems);
    _loadSavedCardDetails();
  }

  @override
  void dispose() {
    _tableController.dispose();
    _classController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCardDetails() async {
    // This would typically load from your existing card details logic
    // For now, I'll simulate some saved card data
    setState(() {
      _savedCardDetails = {
        'cardNumber': '**** **** **** 3456',
        'nameOnCard': 'Jason',
      };
    });
  }

  double get _subtotal {
    return _currentCartItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  double get _serviceFee {
    return !_isInFoodCourt ? 0.5 : 0.0;
  }

  double get _deliveryFee {
    return !_isInFoodCourt ? 0.5 : 0.0;
  }

  double get _total {
    return _subtotal + _serviceFee + _deliveryFee;
  }

  void _navigateToCardDetails() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardDetailsPage(
          onCardSaved: (cardDetails) {
            setState(() {
              _savedCardDetails = cardDetails;
            });
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _savedCardDetails = result;
      });
    }
  }

  // Show confirmation dialog before removing item
  void _showRemoveItemDialog(CartItem item, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                'Remove Item',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
              children: [
                TextSpan(text: 'Are you sure you want to remove '),
                TextSpan(
                  text: item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                TextSpan(text: ' from your cart?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeItemFromCart(index);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Remove',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // Remove item from cart
  void _removeItemFromCart(int index) {
    setState(() {
      final removedItem = _currentCartItems[index];
      _currentCartItems.removeAt(index);

      // Also remove from the actual cart manager using the correct method name
      _cartManager.removeFromCart(removedItem.name);
    });

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Item removed from cart'),
          ],
        ),
        backgroundColor: Color(0xFF8BC34A),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    // If cart is empty, go back to previous screen
    if (_currentCartItems.isEmpty) {
      Navigator.pop(context);
    }
  }

  void _placeOrder() async {
    if (_currentCartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_savedCardDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate location details
    if (_isInFoodCourt && _tableNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your table number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isInFoodCourt && _className.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your class'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate order processing
      await Future.delayed(Duration(seconds: 2));

      // 🔥 KEY ADDITION: Save order to history BEFORE clearing cart and navigating
      await OrderHistoryManager.saveLastOrder(_currentCartItems, _total);

      // Clear the cart after successful order
      _cartManager.clearCart();

      setState(() {
        _isLoading = false;
      });

      // Navigate to success page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderSuccessPage(
            orderItems: _currentCartItems,
            totalAmount: _total,
            isInFoodCourt: _isInFoodCourt,
            serviceFee: _serviceFee,
            deliveryFee: _deliveryFee,
          ),
        ),
      );

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Order placed successfully!'),
            ],
          ),
          backgroundColor: Color(0xFF8BC34A),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to place order. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      print('Error placing order: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            _buildCustomAppBar(),

            // Review Your Order Header
            _buildReviewOrderHeader(),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Method Section
                    _buildPaymentMethodSection(),
                    SizedBox(height: 24),

                    // Location Section
                    _buildLocationSection(),
                    SizedBox(height: 24),

                    // Order Items
                    ..._currentCartItems.asMap().entries.map((entry) {
                      int index = entry.key;
                      CartItem item = entry.value;
                      return _buildOrderItem(item, index);
                    }),

                    SizedBox(height: 24),

                    // Order Summary
                    _buildOrderSummary(),
                  ],
                ),
              ),
            ),

            // Place Order Button
            _buildPlaceOrderButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8BC34A), Color(0xFF9CCC65)],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          SizedBox(width: 16),
          Text(
            'Checkout',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewOrderHeader() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF8BC34A).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF8BC34A).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(0xFF8BC34A),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Text(
            'Review Your Order',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.lightGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.payment, color: Colors.white, size: 12),
              ),
              SizedBox(width: 8),
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.lightGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          if (_savedCardDetails != null) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF8BC34A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF8BC34A).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.credit_card, color: Color(0xFF8BC34A), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _savedCardDetails!['cardNumber'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Text(
                          _savedCardDetails!['nameOnCard'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _navigateToCardDetails,
                    child: Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.lightGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: _navigateToCardDetails,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.grey[600]),
                    SizedBox(width: 12),
                    Text(
                      'Add Payment Method',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.lightGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.location_on, color: Colors.white, size: 12),
              ),
              SizedBox(width: 8),
              Text(
                'Delivery Location',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.lightGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Food Court Toggle
          Row(
            children: [
              Text(
                'Are you in the food court?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isInFoodCourt = true;
                      _className = '';
                      _classController.clear();
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _isInFoodCourt
                          ? Color(0xFF8BC34A).withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isInFoodCourt
                            ? Color(0xFF8BC34A)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 16,
                          color: _isInFoodCourt
                              ? Color(0xFF8BC34A)
                              : Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Yes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _isInFoodCourt
                                ? Color(0xFF8BC34A)
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isInFoodCourt = false;
                      _tableNumber = '';
                      _tableController.clear();
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: !_isInFoodCourt
                          ? Color(0xFF8BC34A).withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !_isInFoodCourt
                            ? Color(0xFF8BC34A)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school,
                          size: 16,
                          color: !_isInFoodCourt
                              ? Color(0xFF8BC34A)
                              : Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'No',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: !_isInFoodCourt
                                ? Color(0xFF8BC34A)
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Additional fee notice for non-food court delivery
          if (!_isInFoodCourt) ...[
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Additional service fee (\$0.50) and delivery fee (\$0.50) apply for outside food court delivery.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Conditional Input Field
          if (_isInFoodCourt) ...[
            Text(
              'Table Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _tableController,
              onChanged: (value) {
                setState(() {
                  _tableNumber = value;
                });
              },
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter your table number',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF8BC34A), width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ] else ...[
            Text(
              'Location',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _classController,
              onChanged: (value) {
                setState(() {
                  _className = value;
                });
              },
              decoration: InputDecoration(
                hintText:
                    'Enter your Location (e.g., Class - T18B504, Study Area - T11Square, Different Food Courts? etc...)',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF8BC34A), width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItem item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Food Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imagePath.isNotEmpty
                  ? Image.asset(
                      item.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            item.emoji,
                            style: TextStyle(fontSize: 24),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(item.emoji, style: TextStyle(fontSize: 24)),
                    ),
            ),
          ),
          SizedBox(width: 16),

          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.description.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Quantity, Price, and Delete Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'SGD \$${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8BC34A),
                        ),
                      ),
                      if (item.quantity > 1) ...[
                        SizedBox(height: 4),
                        Text(
                          'Qty: ${item.quantity}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(width: 12),
                  // Delete Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showRemoveItemDialog(item, index);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.lightGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.receipt, color: Colors.white, size: 12),
              ),
              SizedBox(width: 8),
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.lightGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                'SGD \$${_subtotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),

          // Service Fee (only if not in food court)
          if (!_isInFoodCourt) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Service Fee',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  'SGD \$${_serviceFee.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ],

          // Delivery Fee (only if not in food court)
          if (!_isInFoodCourt) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Fee',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  'SGD \$${_deliveryFee.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 16),
          Divider(color: Colors.grey[200]),
          SizedBox(height: 16),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                'SGD \$${_total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8BC34A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: _isLoading || _currentCartItems.isEmpty ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF8BC34A),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Processing...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              )
            : Text(
                _currentCartItems.isEmpty ? 'Cart is Empty' : 'Place Order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
