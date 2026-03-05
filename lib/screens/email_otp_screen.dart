import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';
import '../utils/email_otp_service.dart';
import '../utils/firebase_auth_service.dart';
import '../utils/fcm_service.dart';
import '../widgets/interactive_scale.dart';

/// Email-based OTP verification screen.
/// This screen is pushed AFTER credential validation, BEFORE Firebase sign-in.
/// On successful OTP → calls [FirebaseAuthService.completeSignIn] which
/// triggers the [StreamBuilder] in main.dart and auto-navigates to [MainLayout].
class EmailOtpScreen extends StatefulWidget {
  final String email;
  final String password;
  final String? name; // non-null = sign-up flow
  final bool isSignUp;

  const EmailOtpScreen({
    super.key,
    required this.email,
    required this.password,
    this.name,
    this.isSignUp = false,
  });

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _canResend = false;
  int _timerSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNodes[0].requestFocus(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _canResend = false;
      _timerSeconds = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_timerSeconds > 0) {
          _timerSeconds--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  String _maskedEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 3) return '***@$domain';
    return '${local.substring(0, 3)}***@$domain';
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.spaceGrotesk()),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _otp;
    if (otp.length != 6) {
      _showSnack('Please enter all 6 digits.');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await EmailOtpService().verifyOtp(widget.email, otp);
      switch (result) {
        case OtpVerifyResult.valid:
          // Clear OTP from Firestore
          await EmailOtpService().clearOtp(widget.email);

          // Complete Firebase sign-in (triggers StreamBuilder → MainLayout)
          final error = await FirebaseAuthService().completeSignIn(
            email: widget.email,
            password: widget.password,
            name: widget.name,
          );
          if (error != null) {
            _showSnack(error);
            return;
          }

          // Init FCM
          final uid = await FirebaseAuthService().currentUser?.uid;
          if (uid != null) await FcmService().init(uid: uid);

          if (!mounted) return;
          _showSnack(
            widget.isSignUp
                ? '🎉 Account verified! Welcome!'
                : '✅ Verified! Logging you in...',
            isError: false,
          );
          // Pop all the way to root — StreamBuilder will show MainLayout
          Navigator.of(context).popUntil((route) => route.isFirst);

        case OtpVerifyResult.expired:
          _showSnack('OTP has expired. Please request a new one.');

        case OtpVerifyResult.wrong:
          _showSnack('Incorrect OTP. Please try again.');
          _clearBoxes();

        case OtpVerifyResult.notFound:
          _showSnack('OTP not found. Please request a new code.');
      }
    } catch (e) {
      _showSnack('Verification failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    setState(() => _loading = true);
    try {
      final otp = EmailOtpService().generateOtp();
      await EmailOtpService().saveOtp(widget.email, otp);
      final error = await EmailOtpService().sendOtpEmail(widget.email, otp);
      if (error != null) {
        _showSnack('Failed to send OTP: $error');
        return;
      }
      _clearBoxes();
      _startTimer();
      _showSnack('OTP resent to ${_maskedEmail(widget.email)}', isError: false);
    } catch (_) {
      _showSnack('Could not resend OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearBoxes() {
    for (final c in _controllers) {
      c.clear();
    }
    if (mounted) _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
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
                        const SizedBox(height: 24),

                        // Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.mark_email_read_outlined,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Email Verification',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We sent a 6-digit code to',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _maskedEmail(widget.email),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            '⏰ Expires in 5 minutes',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              color: Colors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // OTP boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (i) {
                            return SizedBox(
                              width: 46,
                              height: 56,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _controllers[i].text.isNotEmpty
                                        ? AppColors.primary
                                        : Colors.white.withOpacity(0.15),
                                    width: 1.5,
                                  ),
                                ),
                                child: TextField(
                                  controller: _controllers[i],
                                  focusNode: _focusNodes[i],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    border: InputBorder.none,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (val) {
                                    setState(() {}); // refresh border
                                    if (val.isNotEmpty && i < 5) {
                                      _focusNodes[i + 1].requestFocus();
                                    }
                                    if (val.isEmpty && i > 0) {
                                      _focusNodes[i - 1].requestFocus();
                                    }
                                  },
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 32),

                        // Verify button — NO auto-submit
                        InteractiveScale(
                          onTap: _loading ? () {} : _verifyOtp,
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
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Verify & Continue',
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

                        // Resend OTP
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Didn't receive the code? ",
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: _canResend ? _resendOtp : null,
                              child: Text(
                                _canResend
                                    ? 'Resend OTP'
                                    : 'Resend in ${_timerSeconds}s',
                                style: GoogleFonts.spaceGrotesk(
                                  color: _canResend
                                      ? Colors.white
                                      : Colors.white38,
                                  fontSize: 13,
                                  fontWeight: _canResend
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                      'Verifying...',
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
