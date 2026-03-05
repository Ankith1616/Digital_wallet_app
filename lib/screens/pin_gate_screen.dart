import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';
import '../utils/auth_manager.dart';
import '../widgets/pin_pad_widget.dart';

/// A PIN-gate wrapper screen.
///
/// Shows a PIN (and optionally biometric) prompt before granting access to [child].
/// On success → pushes [child] as a replacement or navigates to it.
/// On lockout (3 wrong attempts) → pops with false.
class PinGateScreen extends StatefulWidget {
  /// The screen to navigate to on successful PIN verification.
  final Widget child;

  /// Custom title shown on the gate screen (default: "Verify Identity")
  final String? title;

  /// Custom subtitle shown below title
  final String? subtitle;

  const PinGateScreen({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
  });

  /// Convenience: push a PIN gate that, on success, navigates to [destination].
  static Future<void> push(
    BuildContext context, {
    required Widget destination,
    String? title,
    String? subtitle,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PinGateScreen(title: title, subtitle: subtitle, child: destination),
      ),
    );
  }

  @override
  State<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends State<PinGateScreen> {
  final AuthService _auth = AuthService();
  bool _biometricAttempted = false;
  bool _isLockedOut = false;

  @override
  void initState() {
    super.initState();
    // Attempt biometric first if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_auth.isBiometricEnabled && !_biometricAttempted) {
        _biometricAttempted = true;
        final ok = await _auth.authenticateBiometrics();
        if (ok && mounted) {
          _navigateToChild();
        }
      }
    });
  }

  void _navigateToChild() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => widget.child),
    );
  }

  Future<bool> _handlePin(String pin) async {
    final valid = await _auth.verifyDigiPin(pin);
    if (valid) {
      if (mounted) _navigateToChild();
      return false; // false = don't shake (success)
    }
    return true; // true = shake (wrong PIN)
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background orbs
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFF7B2FBE,
                    ).withValues(alpha: isDark ? 0.1 : 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Lock icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  widget.title ?? 'Verify Identity',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle ?? 'Enter your PIN to continue',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                if (_auth.isBiometricEnabled) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () async {
                      final ok = await _auth.authenticateBiometrics();
                      if (ok && mounted) _navigateToChild();
                    },
                    icon: const Icon(
                      Icons.fingerprint,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      'Use Biometric',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                if (_isLockedOut)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.lock_outlined,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Access Denied',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Too many wrong attempts.',
                          style: GoogleFonts.spaceGrotesk(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else
                  PinPadWidget(
                    onConfirm: _handlePin,
                    maxStrikes: 3,
                    subtitle: 'Enter your transaction PIN',
                    onLockout: () {
                      if (mounted) {
                        setState(() => _isLockedOut = true);
                        final nav = Navigator.of(context);
                        Future.delayed(const Duration(seconds: 2), () {
                          nav.pop();
                        });
                      }
                    },
                  ),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
