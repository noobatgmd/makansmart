// Debugged food_court_selection_screen.dart with better order detection
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:makansmart/foodcourtdetailsscreen.dart';
import 'package:makansmart/ordersuccesspage.dart';
import 'package:makansmart/profile_settings.dart';
import 'package:makansmart/cart_items.dart';
import 'package:makansmart/cart_manager.dart';
import 'package:makansmart/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
// 🔥 ADD THIS IMPORT for SharedPreferences fallback
import 'package:shared_preferences/shared_preferences.dart';

class FoodCourtInfo {
  final String name;
  final IconData icon;
  final Color accentColor;
  final String emoji;

  FoodCourtInfo(this.name, this.icon, this.accentColor, this.emoji);
}

class FoodCourtSelectionScreen extends StatefulWidget {
  const FoodCourtSelectionScreen({Key? key}) : super(key: key);

  @override
  State<FoodCourtSelectionScreen> createState() =>
      _FoodCourtSelectionScreenState();
}

class _FoodCourtSelectionScreenState extends State<FoodCourtSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Services
  final FirebaseService _firebaseService = FirebaseService();
  final CartManager _cartManager = CartManager();
  final AuthStateManager _authManager = AuthStateManager();

  // User data
  String userName = 'User';
  Uint8List? userProfileImage;
  bool isLoadingProfile = true;
  bool hasRecentOrder = false;
  Map<String, dynamic>? latestOrder;

  final List<FoodCourtInfo> foodCourts = [
    FoodCourtInfo('FOOD COURT 1', Icons.restaurant, Color(0xFFFF6B35), '🍕'),
    FoodCourtInfo('FOOD COURT 2', Icons.local_pizza, Color(0xFFE74C3C), '🍔'),
    FoodCourtInfo('FOOD COURT 3', Icons.ramen_dining, Color(0xFFF39C12), '🍜'),
    FoodCourtInfo('FOOD COURT 4', Icons.local_cafe, Color(0xFF8B4513), '☕'),
    FoodCourtInfo('FOOD COURT 5', Icons.bakery_dining, Color(0xFFE91E63), '🧁'),
    FoodCourtInfo('FOOD COURT 6', Icons.icecream, Color(0xFF9C27B0), '🍦'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();

    // 🔥 DEBUG: Add this to see if initState is called
    print('🔍 DEBUG: FoodCourtSelectionScreen initState called');
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      print('🔍 DEBUG: Starting app initialization');

      // Initialize authentication
      await _authManager.initializeUser();
      print('🔍 DEBUG: Auth initialized');

      // Initialize cart
      await _cartManager.initializeCart();
      print('🔍 DEBUG: Cart initialized');

      // Load user data
      await _loadUserProfile();
      print('🔍 DEBUG: Profile loaded');

      await _checkForRecentOrder();
      print('🔍 DEBUG: Recent order check completed');
    } catch (e) {
      print('❌ ERROR initializing app: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 🔥 ENHANCED: Multiple fallback methods to check for recent orders
  Future<void> _checkForRecentOrder() async {
    print('🔍 DEBUG: Checking for recent order...');

    try {
      // Method 1: Try Firebase first
      Map<String, dynamic>? order = await _firebaseService.getLatestOrder();
      print('🔍 DEBUG: Firebase order result: $order');

      // Method 2: If Firebase fails, try SharedPreferences fallback
      if (order == null) {
        print(
          '🔍 DEBUG: No Firebase order found, checking SharedPreferences...',
        );
        order = await _getOrderFromSharedPreferences();
        print('🔍 DEBUG: SharedPreferences order result: $order');
      }

      setState(() {
        hasRecentOrder = order != null;
        latestOrder = order;
        print('🔍 DEBUG: hasRecentOrder set to: $hasRecentOrder');
        print('🔍 DEBUG: latestOrder: $latestOrder');
      });
    } catch (e) {
      print('❌ ERROR checking for recent orders: $e');

      // Fallback: Try SharedPreferences even on error
      try {
        final order = await _getOrderFromSharedPreferences();
        setState(() {
          hasRecentOrder = order != null;
          latestOrder = order;
        });
        print(
          '🔍 DEBUG: Fallback successful - hasRecentOrder: $hasRecentOrder',
        );
      } catch (fallbackError) {
        print('❌ ERROR in fallback: $fallbackError');
      }
    }
  }

  // 🔥 NEW: Fallback method using SharedPreferences (from your CheckoutPage)
  Future<Map<String, dynamic>?> _getOrderFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderData = prefs.getString('last_order_data');
      final orderTotal = prefs.getDouble('last_order_total');

      print('🔍 DEBUG: SharedPreferences orderData: $orderData');
      print('🔍 DEBUG: SharedPreferences orderTotal: $orderTotal');

      if (orderData != null && orderTotal != null) {
        List<dynamic> itemsJson = json.decode(orderData);

        // Convert to the format expected by your existing code
        List<Map<String, dynamic>> items = itemsJson
            .map(
              (item) => {
                'name': item['name'],
                'description': item['description'] ?? '',
                'price': item['price'],
                'quantity': item['quantity'],
                'imagePath': item['imagePath'] ?? '',
                'emoji': item['emoji'] ?? '🍽️',
              },
            )
            .toList();

        return {
          'items': items,
          'total': orderTotal,
          'orderId':
              'LOCAL_${DateTime.now().millisecondsSinceEpoch}', // Generate local ID
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'completed',
        };
      }
    } catch (e) {
      print('❌ ERROR getting order from SharedPreferences: $e');
    }
    return null;
  }

  Future<void> _navigateToOrderDetails() async {
    print('🔍 DEBUG: Attempting to navigate to order details');
    print('🔍 DEBUG: latestOrder is null: ${latestOrder == null}');

    if (latestOrder == null) {
      _showNoOrdersSnackBar();
      return;
    }

    try {
      List<CartItem> items;

      // Handle both Firebase and SharedPreferences data formats
      if (latestOrder!['items'] is List) {
        items = (latestOrder!['items'] as List)
            .map(
              (item) => CartItem(
                name: item['name'] ?? 'Unknown Item',
                imagePath: item['imagePath'] ?? '',
                emoji: item['emoji'] ?? '🍽️',
                price: (item['price'] ?? 0).toDouble(),
                description: item['description'] ?? '',
                quantity: item['quantity'] ?? 1,
              ),
            )
            .toList();
      } else {
        throw Exception('Invalid order items format');
      }

      print('🔍 DEBUG: Converted ${items.length} items for navigation');

      // Add haptic feedback for better user experience
      HapticFeedback.lightImpact();

      // Navigate to OrderSuccessPage with order details
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              OrderSuccessPage(
                orderItems: items,
                totalAmount: (latestOrder!['total'] ?? 0).toDouble(),
                orderId: latestOrder!['orderId'],
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ).then((_) {
        // Refresh order status when returning
        print('🔍 DEBUG: Returned from order details, refreshing...');
        _checkForRecentOrder();
      });

      // Log user action if Firebase service is available
      try {
        await _firebaseService.logUserAction('order_details_viewed', {
          'orderId': latestOrder!['orderId'],
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('⚠️ WARNING: Could not log user action: $e');
      }
    } catch (e) {
      print('❌ ERROR navigating to order details: $e');
      _showErrorSnackBar('Error loading order details: $e');
    }
  }

  void _showNoOrdersSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text("No recent orders found"),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(20),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _loadUserProfile() async {
    setState(() => isLoadingProfile = true);

    try {
      final profileData = await _firebaseService.getUserProfile();

      setState(() {
        userName = profileData?['name']?.isNotEmpty == true
            ? profileData!['name']
            : 'User';

        final profileImageBase64 = profileData?['profileImageBase64'];
        if (profileImageBase64 != null && profileImageBase64.isNotEmpty) {
          try {
            userProfileImage = base64Decode(profileImageBase64);
          } catch (e) {
            print('Error decoding profile image: $e');
            userProfileImage = null;
          }
        } else {
          userProfileImage = null;
        }
      });
    } catch (e) {
      print('Error loading user profile: $e');
    } finally {
      setState(() => isLoadingProfile = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 18) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  // 🔥 NEW: Manual refresh method for debugging
  Future<void> _manualRefresh() async {
    print('🔍 DEBUG: Manual refresh triggered');
    setState(() {
      isLoadingProfile = true;
    });

    await _loadUserProfile();
    await _checkForRecentOrder();

    setState(() {
      isLoadingProfile = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Refreshed! Recent order: ${hasRecentOrder ? "Found" : "Not found"}',
        ),
        backgroundColor: Color(0xFF8BC34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Custom AppBar
                _buildCustomAppBar(),

                // 🔥 DEBUG: Add debug info banner
                if (latestOrder != null || hasRecentOrder)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    color: Colors.green.withOpacity(0.1),
                    child: Text(
                      '🔍 DEBUG: hasRecentOrder=$hasRecentOrder, orderId=${latestOrder?['orderId']}',
                      style: TextStyle(fontSize: 10, color: Colors.green[700]),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Main Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Header Section
                        _buildWelcomeHeader(),
                        const SizedBox(height: 24),

                        // 🔥 DEBUG: Manual refresh button
                        Center(
                          child: TextButton.icon(
                            onPressed: _manualRefresh,
                            icon: Icon(Icons.refresh, size: 16),
                            label: Text('Debug: Manual Refresh'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section Title
                        Text(
                          'What would you like to eat?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose from our food courts',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Food Court Grid
                        Expanded(
                          child: GridView.builder(
                            physics: BouncingScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: foodCourts.length,
                            itemBuilder: (context, index) {
                              return TweenAnimationBuilder<double>(
                                duration: Duration(
                                  milliseconds: 400 + (index * 100),
                                ),
                                tween: Tween(begin: 0, end: 1),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: 0.8 + (0.2 * value),
                                    child: Opacity(
                                      opacity: value,
                                      child: _buildFoodCourtCard(
                                        foodCourts[index],
                                        index,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Navigation Bar
                _buildBottomNavigationBar(),
              ],
            ),
          ),
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
          // App Logo/Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.restaurant, color: Color(0xFF8BC34A), size: 20),
          ),
          SizedBox(width: 12),
          Text(
            'MakanSmart',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Spacer(),

          // 🔥 ENHANCED: Order Details Icon with better debugging
          if (hasRecentOrder) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        print('🔍 DEBUG: Order details button tapped');
                        HapticFeedback.mediumImpact();
                        _navigateToOrderDetails();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // Animated notification dot
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
          ] else ...[
            // 🔥 DEBUG: Show when no recent order
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'No Order',
                style: TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ),
            SizedBox(width: 8),
          ],

          // Notification Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("No new notifications"),
                    backgroundColor: Color(0xFF8BC34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 8),

          // Profile/Menu Icon with actual profile image
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileSettingsPage()),
              ).then((_) {
                // Reload profile when returning from profile page
                print('🔍 DEBUG: Returned from profile page, refreshing...');
                _loadUserProfile();
                _checkForRecentOrder();
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: userProfileImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        userProfileImage!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(Icons.person_outline, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8BC34A).withOpacity(0.1),
            Color(0xFF9CCC65).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF8BC34A).withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoadingProfile ? 'Loading...' : userName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                // 🔥 ENHANCED: Better status badge with order details access
                GestureDetector(
                  onTap: hasRecentOrder
                      ? () {
                          print('🔍 DEBUG: Welcome header order badge tapped');
                          _navigateToOrderDetails();
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: hasRecentOrder
                          ? Color(0xFF8BC34A).withOpacity(0.15)
                          : Color(0xFF8BC34A).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: hasRecentOrder
                          ? Border.all(
                              color: Color(0xFF8BC34A).withOpacity(0.3),
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasRecentOrder
                              ? Icons.receipt_long
                              : Icons.restaurant,
                          size: 14,
                          color: Color(0xFF8BC34A),
                        ),
                        SizedBox(width: 4),
                        Text(
                          hasRecentOrder
                              ? 'Tap to view order details'
                              : 'Ready to order?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8BC34A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (hasRecentOrder) ...[
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 10,
                            color: Color(0xFF8BC34A),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: userProfileImage != null
                ? ClipOval(
                    child: Image.memory(
                      userProfileImage!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(Icons.person, size: 30, color: Color(0xFF8BC34A)),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCourtCard(FoodCourtInfo foodCourt, int index) {
    return GestureDetector(
      onTap: () async {
        // Add haptic feedback
        HapticFeedback.lightImpact();

        try {
          // Log user action to Firebase
          await _firebaseService.logUserAction('food_court_selected', {
            'foodCourtName': foodCourt.name,
            'timestamp': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          print('⚠️ WARNING: Could not log user action: $e');
        }

        // Navigate to the FoodCourtDetailScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodCourtDetailScreen(
              foodCourtName: foodCourt.name,
              accentColor: foodCourt.accentColor,
              emoji: foodCourt.emoji,
            ),
          ),
        ).then((_) {
          // Check for new orders when returning from food court
          print('🔍 DEBUG: Returned from food court, checking for orders...');
          _checkForRecentOrder();
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji Badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: foodCourt.accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(foodCourt.emoji, style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 12),

            // Food Court Name
            Text(
              foodCourt.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Status Indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Open',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF8BC34A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.home, color: Colors.white, size: 20),
                ),
                SizedBox(height: 4),
                Text(
                  'Home',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8BC34A),
                  ),
                ),
              ],
            ),
          ),
          // 🔥 ENHANCED: Better order details tab in bottom navigation
          if (hasRecentOrder) ...[
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _navigateToOrderDetails();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileSettingsPage(),
                  ),
                ).then((_) {
                  _loadUserProfile();
                  _checkForRecentOrder();
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
