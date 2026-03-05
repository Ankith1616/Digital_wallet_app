import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/theme_manager.dart';
import '../../utils/transaction_manager.dart';
import '../../models/transaction.dart';
import '../../utils/auth_manager.dart';
import '../../utils/rewards_service.dart';
import '../../utils/firestore_service.dart';
import '../pin_screen.dart';
import '../../widgets/payment_result_dialog.dart';
import '../../widgets/payment_confirmation_sheet.dart';
import 'service_page_template.dart';

/// A booking result shown after "searching".
class BookingResult {
  final String title;
  final String subtitle;
  final String duration;
  final double price;
  final double? rating;
  final List<String> tags;

  const BookingResult({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.price,
    this.rating,
    this.tags = const [],
  });
}

/// Template for travel booking pages (Flight, Train, Bus, Hotel).
/// Shows a search form → mock results → payment flow.
class TravelBookingTemplate extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color themeColor;
  final List<ServiceField> fields;
  final String searchButtonLabel;
  final TransactionCategory category;

  /// Generator that produces mock results from field values.
  final List<BookingResult> Function(Map<String, String> fieldValues)
      resultGenerator;

  const TravelBookingTemplate({
    super.key,
    required this.title,
    required this.icon,
    required this.themeColor,
    required this.fields,
    required this.resultGenerator,
    this.searchButtonLabel = 'Search',
    this.category = TransactionCategory.transport,
  });

  @override
  State<TravelBookingTemplate> createState() => _TravelBookingTemplateState();
}

class _TravelBookingTemplateState extends State<TravelBookingTemplate> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isSearching = false;
  List<BookingResult>? _results;

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      _controllers[field.label] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _search() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSearching = true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final values = <String, String>{};
    for (var entry in _controllers.entries) {
      values[entry.key] = entry.value.text.trim();
    }

    if (!mounted) return;
    setState(() {
      _results = widget.resultGenerator(values);
      _isSearching = false;
    });
  }

  Future<void> _bookResult(BookingResult result) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final amount = result.price;

    // Payment confirmation sheet
    final confirmation = await PaymentConfirmationSheet.show(
      context,
      user.uid,
      amount,
    );
    if (confirmation == null || !mounted) return;

    // Authentication
    bool verified = false;
    final selectedBank = confirmation.bankAccount;
    final auth = AuthService();

    if (confirmation.useInstantPay) {
      if (auth.canProcessInstantPay(amount)) {
        verified = true;
        await auth.recordInstantPayUsage(amount);
      } else {
        await PaymentResultDialog.show(
          context,
          success: false,
          title: 'Payment Failed',
          subtitle:
              'Instant Pay limit exceeded. Daily limit is ₹${AuthService.maxDailyInstantLimit.toStringAsFixed(0)}.',
          amount: amount.toStringAsFixed(2),
          recipient: widget.title,
        );
        return;
      }
    } else if (confirmation.useBiometric ||
        auth.requiresBiometric(amount)) {
      verified = await auth.authenticateBiometrics();
      if (!verified && mounted) {
        final pinResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PinScreen(
              mode: PinMode.verifyBank,
              expectedBankPinHash: selectedBank.pinHash,
            ),
          ),
        );
        verified = pinResult == true;
      }
    } else {
      final pinResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PinScreen(
            mode: PinMode.verifyBank,
            expectedBankPinHash: selectedBank.pinHash,
          ),
        ),
      );
      verified = pinResult == true;
    }

    if (!verified || !mounted) return;

    // Balance check
    if (selectedBank.balance < amount) {
      await PaymentResultDialog.show(
        context,
        success: false,
        title: 'Insufficient Balance',
        subtitle:
            'Your ${selectedBank.bankName} account does not have enough balance.',
        amount: amount.toStringAsFixed(2),
        recipient: widget.title,
      );
      return;
    }
    if (!mounted) return;

    // Apply coupon & rewards
    double couponDiscount = 0.0;
    if (confirmation.appliedCoupon != null) {
      final coupon = confirmation.appliedCoupon!;
      if (coupon['type'] == 'flat') {
        couponDiscount = coupon['discount'];
      } else {
        couponDiscount = amount * coupon['discount'];
        if (couponDiscount > 50) couponDiscount = 50.0;
      }
    }

    double amountAfterCoupon = (amount - couponDiscount).clamp(0.0, amount);
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

    // Build details
    String details = '${result.title} — ${result.subtitle}';
    if (couponDiscount > 0 || rewardsUsed > 0) {
      final parts = <String>[];
      if (couponDiscount > 0) {
        parts.add('Coupon -₹${couponDiscount.toStringAsFixed(2)}');
      }
      if (rewardsUsed > 0) {
        parts.add('Cashback -₹${rewardsUsed.toStringAsFixed(2)}');
      }
      details += ' (${parts.join(', ')})';
    }

    // Record transaction
    TransactionManager().addTransaction(
      Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: widget.title,
        date: DateTime.now(),
        amount: amountFromBank,
        isPositive: false,
        icon: widget.icon,
        color: widget.themeColor,
        details: details,
        category: widget.category,
      ),
    );

    await RewardsService().awardCashback(amount);
    final autoApplied = await RewardsService().autoApplyCashback();
    if (!mounted) return;

    final cashback = RewardsService().calculateCashback(amount);
    String subtitle;
    if (autoApplied > 0) {
      subtitle =
          'Booking confirmed! +₹${cashback.toStringAsFixed(2)} cashback earned! ₹${autoApplied.toStringAsFixed(0)} transferred to your bank.';
    } else if (cashback > 0) {
      subtitle =
          'Your booking has been confirmed. +₹${cashback.toStringAsFixed(2)} cashback earned!';
    } else {
      subtitle = 'Your booking has been confirmed successfully.';
    }

    await PaymentResultDialog.show(
      context,
      success: true,
      title: 'Booking Confirmed!',
      subtitle: subtitle,
      amount: amountFromBank.toStringAsFixed(2),
      recipient: result.title,
      onDone: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
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
                    child:
                        Icon(widget.icon, color: Colors.white, size: 30),
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

            // Search form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  ...widget.fields.map(
                    (field) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildField(field, isDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isSearching ? null : _search,
                      icon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.search, color: Colors.white),
                      label: Text(
                        _isSearching
                            ? 'Searching...'
                            : widget.searchButtonLabel,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.themeColor,
                        disabledBackgroundColor:
                            widget.themeColor.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Results
            if (_results != null) ...[
              const SizedBox(height: 28),
              Text(
                '${_results!.length} OPTIONS FOUND',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              ..._results!.map(
                (r) => _buildResultCard(r, isDark),
              ),
            ],

            if (_results != null && _results!.isEmpty) ...[
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No results found',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Security info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context)
                      .dividerColor
                      .withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.security,
                      color: widget.themeColor, size: 20),
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
    );
  }

  Widget _buildField(ServiceField field, bool isDark) {
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
        validator: (val) {
          if (field.isRequired && (val == null || val.trim().isEmpty)) {
            return '${field.label} is required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText:
              field.isRequired ? '${field.label} *' : field.label,
          labelStyle: GoogleFonts.spaceGrotesk(
            color: Colors.grey,
            fontSize: 13,
          ),
          hintText: field.hint,
          hintStyle: GoogleFonts.spaceGrotesk(
            color: Colors.grey[400],
            fontSize: 13,
          ),
          prefixIcon:
              Icon(field.icon, color: widget.themeColor, size: 20),
          border: InputBorder.none,
          errorStyle: GoogleFonts.spaceGrotesk(fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BookingResult result, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _bookResult(result),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon,
                          color: widget.themeColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.title,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1B3B52),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.subtitle,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
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
                          '₹${result.price.toInt()}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.themeColor,
                          ),
                        ),
                        if (result.rating != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Color(0xFFFFD166), size: 14),
                              const SizedBox(width: 3),
                              Text(
                                result.rating!.toStringAsFixed(1),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
                if (result.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        result.duration,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      ...result.tags.map(
                        (tag) => Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                widget.themeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: widget.themeColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    result.duration,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
