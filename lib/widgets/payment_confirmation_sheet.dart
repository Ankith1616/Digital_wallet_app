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
  final Map<String, dynamic>? appliedCoupon;

  PaymentConfirmationResult({
    required this.bankAccount,
    this.useInstantPay = false,
    this.useBiometric = false,
    this.applyRewards = false,
    this.appliedCoupon,
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
  Map<String, dynamic>? _selectedCoupon;

  final List<Map<String, dynamic>> _mockCoupons = [
    {
      'code': 'DIGIPE20',
      'discount': 20.0,
      'type': 'flat',
      'description': 'Flat ₹20 off on your first transaction',
    },
    {
      'code': 'SAVE10',
      'discount': 0.1,
      'type': 'percent',
      'description': '10% off up to ₹50',
    },
  ];

  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _useInstantPay = false; // Default choice
    _useBiometric = _auth.isBiometricEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
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

            // Rewards & Coupons Section
            StreamBuilder<Map<String, double>>(
              stream: FirestoreService().rewardsStream(widget.uid),
              builder: (context, snapshot) {
                final balance = snapshot.data?['cashbackBalance'] ?? 0.0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Coupons & Cashback"),
                    SwitchListTile(
                      value: _applyRewards,
                      onChanged: balance > 0
                          ? (val) => setState(() => _applyRewards = val)
                          : null,
                      title: Text(
                        "Apply Available Cashback",
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      subtitle: Text(
                        balance > 0
                            ? "Available Balance: ₹${balance.toStringAsFixed(2)}"
                            : "No cashback balance available",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: balance > 0 ? AppColors.success : Colors.grey,
                        ),
                      ),
                      secondary: Icon(
                        Icons.account_balance_wallet,
                        color: balance > 0 ? Colors.orange : Colors.grey,
                      ),
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: AppColors.primary,
                    ),

                    // Coupon Section
                    const SizedBox(height: 12),
                    _buildSectionHeader("Select Coupon"),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _mockCoupons.length,
                        separatorBuilder: (ctx, i) => const SizedBox(width: 10),
                        itemBuilder: (ctx, i) {
                          final coupon = _mockCoupons[i];
                          final isSelected =
                              _selectedCoupon?['code'] == coupon['code'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedCoupon = null;
                                } else {
                                  _selectedCoupon = coupon;
                                }
                              });
                            },
                            child: Container(
                              width: 140,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : (isDark
                                          ? AppColors.darkCard
                                          : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.success
                                      : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    coupon['code'],
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isSelected
                                          ? AppColors.success
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black),
                                    ),
                                  ),
                                  Text(
                                    coupon['type'] == 'flat'
                                        ? "₹${coupon['discount']} OFF"
                                        : "${(coupon['discount'] * 100).toInt()}% OFF",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Calculation Recap
                    _buildCalculationRecap(balance),

                    const Divider(height: 40),
                  ],
                );
              },
            ),

            // Bank Selection
            _buildSectionHeader("Select Bank Account"),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: StreamBuilder<List<BankAccount>>(
                stream: FirestoreService().linkedBanksStream(widget.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final banks = snapshot.data!;
                  if (banks.isEmpty) return const Text("No linked banks.");

                  _selectedBank ??= banks.firstWhere(
                    (b) => b.isPrimary,
                    orElse: () => banks.first,
                  );

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: banks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
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
                                ? AppColors.primary.withValues(alpha: 0.1)
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

                  if (_useInstantPay) {
                    if (!_auth.canProcessInstantPay(widget.amount)) {
                      Navigator.pop(context, null);
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

                  if (_useBiometric) {
                    if (!_auth.canProcessBiometricPay(widget.amount)) {
                      Navigator.pop(context, null);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Biometric daily limit (₹5,000) exceeded! Transaction failed.",
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
                      appliedCoupon: _selectedCoupon,
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
      ),
    );
  }

  Widget _buildCalculationRecap(double rewardsBalance) {
    double couponDiscount = 0.0;
    if (_selectedCoupon != null) {
      if (_selectedCoupon!['type'] == 'flat') {
        couponDiscount = _selectedCoupon!['discount'];
      } else {
        couponDiscount = widget.amount * _selectedCoupon!['discount'];
        if (couponDiscount > 50) couponDiscount = 50.0;
      }
    }

    final amountAfterCoupon = (widget.amount - couponDiscount).clamp(
      0.0,
      widget.amount,
    );
    final cashbackApplied = _applyRewards
        ? (rewardsBalance > amountAfterCoupon
              ? amountAfterCoupon
              : rewardsBalance)
        : 0.0;
    final finalAmount = (amountAfterCoupon - cashbackApplied).clamp(
      0.0,
      widget.amount,
    );

    return Column(
      children: [
        if (couponDiscount > 0)
          _buildRecapRow(
            "Coupon Discount",
            "-₹${couponDiscount.toStringAsFixed(2)}",
            AppColors.success,
          ),
        if (cashbackApplied > 0)
          _buildRecapRow(
            "Cashback Applied",
            "-₹${cashbackApplied.toStringAsFixed(2)}",
            AppColors.success,
          ),
        if (couponDiscount > 0 || cashbackApplied > 0) ...[
          const SizedBox(height: 8),
          _buildRecapRow(
            "Final Price",
            "₹${finalAmount.toStringAsFixed(2)}",
            AppColors.primary,
            isBold: true,
          ),
        ],
      ],
    );
  }

  Widget _buildRecapRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isBold ? 15 : 13,
              fontWeight: FontWeight.bold,
              color: color,
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
              ? AppColors.primary.withValues(alpha: 0.1)
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
                activeTrackColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
