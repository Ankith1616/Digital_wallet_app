import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme_manager.dart';
import '../../utils/transaction_manager.dart';
import '../../models/transaction.dart';
import '../../utils/auth_manager.dart';
import '../../utils/rewards_service.dart';
import '../pin_screen.dart';
import '../../widgets/payment_result_dialog.dart';
import '../../widgets/payment_confirmation_sheet.dart';
import '../../utils/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Reusable service page template for bill payment / recharge / booking flows.
class ServicePageTemplate extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color themeColor;
  final List<ServiceField> fields;
  final String buttonLabel;
  final List<String>? quickAmounts;
  final List<ServiceProvider>? providers;

  const ServicePageTemplate({
    super.key,
    required this.title,
    required this.icon,
    required this.themeColor,
    required this.fields,
    this.buttonLabel = 'Proceed to Pay',
    this.quickAmounts,
    this.providers,
  });

  @override
  State<ServicePageTemplate> createState() => _ServicePageTemplateState();
}

class _ServicePageTemplateState extends State<ServicePageTemplate> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedProviderIndex;
  String? _selectedQuickAmount;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      _controllers[field.label] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-fill amount from quick select
    if (_selectedQuickAmount != null) {
      final amountKey = widget.fields
          .firstWhere(
            (f) => f.label.toLowerCase().contains('amount'),
            orElse: () => widget.fields.last,
          )
          .label;
      if (_controllers.containsKey(amountKey)) {
        _controllers[amountKey]!.text = _selectedQuickAmount!;
        // Reset selection to avoid overriding manual input immediately?
        // Better implementation: Update text, but clear selection if user edits.
        // For simplicity, just update text.
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service header card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.themeColor,
                      widget.themeColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: widget.themeColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fast, secure & instant',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Provider selection (if any)
              if (widget.providers != null && widget.providers!.isNotEmpty) ...[
                Text(
                  'SELECT PROVIDER',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.providers!.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final provider = widget.providers![index];
                      final isSelected = _selectedProviderIndex == index;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedProviderIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? widget.themeColor
                                  : Theme.of(
                                      context,
                                    ).dividerColor.withValues(alpha: 0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                provider.icon,
                                color: isSelected
                                    ? widget.themeColor
                                    : Colors.grey,
                                size: 26,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                provider.name,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 9,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? widget.themeColor
                                      : Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Form fields
              ...widget.fields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildField(field, isDark),
                ),
              ),

              // Quick amounts (if any)
              if (widget.quickAmounts != null &&
                  widget.quickAmounts!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'QUICK SELECT',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.quickAmounts!.map((amt) {
                    final isSelected = _selectedQuickAmount == amt;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedQuickAmount = amt);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.themeColor
                              : (isDark ? AppColors.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? widget.themeColor
                                : Theme.of(
                                    context,
                                  ).dividerColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          '₹$amt',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Submit button
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.buttonLabel,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: widget.themeColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '100% safe & secure payments. Protected with 256-bit encryption.',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: Colors.grey,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(ServiceField field, bool isDark) {
    final labelText = field.isRequired ? '${field.label} *' : field.label;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
        ),
      ),
      child: TextFormField(
        controller: _controllers[field.label],
        keyboardType: field.keyboardType,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        validator:
            field.validator ??
            (field.isRequired
                ? (val) {
                    if (val == null || val.trim().isEmpty) {
                      return '${field.label} is required';
                    }
                    if (field.keyboardType == TextInputType.number ||
                        field.keyboardType ==
                            const TextInputType.numberWithOptions(
                              decimal: true,
                            )) {
                      final d = double.tryParse(val.trim());
                      if (d == null || d <= 0) {
                        return 'Enter a valid amount greater than 0';
                      }
                    }
                    return null;
                  }
                : null),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: GoogleFonts.spaceGrotesk(
            color: Colors.grey,
            fontSize: 13,
          ),
          hintText: field.hint,
          hintStyle: GoogleFonts.spaceGrotesk(
            color: Colors.grey[400],
            fontSize: 13,
          ),
          prefixIcon: Icon(field.icon, color: widget.themeColor, size: 20),
          border: InputBorder.none,
          errorStyle: GoogleFonts.spaceGrotesk(fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: (val) {
          // Clear quick amount selection if user types manually
          if (_selectedQuickAmount != null &&
              field.label.toLowerCase().contains('amount')) {
            setState(() {
              _selectedQuickAmount = null;
            });
          }
        },
      ),
    );
  }

  Future<void> _onSubmit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // ── Step 1: Validate form fields ──────────────────────────────
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // ── Step 2: Validate provider selection ──────────────────────
    if (widget.providers != null &&
        widget.providers!.isNotEmpty &&
        _selectedProviderIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a provider to continue.',
            style: GoogleFonts.spaceGrotesk(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final auth = AuthService();

    // ── Step 3: Extract amount ────────────────────────────────────
    String amount = '0';
    for (var key in _controllers.keys) {
      if (key.toLowerCase().contains('amount') ||
          key.toLowerCase().contains('price')) {
        amount = _controllers[key]?.text.trim() ?? '0';
        break;
      }
    }
    if (amount.isEmpty) amount = '0';
    final amountDouble = double.tryParse(amount) ?? 0.0;

    // ── Step 4: Show Payment Confirmation Sheet ───────────────────
    final confirmation = await PaymentConfirmationSheet.show(
      context,
      user.uid,
      amountDouble,
    );
    if (confirmation == null) return;
    if (!mounted) return;

    // ── Step 5: Authentication ────────────────────────────────────
    bool verified = false;
    final selectedBank = confirmation.bankAccount;

    if (confirmation.useInstantPay) {
      if (auth.canProcessInstantPay(amountDouble)) {
        verified = true;
        await auth.recordInstantPayUsage(amountDouble);
      } else {
        await PaymentResultDialog.show(
          context,
          success: false,
          title: 'Payment Failed',
          subtitle:
              'Instant Pay limit exceeded. Daily limit is ₹${AuthService.maxDailyInstantLimit.toStringAsFixed(0)}.',
          amount: amount,
          recipient: widget.title,
        );
        return;
      }
    } else if (confirmation.useBiometric ||
        auth.requiresBiometric(amountDouble)) {
      // Biometric-first (also triggered by limit rule)
      verified = await auth.authenticateBiometrics();
      if (!verified && mounted) {
        // Fallback to PIN
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
    } else {
      // Default: PIN Verification
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
    if (!mounted) return;

    // ── Step 6: Check sufficient balance ──────────────────────────
    if (selectedBank.balance < amountDouble) {
      await PaymentResultDialog.show(
        context,
        success: false,
        title: 'Insufficient Balance',
        subtitle:
            'Your ${selectedBank.bankName} account does not have enough balance for this payment.',
        amount: amount,
        recipient: widget.title,
      );
      return;
    }

    if (!mounted) return;

    // ── Step 7: Deduct bank balance with coupons & rewards applied ──
    double couponDiscount = 0.0;
    if (confirmation.appliedCoupon != null) {
      final coupon = confirmation.appliedCoupon!;
      if (coupon['type'] == 'flat') {
        couponDiscount = coupon['discount'];
      } else {
        couponDiscount = amountDouble * coupon['discount'];
        if (couponDiscount > 50) couponDiscount = 50.0;
      }
    }

    double amountAfterCoupon = (amountDouble - couponDiscount).clamp(
      0.0,
      amountDouble,
    );
    double rewardsUsed = 0.0;
    if (confirmation.applyRewards) {
      rewardsUsed = await RewardsService().redeemCashback(amountAfterCoupon);
    }

    double amountFromBank = amountAfterCoupon - rewardsUsed;

    if (amountFromBank > 0) {
      await FirestoreService().updateBankAccountBalance(
        user.uid,
        selectedBank.id,
        -amountFromBank,
      );
    }

    if (!mounted) return;

    // Build transaction details
    String details = 'Service Payment';
    if (couponDiscount > 0 || rewardsUsed > 0) {
      List<String> discounts = [];
      if (couponDiscount > 0) {
        discounts.add("Coupon -₹${couponDiscount.toStringAsFixed(2)}");
      }
      if (rewardsUsed > 0) {
        discounts.add("Cashback -₹${rewardsUsed.toStringAsFixed(2)}");
      }
      details += " (${discounts.join(', ')})";
    }

    // ── Step 8: Record transaction ────────────────────────────────
    TransactionManager().addTransaction(
      Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: widget.title,
        date: DateTime.now(),
        amount: amountFromBank,
        isPositive: false,
        icon: Icons.payments,
        color: AppColors.primary,
        details: details,
        category: TransactionCategory.bills,
      ),
    );

    // ── Step 8: Award cashback ────────────────────────────────────
    await RewardsService().awardCashback(amountDouble);

    // ── Step 8b: Auto-apply Expensya cashback if eligible ──────────
    final autoApplied = await RewardsService().autoApplyCashback();

    if (!mounted) return;

    // ── Step 9: Show result ───────────────────────────────────────
    final cashback = RewardsService().calculateCashback(amountDouble);
    String subtitle;
    if (autoApplied > 0) {
      subtitle =
          'Payment processed. +₹${cashback.toStringAsFixed(2)} cashback earned! ₹${autoApplied.toStringAsFixed(0)} transferred to your bank.';
    } else if (cashback > 0) {
      subtitle =
          'Your ${widget.title.toLowerCase()} has been processed. +₹${cashback.toStringAsFixed(2)} cashback earned!';
    } else {
      subtitle =
          'Your ${widget.title.toLowerCase()} request has been processed successfully.';
    }

    await PaymentResultDialog.show(
      context,
      success: true,
      title: 'Payment Successful!',
      subtitle: subtitle,
      amount: amountFromBank.toStringAsFixed(2),
      recipient: widget.title,
      onDone: () => Navigator.pop(context),
    );
  }
}

/// Data model for a form field in a service page.
class ServiceField {
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType keyboardType;

  /// Whether this field is required (shown with * and validated non-empty)
  final bool isRequired;

  /// Optional custom validator. Return an error string or null.
  final String? Function(String?)? validator;

  const ServiceField({
    required this.label,
    this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.isRequired = true,
    this.validator,
  });
}

/// Data model for a provider (operator / company).
class ServiceProvider {
  final String name;
  final IconData icon;

  const ServiceProvider({required this.name, required this.icon});
}
