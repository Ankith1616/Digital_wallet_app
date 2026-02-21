import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';
import '../utils/auth_manager.dart';

enum PinMode { create, verify, change }

class PinScreen extends StatefulWidget {
  final PinMode mode;
  final VoidCallback? onSuccess;

  const PinScreen({super.key, required this.mode, this.onSuccess});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _firstPin = '';
  bool _isConfirming = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.mode) {
      case PinMode.create:
        return _isConfirming ? 'Confirm PIN' : 'Create PIN';
      case PinMode.verify:
        return 'Enter PIN';
      case PinMode.change:
        return _isConfirming ? 'New PIN' : 'Current PIN';
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case PinMode.create:
        return _isConfirming
            ? 'Re-enter your 4-digit PIN'
            : 'Set a PIN to secure your payments';
      case PinMode.verify:
        return 'Enter your PIN to authorise';
      case PinMode.change:
        return _isConfirming
            ? 'Enter a new 4-digit PIN'
            : 'Verify your existing PIN';
    }
  }

  void _onDigitPress(String digit) {
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() => _pin += digit);
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), _handlePinSubmit);
    }
  }

  void _onDeletePress() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _handlePinSubmit() async {
    if (_pin.length != 4) return;
    final auth = AuthService();

    if (widget.mode == PinMode.verify) {
      bool isValid = await auth.verifyPin(_pin);
      if (isValid) {
        HapticFeedback.heavyImpact();
        if (widget.onSuccess != null) widget.onSuccess!();
        if (mounted) Navigator.pop(context, true);
      } else {
        _showShake('Incorrect PIN');
      }
    } else if (widget.mode == PinMode.create) {
      if (_isConfirming) {
        if (_pin == _firstPin) {
          await auth.setPin(_pin);
          HapticFeedback.heavyImpact();
          if (widget.onSuccess != null) widget.onSuccess!();
          if (mounted) Navigator.pop(context, true);
        } else {
          _showShake('PINs do not match');
          setState(() {
            _isConfirming = false;
            _firstPin = '';
          });
        }
      } else {
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _isConfirming = true;
        });
      }
    } else if (widget.mode == PinMode.change) {
      if (!_isConfirming) {
        bool isValid = await auth.verifyPin(_pin);
        if (isValid) {
          setState(() {
            _pin = '';
            _isConfirming = true;
          });
        } else {
          _showShake('Incorrect PIN');
        }
      } else {
        await auth.setPin(_pin);
        HapticFeedback.heavyImpact();
        if (mounted) Navigator.pop(context, true);
      }
    }
  }

  void _showShake(String message) {
    HapticFeedback.vibrate();
    setState(() => _pin = '');
    _shakeController.forward(from: 0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.spaceGrotesk()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          // Subtle cosmic background orbs
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
            bottom: 80,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
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
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  _title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),

                // PIN Dots with shake animation
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    final offset = _shakeController.isAnimating
                        ? 8 *
                              (0.5 - (_shakeAnimation.value % 0.25 / 0.25))
                                  .abs()
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(offset * 8, 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final filled = index < _pin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: filled ? 18 : 16,
                        height: filled ? 18 : 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: filled ? AppColors.primaryGradient : null,
                          color: filled
                              ? null
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.grey.shade200),
                          boxShadow: filled
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ),

                const Spacer(flex: 3),

                // Keypad
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _buildKeyRow(['1', '2', '3'], isDark),
                      const SizedBox(height: 16),
                      _buildKeyRow(['4', '5', '6'], isDark),
                      const SizedBox(height: 16),
                      _buildKeyRow(['7', '8', '9'], isDark),
                      const SizedBox(height: 16),
                      _buildKeyRow(['del', '0', '✓'], isDark),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) => _buildKey(key, isDark)).toList(),
    );
  }

  Widget _buildKey(String key, bool isDark) {
    final isDelete = key == 'del';
    final isConfirm = key == '✓';
    final isConfirmEnabled = isConfirm && _pin.length == 4;

    Color bgColor;
    Color? glowColor;

    if (isConfirm) {
      bgColor = isConfirmEnabled
          ? AppColors.primary
          : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade100);
      glowColor = isConfirmEnabled ? AppColors.primary : null;
    } else if (isDelete) {
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.grey.shade100;
    } else {
      bgColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white;
    }

    return GestureDetector(
      onTap: () {
        if (isDelete) {
          _onDeletePress();
        } else if (isConfirm) {
          if (isConfirmEnabled) _handlePinSubmit();
        } else {
          _onDigitPress(key);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: glowColor != null
              ? [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Center(
          child: isDelete
              ? Icon(
                  Icons.backspace_rounded,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: 22,
                )
              : isConfirm
              ? Icon(
                  Icons.check_rounded,
                  color: isConfirmEnabled
                      ? Colors.white
                      : (isDark ? Colors.white24 : Colors.grey.shade400),
                  size: 26,
                )
              : Text(
                  key,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
        ),
      ),
    );
  }
}
