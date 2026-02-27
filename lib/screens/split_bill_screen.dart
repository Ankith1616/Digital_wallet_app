import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';
import '../utils/transaction_manager.dart';
import '../models/transaction.dart';
import '../utils/auth_manager.dart';
import 'pin_screen.dart';
import '../widgets/interactive_scale.dart';
import '../widgets/payment_confirmation_sheet.dart';
import '../utils/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount?.toString() ?? "",
    );
    _noteController = TextEditingController(text: widget.initialNote ?? "");
  }

  final List<Map<String, dynamic>> _allContacts = [];

  final Set<int> _selectedContactIndices = {};

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
                    color: AppColors.primary.withOpacity(0.1),
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
                        color: Theme.of(context).dividerColor.withOpacity(0.08),
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
                        color: Theme.of(context).dividerColor.withOpacity(0.08),
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
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _allContacts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final contact = _allContacts[index];
                      final isSelected = _selectedContactIndices.contains(
                        index,
                      );
                      return InteractiveScale(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedContactIndices.remove(index);
                            } else {
                              _selectedContactIndices.add(index);
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
                                    ).dividerColor.withOpacity(0.08),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: (contact['color'] as Color)
                                    .withOpacity(0.15),
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
                  color: Colors.black.withOpacity(0.05),
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
                                color: AppColors.primary.withOpacity(0.3),
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

    // 3. Deduct balance from the specific bank account
    await FirestoreService().updateBankAccountBalance(
      user.uid,
      selectedBank.id,
      -amount,
    );

    if (!verified) return;

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

    TransactionManager().addTransaction(
      Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "Split Paid: $note",
        date: DateTime.now(),
        amount: -amount,
        isPositive: false,
        icon: Icons.receipt_long,
        color: Colors.grey,
        details: 'Total Bill Paid',
        category: TransactionCategory.bills,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Split requests sent successfully!"),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }
}
