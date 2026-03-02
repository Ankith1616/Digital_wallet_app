import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/theme_manager.dart';
import '../utils/firestore_service.dart';
import '../utils/auth_manager.dart';
import '../utils/transaction_manager.dart';
import '../models/transaction.dart';
import '../models/bank_account.dart';
import '../widgets/payment_result_dialog.dart';
import 'pin_screen.dart';

/// Self-Transfer Screen — transfer funds between two linked bank accounts.
///
/// - Source and destination bank pickers (must differ)
/// - Shows live balances from Firestore
/// - Amount field with validation (non-empty, > 0, ≤ source balance)
/// - Biometric-first if amount > threshold, else PIN
/// - Idempotency guard (button disabled during processing)
/// - Records a transaction in Firestore on success
class SelfTransferScreen extends StatefulWidget {
  const SelfTransferScreen({super.key});

  @override
  State<SelfTransferScreen> createState() => _SelfTransferScreenState();
}

class _SelfTransferScreenState extends State<SelfTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final AuthService _auth = AuthService();

  List<BankAccount> _banks = [];
  BankAccount? _fromBank;
  BankAccount? _toBank;

  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBanks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final banks = await FirestoreService().linkedBanksStream(uid).first;
    setState(() {
      _banks = banks;
      if (banks.isNotEmpty) {
        _fromBank = banks.first;
        _toBank = banks.length > 1 ? banks[1] : null;
      }
      _isLoading = false;
    });
  }

  String _fmt(double v) => NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  ).format(v);

  Future<void> _onTransfer() async {
    if (_isProcessing) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // ── Validate form ───────────────────────────────────────────
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_fromBank == null || _toBank == null) {
      _showSnack('Please select both source and destination accounts.');
      return;
    }
    if (_fromBank!.id == _toBank!.id) {
      _showSnack('Source and destination must be different accounts.');
      return;
    }

    final amountDouble = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amountDouble <= 0) {
      _showSnack('Enter a valid amount greater than ₹0.');
      return;
    }
    if (amountDouble > _fromBank!.balance) {
      _showSnack('Insufficient balance in ${_fromBank!.bankName}.');
      return;
    }

    // ── Authentication ──────────────────────────────────────────
    bool verified = false;
    if (_auth.requiresBiometric(amountDouble)) {
      verified = await _auth.authenticateBiometrics();
      if (!verified && mounted) {
        // Fallback to PIN
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PinScreen(
              mode: PinMode.verifyBank,
              expectedBankPinHash: _fromBank!.pinHash,
            ),
          ),
        );
        verified = result == true;
      }
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PinScreen(
            mode: PinMode.verifyBank,
            expectedBankPinHash: _fromBank!.pinHash,
          ),
        ),
      );
      verified = result == true;
    }

    if (!verified) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      // ── Debit source bank ───────────────────────────────────────
      await FirestoreService().updateBankAccountBalance(
        uid,
        _fromBank!.id,
        -amountDouble,
      );

      // ── Credit destination bank ─────────────────────────────────
      await FirestoreService().updateBankAccountBalance(
        uid,
        _toBank!.id,
        amountDouble,
      );

      // ── Record transaction ──────────────────────────────────────
      TransactionManager().addTransaction(
        Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Self Transfer',
          date: DateTime.now(),
          amount: amountDouble,
          isPositive: false,
          icon: Icons.swap_horiz_rounded,
          color: AppColors.primary,
          details: 'From ${_fromBank!.bankName} → ${_toBank!.bankName}',
          category: TransactionCategory.other,
        ),
      );

      if (!mounted) return;

      // ── Show success ────────────────────────────────────────────
      await PaymentResultDialog.show(
        context,
        success: true,
        title: 'Transfer Successful!',
        subtitle:
            '₹${amountDouble.toStringAsFixed(2)} transferred from ${_fromBank!.bankName} to ${_toBank!.bankName}.',
        amount: _amountController.text,
        recipient: _toBank!.bankName,
        onDone: () {
          Navigator.pop(context);
        },
      );

      // Reload balances
      await _loadBanks();
    } catch (e) {
      if (!mounted) return;
      await PaymentResultDialog.show(
        context,
        success: false,
        title: 'Transfer Failed',
        subtitle: 'An error occurred. Please try again.',
        amount: _amountController.text,
        recipient: '',
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.spaceGrotesk()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          'Self Transfer',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _banks.isEmpty
          ? _noBanksView(isDark)
          : _transferForm(isDark),
    );
  }

  Widget _noBanksView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Bank Accounts Linked',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Link at least two bank accounts to use Self Transfer.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transferForm(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Transfer visualization card ───────────────────────────
            _transferCard(isDark),
            const SizedBox(height: 20),

            // ── Amount field ──────────────────────────────────────────
            _sectionLabel('AMOUNT'),
            const SizedBox(height: 8),
            _card(
              isDark,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.spaceGrotesk(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    hintText: '0.00',
                    hintStyle: GoogleFonts.spaceGrotesk(
                      color: Colors.grey[400],
                      fontSize: 26,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final d = double.tryParse(val.trim());
                    if (d == null || d <= 0) {
                      return 'Enter a valid amount greater than ₹0';
                    }
                    if (_fromBank != null && d > _fromBank!.balance) {
                      return 'Insufficient balance (Available: ${_fmt(_fromBank!.balance)})';
                    }
                    return null;
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Available balance hint
            if (_fromBank != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Available: ${_fmt(_fromBank!.balance)}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // ── Quick amounts ─────────────────────────────────────────
            _sectionLabel('QUICK SELECT'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [500, 1000, 2000, 5000]
                  .map(
                    (v) => GestureDetector(
                      onTap: () => _amountController.text = v.toString(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '₹$v',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 32),

            // ── Transfer button ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _onTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Transfer Now',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transferCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(isDark ? 0.25 : 0.12),
            const Color(0xFF7B2FBE).withOpacity(isDark ? 0.2 : 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // From bank
          _bankSelector(
            label: 'FROM',
            banks: _banks,
            selected: _fromBank,
            onChanged: (b) => setState(() => _fromBank = b),
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Arrow
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_downward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(height: 16),

          // To bank
          _bankSelector(
            label: 'TO',
            banks: _banks.where((b) => b.id != _fromBank?.id).toList(),
            selected: _toBank?.id == _fromBank?.id ? null : _toBank,
            onChanged: (b) => setState(() => _toBank = b),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _bankSelector({
    required String label,
    required List<BankAccount> banks,
    required BankAccount? selected,
    required ValueChanged<BankAccount?> onChanged,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary.withOpacity(0.7),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: DropdownButton<BankAccount>(
              value: selected,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: isDark ? AppColors.darkCard : Colors.white,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
              hint: Text(
                'Select account',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              onChanged: onChanged,
              items: banks.map((b) {
                return DropdownMenuItem<BankAccount>(
                  value: b,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        b.bankName,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '****${b.accountNumber.substring(b.accountNumber.length > 4 ? b.accountNumber.length - 4 : 0)} · ${_fmt(b.balance)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
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

  Widget _card(bool isDark, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withOpacity(0.4)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: child,
    );
  }
}
