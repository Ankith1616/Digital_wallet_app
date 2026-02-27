import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';
import '../utils/firebase_auth_service.dart';
import '../utils/fcm_service.dart';
import '../widgets/interactive_scale.dart';
import 'otp_verification_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String _selectedCountryCode = '+91';

  final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'flag': 'IN'},
    {'code': '+1', 'flag': 'US'},
    {'code': '+44', 'flag': 'UK'},
    {'code': '+61', 'flag': 'AU'},
    {'code': '+81', 'flag': 'JP'},
    {'code': '+86', 'flag': 'CN'},
    {'code': '+971', 'flag': 'AE'},
    {'code': '+65', 'flag': 'SG'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.spaceGrotesk()),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    var phone = _phoneController.text.trim();
    // Prevent double country code if user types it manually
    if (phone.startsWith('+')) {
      if (phone.startsWith(_selectedCountryCode)) {
        phone = phone.substring(_selectedCountryCode.length);
      } else {
        // If they typed a DIFFERENT country code than selected,
        // they might be confused. Let's try to handle it.
        _showError(
          'Number starts with a different country code than selected.',
        );
        setState(() => _loading = false);
        return;
      }
    }

    final fullNumber = '$_selectedCountryCode$phone';
    if (kDebugMode) print('[PhoneAuth] Sending full number: $fullNumber');

    setState(() => _loading = true);

    await FirebaseAuthService().verifyPhoneNumber(
      phoneNumber: fullNumber,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              phoneNumber: fullNumber,
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          ),
        );
      },
      onAutoVerified: (credential) async {
        // Auto-verified on Android — init FCM and navigate
        if (credential.user != null) {
          await FcmService().init(uid: credential.user!.uid);
        }
        if (!mounted) return;
        setState(() => _loading = false);
        // StreamBuilder in main.dart will auto-navigate to MainLayout
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      onFailed: (error) {
        if (!mounted) return;
        setState(() => _loading = false);
        _showError(error);
      },
      onTimeout: (verificationId) {
        // Timeout is handled on the OTP screen
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Phone OTP auth via SMS is not supported on web.
    // It requires a physical Android/iOS device with a SIM card.
    if (kIsWeb) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.headerGradient),
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.smartphone_rounded,
                  size: 72,
                  color: Colors.white54,
                ),
                const SizedBox(height: 24),
                Text(
                  'Phone login not\navailable on web',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'OTP verification requires a real Android or iOS device with a SIM card. Please open the app on your mobile phone.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: Colors.white60,
                      height: 1.6,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(gradient: AppColors.headerGradient),
          ),
          // Decorative circles
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Phone icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.phone_android_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Phone Verification',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We will send a 6-digit verification code\nto your mobile number',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            color: Colors.white54,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Phone number input
                        Form(
                          key: _formKey,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Country code dropdown
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCountryCode,
                                      dropdownColor: const Color(0xFF1E1E2C),
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white38,
                                        size: 18,
                                      ),
                                      items: _countryCodes.map((cc) {
                                        return DropdownMenuItem(
                                          value: cc['code'],
                                          child: Text(
                                            '${cc['flag']} ${cc['code']}',
                                            style: GoogleFonts.spaceGrotesk(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(
                                            () => _selectedCountryCode = val,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                // Divider
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.white.withOpacity(0.15),
                                ),
                                // Phone field
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontSize: 16,
                                      letterSpacing: 1.2,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter mobile number',
                                      hintStyle: GoogleFonts.spaceGrotesk(
                                        color: Colors.white30,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter your phone number';
                                      }
                                      if (value.trim().length < 10) {
                                        return 'Enter a valid phone number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Send OTP button
                        InteractiveScale(
                          onTap: _loading ? () {} : _sendOTP,
                          child: Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Send OTP',
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Text(
                          'Standard SMS charges may apply',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: Colors.white30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Sending OTP...',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                        fontSize: 14,
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

