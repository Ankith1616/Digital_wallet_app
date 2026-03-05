import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/theme_manager.dart';
import '../utils/auth_manager.dart';

/// Biometric & Security Settings Screen.
///
/// Allows the user to:
/// - Enable/disable biometric authentication
/// - Set the biometric transaction limit (₹100 – ₹10,000)
/// - View device biometric support status
/// - View today's instant pay usage
class BiometricSettingsScreen extends StatefulWidget {
  const BiometricSettingsScreen({super.key});

  @override
  State<BiometricSettingsScreen> createState() =>
      _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState extends State<BiometricSettingsScreen> {
  final AuthService _auth = AuthService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _biometricEnabled = false;
  double _limit = 1000.0;
  bool _deviceSupported = false;
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableTypes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Check device capability
    final supported = await _localAuth.isDeviceSupported();
    final canCheck = await _localAuth.canCheckBiometrics;
    final types = await _localAuth.getAvailableBiometrics();

    setState(() {
      _deviceSupported = supported;
      _canCheckBiometrics = canCheck;
      _availableTypes = types;
      _biometricEnabled = _auth.isBiometricEnabled;
      _limit = _auth.instantLimit.clamp(100.0, 10000.0);
      _loading = false;
    });
  }

  Future<void> _toggleBiometric(bool val) async {
    if (val && (!_deviceSupported || !_canCheckBiometrics)) {
      _showSnack('⚠️ Biometric not available on this device');
      return;
    }
    if (val) {
      // Verify once before enabling
      final ok = await _auth.authenticateBiometrics();
      if (!ok) {
        _showSnack('Biometric verification failed');
        return;
      }
    }
    await _auth.toggleBiometric(val);
    setState(() => _biometricEnabled = val);
    _showSnack(val ? 'Biometric enabled ✓' : 'Biometric disabled');
  }

  Future<void> _saveLimit(double val) async {
    await _auth.setInstantLimit(val);
    setState(() => _limit = val);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.spaceGrotesk()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _biometricTypeLabel() {
    if (_availableTypes.contains(BiometricType.face)) return 'Face ID';
    if (_availableTypes.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    }
    if (_availableTypes.contains(BiometricType.iris)) return 'Iris';
    return 'Biometric';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          'Biometric & Security',
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
                  // ── Device support card ─────────────────────────
                  _infoCard(isDark),
                  const SizedBox(height: 20),

                  // ── Biometric toggle ────────────────────────────
                  _sectionLabel('BIOMETRIC LOGIN'),
                  const SizedBox(height: 8),
                  _card(
                    isDark,
                    child: SwitchListTile(
                      value: _biometricEnabled,
                      onChanged: _deviceSupported && _canCheckBiometrics
                          ? _toggleBiometric
                          : null,
                      activeTrackColor: AppColors.primary,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.fingerprint,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        'Enable ${_biometricTypeLabel()}',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        _biometricEnabled
                            ? 'Used for login & high-value payments'
                            : 'Tap to enable for faster login',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Transaction limit ───────────────────────────
                  _sectionLabel('BIOMETRIC PAYMENT LIMIT'),
                  const SizedBox(height: 4),
                  Text(
                    'Transactions above this limit require biometric authentication.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    isDark,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Limit',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '₹${_limit.toStringAsFixed(0)}',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: AppColors.primary.withValues(
                                alpha: 0.2,
                              ),
                              thumbColor: AppColors.primary,
                              overlayColor: AppColors.primary.withValues(
                                alpha: 0.15,
                              ),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _limit,
                              min: 100,
                              max: 10000,
                              divisions: 99,
                              label: '₹${_limit.toStringAsFixed(0)}',
                              onChanged: _biometricEnabled
                                  ? (val) => setState(() => _limit = val)
                                  : null,
                              onChangeEnd: _biometricEnabled
                                  ? _saveLimit
                                  : null,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹100',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '₹10,000',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Daily usage ─────────────────────────────────
                  _sectionLabel('TODAY\'S INSTANT PAY USAGE'),
                  const SizedBox(height: 8),
                  _card(
                    isDark,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.flash_on_rounded,
                          color: AppColors.success,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        '₹${_auth.instantDailyUsage.toStringAsFixed(2)} used',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Daily limit: ₹${AuthService.maxDailyInstantLimit.toStringAsFixed(0)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Text(
                        '${((_auth.instantDailyUsage / AuthService.maxDailyInstantLimit) * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Security tip
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Biometric is an additional layer. PIN always serves as the final fallback for all transactions.',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : Colors.black54,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoCard(bool isDark) {
    final supported = _deviceSupported && _canCheckBiometrics;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: supported
              ? [
                  AppColors.success.withValues(alpha: 0.15),
                  AppColors.success.withValues(alpha: 0.05),
                ]
              : [
                  AppColors.error.withValues(alpha: 0.12),
                  AppColors.error.withValues(alpha: 0.04),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: supported
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            supported ? Icons.verified_rounded : Icons.error_outline_rounded,
            color: supported ? AppColors.success : AppColors.error,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supported ? 'Device Supported ✓' : 'Biometric Not Available',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: supported ? AppColors.success : AppColors.error,
                  ),
                ),
                Text(
                  supported
                      ? 'Available: ${_availableTypes.map((t) => t.name).join(', ')}'
                      : 'Your device does not support biometric auth.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
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

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.primary.withValues(alpha: 0.7),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _card(bool isDark, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: child,
    );
  }
}
