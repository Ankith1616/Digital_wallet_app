import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';
import '../utils/auth_manager.dart';
import 'biometric_settings_screen.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _hasDigiPin = false;
  bool _loading = true;

  final _setPinControllers = List.generate(4, (_) => TextEditingController());
  final _setPinNodes = List.generate(4, (_) => FocusNode());
  final _confirmPinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final _confirmPinNodes = List.generate(4, (_) => FocusNode());
  final _currentPinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final _currentPinNodes = List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _checkDigiPin();
  }

  @override
  void dispose() {
    for (final c in [
      ..._setPinControllers,
      ..._confirmPinControllers,
      ..._currentPinControllers,
    ]) {
      c.dispose();
    }
    for (final f in [
      ..._setPinNodes,
      ..._confirmPinNodes,
      ..._currentPinNodes,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _checkDigiPin() async {
    final has = await AuthService().hasDigiPin();
    if (mounted)
      setState(() {
        _hasDigiPin = has;
        _loading = false;
      });
  }

  String get _setPin => _setPinControllers.map((c) => c.text).join();
  String get _confirmPin => _confirmPinControllers.map((c) => c.text).join();
  String get _currentPin => _currentPinControllers.map((c) => c.text).join();

  void _clearAll() {
    for (final c in [
      ..._setPinControllers,
      ..._confirmPinControllers,
      ..._currentPinControllers,
    ]) {
      c.clear();
    }
    if (_hasDigiPin) {
      _currentPinNodes[0].requestFocus();
    } else {
      _setPinNodes[0].requestFocus();
    }
  }

  void _snack(String msg, {bool isError = true}) {
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

  Future<void> _saveDigiPin() async {
    // If an existing PIN is set, verify it first
    if (_hasDigiPin) {
      if (_currentPin.length != 4) {
        _snack('Please enter your current PIN.');
        return;
      }
      final valid = await AuthService().verifyDigiPin(_currentPin);
      if (!valid) {
        _snack('Current PIN is incorrect.');
        _clearAll();
        return;
      }
    }
    if (_setPin.length != 4 || _confirmPin.length != 4) {
      _snack('Please fill all digits.');
      return;
    }
    if (_setPin != _confirmPin) {
      _snack('PINs do not match. Try again.');
      _clearAll();
      return;
    }
    await AuthService().setDigiPin(_setPin);
    _clearAll();
    _snack('Digi PIN set successfully!', isError: false);
    await _checkDigiPin();
  }

  Future<void> _clearDigiPin() async {
    await AuthService().clearDigiPin();
    _snack('Digi PIN removed.', isError: false);
    await _checkDigiPin();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy & Security',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status card
                  _infoCard(
                    isDark,
                    icon: _hasDigiPin
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                    iconColor: _hasDigiPin ? Colors.green : Colors.orange,
                    title: _hasDigiPin ? 'Digi PIN Active' : 'No Digi PIN Set',
                    subtitle: _hasDigiPin
                        ? 'Your app is locked with Digi PIN on every launch.'
                        : 'Set a 4-digit Digi PIN to lock the app on every launch.',
                  ),

                  const SizedBox(height: 24),
                  _sectionLabel(
                    _hasDigiPin ? 'Change Digi PIN' : 'Set Digi PIN',
                  ),

                  if (_hasDigiPin) ...[
                    _fourBoxRow(
                      label: 'Current PIN',
                      controllers: _currentPinControllers,
                      nodes: _currentPinNodes,
                      nextNodes: _setPinNodes,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _fourBoxRow(
                    label: 'New PIN',
                    controllers: _setPinControllers,
                    nodes: _setPinNodes,
                    nextNodes: _confirmPinNodes,
                  ),
                  const SizedBox(height: 16),
                  _fourBoxRow(
                    label: 'Confirm PIN',
                    controllers: _confirmPinControllers,
                    nodes: _confirmPinNodes,
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _hasDigiPin
                          ? (_currentPin.length == 4 &&
                                    _setPin.length == 4 &&
                                    _confirmPin.length == 4
                                ? _saveDigiPin
                                : null)
                          : (_setPin.length == 4 && _confirmPin.length == 4
                                ? _saveDigiPin
                                : null),
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        _hasDigiPin ? 'Change Digi PIN' : 'Set Digi PIN',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  if (_hasDigiPin) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(
                              'Remove Digi PIN?',
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              'This will disable the app lock. Are you sure?',
                              style: GoogleFonts.spaceGrotesk(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _clearDigiPin();
                                },
                                child: Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.red.shade600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        icon: Icon(
                          Icons.no_encryption_outlined,
                          color: Colors.red.shade400,
                        ),
                        label: Text(
                          'Remove Digi PIN',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.red.shade400,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  _sectionLabel('Biometric Authentication'),
                  const SizedBox(height: 10),
                  _actionTile(
                    isDark,
                    icon: Icons.fingerprint_rounded,
                    title: 'Biometric & Transaction Limits',
                    subtitle: 'Enable fingerprint and set transaction limit',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BiometricSettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 0.4,
      ),
    ),
  );

  Widget _infoCard(
    bool isDark, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fourBoxRow({
    required String label,
    required List<TextEditingController> controllers,
    required List<FocusNode> nodes,
    List<FocusNode>? nextNodes,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(4, (i) {
            return Container(
              margin: const EdgeInsets.only(right: 12),
              width: 54,
              height: 58,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E2C)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: controllers[i].text.isNotEmpty
                      ? AppColors.primary
                      : Colors.grey.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: controllers[i],
                focusNode: nodes[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                obscureText: true,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (val) {
                  setState(() {});
                  if (val.isNotEmpty) {
                    if (i < 3) {
                      nodes[i + 1].requestFocus();
                    } else if (nextNodes != null) {
                      nextNodes[0].requestFocus();
                    }
                  } else if (i > 0) {
                    nodes[i - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _actionTile(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
