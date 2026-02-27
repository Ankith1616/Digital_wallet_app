import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Help & Support",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Support card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.headset_mic,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Need help?",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "Our support team is available 24/7",
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Chat",
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              "FREQUENTLY ASKED QUESTIONS",
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            _faqTile(
              context,
              "How do I send money?",
              "Go to the Home tab and tap 'To Mobile' or 'To Bank' under Money Transfer. Enter the recipient's details, amount, and confirm with your UPI PIN.",
              isDark,
            ),
            _faqTile(
              context,
              "How do I scan and pay?",
              "Tap the Scan button in the center of the bottom navigation bar. Point your camera at a QR code. Enter the amount and confirm the payment.",
              isDark,
            ),
            _faqTile(
              context,
              "How to add a bank account?",
              "Go to My Money → Bank Accounts → Link New Bank Account. Enter your bank details and verify with OTP.",
              isDark,
            ),
            _faqTile(
              context,
              "How to change my UPI PIN?",
              "Navigate to My Money → Privacy & Security → Change UPI PIN. Enter your current PIN and set a new one.",
              isDark,
            ),
            _faqTile(
              context,
              "Is my data secure?",
              "Yes! We use 256-bit bank-grade encryption to protect all your data. You can also enable biometric login and two-factor authentication for additional security.",
              isDark,
            ),
            _faqTile(
              context,
              "How do I get cashback?",
              "Check the Offers & Rewards section on the Home tab. Complete eligible transactions to earn cashback and rewards.",
              isDark,
            ),
            _faqTile(
              context,
              "How to check transaction history?",
              "Tap the History tab in the bottom navigation, or tap 'View All' next to Recent Transactions on the Home screen.",
              isDark,
            ),

            const SizedBox(height: 24),

            // Contact options
            Text(
              "OTHER WAYS TO REACH US",
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            _contactTile(
              context,
              Icons.email_outlined,
              "Email Us",
              "support@digitalwallet.com",
              isDark,
            ),
            _contactTile(
              context,
              Icons.phone_outlined,
              "Call Us",
              "1800-123-4567 (Toll Free)",
              isDark,
            ),
            _contactTile(
              context,
              Icons.language,
              "Visit Website",
              "www.digitalwallet.com/help",
              isDark,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _faqTile(
    BuildContext context,
    String question,
    String answer,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.06),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(
          question,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: Colors.grey,
        children: [
          Text(
            answer,
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.06),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
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
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Opening $title...")));
        },
      ),
    );
  }
}

