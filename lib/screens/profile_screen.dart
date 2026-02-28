import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme_manager.dart';
import '../utils/firebase_auth_service.dart';
import 'personal_info_screen.dart';
import 'bank_accounts_screen.dart';
import 'notifications_settings_screen.dart';
import 'privacy_security_screen.dart';
import 'theme_selection_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'autopay_management_screen.dart';
import '../widgets/interactive_scale.dart';
import '../utils/locale_manager.dart';
import '../utils/localization_helper.dart';

// Used for direct navigation (Push)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          L10n.s('my_profile'),
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
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
                L10n.s('my_profile'),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Profile Card
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.userChanges(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                final name =
                    user?.displayName ??
                    user?.email?.split('@').first ??
                    'User';
                final email = user?.email ?? '';
                final photoUrl = user?.photoURL;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.headerGradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: photoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  width: 56,
                                  height: 56,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.person_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                ),
                              )
                            : const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              email,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "⭐ Gold",
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFF3D2700),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // == Payment Settings ==
            _sectionHeader(L10n.s("payment_settings")),
            const SizedBox(height: 8),
            _settingsTile(
              context,
              Icons.autorenew_rounded,
              L10n.s("autopay_management"),
              const Color(0xFF00D4FF), // electric cyan
              const AutopayManagementScreen(),
              isDark,
            ),
            _settingsTile(
              context,
              Icons.account_balance_rounded,
              L10n.s("bank_accounts"),
              const Color(0xFFFFD166), // gold
              const BankAccountsScreen(),
              isDark,
            ),
            _settingsTile(
              context,
              Icons.person_pin_rounded,
              L10n.s("personal_info"),
              const Color(0xFF00E5A0), // teal neon
              const PersonalInfoScreen(),
              isDark,
            ),

            const SizedBox(height: 20),

            // == App Settings ==
            _sectionHeader(L10n.s("app_settings")),
            const SizedBox(height: 8),
            _settingsTile(
              context,
              Icons.notifications_rounded,
              L10n.s("notifications"),
              const Color(0xFFFF8C42), // amber
              const NotificationsSettingsScreen(),
              isDark,
            ),
            _settingsTile(
              context,
              Icons.shield_rounded,
              L10n.s("privacy_security"),
              const Color(0xFFFF4F6D), // coral
              const PrivacySecurityScreen(),
              isDark,
            ),
            _settingsTile(
              context,
              Icons.palette_rounded,
              L10n.s("theme"),
              const Color(0xFF7B2FBE), // nebula purple
              const ThemeSelectionScreen(),
              isDark,
            ),
            _languageTile(context, isDark),

            const SizedBox(height: 20),

            // == More ==
            _sectionHeader(L10n.s("more")),
            const SizedBox(height: 8),
            _settingsTile(
              context,
              Icons.headset_mic_rounded,
              L10n.s("help_support"),
              const Color(0xFF6EE9FF), // light cyan
              const HelpSupportScreen(),
              isDark,
            ),
            _settingsTile(
              context,
              Icons.info_rounded,
              L10n.s("about"),
              const Color(0xFF8B6F4E), // warm brown
              const AboutScreen(),
              isDark,
            ),

            const SizedBox(height: 16),

            // Logout
            InteractiveScale(
              onTap: () async {
                await FirebaseAuthService().signOut();
                if (context.mounted) {
                  // Ensure any pushed routes are cleared so the LoginScreen is visible
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.error.withOpacity(0.12),
                      AppColors.error.withOpacity(0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withOpacity(0.25)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    L10n.s("logout"),
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary.withOpacity(0.7),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context,
    IconData icon,
    String title,
    Color iconColor,
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
            color: isDark
                ? AppColors.darkBorder.withOpacity(0.4)
                : Colors.black.withOpacity(0.04),
          ),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isDark ? const Color(0xFF4A5580) : Colors.grey[400],
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
            color: isDark
                ? AppColors.darkBorder.withOpacity(0.4)
                : Colors.black.withOpacity(0.04),
          ),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7B2FBE).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.translate_rounded,
              color: Color(0xFF7B2FBE),
              size: 20,
            ),
          ),
          title: Text(
            L10n.s("language"),
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocaleManager().languageName,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? const Color(0xFF4A5580) : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, bool isDark) {
    final languages = [
      {"name": "English", "code": "en"},
      {"name": "\u0939\u093f\u0902\u0926\u0940", "code": "hi"},
      {"name": "\u0c24\u0c46\u0c32\u0c41\u0c17\u0c41", "code": "te"},
      {"name": "\u0ba4\u0bae\u0bbf\u0bb4\u0bcd", "code": "ta"},
      {"name": "\u0c95\u0ca8\u0ccd\u0ca8\u0ca1", "code": "kn"},
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
                L10n.s("select_language"),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              ...languages.map((lang) {
                final isSelected =
                    LocaleManager().locale.value.languageCode == lang["code"];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    lang["name"] as String,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(ctx).textTheme.bodyLarge?.color,
                    ),
                  ),
                  trailing: isSelected
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
                  onTap: () async {
                    await LocaleManager().setLocale(lang["code"] as String);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "${L10n.s("language_set_to")} ${lang["name"]}",
                          ),
                        ),
                      );
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
