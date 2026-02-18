import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailAlerts = false;
  bool _transactionAlerts = true;
  bool _promoOffers = false;
  bool _securityAlerts = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _toggleTile(
              context,
              Icons.notifications_active,
              "Push Notifications",
              "Receive transaction alerts",
              _pushNotifications,
              (v) => setState(() => _pushNotifications = v),
              isDark,
            ),
            const SizedBox(height: 10),
            _toggleTile(
              context,
              Icons.email_outlined,
              "Email Alerts",
              "Get email summaries",
              _emailAlerts,
              (v) => setState(() => _emailAlerts = v),
              isDark,
            ),
            const SizedBox(height: 10),
            _toggleTile(
              context,
              Icons.payment,
              "Transaction Alerts",
              "Instant payment notifications",
              _transactionAlerts,
              (v) => setState(() => _transactionAlerts = v),
              isDark,
            ),
            const SizedBox(height: 10),
            _toggleTile(
              context,
              Icons.local_offer,
              "Promotional Offers",
              "Deals and cashback offers",
              _promoOffers,
              (v) => setState(() => _promoOffers = v),
              isDark,
            ),
            const SizedBox(height: 10),
            _toggleTile(
              context,
              Icons.security,
              "Security Alerts",
              "Login & password change alerts",
              _securityAlerts,
              (v) => setState(() => _securityAlerts = v),
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.06),
        ),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
