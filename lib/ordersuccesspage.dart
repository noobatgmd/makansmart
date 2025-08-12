// Updated ordersuccesspage.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:makansmart/cart_items.dart';
import 'package:makansmart/firebase_service.dart';

class OrderSuccessPage extends StatefulWidget {
  final List<CartItem> orderItems;
  final double totalAmount;
  final String? orderId;
  final bool? isInFoodCourt; // Add this to know if delivery was in food court
  final double? serviceFee; // Add this to pass service fee
  final double? deliveryFee; // Add this to pass delivery fee

  const OrderSuccessPage({
    Key? key,
    required this.orderItems,
    required this.totalAmount,
    this.orderId,
    this.isInFoodCourt,
    this.serviceFee,
    this.deliveryFee,
  }) : super(key: key);

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _orderDetails;
  bool _isLoadingOrderDetails = false;

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) {
      _loadOrderDetails();
    }
    _logOrderView();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => _isLoadingOrderDetails = true);

    try {
      final orderDetails = await _firebaseService.getOrderById(widget.orderId!);
      setState(() {
        _orderDetails = orderDetails;
      });
    } catch (e) {
      print('Error loading order details: $e');
    } finally {
      setState(() => _isLoadingOrderDetails = false);
    }
  }

  Future<void> _logOrderView() async {
    await _firebaseService.logUserAction('order_success_viewed', {
      'orderId': widget.orderId,
      'total': widget.totalAmount,
      'itemCount': widget.orderItems.length,
    });
  }

  double get _subtotal {
    return widget.orderItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  // Get service fee (use passed value or determine from order details)
  double get _serviceFee {
    if (widget.serviceFee != null) return widget.serviceFee!;

    // Try to get from order details
    if (_orderDetails != null && _orderDetails!['isInFoodCourt'] == false) {
      return 0.5;
    }

    // Fallback: determine from widget.isInFoodCourt
    if (widget.isInFoodCourt != null && !widget.isInFoodCourt!) {
      return 0.5;
    }

    return 0.0;
  }

  // Get delivery fee (use passed value or determine from order details)
  double get _deliveryFee {
    if (widget.deliveryFee != null) return widget.deliveryFee!;

    // Try to get from order details
    if (_orderDetails != null && _orderDetails!['isInFoodCourt'] == false) {
      return 0.5;
    }

    // Fallback: determine from widget.isInFoodCourt
    if (widget.isInFoodCourt != null && !widget.isInFoodCourt!) {
      return 0.5;
    }

    return 0.0;
  }

  // Check if this was a non-food court delivery
  bool get _hasDeliveryFees {
    return _serviceFee > 0 || _deliveryFee > 0;
  }

  String _getEstimatedDeliveryTime() {
    if (_orderDetails != null &&
        _orderDetails!['estimatedDeliveryTime'] != null) {
      final deliveryTime = _orderDetails!['estimatedDeliveryTime'].toDate();
      final now = DateTime.now();
      final difference = deliveryTime.difference(now).inMinutes;

      if (difference > 0) {
        return '$difference minutes';
      } else {
        return 'Soon';
      }
    }
    return '10 minutes';
  }

  String _getOrderStatus() {
    if (_orderDetails != null) {
      final status = _orderDetails!['status'] ?? 'pending';
      switch (status) {
        case 'pending':
          return 'Order Received';
        case 'preparing':
          return 'Preparing Your Food';
        case 'ready':
          return 'Ready for Pickup/Delivery';
        case 'delivered':
          return 'Delivered';
        case 'cancelled':
          return 'Order Cancelled';
        default:
          return 'Order Processed';
      }
    }
    return 'Order Processed';
  }

  Color _getStatusColor() {
    if (_orderDetails != null) {
      final status = _orderDetails!['status'] ?? 'pending';
      switch (status) {
        case 'pending':
          return Colors.orange;
        case 'preparing':
          return Colors.blue;
        case 'ready':
          return Color(0xFF8BC34A);
        case 'delivered':
          return Colors.green;
        case 'cancelled':
          return Colors.red;
        default:
          return Color(0xFF8BC34A);
      }
    }
    return Color(0xFF8BC34A);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            _buildCustomAppBar(context),

            // Success Message
            _buildSuccessMessage(),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Status and Details Section
                    _buildOrderStatusSection(),
                    SizedBox(height: 24),

                    // Order Items
                    ...widget.orderItems.map((item) => _buildOrderItem(item)),

                    SizedBox(height: 24),

                    // Payment Summary
                    _buildPaymentSummary(),

                    SizedBox(height: 24),

                    // Delivery Information
                    if (_orderDetails != null) _buildDeliveryInfo(),
                  ],
                ),
              ),
            ),

            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
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
              Navigator.popUntil(context, (route) => route.isFirst);
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
          Icon(Icons.check_circle, color: Colors.white, size: 24),
          SizedBox(width: 8),
          Text(
            'Order Success',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Spacer(),
          // Order ID
          if (widget.orderId != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${widget.orderId!.substring(0, 8).toUpperCase()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      margin: EdgeInsets.all(20),
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
          // Success Icon and Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🎉', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8BC34A),
                ),
              ),
              SizedBox(width: 8),
              Text('🎉', style: TextStyle(fontSize: 24)),
            ],
          ),
          SizedBox(height: 12),

          // Thank you message
          Text(
            'Thank You for using MakanSmart!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your food will arrive in about ${_getEstimatedDeliveryTime()}!',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusSection() {
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
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.info_outline, color: Colors.white, size: 12),
              ),
              SizedBox(width: 8),
              Text(
                'Order Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(),
                ),
              ),
              Spacer(),
              if (_isLoadingOrderDetails) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getStatusColor().withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getOrderStatus(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Estimated delivery: ${_getEstimatedDeliveryTime()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (_orderDetails != null &&
                    _orderDetails!['deliveryLocation'] != null) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _orderDetails!['isInFoodCourt'] == true
                            ? Icons.restaurant
                            : Icons.school,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        _orderDetails!['isInFoodCourt'] == true
                            ? 'Table ${_orderDetails!['deliveryLocation']}'
                            : 'Class ${_orderDetails!['deliveryLocation']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.description.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'SGD \$${(item.price * item.quantity).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD84315),
                ),
              ),
              if (item.quantity > 1) ...[
                SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Color(0xFF8BC34A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.payment, color: Colors.white, size: 12),
              ),
              SizedBox(width: 8),
              Text(
                'Payment Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8BC34A),
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
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                'SGD \$${_subtotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD84315),
                ),
              ),
            ],
          ),

          // Service Fee (only show if there was a service fee)
          if (_serviceFee > 0) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Service Fee',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                Text(
                  'SGD \$${_serviceFee.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD84315),
                  ),
                ),
              ],
            ),
          ],

          // Delivery Fee (only show if there was a delivery fee)
          if (_deliveryFee > 0) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Fee',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                Text(
                  'SGD \$${_deliveryFee.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD84315),
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 12),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                'SGD \$${widget.totalAmount.toStringAsFixed(2)}',
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

  Widget _buildDeliveryInfo() {
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
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Delivery Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _orderDetails!['isInFoodCourt'] == true
                          ? Icons.restaurant
                          : Icons.school,
                      size: 16,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 8),
                    Text(
                      _orderDetails!['isInFoodCourt'] == true
                          ? 'Food Court Delivery'
                          : 'Class Delivery',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  _orderDetails!['isInFoodCourt'] == true
                      ? 'Table ${_orderDetails!['deliveryLocation']}'
                      : 'Class ${_orderDetails!['deliveryLocation']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                if (_orderDetails!['foodCourtName'] != null) ...[
                  SizedBox(height: 4),
                  Text(
                    'From: ${_orderDetails!['foodCourtName']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(20),
      child: Column(
        children: [
          // Track Order Button (if order ID available)
          if (widget.orderId != null) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement order tracking page
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Order tracking feature coming soon!'),
                      backgroundColor: Color(0xFF8BC34A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFF8BC34A)),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(Icons.track_changes, color: Color(0xFF8BC34A)),
                label: Text(
                  'Track Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8BC34A),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
          ],

          // Back to Home Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8BC34A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              child: Text(
                'Back to Home Page',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
