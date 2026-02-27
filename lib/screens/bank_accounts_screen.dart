import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme_manager.dart';
import '../utils/firestore_service.dart';
import '../utils/hash_helper.dart';
import '../models/bank_account.dart';
import 'pin_screen.dart';

class BankAccountsScreen extends StatelessWidget {
  const BankAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Bank Accounts",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text("Please login to see bank accounts"))
          : StreamBuilder<List<BankAccount>>(
              stream: FirestoreService().linkedBanksStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final banks = snapshot.data ?? [];

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (banks.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.account_balance_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No bank accounts linked",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: banks.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final bank = banks[index];
                              return GestureDetector(
                                onTap: () => _showBankOptionsSheet(
                                  context,
                                  bank,
                                  user.uid,
                                ),
                                child: _bankTile(context, bank, isDark),
                              );
                            },
                          ),
                        ),
                      _addBankButton(context),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _bankTile(BuildContext context, BankAccount bank, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: bank.isPrimary
              ? AppColors.primary.withOpacity(0.3)
              : Theme.of(context).dividerColor.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bank.bankName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "Savings  •  **** ${bank.accountNumber.substring(bank.accountNumber.length > 4 ? bank.accountNumber.length - 4 : 0)}",
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (bank.isPrimary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Primary",
                style: GoogleFonts.poppins(
                  color: AppColors.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showBankOptionsSheet(
    BuildContext context,
    BankAccount bank,
    String uid,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank.bankName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "**** ${bank.accountNumber.substring(bank.accountNumber.length > 4 ? bank.accountNumber.length - 4 : 0)}",
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              if (!bank.isPrimary)
                ListTile(
                  leading: const Icon(
                    Icons.star_border,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    "Set as Primary Account",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await FirestoreService().setPrimaryBankAccount(
                      uid,
                      bank.id,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Primary account updated successfully.",
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                ),
                title: Text(
                  "Change PIN",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  _handlePinChange(context, bank, uid);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: Text(
                  "Delete Account",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.redAccent,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  _confirmDeleteBank(context, bank, uid);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteBank(BuildContext context, BankAccount bank, String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Remove Account?",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to remove ${bank.bankName} ending in ${bank.accountNumber.substring(bank.accountNumber.length > 4 ? bank.accountNumber.length - 4 : 0)}? You will need your PIN to confirm.",
          style: GoogleFonts.poppins(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // close dialog

              // Launch PIN Verification explicitly for this specific bank if a PIN exists
              bool? verified = true;
              if (bank.pinHash.isNotEmpty) {
                verified = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PinScreen(
                      mode: PinMode.verifyBank,
                      expectedBankPinHash: bank.pinHash,
                    ),
                  ),
                );
              }

              if (verified == true && context.mounted) {
                await FirestoreService().deleteBankAccount(uid, bank.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Bank account removed successfully."),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(
              "Remove",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addBankButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        final bankNameCtrl = TextEditingController();
        final accNumCtrl = TextEditingController();
        final ifscCtrl = TextEditingController();

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 20),
                  Text(
                    "Link New Bank Account",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(ctx).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _dialogField(ctx, "Bank Name", bankNameCtrl, isDark),
                  const SizedBox(height: 12),
                  _dialogField(
                    ctx,
                    "Account Number",
                    accNumCtrl,
                    isDark,
                    isNumber: true,
                  ),
                  const SizedBox(height: 12),
                  _dialogField(ctx, "IFSC Code", ifscCtrl, isDark),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (bankNameCtrl.text.isEmpty) return;

                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        if (!context.mounted) return;

                        // First capture the PIN for this new bank account
                        final String? rawPin = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PinScreen(mode: PinMode.createBank),
                          ),
                        );

                        if (rawPin == null) {
                          // User cancelled PIN creation
                          return;
                        }

                        final String hashedPin = HashHelper.hashPin(rawPin);

                        final newBank = BankAccount(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          bankName: bankNameCtrl.text,
                          accountNumber: accNumCtrl.text,
                          ifscCode: ifscCtrl.text,
                          balance: 0.0,
                          pinHash: hashedPin,
                          icon: Icons.account_balance,
                          color: AppColors.primary,
                        );

                        await FirestoreService().addBankAccount(
                          user.uid,
                          newBank,
                        );

                        if (context.mounted) Navigator.pop(ctx);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Bank account and PIN linked successfully!",
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Link Account",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Text(
              "Link New Bank Account",
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePinChange(
    BuildContext context,
    BankAccount bank,
    String uid,
  ) async {
    // 1. Verify current bank PIN
    bool? verified = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinScreen(
          mode: PinMode.verifyBank,
          expectedBankPinHash: bank.pinHash,
        ),
      ),
    );

    if (verified == true && context.mounted) {
      // 2. Create new bank PIN
      final String? rawPin = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PinScreen(mode: PinMode.createBank),
        ),
      );

      if (rawPin != null && context.mounted) {
        final String hashedPin = HashHelper.hashPin(rawPin);

        // 3. Update Firestore
        await FirestoreService().updateBankAccountPin(uid, bank.id, hashedPin);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Bank PIN updated successfully!"),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    }
  }

  Widget _dialogField(
    BuildContext context,
    String hint,
    TextEditingController controller,
    bool isDark, {
    bool obscure = false,
    bool isNumber = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
