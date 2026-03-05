import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme_manager.dart';
import '../utils/firestore_service.dart';
import '../models/bank_account.dart';
import 'setup_screen.dart';
import '../utils/auth_manager.dart';
import 'pin_gate_screen.dart';
import 'pin_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Check Balance",
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            if (user != null)
              StreamBuilder<List<BankAccount>>(
                stream: FirestoreService().linkedBanksStream(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }

                  final banks = snapshot.data ?? [];

                  if (banks.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 24,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            color: Colors.white24,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No bank accounts linked",
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: banks.map((bank) {
                      return _listTile(
                        context,
                        title: bank.bankName,
                        subtitle:
                            "Bank Account (..${bank.accountNumber.substring(bank.accountNumber.length > 4 ? bank.accountNumber.length - 4 : 0)})",
                        leading: _bankLogo(bank.icon, bank.color),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () => _handleBankTap(
                          context,
                          bank,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            _listTile(
              context,
              title: "Instant Pay",
              subtitle:
                  "Pin-less payments up to ₹${AuthService().instantLimit.toStringAsFixed(0)}",
              leading: const Icon(Icons.bolt, color: Colors.white, size: 32),
              trailing: TextButton(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final hasPin = await AuthService().hasDigiPin();
                  if (!mounted) return;
                  if (hasPin) {
                    await nav.push(
                      MaterialPageRoute(
                        builder: (_) => PinGateScreen(
                          title: 'Verify Digi PIN',
                          subtitle: 'Enter your PIN to access Setup',
                          child: const SetupScreen(),
                        ),
                      ),
                    );
                  } else {
                    await nav.push(
                      MaterialPageRoute(builder: (_) => const SetupScreen()),
                    );
                  }
                  if (mounted) setState(() {});
                },
                child: Text(
                  AuthService().isInstantPayEnabled ? "Enabled" : "Try Now",
                  style: GoogleFonts.spaceGrotesk(
                    color: AuthService().isInstantPayEnabled
                        ? AppColors.primary
                        : Colors.deepPurpleAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (user != null)
              StreamBuilder<Map<String, double>>(
                stream: FirestoreService().rewardsStream(user.uid),
                builder: (context, snapshot) {
                  final balance = snapshot.data?['cashbackBalance'] ?? 0.0;
                  return FutureBuilder<bool>(
                    future: FirestoreService().isExpensyaActivated(user.uid),
                    builder: (context, activatedSnap) {
                      final isActivated = activatedSnap.data ?? false;
                      return _listTile(
                        context,
                        title: "Expensya Wallet",
                        subtitle: isActivated
                            ? "Balance: ₹${balance.toStringAsFixed(2)}"
                            : "Activate to earn cashback rewards",
                        leading: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            if (isActivated) return;
                            final messenger = ScaffoldMessenger.of(context);
                            await FirestoreService().setExpensyaActivated(
                              user.uid,
                              true,
                            );
                            if (!mounted) return;
                            setState(() {});
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Expensya Wallet Activated! 🎉'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          child: Text(
                            isActivated ? "Active ✓" : "Activate",
                            style: GoogleFonts.spaceGrotesk(
                              color: isActivated
                                  ? AppColors.primary
                                  : Colors.deepPurpleAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBankTap(BuildContext context, BankAccount bank) async {
    if (bank.pinHash.isEmpty) {
      // No PIN set for this bank — show balance directly
      _showBalanceDialog(context, bank.bankName, "₹${bank.balance.toStringAsFixed(2)}");
      return;
    }

    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PinScreen(
          mode: PinMode.verifyBank,
          expectedBankPinHash: bank.pinHash,
        ),
      ),
    );

    if (verified == true && context.mounted) {
      _showBalanceDialog(context, bank.bankName, "₹${bank.balance.toStringAsFixed(2)}");
    }
  }

  void _showBalanceDialog(
    BuildContext context,
    String bankName,
    String balance,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              bankName,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Account Balance",
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              balance,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "DONE",
                  style: GoogleFonts.spaceGrotesk(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: leading,
      title: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.spaceGrotesk(color: Colors.grey, fontSize: 12),
      ),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _bankLogo(IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(child: Icon(icon, color: color, size: 28)),
    );
  }
}
