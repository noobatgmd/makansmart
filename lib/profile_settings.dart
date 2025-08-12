import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class ProfileSettingsPage extends StatefulWidget {
  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController admNoController = TextEditingController();

  File? _imageFile;
  Uint8List? _base64ImageBytes;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _loadProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    admNoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      setState(() {
        _imageFile = File(pickedFile.path);
        _base64ImageBytes = imageBytes;
      });

      // Save to SharedPreferences immediately
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImageBase64', base64Image);

      // Save to Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'profileImageBase64': base64Image,
                'lastUpdated': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        } catch (e) {
          print('Error saving image to Firebase: $e');
        }
      }

      _showSuccessSnackBar("Profile picture updated successfully!");
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF66BB6A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;

          nameController.text = data['name'] ?? '';
          admNoController.text = data['admNo'] ?? '';

          final base64Image =
              data['profileImageBase64'] ??
              prefs.getString('profileImageBase64');
          if (base64Image != null && base64Image.isNotEmpty) {
            try {
              final imageBytes = base64Decode(base64Image);
              setState(() {
                _base64ImageBytes = imageBytes;
              });
            } catch (e) {
              print('Error decoding image: $e');
            }
          }

          // Save to SharedPreferences for offline access
          await prefs.setString('name', nameController.text);
          await prefs.setString('admNo', admNoController.text);
          if (base64Image != null) {
            await prefs.setString('profileImageBase64', base64Image);
          }
        } else {
          // Fallback to SharedPreferences
          nameController.text = prefs.getString('name') ?? '';
          admNoController.text = prefs.getString('admNo') ?? '';

          final base64Image = prefs.getString('profileImageBase64');
          if (base64Image != null && base64Image.isNotEmpty) {
            try {
              final imageBytes = base64Decode(base64Image);
              setState(() {
                _base64ImageBytes = imageBytes;
              });
            } catch (e) {
              print('Error decoding cached image: $e');
            }
          }
        }
      } catch (e) {
        print('Error loading profile: $e');
        _showErrorSnackBar('Error loading profile data');
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', nameController.text);
      await prefs.setString('admNo', admNoController.text);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': nameController.text,
          'admNo': admNoController.text,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      _showSuccessSnackBar("Profile saved successfully!");
    } catch (e) {
      print('Error saving profile: $e');
      _showErrorSnackBar('Error saving profile');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF66BB6A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF66BB6A), size: 20),
          ),
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
            borderSide: BorderSide(color: Color(0xFF66BB6A), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F5E8),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Custom Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF66BB6A), Color(0xFF81C784)],
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF66BB6A),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Picture Section
                              Center(
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      GestureDetector(
                                        onTap: _pickImage,
                                        child: Stack(
                                          alignment: Alignment.bottomRight,
                                          children: [
                                            Container(
                                              width: 120,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Color(
                                                  0xFF66BB6A,
                                                ).withOpacity(0.1),
                                              ),
                                              child: _base64ImageBytes != null
                                                  ? ClipOval(
                                                      child: Image.memory(
                                                        _base64ImageBytes!,
                                                        width: 120,
                                                        height: 120,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                  : Icon(
                                                      Icons.person,
                                                      size: 60,
                                                      color: Color(0xFF66BB6A),
                                                    ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF66BB6A),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                    blurRadius: 6,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.camera_alt,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Tap to change photo',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: 24),

                              // Basic Information Section
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF66BB6A).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: Color(0xFF66BB6A),
                                      size: 18,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Basic Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 16),

                              _buildTextField(
                                controller: nameController,
                                label: 'Your Name',
                                icon: Icons.person,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),

                              _buildTextField(
                                controller: admNoController,
                                label: 'Adm No.',
                                icon: Icons.badge,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Please enter your admission number';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
              ),

              // Save Button (Fixed at bottom)
              Container(
                padding: EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF66BB6A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Save Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Bottom Navigation
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.home,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Home',
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
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFF333333),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Profile',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333333),
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
    );
  }
}
