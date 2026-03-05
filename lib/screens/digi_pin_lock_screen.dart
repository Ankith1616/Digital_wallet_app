import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';
import '../utils/auth_manager.dart';

/// App lock screen — shown at launch when a Digi PIN is set.
/// Must be verified before [MainLayout] is shown.
/// On success, [onUnlocked] is called (navigates to MainLayout).
class DigiPinLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const DigiPinLockScreen({super.key, required this.onUnlocked});

  @override
  State<DigiPinLockScreen> createState() => _DigiPinLockScreenState();
}

class _DigiPinLockScreenState extends State<DigiPinLockScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  static const int _maxAttempts = 5;
  int _attempts = 0;
  bool _loading = false;
  String? _errorMsg;
  bool _locked = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNodes[0].requestFocus(),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _pin => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_locked) return;
    final pin = _pin;
    if (pin.length != 4) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final correct = await AuthService().verifyDigiPin(pin);
      if (!mounted) return;

      if (correct) {
        widget.onUnlocked();
      } else {
        _attempts++;
        _clearBoxes();
        await _shakeController.forward(from: 0);

        if (_attempts >= _maxAttempts) {
          setState(() {
            _locked = true;
            _errorMsg = 'Too many attempts. Please sign in again.';
          });
          // Sign out after too many attempts
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            // Pop and let StreamBuilder show LoginScreen
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
        } else {
          setState(() {
            _errorMsg =
                'Incorrect PIN. ${_maxAttempts - _attempts} attempt(s) remaining.';
          });
        }
      }
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
          // Gradient background
          Container(
            decoration: BoxDecoration(gradient: AppColors.headerGradient),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lock icon
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Enter Digi PIN',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your 4-digit app lock PIN\nto access Digital Wallet',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        color: Colors.white54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // PIN boxes with shake animation
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        final dx =
                            _shakeAnimation.value *
                            12 *
                            ((_shakeAnimation.value * 8).floor().isEven
                                ? 1
                                : -1);
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: child,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 54,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _controllers[i].text.isNotEmpty
                                    ? AppColors.primary
                                    : Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              obscureText: true,
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 24,
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
                                setState(() {});
                                if (val.isNotEmpty && i < 3) {
                                  _focusNodes[i + 1].requestFocus();
                                }
                                if (val.isEmpty && i > 0) {
                                  _focusNodes[i - 1].requestFocus();
                                }
                              },
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Error message
                    if (_errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _errorMsg!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.red.shade300,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Confirm button — NO auto-submit
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_loading || _locked || _pin.length != 4)
                            ? null
                            : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          disabledBackgroundColor: Colors.white.withOpacity(
                            0.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
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
                                'Unlock',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
