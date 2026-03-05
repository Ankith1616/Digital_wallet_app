import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme_manager.dart';
import '../widgets/payment_confirmation_sheet.dart';
import '../widgets/payment_result_dialog.dart';
import '../utils/auth_manager.dart';
import '../utils/firestore_service.dart';
import 'pin_screen.dart';

class DigiPremiumScreen extends StatelessWidget {
  const DigiPremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1A1A3E),
                      Color(0xFF6C3FE0),
                      Color(0xFFB060FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Background glow
                    Positioned(
                      right: -40,
                      top: -40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          // Crown icon
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Digi Premium',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your exclusive financial superpower',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pricing card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C3FE0), Color(0xFFB060FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C3FE0).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹99 / month',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'or ₹799/year — Save 33%',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _showPlanSelection(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Upgrade',
                              style: GoogleFonts.spaceGrotesk(
                                color: const Color(0xFF6C3FE0),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'Premium Benefits',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _benefitCard(
                    icon: Icons.trending_up_rounded,
                    iconColor: const Color(0xFF6C3FE0),
                    title: 'Higher Transaction Limits',
                    subtitle: 'Send up to ₹5,00,000 per day',
                  ),
                  _benefitCard(
                    icon: Icons.card_giftcard_rounded,
                    iconColor: Colors.amber.shade700,
                    title: 'Exclusive Cashback',
                    subtitle:
                        'Earn 3% cashback on all payments (up to ₹500/tx)',
                  ),
                  _benefitCard(
                    icon: Icons.support_agent_rounded,
                    iconColor: Colors.green.shade600,
                    title: 'Priority Customer Support',
                    subtitle: '24×7 dedicated support line',
                  ),
                  _benefitCard(
                    icon: Icons.shield_rounded,
                    iconColor: Colors.blue.shade600,
                    title: 'Advanced Security Shield',
                    subtitle: 'Real-time fraud alerts & insurance cover',
                  ),
                  _benefitCard(
                    icon: Icons.auto_awesome_rounded,
                    iconColor: Colors.pink.shade400,
                    title: 'Smart Insights Pro',
                    subtitle: 'AI-powered budgeting and spending analytics',
                  ),
                  _benefitCard(
                    icon: Icons.receipt_long_rounded,
                    iconColor: Colors.teal.shade500,
                    title: 'Unlimited Transactions',
                    subtitle: 'No monthly transaction count cap',
                  ),

                  const SizedBox(height: 28),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
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
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlanSelection(BuildContext context) {
    showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose a Plan',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _planTile(
                context: ctx,
                title: 'Monthly Plan',
                price: '₹99 / month',
                amount: 99.0,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _planTile(
                context: ctx,
                title: 'Yearly Plan',
                price: '₹799 / year (Save 33%)',
                amount: 799.0,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    ).then((selectedAmount) {
      if (selectedAmount != null && context.mounted) {
        _processPremiumPayment(context, selectedAmount);
      }
    });
  }

  Widget _planTile({
    required BuildContext context,
    required String title,
    required String price,
    required double amount,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, amount); // close bottom sheet and return amount
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6C3FE0).withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF6C3FE0)),
          ],
        ),
      ),
    );
  }

  Future<void> _processPremiumPayment(
    BuildContext context,
    double amount,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmation = await PaymentConfirmationSheet.show(
      context,
      user.uid,
      amount,
    );
    if (confirmation == null) return;

    if (!context.mounted) return;

    final selectedBank = confirmation.bankAccount;
    final auth = AuthService();
    bool verified = false;

    if (confirmation.useInstantPay) {
      if (auth.canProcessInstantPay(amount)) {
        verified = true;
        await auth.recordInstantPayUsage(amount);
      } else {
        await PaymentResultDialog.show(
          context,
          success: false,
          title: 'Payment Failed',
          subtitle: 'Instant Pay limit exceeded.',
          amount: amount.toStringAsFixed(2),
          recipient: 'Digi Premium',
        );
        return;
      }
    } else if (confirmation.useBiometric) {
      verified = await auth.authenticateBiometrics();
      if (verified) await auth.recordBiometricUsage(amount);
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PinScreen(
            mode: PinMode.verifyBank,
            expectedBankPinHash: selectedBank.pinHash,
          ),
        ),
      );
      verified = result == true;
    }

    if (!verified) return;
    if (!context.mounted) return;

    if (selectedBank.balance < amount) {
      await PaymentResultDialog.show(
        context,
        success: false,
        title: 'Insufficient Balance',
        subtitle: 'Please choose another bank account.',
        amount: amount.toStringAsFixed(2),
        recipient: 'Digi Premium',
      );
      return;
    }

    // Deduct
    await FirestoreService().updateBankAccountBalance(
      user.uid,
      selectedBank.id,
      -amount,
    );

    // Save Premium state locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', true);

    if (!context.mounted) return;

    await PaymentResultDialog.show(
      context,
      success: true,
      title: 'Premium Activated!',
      subtitle: 'Welcome to Digi Premium.',
      amount: amount.toStringAsFixed(2),
      recipient: 'Digi Premium',
    );

    if (!context.mounted) return;
    Navigator.pop(context, true); // return to profile, mark as true
  }
}
