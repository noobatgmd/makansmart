import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:makansmart/card_details_page.dart';
import 'package:makansmart/firebase_options.dart';
import 'package:makansmart/foodcourtselection.dart';
import 'package:makansmart/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MaterialApp(home: LoginScreen()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      title: 'MakanSmart',
      debugShowCheckedModeBanner: false,
      initialRoute: user == null ? '/login' : '/home',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => FoodCourtSelectionScreen(),
      },
    );
  }
}
