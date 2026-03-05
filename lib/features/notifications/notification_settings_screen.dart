import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'notification_controller.dart';
import '../../utils/theme_manager.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<NotificationController>(
        builder: (context, controller, child) {
          if (controller.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final prefs = controller.prefs;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _buildSectionHeader('General'),
              _buildSettingTile(
                icon: Icons.notifications_active_outlined,
                title: 'Push Notifications',
                description: 'Master toggle for all push notifications',
                value: prefs.pushNotifications,
                onChanged: (val) =>
                    controller.togglePreference('pushNotifications', val),
                isMaster: true,
              ),
              const SizedBox(height: 24),

              Opacity(
                opacity: prefs.pushNotifications ? 1.0 : 0.5,
                child: AbsorbPointer(
                  absorbing: !prefs.pushNotifications,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Transactions'),
                      _buildSettingTile(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Transaction Success',
                        description: 'Notify when payment succeeds',
                        value: prefs.transactionSuccess,
                        onChanged: (val) => controller.togglePreference(
                          'transactionSuccess',
                          val,
                        ),
                      ),
                      _buildSettingTile(
                        icon: Icons.error_outline_rounded,
                        title: 'Transaction Failed',
                        description: 'Notify when payment fails',
                        value: prefs.transactionFailed,
                        onChanged: (val) => controller.togglePreference(
                          'transactionFailed',
                          val,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionHeader('Rewards'),
                      _buildSettingTile(
                        icon: Icons.card_giftcard_rounded,
                        title: 'Cashback Earned',
                        description: 'Notify when cashback is credited',
                        value: prefs.cashbackEarned,
                        onChanged: (val) =>
                            controller.togglePreference('cashbackEarned', val),
                      ),
                      _buildSettingTile(
                        icon: Icons.star_outline_rounded,
                        title: 'Rewards & Offers',
                        description: 'Notify about reward programs',
                        value: prefs.rewardsOffers,
                        onChanged: (val) =>
                            controller.togglePreference('rewardsOffers', val),
                      ),
                      _buildSettingTile(
                        icon: Icons.local_offer_outlined,
                        title: 'Promotional Offers',
                        description: 'Notify marketing offers',
                        value: prefs.promotionalOffers,
                        onChanged: (val) => controller.togglePreference(
                          'promotionalOffers',
                          val,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionHeader('Security'),
                      _buildSettingTile(
                        icon: Icons.security_rounded,
                        title: 'Security Alerts',
                        description: 'Notify login or PIN changes',
                        value: prefs.securityAlerts,
                        onChanged: (val) =>
                            controller.togglePreference('securityAlerts', val),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isMaster = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isMaster
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMaster
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.darkBorder.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMaster
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.darkSurface.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isMaster ? AppColors.primary : Colors.white70,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.white54),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
