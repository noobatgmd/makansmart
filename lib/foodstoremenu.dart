import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:makansmart/checkoutpage.dart';
import 'package:makansmart/cart_items.dart';
import 'package:makansmart/cart_manager.dart';

class FoodStallMenuScreen extends StatefulWidget {
  final String stallName;
  final String stallEmoji;
  final String foodCourtName;

  const FoodStallMenuScreen({
    Key? key,
    required this.stallName,
    required this.stallEmoji,
    required this.foodCourtName,
  }) : super(key: key);

  @override
  State<FoodStallMenuScreen> createState() => _FoodStallMenuScreenState();
}

class _FoodStallMenuScreenState extends State<FoodStallMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final CartManager _cartManager = CartManager();

  @override
  void initState() {
    super.initState();

    // Ensure we're working with the same food court
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

  void _addToCart(MenuItem menuItem) {
    final cartItem = CartItem(
      name: menuItem.name,
      imagePath: menuItem.imagePath,
      emoji: menuItem.emoji,
      price: menuItem.price,
      description: menuItem.description,
      quantity: 1,
    );

    _cartManager.addToCart(cartItem);

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${menuItem.name} to cart - \$${menuItem.price.toStringAsFixed(2)}',
        ),
        backgroundColor: Color(0xFF8BC34A),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _proceedToCheckout() {
    if (!_cartManager.hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add items to cart before checkout'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(cartItems: _cartManager.cartItems),
      ),
    );
  }

  List<MenuItem> _getMenuItemsForStall(String stallName) {
    switch (stallName) {
      // FOOD COURT 1
      case 'Chicken Rice Stall':
        return [
          MenuItem(
            'Hainanese Chicken Rice',
            'assets/hainanese_chicken.jpg',
            '🍗',
            4.50,
            4.8,
            'Tender steamed chicken with fragrant rice',
          ),
          MenuItem(
            'Roasted Chicken Rice, 烧鸡饭',
            'assets/roasted_chicken.jpg',
            '🔥',
            5.00,
            4.6,
            'Crispy roasted chicken with aromatic rice',
          ),
          MenuItem(
            'Chicken Soup',
            'assets/chicken_soup.jpg',
            '🍲',
            2.50,
            4.4,
            'Clear chicken broth with tender meat',
          ),
        ];
      case 'Waffles and Takoyaki':
        return [
          MenuItem(
            'Belgian Waffles',
            'assets/belgian_waffles.jpg',
            '🧇',
            6.80,
            4.7,
            'Crispy waffles with maple syrup and butter',
          ),
          MenuItem(
            'Takoyaki (6pcs)',
            'assets/takoyaki.jpg',
            '🐙',
            7.50,
            4.5,
            'Japanese octopus balls with special sauce',
          ),
          MenuItem(
            'Waffle Ice Cream',
            'assets/waffle_icecream.jpg',
            '🍦',
            8.90,
            4.9,
            'Warm waffle with vanilla ice cream',
          ),
        ];
      case 'Curry Rice':
        return [
          MenuItem(
            'Japanese Curry Rice',
            'assets/japanese_curry.jpg',
            '🍛',
            6.20,
            4.6,
            'Rich curry with tender beef and vegetables',
          ),
          MenuItem(
            'Katsu Curry',
            'assets/katsu_curry.jpg',
            '🍖',
            8.50,
            4.8,
            'Crispy pork cutlet with curry sauce',
          ),
          MenuItem(
            'Vegetable Curry',
            'assets/veggie_curry.jpg',
            '🥕',
            5.80,
            4.3,
            'Healthy curry with mixed vegetables',
          ),
        ];

      // FOOD COURT 2
      case 'Burger Junction':
        return [
          MenuItem(
            'Classic Beef Burger',
            'assets/beef_burger.jpg',
            '🍔',
            9.90,
            4.7,
            'Juicy beef patty with lettuce and tomato',
          ),
          MenuItem(
            'Chicken Burger',
            'assets/chicken_burger.jpg',
            '🐔',
            8.50,
            4.5,
            'Crispy chicken fillet with mayo',
          ),
          MenuItem(
            'Double Cheese Burger',
            'assets/double_cheese.jpg',
            '🧀',
            12.80,
            4.9,
            'Double patty with melted cheese',
          ),
        ];
      case 'Pizza Corner':
        return [
          MenuItem(
            'Margherita Pizza',
            'assets/margherita.jpg',
            '🍕',
            15.90,
            4.6,
            'Classic pizza with tomato and mozzarella',
          ),
          MenuItem(
            'Pepperoni Pizza',
            'assets/pepperoni.jpg',
            '🍖',
            18.90,
            4.8,
            'Spicy pepperoni with cheese',
          ),
          MenuItem(
            'Hawaiian Pizza',
            'assets/hawaiian.jpg',
            '🍍',
            17.50,
            4.4,
            'Ham and pineapple combination',
          ),
        ];
      case 'Sandwich Bar':
        return [
          MenuItem(
            'Club Sandwich',
            'assets/club_sandwich.jpg',
            '🥪',
            7.80,
            4.5,
            'Triple layer with bacon and lettuce',
          ),
          MenuItem(
            'Tuna Melt',
            'assets/tuna_melt.jpg',
            '🐟',
            6.50,
            4.3,
            'Grilled tuna sandwich with cheese',
          ),
          MenuItem(
            'BLT Sandwich',
            'assets/blt.jpg',
            '🥓',
            8.20,
            4.7,
            'Bacon, lettuce and tomato classic',
          ),
        ];

      // FOOD COURT 3
      case 'Ramen House':
        return [
          MenuItem(
            'Tonkotsu Ramen',
            'assets/tonkotsu.jpg',
            '🍜',
            12.80,
            4.9,
            'Rich pork bone broth with chashu',
          ),
          MenuItem(
            'Miso Ramen',
            'assets/miso_ramen.jpg',
            '🍲',
            11.50,
            4.6,
            'Savory miso-based broth',
          ),
          MenuItem(
            'Spicy Ramen',
            'assets/spicy_ramen.jpg',
            '🌶',
            13.20,
            4.7,
            'Fiery broth with chili oil',
          ),
        ];
      case 'Udon Station':
        return [
          MenuItem(
            'Beef Udon',
            'assets/beef_udon.jpg',
            '🥩',
            10.80,
            4.5,
            'Thick noodles with tender beef slices',
          ),
          MenuItem(
            'Tempura Udon',
            'assets/tempura_udon.jpg',
            '🍤',
            12.50,
            4.8,
            'Udon with crispy tempura',
          ),
          MenuItem(
            'Curry Udon',
            'assets/curry_udon.jpg',
            '🍛',
            11.20,
            4.4,
            'Udon in mild curry broth',
          ),
        ];
      case 'Soba Express':
        return [
          MenuItem(
            'Cold Soba',
            'assets/cold_soba.jpg',
            '🥢',
            9.80,
            4.6,
            'Chilled buckwheat noodles with dipping sauce',
          ),
          MenuItem(
            'Hot Soba',
            'assets/hot_soba.jpg',
            '♨',
            10.50,
            4.4,
            'Warm soba in clear broth',
          ),
          MenuItem(
            'Tempura Soba',
            'assets/tempura_soba.jpg',
            '🍤',
            13.80,
            4.7,
            'Soba with assorted tempura',
          ),
        ];

      // FOOD COURT 4
      case 'Coffee Bean':
        return [
          MenuItem(
            'Cappuccino',
            'assets/cappuccino.jpg',
            '☕',
            4.80,
            4.7,
            'Rich espresso with steamed milk foam',
          ),
          MenuItem(
            'Iced Latte',
            'assets/iced_latte.jpg',
            '🧊',
            5.20,
            4.5,
            'Chilled coffee with milk',
          ),
          MenuItem(
            'Espresso',
            'assets/espresso.jpg',
            '⚫',
            3.50,
            4.9,
            'Pure intense coffee shot',
          ),
        ];
      case 'Tea Garden':
        return [
          MenuItem(
            'Earl Grey Tea',
            'assets/earl_grey.jpg',
            '🍵',
            3.80,
            4.4,
            'Classic bergamot-flavored black tea',
          ),
          MenuItem(
            'Green Tea Latte',
            'assets/green_tea_latte.jpg',
            '🍃',
            5.50,
            4.6,
            'Creamy matcha latte',
          ),
          MenuItem(
            'Bubble Tea',
            'assets/bubble_tea.jpg',
            '🧋',
            6.20,
            4.8,
            'Taiwan-style tea with pearls',
          ),
        ];
      case 'Smoothie Bar':
        return [
          MenuItem(
            'Mango Smoothie',
            'assets/mango_smoothie.jpg',
            '🥭',
            6.80,
            4.7,
            'Fresh mango blended with yogurt',
          ),
          MenuItem(
            'Berry Blast',
            'assets/berry_smoothie.jpg',
            '🫐',
            7.20,
            4.6,
            'Mixed berries with banana',
          ),
          MenuItem(
            'Green Detox',
            'assets/green_smoothie.jpg',
            '🥬',
            7.50,
            4.3,
            'Spinach, apple and cucumber blend',
          ),
        ];

      // FOOD COURT 5
      case 'Sweet Bakery':
        return [
          MenuItem(
            'Chocolate Croissant',
            'assets/choc_croissant.jpg',
            '🥐',
            4.50,
            4.6,
            'Buttery pastry with chocolate filling',
          ),
          MenuItem(
            'Red Velvet Cupcake',
            'assets/red_velvet.jpg',
            '🧁',
            5.80,
            4.8,
            'Moist cupcake with cream cheese frosting',
          ),
          MenuItem(
            'Apple Pie',
            'assets/apple_pie.jpg',
            '🥧',
            6.20,
            4.5,
            'Traditional pie with cinnamon apples',
          ),
        ];
      case 'Donut Delight':
        return [
          MenuItem(
            'Glazed Donut',
            'assets/glazed_donut.jpg',
            '🍩',
            2.80,
            4.4,
            'Classic ring donut with sweet glaze',
          ),
          MenuItem(
            'Chocolate Donut',
            'assets/choc_donut.jpg',
            '🍫',
            3.20,
            4.6,
            'Rich chocolate-covered donut',
          ),
          MenuItem(
            'Boston Cream',
            'assets/boston_cream.jpg',
            '🍮',
            4.50,
            4.7,
            'Filled with custard cream',
          ),
        ];
      case 'Cake Corner':
        return [
          MenuItem(
            'Chocolate Cake',
            'assets/choc_cake.jpg',
            '🎂',
            7.80,
            4.8,
            'Rich chocolate layer cake',
          ),
          MenuItem(
            'Cheesecake',
            'assets/cheesecake.jpg',
            '🍰',
            8.50,
            4.9,
            'Creamy New York style cheesecake',
          ),
          MenuItem(
            'Tiramisu',
            'assets/tiramisu.jpg',
            '☕',
            9.20,
            4.7,
            'Italian coffee-flavored dessert',
          ),
        ];

      // FOOD COURT 6
      case 'Ice Cream Palace':
        return [
          MenuItem(
            'Vanilla Sundae',
            'assets/vanilla_sundae.jpg',
            '🍦',
            5.80,
            4.5,
            'Classic vanilla with chocolate sauce',
          ),
          MenuItem(
            'Strawberry Cone',
            'assets/strawberry_cone.jpg',
            '🍓',
            4.20,
            4.4,
            'Fresh strawberry in waffle cone',
          ),
          MenuItem(
            'Banana Split',
            'assets/banana_split.jpg',
            '🍌',
            8.90,
            4.8,
            'Three scoops with banana and toppings',
          ),
        ];
      case 'Frozen Yogurt':
        return [
          MenuItem(
            'Original Tart',
            'assets/original_froyo.jpg',
            '🍧',
            6.50,
            4.6,
            'Classic tart frozen yogurt',
          ),
          MenuItem(
            'Mango Froyo',
            'assets/mango_froyo.jpg',
            '🥭',
            7.20,
            4.7,
            'Tropical mango frozen yogurt',
          ),
          MenuItem(
            'Chocolate Froyo',
            'assets/choc_froyo.jpg',
            '🍫',
            6.80,
            4.5,
            'Rich chocolate frozen yogurt',
          ),
        ];
      case 'Milkshake Mania':
        return [
          MenuItem(
            'Chocolate Milkshake',
            'assets/choc_shake.jpg',
            '🥛',
            7.50,
            4.6,
            'Thick chocolate milkshake with whipped cream',
          ),
          MenuItem(
            'Strawberry Shake',
            'assets/strawberry_shake.jpg',
            '🍓',
            7.20,
            4.5,
            'Fresh strawberry milkshake',
          ),
          MenuItem(
            'Oreo Shake',
            'assets/oreo_shake.jpg',
            '🍪',
            8.80,
            4.8,
            'Cookies and cream milkshake',
          ),
        ];

      default:
        return [
          MenuItem('Menu Item 1', '', '🍽', 5.00, 4.0, 'Delicious food item'),
          MenuItem('Menu Item 2', '', '🍽', 6.00, 4.2, 'Another tasty option'),
          MenuItem('Menu Item 3', '', '🍽', 7.00, 4.5, 'Premium food choice'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _getMenuItemsForStall(widget.stallName);

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
                        // Stall Info Header
                        _buildStallHeader(),
                        const SizedBox(height: 32),

                        // Menu Items List
                        Expanded(
                          child: ListView.builder(
                            physics: BouncingScrollPhysics(),
                            itemCount: menuItems.length,
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
                                      child: _buildMenuItemCard(
                                        menuItems[index],
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

                // Checkout Button (only show if cart has items)
                ListenableBuilder(
                  listenable: _cartManager,
                  builder: (context, child) {
                    if (_cartManager.hasItems) {
                      return _buildCheckoutButton();
                    }
                    return SizedBox.shrink();
                  },
                ),
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

          // Cart Icon with Badge
          ListenableBuilder(
            listenable: _cartManager,
            builder: (context, child) {
              if (_cartManager.hasItems) {
                return Container(
                  margin: EdgeInsets.only(right: 8),
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

          // Stall Emoji
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(widget.stallEmoji, style: TextStyle(fontSize: 20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStallHeader() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFF8BC34A).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.stallEmoji,
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.stallName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Text(
                      widget.foodCourtName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🕐 Open Now • 10:00 AM - 9:00 PM',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem menuItem) {
    return ListenableBuilder(
      listenable: _cartManager,
      builder: (context, child) {
        final itemQuantity = _cartManager.getItemQuantity(menuItem.name);

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () => _addToCart(menuItem),
            child: Container(
              height: 130,
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Food Image
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: menuItem.imagePath.isNotEmpty
                            ? Image.asset(
                                menuItem.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImagePlaceholder(menuItem.emoji);
                                },
                              )
                            : _buildImagePlaceholder(menuItem.emoji),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Menu Item Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Name and Rating
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                menuItem.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF333333),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    menuItem.rating.toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber[700],
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      menuItem.description,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Price and Add Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\$${menuItem.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF8BC34A),
                                    ),
                                  ),
                                  if (itemQuantity > 0) ...[
                                    Text(
                                      'In cart: $itemQuantity',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF8BC34A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF8BC34A),
                                      Color(0xFF9CCC65),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Add',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ElevatedButton(
        onPressed: _proceedToCheckout,
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
  }

  Widget _buildImagePlaceholder(String emoji) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[100]!, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(child: Text(emoji, style: TextStyle(fontSize: 36))),
    );
  }
}

class MenuItem {
  final String name;
  final String imagePath;
  final String emoji;
  final double price;
  final double rating;
  final String description;

  MenuItem(
    this.name,
    this.imagePath,
    this.emoji,
    this.price,
    this.rating,
    this.description,
  );
}
