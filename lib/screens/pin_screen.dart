import 'package:flutter/material.dart';
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

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String _firstPin = '';
  String _title = '';
  String _subtitle = '';
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _updateUI();
  }

  void _updateUI() {
    setState(() {
      switch (widget.mode) {
        case PinMode.create:
          _title = _isConfirming ? "Confirm PIN" : "Create PIN";
          _subtitle = _isConfirming
              ? "Re-enter your PIN to confirm"
              : "Set a 4-digit PIN for security";
          break;
        case PinMode.verify:
          _title = "Enter PIN";
          _subtitle = "Please enter your PIN to proceed";
          break;
        case PinMode.change:
          _title = _isConfirming ? "Enter New PIN" : "Enter Old PIN";
          _subtitle = _isConfirming
              ? "Set your new 4-digit PIN"
              : "Verify your current PIN";
          break;
      }
    });
  }

  void _onDigitPress(String digit) {
    if (_pin.length < 4) {
      setState(() => _pin += digit);
      // Auto-submit removed
    }
  }

  void _onDeletePress() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _handlePinSubmit() async {
    // ... logic remains somewhat same, but ensure we check length
    if (_pin.length != 4) return;

    final auth = AuthService();

    if (widget.mode == PinMode.verify) {
      bool isValid = await auth.verifyPin(_pin);
      if (isValid) {
        if (widget.onSuccess != null) widget.onSuccess!();
        if (mounted) Navigator.pop(context, true);
      } else {
        _showError("Incorrect PIN");
        setState(() => _pin = '');
      }
    } else if (widget.mode == PinMode.create) {
      if (_isConfirming) {
        if (_pin == _firstPin) {
          await auth.setPin(_pin);
          if (widget.onSuccess != null) widget.onSuccess!();
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("PIN Set Successfully")),
            );
          }
        } else {
          _showError("PINs do not match");
          setState(() {
            _pin = '';
            _isConfirming = false;
            _updateUI();
          });
        }
      } else {
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _isConfirming = true;
          _updateUI();
        });
      }
    } else if (widget.mode == PinMode.change) {
      // First enter old PIN
      if (!_isConfirming) {
        bool isValid = await auth.verifyPin(_pin);
        if (isValid) {
          setState(() {
            _pin = '';
            _isConfirming = true; // reusing bool to mean "now enter new pin"
            _updateUI();
          });
        } else {
          _showError("Incorrect Old PIN");
          setState(() => _pin = '');
        }
      } else {
        // Now Create New PIN logic (simplified for immediate set, ideally double confirm new pin too)
        await auth.setPin(_pin);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("PIN Changed Successfully")),
          );
        }
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 48),
          // PIN Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < _pin.length
                      ? AppColors.primary
                      : (isDark ? Colors.white24 : Colors.grey.shade300),
                ),
              );
            }),
          ),
          const SizedBox(height: 64),
          // Keypad
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildKeyRow(['1', '2', '3'], isDark),
                  const SizedBox(height: 24),
                  _buildKeyRow(['4', '5', '6'], isDark),
                  const SizedBox(height: 24),
                  _buildKeyRow(['7', '8', '9'], isDark),
                  const SizedBox(height: 24),
                  _buildKeyRow(['delete', '0', 'confirm'], isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) {
        if (key == 'delete') {
          return _buildKeyButton(
            child: Icon(
              Icons.backspace_outlined,
              color: isDark ? Colors.white : Colors.black,
            ),
            onTap: _onDeletePress,
            isDark: isDark,
          );
        }
        if (key == 'confirm') {
          final isEnabled = _pin.length == 4;
          return _buildKeyButton(
            child: Icon(
              Icons.check,
              color: isEnabled ? Colors.white : Colors.grey,
            ),
            bgColor: isEnabled
                ? AppColors.primary
                : (isDark ? Colors.white10 : Colors.grey.shade200),
            onTap: isEnabled ? _handlePinSubmit : () {},
            isDark: isDark,
          );
        }
        return _buildKeyButton(
          child: Text(
            key,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          onTap: () => _onDigitPress(key),
          isDark: isDark,
        );
      }).toList(),
    );
  }

  Widget _buildKeyButton({
    required Widget child,
    required VoidCallback onTap,
    required bool isDark,
    Color? bgColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              bgColor ??
              (isDark ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(20)),
        ),
        child: child,
      ),
    );
  }
}
