import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "About",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // App Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "Digital Wallet",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              "Version 1.0.0",
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Up to date",
                style: GoogleFonts.poppins(
                  color: AppColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Info cards
            _infoCard(
              context,
              Icons.developer_mode,
              "Developer",
              "Vamsidhar — SEM-6 MAD Project",
              isDark,
            ),
            const SizedBox(height: 10),
            _infoCard(
              context,
              Icons.school_outlined,
              "Institution",
              "Amrita Vishwa Vidyapeetham",
              isDark,
            ),
            const SizedBox(height: 10),
            _infoCard(
              context,
              Icons.build_outlined,
              "Built With",
              "Flutter & Dart",
              isDark,
            ),
            const SizedBox(height: 10),
            _infoCard(
              context,
              Icons.design_services_outlined,
              "Design Inspired By",
              "PhonePe, Google Pay",
              isDark,
            ),

            const SizedBox(height: 28),

            // Links
            _linkTile(
              context,
              Icons.description_outlined,
              "Terms of Service",
              isDark,
            ),
            _linkTile(
              context,
              Icons.privacy_tip_outlined,
              "Privacy Policy",
              isDark,
            ),
            _linkTile(
              context,
              Icons.open_in_new,
              "Open Source Licenses",
              isDark,
            ),

            const SizedBox(height: 24),

            Text(
              "Made with ❤️ in Flutter",
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              "© 2026 Digital Wallet",
              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 11),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkTile(
    BuildContext context,
    IconData icon,
    String title,
    bool isDark,
  ) {
    return Container(
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
        leading: Icon(icon, color: AppColors.primary, size: 20),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("$title — coming soon!")));
        },
      ),
    );
  }
}
