import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  Future<String?> registration({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return 'Success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        return 'The account already exists for that email.';
      } else {
        return e.message;
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return 'Success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided for that user.';
      } else {
        return e.message;
      }
    } catch (e) {
      return e.toString();
    }
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<String?> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final user = await _auth.signInWithEmailAndPassword(
        email: email,
        password: newPassword,
      );

      await user.user!.updatePassword(newPassword);
      return 'Success: Password has been updated';
    } on FirebaseAuthException catch (e) {
      return 'Error: ${e.message}';
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return 'A password reset link has been sent to your email.';
    } on FirebaseAuthException catch (e) {
      return 'Error: ${e.message}';
    }
  }
}
