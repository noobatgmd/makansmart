// firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:makansmart/cart_items.dart';
import 'dart:convert';
import 'dart:typed_data';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Authentication Methods
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in with email: $e');
      return null;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // User Profile Methods
  Future<void> saveUserProfile({
    required String name,
    String? email,
    String? profileImageBase64,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!isAuthenticated) return;

    try {
      final userData = {
        'name': name,
        'email': email ?? currentUser?.email,
        'profileImageBase64': profileImageBase64,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      };

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .set(userData, SetOptions(merge: true));
    } catch (e) {
      print('Error saving user profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isAuthenticated) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Cart Methods
  Future<void> saveCartToFirebase(
    List<CartItem> cartItems,
    String foodCourtName,
  ) async {
    if (!isAuthenticated || cartItems.isEmpty) return;

    try {
      final cartData = {
        'foodCourtName': foodCourtName,
        'items': cartItems
            .map(
              (item) => {
                'name': item.name,
                'imagePath': item.imagePath,
                'emoji': item.emoji,
                'price': item.price,
                'description': item.description,
                'quantity': item.quantity,
              },
            )
            .toList(),
        'total': cartItems.fold<double>(
          0,
          (sum, item) => sum + (item.price * item.quantity),
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('cart')
          .doc('current')
          .set(cartData);
    } catch (e) {
      print('Error saving cart to Firebase: $e');
    }
  }

  Future<Map<String, dynamic>?> getCartFromFirebase() async {
    if (!isAuthenticated) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('cart')
          .doc('current')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final items = (data['items'] as List)
            .map(
              (item) => CartItem(
                name: item['name'],
                imagePath: item['imagePath'] ?? '',
                emoji: item['emoji'] ?? '🍽️',
                price: item['price'].toDouble(),
                description: item['description'] ?? '',
                quantity: item['quantity'],
              ),
            )
            .toList();

        return {
          'items': items,
          'foodCourtName': data['foodCourtName'],
          'total': data['total'],
        };
      }
      return null;
    } catch (e) {
      print('Error getting cart from Firebase: $e');
      return null;
    }
  }

  Future<void> clearCartFromFirebase() async {
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('cart')
          .doc('current')
          .delete();
    } catch (e) {
      print('Error clearing cart from Firebase: $e');
    }
  }

  // Order Methods
  Future<String?> saveOrder({
    required List<CartItem> items,
    required double total,
    required String foodCourtName,
    required bool isInFoodCourt,
    required String deliveryLocation, // table number or class
    Map<String, String>? paymentDetails,
  }) async {
    if (!isAuthenticated) return null;

    try {
      final orderId = _firestore.collection('orders').doc().id;

      final orderData = {
        'orderId': orderId,
        'userId': currentUser!.uid,
        'userEmail': currentUser!.email,
        'items': items
            .map(
              (item) => {
                'name': item.name,
                'imagePath': item.imagePath,
                'emoji': item.emoji,
                'price': item.price,
                'description': item.description,
                'quantity': item.quantity,
                'subtotal': item.price * item.quantity,
              },
            )
            .toList(),
        'total': total,
        'foodCourtName': foodCourtName,
        'isInFoodCourt': isInFoodCourt,
        'deliveryLocation': deliveryLocation,
        'status': 'pending',
        'paymentStatus': 'completed',
        'paymentMethod':
            paymentDetails?['cardNumber']?.substring(
              paymentDetails['cardNumber']!.length - 4,
            ) ??
            'Card',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'estimatedDeliveryTime': Timestamp.fromDate(
          DateTime.now().add(Duration(minutes: 10)),
        ),
      };

      // Save to orders collection (for restaurant/admin)
      await _firestore.collection('orders').doc(orderId).set(orderData);

      // Also save to user's order history
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('orders')
          .doc(orderId)
          .set(orderData);

      return orderId;
    } catch (e) {
      print('Error saving order: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUserOrders({int? limit}) async {
    if (!isAuthenticated) return [];

    try {
      Query query = _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('orders')
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error getting user orders: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLatestOrder() async {
    final orders = await getUserOrders(limit: 1);
    return orders.isNotEmpty ? orders.first : null;
  }

  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    if (!isAuthenticated) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('orders')
          .doc(orderId)
          .get();

      return doc.exists ? {'id': doc.id, ...doc.data()!} : null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // Payment Methods
  Future<void> savePaymentMethod({
    required String cardNumber,
    required String nameOnCard,
    required String expiryDate,
    required String cvv,
    required String address,
  }) async {
    if (!isAuthenticated) return;

    try {
      // Mask card number for security
      final maskedCardNumber =
          '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';

      final paymentData = {
        'cardNumber': maskedCardNumber,
        'nameOnCard': nameOnCard,
        'expiryDate': expiryDate,
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
        // Note: Never store CVV in production
      };

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('payment')
          .doc('card_details')
          .set(paymentData);
    } catch (e) {
      print('Error saving payment method: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getPaymentMethod() async {
    if (!isAuthenticated) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('payment')
          .doc('card_details')
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting payment method: $e');
      return null;
    }
  }

  // Real-time listeners
  Stream<DocumentSnapshot> getUserProfileStream() {
    if (!isAuthenticated) {
      return Stream.empty();
    }

    return _firestore.collection('users').doc(currentUser!.uid).snapshots();
  }

  Stream<QuerySnapshot> getUserOrdersStream() {
    if (!isAuthenticated) {
      return Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getOrderStatusStream(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots();
  }

  // Utility Methods
  Future<void> ensureUserAuthenticated() async {
    if (!isAuthenticated) {
      await signInAnonymously();
    }
  }

  Future<void> updateUserLastActive() async {
    if (!isAuthenticated) return;

    try {
      await _firestore.collection('users').doc(currentUser!.uid).set({
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating last active: $e');
    }
  }

  // Analytics/Metrics (optional)
  Future<void> logUserAction(String action, Map<String, dynamic>? data) async {
    if (!isAuthenticated) return;

    try {
      await _firestore.collection('user_actions').add({
        'userId': currentUser!.uid,
        'action': action,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging user action: $e');
    }
  }
}

// Authentication State Manager
class AuthStateManager {
  static final AuthStateManager _instance = AuthStateManager._internal();
  factory AuthStateManager() => _instance;
  AuthStateManager._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> initializeUser() async {
    if (_auth.currentUser == null) {
      await _firebaseService.signInAnonymously();
    }

    if (_auth.currentUser != null) {
      await _firebaseService.updateUserLastActive();
    }
  }
}
