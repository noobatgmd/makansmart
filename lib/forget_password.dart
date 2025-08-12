import 'package:flutter/material.dart';
import 'package:makansmart/auth_service.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({Key? key}) : super(key: key);

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9DEC6), // App theme color
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF6B4E3D),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'MakanSmart',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B4E3D), // Dark brown for contrast
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/img/makansmart_logo.jpg',
                    width: 280,
                    height: 280,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4E3D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your email to receive a reset link',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8A7968),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'email@domain.com',
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF8A7968),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE9DEC6),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE9DEC6),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6B4E3D),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F3F0),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B4E3D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          onPressed: () async {
                            if (_emailController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter your email'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final message = await AuthService()
                                .sendPasswordResetEmail(
                                  _emailController.text.trim(),
                                );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message ?? 'Unexpected error'),
                                backgroundColor:
                                    message != null && message.contains('sent')
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            );

                            // If successful, optionally navigate back
                            if (message != null && message.contains('sent')) {
                              Future.delayed(const Duration(seconds: 2), () {
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                              });
                            }
                          },
                          child: const Text(
                            'Send Reset Link',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(
                            color: Color(0xFF6B4E3D),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
  }
}
