import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/theme_manager.dart';
import '../utils/firestore_service.dart';
import '../models/transaction.dart';

class OffersRewardsScreen extends StatefulWidget {
  const OffersRewardsScreen({super.key});

  @override
  State<OffersRewardsScreen> createState() => _OffersRewardsScreenState();
}

class _OffersRewardsScreenState extends State<OffersRewardsScreen> {
  bool _applyRewardsNext = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          'Rewards & Cashback',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<Map<String, double>>(
        stream: FirestoreService().rewardsStream(uid),
        builder: (context, rewardsSnap) {
          final cashbackBalance = rewardsSnap.data?['cashbackBalance'] ?? 0.0;
          final totalEarned = rewardsSnap.data?['totalEarned'] ?? 0.0;

          return StreamBuilder<List<Transaction>>(
            stream: FirestoreService().transactionsStream(uid),
            builder: (context, txSnap) {
              final allTx = txSnap.data ?? [];
              // Show recent debit transactions (these earned cashback)
              final cashbackHistory = allTx
                  .where((t) => !t.isPositive && t.amount.abs() >= 10)
                  .take(30)
                  .toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Hero balance card ─────────────────────────────────
                  _heroCard(cashbackBalance, totalEarned, isDark),
                  const SizedBox(height: 20),

                  // ── Apply rewards toggle ──────────────────────────────
                  _applyToggleCard(isDark),
                  const SizedBox(height: 20),

                  // ── How it works ──────────────────────────────────────
                  _howItWorksCard(isDark),
                  const SizedBox(height: 20),

                  // ── History ───────────────────────────────────────────
                  _sectionLabel('CASHBACK HISTORY'),
                  const SizedBox(height: 8),
                  if (cashbackHistory.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No transactions yet.\nStart paying to earn cashback!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...cashbackHistory.map(
                      (tx) => _cashbackHistoryTile(tx, isDark),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Hero card ─────────────────────────────────────────────────────────────
  Widget _heroCard(double balance, double totalEarned, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF7B2FBE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                'Your Cashback',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Available Balance',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const Divider(color: Colors.white24, height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statCol('₹${totalEarned.toStringAsFixed(2)}', 'Total Earned'),
              _statCol(
                '₹${(totalEarned - balance).toStringAsFixed(2)}',
                'Redeemed',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCol(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }

  // ── Apply rewards toggle ──────────────────────────────────────────────────
  Widget _applyToggleCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _applyRewardsNext
              ? AppColors.success.withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      child: SwitchListTile(
        value: _applyRewardsNext,
        onChanged: (val) => setState(() => _applyRewardsNext = val),
        activeColor: AppColors.success,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.redeem_rounded,
            color: AppColors.success,
            size: 22,
          ),
        ),
        title: Text(
          'Apply Rewards Next Payment',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          _applyRewardsNext
              ? 'Rewards will be applied on your next transaction'
              : 'Toggle to use your cashback balance',
          style: GoogleFonts.spaceGrotesk(fontSize: 11, color: Colors.grey),
        ),
      ),
    );
  }

  // ── How it works ──────────────────────────────────────────────────────────
  Widget _howItWorksCard(bool isDark) {
    final steps = [
      (
        Icons.payment_rounded,
        'Pay with Wallet or Bank',
        'Every payment earns cashback',
      ),
      (
        Icons.percent_rounded,
        'Earn 1% Cashback',
        'Up to ₹50 per transaction, min ₹10',
      ),
      (Icons.redeem_rounded, 'Redeem Instantly', 'Apply to your next payment'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How It Works',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          ...steps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(s.$1, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.$2,
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          s.$3,
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
            ),
          ),
        ],
      ),
    );
  }

  // ── Cashback history tile ─────────────────────────────────────────────────
  Widget _cashbackHistoryTile(Transaction tx, bool isDark) {
    final cashback = (tx.amount.abs() * 0.01).clamp(0.0, 50.0);
    final fmt = DateFormat('dd MMM, hh:mm a');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tx.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tx.icon, color: tx.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  fmt.format(tx.date),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-₹${tx.amount.abs().toStringAsFixed(0)}',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.error,
                ),
              ),
              Text(
                '+₹${cashback.toStringAsFixed(2)} CB',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.success,
                ),
              ),
            ],
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
        color: AppColors.primary.withOpacity(0.7),
        letterSpacing: 1.2,
      ),
    );
  }
}
