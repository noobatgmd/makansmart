import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:makansmart/checkoutpage.dart';
import 'package:makansmart/foodstoremenu.dart';
import 'package:makansmart/cart_manager.dart';

class FoodCourtDetailScreen extends StatefulWidget {
  final String foodCourtName;
  final Color accentColor;
  final String emoji;

  const FoodCourtDetailScreen({
    Key? key,
    required this.foodCourtName,
    required this.accentColor,
    required this.emoji,
  }) : super(key: key);

  @override
  State<FoodCourtDetailScreen> createState() => _FoodCourtDetailScreenState();
}

class _FoodCourtDetailScreenState extends State<FoodCourtDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final CartManager _cartManager = CartManager();

  @override
  void initState() {
    super.initState();

    // Set the current food court in the cart manager
    _cartManager.setFoodCourt(widget.foodCourtName);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<FoodStall> _getFoodStallsForCourt(String courtName) {
    switch (courtName) {
      case 'FOOD COURT 1':
        return [
          FoodStall('Chicken Rice Stall', 'assets/chicken_rice.jpg', '🍗'),
          FoodStall(
            'Waffles and Takoyaki',
            'assets/waffles_takoyaki.jpg',
            '🧇',
          ),
          FoodStall('Curry Rice', 'assets/curry_rice.jpg', '🍛'),
        ];
      case 'FOOD COURT 2':
        return [
          FoodStall('Burger Junction', 'assets/burger.jpg', '🍔'),
          FoodStall('Pizza Corner', 'assets/pizza.jpg', '🍕'),
          FoodStall('Sandwich Bar', 'assets/sandwich.jpg', '🥪'),
        ];
      case 'FOOD COURT 3':
        return [
          FoodStall('Ramen House', 'assets/ramen.jpg', '🍜'),
          FoodStall('Udon Station', 'assets/udon.jpg', '🍲'),
          FoodStall('Soba Express', 'assets/soba.jpg', '🥢'),
        ];
      case 'FOOD COURT 4':
        return [
          FoodStall('Coffee Bean', 'assets/coffee.jpg', '☕'),
          FoodStall('Tea Garden', 'assets/tea.jpg', '🍵'),
          FoodStall('Smoothie Bar', 'assets/smoothie.jpg', '🥤'),
        ];
      case 'FOOD COURT 5':
        return [
          FoodStall('Sweet Bakery', 'assets/bakery.jpg', '🧁'),
          FoodStall('Donut Delight', 'assets/donut.jpg', '🍩'),
          FoodStall('Cake Corner', 'assets/cake.jpg', '🎂'),
        ];
      case 'FOOD COURT 6':
        return [
          FoodStall('Ice Cream Palace', 'assets/icecream.jpg', '🍦'),
          FoodStall('Frozen Yogurt', 'assets/froyo.jpg', '🍧'),
          FoodStall('Milkshake Mania', 'assets/milkshake.jpg', '🥛'),
        ];
      default:
        return [
          FoodStall('Stall 1', '', '🍽️'),
          FoodStall('Stall 2', '', '🍽️'),
          FoodStall('Stall 3', '', '🍽️'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final stalls = _getFoodStallsForCourt(widget.foodCourtName);

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

                // Main Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Food Court Title with Cart Info
                        _buildFoodCourtHeader(),
                        const SizedBox(height: 32),

                        // Food Stalls List
                        Expanded(
                          child: ListView.builder(
                            physics: BouncingScrollPhysics(),
                            itemCount: stalls.length,
                            itemBuilder: (context, index) {
                              return TweenAnimationBuilder<double>(
                                duration: Duration(
                                  milliseconds: 300 + (index * 150),
                                ),
                                tween: Tween(begin: 0, end: 1),
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: _buildFoodStallCard(stalls[index]),
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

                // Show checkout button if cart has items
                if (_cartManager.hasItems) _buildCheckoutButton(),
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
          // Back Button
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
          SizedBox(width: 12),

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

          // Cart Icon with Badge (if has items)
          ListenableBuilder(
            listenable: _cartManager,
            builder: (context, child) {
              if (_cartManager.hasItems) {
                return Container(
                  margin: EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.shopping_cart,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _cartManager.cartItemCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),

          // Food Court Emoji
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(widget.emoji, style: TextStyle(fontSize: 20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCourtHeader() {
    return ListenableBuilder(
      listenable: _cartManager,
      builder: (context, child) {
        return Column(
          children: [
            // Food Court Title
            Center(
              child: Text(
                widget.foodCourtName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ),

            // Cart Summary (if has items)
            if (_cartManager.hasItems) ...[
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Color(0xFF8BC34A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF8BC34A).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      color: Color(0xFF8BC34A),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${_cartManager.cartItemCount} items • \$${_cartManager.cartTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8BC34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFoodStallCard(FoodStall stall) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();

          // Navigate to the FoodStallMenuScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FoodStallMenuScreen(
                stallName: stall.name,
                stallEmoji: stall.emoji,
                foodCourtName: widget.foodCourtName,
              ),
            ),
          );
        },
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8BC34A), Color(0xFF9CCC65)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF8BC34A).withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Food Image Placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: stall.imagePath.isNotEmpty
                        ? Image.asset(
                            stall.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder(stall.emoji);
                            },
                          )
                        : _buildImagePlaceholder(stall.emoji),
                  ),
                ),
                const SizedBox(width: 20),

                // Stall Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        stall.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Open Now',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return ListenableBuilder(
      listenable: _cartManager,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CheckoutPage(cartItems: _cartManager.cartItems),
                ),
              );
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_checkout, size: 20),
                SizedBox(width: 8),
                Text(
                  'Proceed to Checkout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\$${_cartManager.cartTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder(String emoji) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[100]!],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(child: Text(emoji, style: TextStyle(fontSize: 32))),
    );
  }
}

class FoodStall {
  final String name;
  final String imagePath;
  final String emoji;

  FoodStall(this.name, this.imagePath, this.emoji);
}
