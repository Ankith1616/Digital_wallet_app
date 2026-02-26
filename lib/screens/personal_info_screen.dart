import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/theme_manager.dart';
import '../utils/firestore_service.dart';
import '../utils/storage_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _upiController = TextEditingController();
  bool _isLoading = false;
  XFile? _pickedFile;
  String? _photoUrl;
  final _firestore = FirestoreService();
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (mounted) setState(() => _isLoading = true);
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _photoUrl = user.photoURL;

      final profile = await _firestore.getUserProfile(user.uid);
      if (profile != null) {
        _phoneController.text = profile['phone'] ?? user.phoneNumber ?? '';
        _dobController.text = profile['dob'] ?? '';
      }

      _upiController.text = "${user.email?.split('@').first ?? 'user'}@upi";
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? newPhotoUrl = _photoUrl;

        // 1. Upload Image if changed
        if (_pickedFile != null) {
          String? uploadedUrl;
          if (kIsWeb) {
            final bytes = await _pickedFile!.readAsBytes();
            uploadedUrl = await _storage.uploadProfileImage(
              user.uid,
              bytes: bytes,
            );
          } else {
            uploadedUrl = await _storage.uploadProfileImage(
              user.uid,
              file: File(_pickedFile!.path),
            );
          }

          if (uploadedUrl == null) {
            throw Exception(
              "Failed to upload image. Please check your internet and Firebase Storage rules.",
            );
          }
          newPhotoUrl = uploadedUrl;
        }

        // 2. Update Firebase Auth Profile
        await user.updateDisplayName(_nameController.text);
        if (newPhotoUrl != null) {
          await user.updatePhotoURL(newPhotoUrl);
        }

        // 3. Update Firestore Document
        await _firestore.updateUserProfile(user.uid, {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'dob': _dobController.text,
          'photoUrl': newPhotoUrl,
        });

        // Refresh the user object
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;

        if (mounted) {
          setState(() {
            _photoUrl = updatedUser?.photoURL;
            _pickedFile = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile Updated Successfully!")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Personal Info",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: _pickedFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: kIsWeb
                                  ? Image.network(
                                      _pickedFile!.path,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                    )
                                  : Image.file(
                                      File(_pickedFile!.path),
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                    ),
                            )
                          : _photoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.network(
                                _photoUrl!,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.person,
                                      size: 52,
                                      color: AppColors.primary,
                                    ),
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 52,
                              color: AppColors.primary,
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBg
                                : AppColors.lightBg,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _infoField(
              "Full Name",
              _nameController,
              Icons.person_outline,
              isDark,
            ),
            const SizedBox(height: 14),
            _infoField(
              "Email",
              _emailController,
              Icons.email_outlined,
              isDark,
              enabled: false,
            ),
            const SizedBox(height: 14),
            _infoField("Phone", _phoneController, Icons.phone_outlined, isDark),
            const SizedBox(height: 14),
            _infoField(
              "Date of Birth",
              _dobController,
              Icons.cake_outlined,
              isDark,
              hint: "DD/MM/YYYY",
            ),
            const SizedBox(height: 14),
            _infoField(
              "UPI ID",
              _upiController,
              Icons.account_balance_wallet_outlined,
              isDark,
              enabled: false,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Save Changes",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isDark, {
    bool enabled = true,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(
                alpha: enabled ? 1.0 : 0.6,
              ),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
              prefixIcon: Icon(
                icon,
                color: AppColors.primary.withValues(alpha: enabled ? 1.0 : 0.6),
                size: 20,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
