import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme_manager.dart';
import '../utils/auth_manager.dart';
import '../utils/email_otp_service.dart';
import '../widgets/interactive_scale.dart';
import 'digi_pin_entry_screen.dart';

class DigiPinSettingsScreen extends StatefulWidget {
  const DigiPinSettingsScreen({super.key});

  @override
  State<DigiPinSettingsScreen> createState() => _DigiPinSettingsScreenState();
}

class _DigiPinSettingsScreenState extends State<DigiPinSettingsScreen> {
  final AuthService _auth = AuthService();
  bool _hasPin = false;
  bool _biometricEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    await _auth.init();
    final hasPin = await _auth.hasDigiPin();
    if (mounted) {
      setState(() {
        _hasPin = hasPin;
        _biometricEnabled = _auth.isBiometricEnabled;
        _loading = false;
      });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
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

  // ─── Set / Change / Remove ─────────────────────────────────────────

  Future<void> _handleSetPin() async {
    final pin = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const DigiPinEntryScreen(mode: DigiPinMode.create),
      ),
    );
    if (pin != null) {
      await _auth.setDigiPin(pin);
      _showSnack('Digi PIN set successfully!');
      _loadState();
    }
  }

  Future<void> _handleChangePin() async {
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const DigiPinEntryScreen(mode: DigiPinMode.verify),
      ),
    );
    if (verified != true) return;
    if (!mounted) return;

    final newPin = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const DigiPinEntryScreen(mode: DigiPinMode.create),
      ),
    );
    if (newPin != null) {
      await _auth.setDigiPin(newPin);
      if (!mounted) return;
      _showSnack('Digi PIN changed successfully!');
      _loadState();
    }
  }

  Future<void> _handleRemovePin() async {
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const DigiPinEntryScreen(mode: DigiPinMode.verify),
      ),
    );
    if (verified != true) return;

    await _auth.clearDigiPin();
    if (_biometricEnabled) {
      await _auth.toggleBiometric(false);
    }
    _showSnack('Digi PIN removed.');
    _loadState();
  }

  // ─── Biometric Toggle ──────────────────────────────────────────────

  Future<void> _toggleBiometric(bool val) async {
    if (!_hasPin) {
      _showSnack('Set a Digi PIN first to enable biometric unlock',
          isError: true);
      return;
    }
    if (val) {
      try {
        final result = await _auth.authenticateBiometricsDetailed();
        if (!result.success) {
          _showSnack(
            result.errorMessage ?? 'Biometric verification failed',
            isError: true,
          );
          return;
        }
      } catch (e) {
        _showSnack('Could not verify biometrics: $e', isError: true);
        return;
      }
    }
    await _auth.toggleBiometric(val);
    setState(() => _biometricEnabled = val);
    _showSnack(val ? 'Biometric unlock enabled' : 'Biometric unlock disabled');
  }

  // ─── Forgot PIN ────────────────────────────────────────────────────

  Future<void> _handleForgotPin() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) {
      _showSnack('No email found on your account.', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Digi PIN',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'We will send a verification code to\n$email',
          style: GoogleFonts.spaceGrotesk(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.spaceGrotesk(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Send OTP',
                style: GoogleFonts.spaceGrotesk(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Send OTP
    try {
      final otp = EmailOtpService().generateOtp();
      await EmailOtpService().saveOtp(email, otp);
      final sendErr = await EmailOtpService().sendOtpEmail(email, otp);
      if (sendErr != null) {
        _showSnack('Could not send OTP: $sendErr', isError: true);
        return;
      }
    } catch (e) {
      _showSnack('Failed to send OTP.', isError: true);
      return;
    }

    if (!mounted) return;
    _showSnack('OTP sent to $email');

    // Verify OTP
    final otpVerified = await _showOtpVerifyDialog(email);
    if (otpVerified != true) return;
    if (!mounted) return;

    // Allow creating new PIN
    final newPin = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const DigiPinEntryScreen(mode: DigiPinMode.create),
      ),
    );
    if (newPin != null) {
      await _auth.setDigiPin(newPin);
      if (!mounted) return;
      _showSnack('Digi PIN has been reset!');
      _loadState();
    }
  }

  // ─── Dialogs ───────────────────────────────────────────────────────

  /// OTP verification dialog. Returns true if verified.
  Future<bool?> _showOtpVerifyDialog(String email) {
    final controller = TextEditingController();
    String? errorMsg;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          Future<void> verify() async {
            final otp = controller.text.trim();
            if (otp.length != 6) {
              setDialogState(() => errorMsg = 'Enter the 6-digit code');
              return;
            }
            final result = await EmailOtpService().verifyOtp(email, otp);
            switch (result) {
              case OtpVerifyResult.valid:
                await EmailOtpService().clearOtp(email);
                if (ctx.mounted) Navigator.pop(ctx, true);
              case OtpVerifyResult.expired:
                setDialogState(() => errorMsg = 'OTP expired. Try again.');
              case OtpVerifyResult.wrong:
                setDialogState(() => errorMsg = 'Incorrect code.');
              case OtpVerifyResult.notFound:
                setDialogState(() => errorMsg = 'OTP not found. Try again.');
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Enter Verification Code',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Code sent to $email',
                    style:
                        GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white, fontSize: 22, letterSpacing: 8),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '------',
                    hintStyle: GoogleFonts.spaceGrotesk(
                        color: Colors.white24, fontSize: 22, letterSpacing: 8),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 10),
                  Text(errorMsg!,
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.red.shade300, fontSize: 13)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style: GoogleFonts.spaceGrotesk(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Verify',
                    style: GoogleFonts.spaceGrotesk(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D1A) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Digi PIN & Security',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.headerGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.shield_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('App Lock',
                                  style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                _hasPin
                                    ? 'Digi PIN is active'
                                    : 'No Digi PIN set',
                                style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white60, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _hasPin
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _hasPin ? 'ON' : 'OFF',
                            style: GoogleFonts.spaceGrotesk(
                              color: _hasPin
                                  ? Colors.green.shade300
                                  : Colors.orange.shade300,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // PIN actions section
                  _sectionLabel('PIN MANAGEMENT'),
                  const SizedBox(height: 10),

                  if (!_hasPin)
                    _actionTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Set Digi PIN',
                      subtitle: 'Create a 4-digit app lock PIN',
                      color: const Color(0xFF00E676),
                      onTap: _handleSetPin,
                      isDark: isDark,
                    ),

                  if (_hasPin) ...[
                    _actionTile(
                      icon: Icons.sync_lock_rounded,
                      title: 'Change Digi PIN',
                      subtitle: 'Update your existing PIN',
                      color: const Color(0xFF448AFF),
                      onTap: _handleChangePin,
                      isDark: isDark,
                    ),
                    _actionTile(
                      icon: Icons.lock_open_rounded,
                      title: 'Remove Digi PIN',
                      subtitle: 'Disable app lock',
                      color: Colors.red.shade400,
                      onTap: _handleRemovePin,
                      isDark: isDark,
                    ),
                  ],

                  if (_hasPin) ...[
                    const SizedBox(height: 24),

                    // Biometric section
                    _sectionLabel('BIOMETRIC UNLOCK'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fingerprint,
                              color: Color(0xFF7C4DFF), size: 22),
                        ),
                        title: Text('Biometric Unlock',
                            style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(
                          'Use fingerprint or face to unlock app',
                          style: GoogleFonts.spaceGrotesk(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 12),
                        ),
                        trailing: Switch(
                          value: _biometricEnabled,
                          activeTrackColor: AppColors.primary,
                          onChanged: _toggleBiometric,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Forgot PIN
                    _sectionLabel('RECOVERY'),
                    const SizedBox(height: 10),
                    _actionTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Forgot Digi PIN?',
                      subtitle: 'Reset via email verification',
                      color: const Color(0xFFFFAB40),
                      onTap: _handleForgotPin,
                      isDark: isDark,
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary.withValues(alpha: 0.7),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InteractiveScale(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(title,
                style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(subtitle,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          ),
        ),
      ),
    );
  }
}
