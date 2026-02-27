import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';
import '../utils/firestore_service.dart';
import '../models/bank_account.dart';
import '../utils/auth_manager.dart';

class PaymentConfirmationResult {
  final BankAccount bankAccount;
  final bool useInstantPay;
  final bool useBiometric;
  final bool applyRewards;

  PaymentConfirmationResult({
    required this.bankAccount,
    this.useInstantPay = false,
    this.useBiometric = false,
    this.applyRewards = false,
  });
}

class PaymentConfirmationSheet extends StatefulWidget {
  final String uid;
  final double amount;

  const PaymentConfirmationSheet({
    super.key,
    required this.uid,
    required this.amount,
  });

  static Future<PaymentConfirmationResult?> show(
    BuildContext context,
    String uid,
    double amount,
  ) async {
    return showModalBottomSheet<PaymentConfirmationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentConfirmationSheet(uid: uid, amount: amount),
    );
  }

  @override
  State<PaymentConfirmationSheet> createState() =>
      _PaymentConfirmationSheetState();
}

class _PaymentConfirmationSheetState extends State<PaymentConfirmationSheet> {
  BankAccount? _selectedBank;
  bool _applyRewards = false;
  bool _useInstantPay = false;
  bool _useBiometric = false;

  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _useInstantPay =
        false; // Always default to OFF for per-transaction manual choice
    _useBiometric = _auth.isBiometricEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
          const SizedBox(height: 24),

          Text(
            "Confirm Payment",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Total Amount: ₹${widget.amount.toStringAsFixed(2)}",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(height: 40),

          // Rewards Section
          _buildSectionHeader("Rewards"),
          SwitchListTile(
            value: _applyRewards,
            onChanged: (val) => setState(() => _applyRewards = val),
            title: Text(
              "Apply Available Rewards",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            secondary: const Icon(Icons.card_giftcard, color: Colors.orange),
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
          ),
          const SizedBox(height: 12),

          // Bank Selection
          _buildSectionHeader("Select Bank Account"),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: StreamBuilder<List<BankAccount>>(
              stream: FirestoreService().linkedBanksStream(widget.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final banks = snapshot.data!;
                if (banks.isEmpty) return const Text("No linked banks.");

                // Default selection
                _selectedBank ??= banks.firstWhere(
                  (b) => b.isPrimary,
                  orElse: () => banks.first,
                );

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: banks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, index) {
                    final bank = banks[index];
                    final isSelected = _selectedBank?.id == bank.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedBank = bank),
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : (isDark
                                    ? AppColors.darkCard
                                    : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              bank.icon,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bank.bankName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Authentication Options
          _buildSectionHeader("Payment Method"),
          Row(
            children: [
              Expanded(
                child: _buildAuthOption(
                  icon: Icons.flash_on,
                  label: "Instant Pay",
                  subtitle: "Skip PIN (limit ₹2k)",
                  value: _useInstantPay,
                  onChanged: (val) => setState(() {
                    _useInstantPay = val;
                    if (val) _useBiometric = false;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAuthOption(
                  icon: Icons.fingerprint,
                  label: "Biometric",
                  subtitle: "Fast & Secure",
                  value: _useBiometric,
                  onChanged: (val) => setState(() {
                    _useBiometric = val;
                    if (val) _useInstantPay = false;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () {
                if (_selectedBank == null) return;

                // Limit Check for Instant Pay
                if (_useInstantPay) {
                  if (!_auth.canProcessInstantPay(widget.amount)) {
                    // Fail high level as requested
                    Navigator.pop(
                      context,
                      null,
                    ); // Returning null to indicate failure/cancellation due to limits
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Instant Pay limit exceeded! Transaction failed.",
                        ),
                      ),
                    );
                    return;
                  }
                }

                Navigator.pop(
                  context,
                  PaymentConfirmationResult(
                    bankAccount: _selectedBank!,
                    useInstantPay: _useInstantPay,
                    useBiometric: _useBiometric,
                    applyRewards: _applyRewards,
                  ),
                );
              },
              child: Text(
                "Pay Now",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAuthOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: value
              ? AppColors.primary.withOpacity(0.1)
              : (isDark ? AppColors.darkCard : Colors.grey[50]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: value ? AppColors.primary : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.7,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
