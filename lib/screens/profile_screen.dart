import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';
import 'personal_info_screen.dart';
import 'bank_accounts_screen.dart';
import 'notifications_settings_screen.dart';
import 'privacy_security_screen.dart';
import 'wallet_screen.dart';
import 'theme_selection_screen.dart';
import 'help_support_screen.dart';

import 'about_screen.dart';
import 'login_screen.dart';
import '../widgets/interactive_scale.dart';

// Used for direct navigation (Push)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Money",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: const ProfileTab(isNested: false),
    );
  }
}

// Used in Bottom Navigation Tab
class ProfileTab extends StatelessWidget {
  final bool isNested;
  const ProfileTab({super.key, this.isNested = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNested) ...[
              Text(
                "My Money",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Vamsidhar",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "UPI: vamsidhar@upi",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Gold ⭐",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // == Payment Settings ==
            _sectionHeader("Payment Settings"),
            const SizedBox(height: 8),
            _settingsTile(
              context,
              Icons.credit_card,
              "My Cards",
              const WalletScreen(),
              isDark,
            ),
            _settingsTile(
              context,
              Icons.account_balance,
              "Bank Accounts",
              const BankAccountsScreen(),
              isDark,
            ),
            _settingsTile(
              context,
              Icons.person_outline,
              "Personal Info",
              const PersonalInfoScreen(),
              isDark,
            ),

            const SizedBox(height: 20),

            // == App Settings ==
            _sectionHeader("App Settings"),
            const SizedBox(height: 8),
            _settingsTile(
              context,
              Icons.notifications_outlined,
              "Notifications",
              const NotificationsSettingsScreen(),
              isDark,
            ),
            _settingsTile(
              context,
              Icons.lock_outline,
              "Privacy & Security",
              const PrivacySecurityScreen(),
              isDark,
            ),
            _settingsTile(
              context,
              Icons.dark_mode_outlined,
              "Theme",
              const ThemeSelectionScreen(),
              isDark,
            ),
            _languageTile(context, isDark),

            const SizedBox(height: 20),

            // == More ==
            _sectionHeader("More"),
            const SizedBox(height: 8),
            _settingsTile(
              context,
              Icons.help_outline,
              "Help & Support",
              const HelpSupportScreen(),
              isDark,
            ),
            _settingsTile(
              context,
              Icons.info_outline,
              "About",
              const AboutScreen(),
              isDark,
            ),

            const SizedBox(height: 16),

            // Logout
            InteractiveScale(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: AppColors.error,
                    size: 22,
                  ),
                  title: Text(
                    "Logout",
                    style: GoogleFonts.poppins(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: isNested ? 80 : 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context,
    IconData icon,
    String title,
    Widget? dest,
    bool isDark,
  ) {
    return InteractiveScale(
      onTap: () {
        if (dest != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => dest));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Feature coming soon!")));
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.06),
          ),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            size: 20,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _languageTile(BuildContext context, bool isDark) {
    return InteractiveScale(
      onTap: () => _showLanguageDialog(context, isDark),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.06),
          ),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.language,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            "Language",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "English",
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, bool isDark) {
    final languages = [
      {"name": "English", "code": "en", "selected": true},
      {
        "name": "\u0939\u093f\u0902\u0926\u0940",
        "code": "hi",
        "selected": false,
      },
      {
        "name": "\u0c24\u0c46\u0c32\u0c41\u0c17\u0c41",
        "code": "te",
        "selected": false,
      },
      {
        "name": "\u0ba4\u0bae\u0bbf\u0bb4\u0bcd",
        "code": "ta",
        "selected": false,
      },
      {
        "name": "\u0c95\u0ca8\u0ccd\u0ca8\u0ca1",
        "code": "kn",
        "selected": false,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Select Language",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              ...languages.map(
                (lang) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    lang["name"] as String,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(ctx).textTheme.bodyLarge?.color,
                    ),
                  ),
                  trailing: lang["selected"] as bool
                      ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Language set to ${lang["name"]}"),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
