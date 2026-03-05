import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';
import '../utils/notification_prefs.dart' as np;

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  /// Mirrors the values from [NotificationPrefs]
  final Map<np.NotificationType, bool> _prefs = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await np.NotificationPrefs().getAllPrefs();
    if (mounted)
      setState(() {
        _prefs.addAll(all);
        _loading = false;
      });
  }

  Future<void> _setToggle(np.NotificationType type, bool value) async {
    await np.NotificationPrefs().setEnabled(type, value);
    if (mounted) setState(() => _prefs[type] = value);
  }

  bool _get(np.NotificationType type) => _prefs[type] ?? true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Settings',
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
                  _sectionHeader('Transactions'),
                  _toggleTile(
                    context,
                    Icons.check_circle_outline,
                    isDark,
                    'Transaction Success',
                    'Alert on successful payments',
                    np.NotificationType.txSuccess,
                  ),
                  const SizedBox(height: 10),
                  _toggleTile(
                    context,
                    Icons.error_outline,
                    isDark,
                    'Transaction Failed',
                    'Alert on failed or declined payments',
                    np.NotificationType.txFailed,
                  ),
                  const SizedBox(height: 20),
                  _sectionHeader('Rewards'),
                  _toggleTile(
                    context,
                    Icons.card_giftcard_outlined,
                    isDark,
                    'Cashback Earned',
                    'When cashback is credited to your account',
                    np.NotificationType.cashback,
                  ),
                  const SizedBox(height: 10),
                  _toggleTile(
                    context,
                    Icons.star_outline_rounded,
                    isDark,
                    'Rewards & Offers',
                    'Exclusive deals and reward credits',
                    np.NotificationType.rewards,
                  ),
                  const SizedBox(height: 10),
                  _toggleTile(
                    context,
                    Icons.local_offer_outlined,
                    isDark,
                    'Promotional Offers',
                    'Deals and partner cashback offers',
                    np.NotificationType.promoOffers,
                  ),
                  const SizedBox(height: 20),
                  _sectionHeader('Security'),
                  _toggleTile(
                    context,
                    Icons.security_outlined,
                    isDark,
                    'Security Alerts',
                    'Login, PIN changes & suspicious activity',
                    np.NotificationType.securityAlerts,
                  ),
                  const SizedBox(height: 10),
                  _toggleTile(
                    context,
                    Icons.notifications_active_outlined,
                    isDark,
                    'Push Notifications',
                    'Master toggle for all push alerts',
                    np.NotificationType.pushNotifications,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _toggleTile(
    BuildContext context,
    IconData icon,
    bool isDark,
    String title,
    String subtitle,
    np.NotificationType type,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.06),
        ),
      ),
      child: SwitchListTile.adaptive(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.spaceGrotesk(color: Colors.grey, fontSize: 11),
        ),
        value: _get(type),
        onChanged: (v) => _setToggle(type, v),
        activeColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
