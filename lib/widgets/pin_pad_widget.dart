import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../utils/theme_manager.dart';

/// A fully self-contained PIN pad widget.
///
/// - Shows 4 dot indicators
/// - Digit keys 1-9, 0, delete, and a confirm (✓) button
/// - NO auto-submit — user must press ✓ when all 4 digits are entered
/// - Exposes [onConfirm] callback with the 4-digit PIN string
/// - Manages [maxStrikes] internally; calls [onLockout] when exceeded
/// - Shake animation on wrong PIN via [shake()]
class PinPadWidget extends StatefulWidget {
  /// Called when the user presses ✓ with a full 4-digit PIN.
  /// Return `true` to clear and allow retry, `false` to indicate success and lock.
  final Future<bool> Function(String pin) onConfirm;

  /// Maximum incorrect attempts before lockout (default: 3)
  final int maxStrikes;

  /// Called after [maxStrikes] failures (optional)
  final VoidCallback? onLockout;

  /// Optional message shown below dots (e.g. "Enter PIN · 2 attempts left")
  final String? subtitle;

  const PinPadWidget({
    super.key,
    required this.onConfirm,
    this.maxStrikes = 3,
    this.onLockout,
    this.subtitle,
  });

  @override
  State<PinPadWidget> createState() => PinPadWidgetState();
}

class PinPadWidgetState extends State<PinPadWidget>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isSuccess = false;
  bool _isProcessing = false;
  int _strikeCount = 0;
  String? _errorMessage;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
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

  /// Call this from parent to trigger a shake + clear (on wrong PIN)
  void shake({String? message}) {
    HapticFeedback.vibrate();
    setState(() {
      _pin = '';
      _strikeCount++;
      _errorMessage = message ?? 'Incorrect PIN';
    });
    _shakeController.forward(from: 0);

    if (_strikeCount >= widget.maxStrikes) {
      setState(() => _errorMessage = 'Too many attempts. Access denied.');
      Future.delayed(const Duration(milliseconds: 800), () {
        widget.onLockout?.call();
      });
    }
  }

  /// Call this from parent to mark success (fills dots green)
  void markSuccess() {
    setState(() {
      _isSuccess = true;
      _errorMessage = null;
    });
  }

  void _onDigit(String digit) {
    if (_isSuccess || _isProcessing || _pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += digit;
      _errorMessage = null;
    });
  }

  void _onDelete() {
    if (_isSuccess || _isProcessing || _pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onConfirm() async {
    if (_pin.length != 4 || _isSuccess || _isProcessing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);
    final wrong = await widget.onConfirm(_pin);
    if (!mounted) return;
    if (wrong) {
      shake();
    }
    setState(() => _isProcessing = false);
  }

  int get remainingAttempts => widget.maxStrikes - _strikeCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Dot indicators ──────────────────────────────────────
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset = _shakeController.isAnimating
                ? math.sin(_shakeAnimation.value * math.pi * 6) * 12
                : 0.0;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < _pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: filled ? 18 : 15,
                height: filled ? 18 : 15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isSuccess
                      ? const LinearGradient(
                          colors: [AppColors.success, AppColors.success],
                        )
                      : filled
                      ? AppColors.primaryGradient
                      : null,
                  color: filled || _isSuccess
                      ? null
                      : (isDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.grey.shade200),
                  boxShadow: filled || _isSuccess
                      ? [
                          BoxShadow(
                            color: (_isSuccess
                                    ? AppColors.success
                                    : AppColors.primary)
                                .withOpacity(0.45),
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

        // ── Error/strike message ─────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _errorMessage != null
              ? Padding(
                  key: ValueKey(_errorMessage),
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : widget.subtitle != null
              ? Padding(
                  key: const ValueKey('subtitle'),
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _strikeCount > 0
                        ? '${widget.subtitle} · $remainingAttempts left'
                        : widget.subtitle!,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                )
              : const SizedBox(key: ValueKey('empty'), height: 10),
        ),

        const SizedBox(height: 32),

        // ── Keypad ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              _row(['1', '2', '3'], isDark),
              const SizedBox(height: 14),
              _row(['4', '5', '6'], isDark),
              const SizedBox(height: 14),
              _row(['7', '8', '9'], isDark),
              const SizedBox(height: 14),
              _row(['del', '0', '✓'], isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(List<String> keys, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((k) => _key(k, isDark)).toList(),
    );
  }

  Widget _key(String key, bool isDark) {
    final isDelete = key == 'del';
    final isConfirm = key == '✓';
    final confirmEnabled = isConfirm && _pin.length == 4 && !_isProcessing;

    Color bgColor;
    Color? glowColor;

    if (isConfirm) {
      bgColor = confirmEnabled
          ? AppColors.primary
          : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100);
      glowColor = confirmEnabled ? AppColors.primary : null;
    } else if (isDelete) {
      bgColor = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100;
    } else {
      bgColor = isDark ? Colors.white.withOpacity(0.08) : Colors.white;
    }

    return GestureDetector(
      onTap: (_isSuccess || _isProcessing)
          ? null
          : isDelete
          ? _onDelete
          : isConfirm
          ? (confirmEnabled ? _onConfirm : null)
          : () => _onDigit(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: glowColor != null
              ? [
                  BoxShadow(
                    color: glowColor.withOpacity(0.42),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.withOpacity(0.12),
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
              ? (_isProcessing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: confirmEnabled ? Colors.white : Colors.grey,
                        ),
                      )
                    : Icon(
                        Icons.check_rounded,
                        color: confirmEnabled
                            ? Colors.white
                            : (isDark ? Colors.white24 : Colors.grey.shade400),
                        size: 26,
                      ))
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
