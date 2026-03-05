import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/theme_manager.dart';
import '../utils/transaction_manager.dart';
import '../models/transaction.dart';
import '../utils/auth_manager.dart';
import 'pin_screen.dart';
import '../widgets/interactive_scale.dart';
import '../widgets/payment_confirmation_sheet.dart';
import '../utils/firestore_service.dart';
import '../utils/rewards_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

const List<Color> _splitAvatarColors = [
  Color(0xFF6C63FF),
  Color(0xFFFF6584),
  Color(0xFF43C59E),
  Color(0xFFF7B731),
  Color(0xFF45AAF2),
  Color(0xFFFC5C65),
  Color(0xFF26DE81),
  Color(0xFFFD9644),
];

class SplitBillScreen extends StatefulWidget {
  final double? initialAmount;
  final String? initialNote;
  const SplitBillScreen({super.key, this.initialAmount, this.initialNote});

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allContacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  final Set<int> _selectedContactIndices = {};
  bool _isLoadingContacts = true;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount?.toString() ?? "",
    );
    _noteController = TextEditingController(text: widget.initialNote ?? "");
    _searchController.addListener(_onSearch);
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    if (kIsWeb) {
      setState(() => _isLoadingContacts = false);
      return;
    }
    try {
      final status = await Permission.contacts.status;
      if (!status.isGranted) {
        final result = await Permission.contacts.request();
        if (!result.isGranted) {
          if (mounted) setState(() => _isLoadingContacts = false);
          return;
        }
      }
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      final list = <Map<String, dynamic>>[];
      for (final c in contacts) {
        if (c.displayName.trim().isEmpty) continue;
        final phone = c.phones.isNotEmpty ? c.phones.first.number : '';
        final color = _splitAvatarColors[
            c.displayName.codeUnitAt(0) % _splitAvatarColors.length];
        list.add({
          'name': c.displayName,
          'phone': phone,
          'color': color,
        });
      }
      if (mounted) {
        setState(() {
          _allContacts = list;
          _filteredContacts = list;
          _isLoadingContacts = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load contacts for split: $e');
      if (mounted) setState(() => _isLoadingContacts = false);
    }
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = q.isEmpty
          ? _allContacts
          : _allContacts.where((c) {
              return c['name'].toString().toLowerCase().contains(q) ||
                  c['phone'].toString().contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Split Expense",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_selectedContactIndices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${_selectedContactIndices.length} People",
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TOTAL AMOUNT",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "₹",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                            decoration: InputDecoration(
                              hintText: "0",
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey[400],
                              ),
                              border: InputBorder.none,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.08),
                      ),
                    ),
                    child: TextField(
                      controller: _noteController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "What is this for? (e.g. Dinner)",
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                        border: InputBorder.none,
                        icon: Icon(Icons.notes, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "SPLIT WITH",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search contacts
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search contacts...',
                        hintStyle:
                            GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingContacts)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_filteredContacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          _allContacts.isEmpty
                              ? 'No contacts found.\nPlease grant contacts permission.'
                              : 'No matching contacts.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredContacts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      // find the original index in _allContacts for selection tracking
                      final origIndex = _allContacts.indexOf(contact);
                      final isSelected = _selectedContactIndices.contains(
                        origIndex,
                      );
                      return InteractiveScale(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedContactIndices.remove(origIndex);
                            } else {
                              _selectedContactIndices.add(origIndex);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Theme.of(
                                      context,
                                    ).dividerColor.withValues(alpha: 0.08),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: (contact['color'] as Color)
                                    .withValues(alpha: 0.15),
                                child: Text(
                                  (contact['name'] as String)[0],
                                  style: GoogleFonts.poppins(
                                    color: contact['color'],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact['name'],
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isSelected
                                            ? AppColors.primary
                                            : Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    Text(
                                      contact['phone'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_amountController.text.isNotEmpty &&
                      _selectedContactIndices.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Per person pay",
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                        Text(
                          "₹${_calculatePerPerson().toStringAsFixed(1)}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: InteractiveScale(
                      onTap:
                          _amountController.text.isEmpty ||
                              _selectedContactIndices.isEmpty
                          ? null
                          : _handleSplit,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              _amountController.text.isEmpty ||
                                  _selectedContactIndices.isEmpty
                              ? Colors.grey[300]
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            if (!(_amountController.text.isEmpty ||
                                _selectedContactIndices.isEmpty))
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Text(
                          "Split Expense",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
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

  double _calculatePerPerson() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    return amount / (_selectedContactIndices.length + 1);
  }

  Future<void> _handleSplit() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final auth = AuthService();

    // ─── Unified Multi-Step Payment Process ────────────────
    // 1. Show Confirmation Sheet (Rewards + Bank + Auth Choice)
    final confirmation = await PaymentConfirmationSheet.show(
      context,
      user.uid,
      amount,
    );

    if (confirmation == null) return; // Cancelled or Limit Failure inside sheet

    if (!mounted) return;

    // 2. Authentication Verification
    bool verified = false;
    final selectedBank = confirmation.bankAccount;

    if (confirmation.useInstantPay) {
      if (auth.canProcessInstantPay(amount)) {
        verified = true;
        await auth.recordInstantPayUsage(amount);
      } else {
        // Explicitly fail as per user request
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Instant Payment limit exceeded. Cumulative daily limit is ₹2000.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    } else if (confirmation.useBiometric) {
      verified = await auth.authenticateBiometrics();
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

    // 3. Deduct balance with coupons & rewards applied
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

    final perPerson = _calculatePerPerson();
    final note = _noteController.text.isEmpty
        ? "Split Expense"
        : _noteController.text;
    final totalPeople = _selectedContactIndices.length + 1;

    for (var index in _selectedContactIndices) {
      final contact = _allContacts[index];
      TransactionManager().addTransaction(
        Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: "Request: ${contact['name']}",
          date: DateTime.now(),
          amount: perPerson,
          isPositive: true,
          icon: Icons.call_split,
          color: contact['color'],
          details: '$note (1/$totalPeople)',
          category: TransactionCategory.transfer,
        ),
      );
    }

    // Build transaction details for the payer
    String details = 'Total Bill Paid';
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

    TransactionManager().addTransaction(
      Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "Split Paid: $note",
        date: DateTime.now(),
        amount: amountFromBank,
        isPositive: false,
        icon: Icons.receipt_long,
        color: Colors.grey,
        details: details,
        category: TransactionCategory.bills,
      ),
    );

    // Award cashback & auto-apply Expensya
    await RewardsService().awardCashback(amount);
    final autoApplied = await RewardsService().autoApplyCashback();

    if (!mounted) return;

    final cashback = RewardsService().calculateCashback(amount);
    String snackMsg;
    if (autoApplied > 0) {
      snackMsg =
          'Split sent! +₹${cashback.toStringAsFixed(2)} cashback earned. ₹${autoApplied.toStringAsFixed(0)} transferred to your bank.';
    } else if (cashback > 0) {
      snackMsg =
          'Split requests sent! +₹${cashback.toStringAsFixed(2)} cashback earned!';
    } else {
      snackMsg = 'Split requests sent successfully!';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(snackMsg), backgroundColor: AppColors.success),
    );
    Navigator.pop(context);
  }
}
