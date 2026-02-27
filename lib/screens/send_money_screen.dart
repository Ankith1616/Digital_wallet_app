import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/theme_manager.dart';
import '../utils/transaction_manager.dart';
import '../models/transaction.dart';
import '../utils/firestore_service.dart';
import '../widgets/payment_confirmation_sheet.dart';
import 'pin_screen.dart';
import '../widgets/payment_result_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/auth_manager.dart';

// ─── Colour palette for avatars ────────────────────────────────────────────
const List<Color> _avatarColors = [
  Color(0xFF6C63FF),
  Color(0xFFFF6584),
  Color(0xFF43C59E),
  Color(0xFFF7B731),
  Color(0xFF45AAF2),
  Color(0xFFFC5C65),
  Color(0xFF26DE81),
  Color(0xFFFD9644),
];

Color _colorForName(String name) =>
    _avatarColors[name.codeUnitAt(0) % _avatarColors.length];

// ─── Screen ─────────────────────────────────────────────────────────────────
class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  // Permission + loading
  _ContactsState _state = _ContactsState.idle;

  // Raw contacts, filtered contacts, search
  List<Contact> _contacts = [];
  List<Contact> _filtered = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _checkAndLoad();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Check permission then load ───────────────────────────────────────────
  Future<void> _checkAndLoad() async {
    // Permission.contacts is not supported on web
    if (kIsWeb) {
      setState(() => _state = _ContactsState.needsPermission);
      return;
    }
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      _loadContacts();
    } else {
      setState(() => _state = _ContactsState.needsPermission);
    }
  }

  Future<void> _requestPermission() async {
    // Cannot request contacts permission on web
    if (kIsWeb) return;
    setState(() => _state = _ContactsState.loading);
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      _loadContacts();
    } else if (status.isPermanentlyDenied) {
      setState(() => _state = _ContactsState.permanentlyDenied);
    } else {
      setState(() => _state = _ContactsState.needsPermission);
    }
  }

  Future<void> _loadContacts() async {
    setState(() => _state = _ContactsState.loading);
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      // Keep only contacts that have at least a name
      final valid = contacts
          .where((c) => c.displayName.trim().isNotEmpty)
          .toList();
      setState(() {
        _contacts = valid;
        _filtered = valid;
        _state = _ContactsState.loaded;
      });
    } catch (_) {
      setState(() => _state = _ContactsState.error);
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _contacts
          : _contacts.where((c) {
              final phone = c.phones.isNotEmpty ? c.phones.first.number : '';
              return c.displayName.toLowerCase().contains(q) ||
                  phone.contains(q);
            }).toList();
    });
  }

  // ── Recent = first 5 of loaded contacts ─────────────────────────────────
  List<Contact> get _recent => _contacts.take(5).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Send Money',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_state == _ContactsState.loaded)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh contacts',
              onPressed: _loadContacts,
            ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    switch (_state) {
      case _ContactsState.idle:
      case _ContactsState.loading:
        return const Center(child: CircularProgressIndicator());

      case _ContactsState.needsPermission:
        return _PermissionPrompt(onAllow: _requestPermission, isDark: isDark);

      case _ContactsState.permanentlyDenied:
        return _PermissionPrompt(
          onAllow: () => openAppSettings(),
          isDark: isDark,
          permanent: true,
        );

      case _ContactsState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Could not load contacts',
                style: GoogleFonts.spaceGrotesk(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadContacts,
                child: const Text('Retry'),
              ),
            ],
          ),
        );

      case _ContactsState.loaded:
        return _ContactsView(
          recent: _recent,
          filtered: _filtered,
          searchCtrl: _searchCtrl,
          isDark: isDark,
          onPay: (name) => _showPaymentSheet(context, name, isDark),
        );
    }
  }

  // ── Premium Payment Sheet ────────────────────────────────────────────────
  void _showPaymentSheet(BuildContext context, String name, bool isDark) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? selectedQuick;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient header
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.headerGradient,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              name[0].toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Paying $name',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Enter the amount to send',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      20,
                      24,
                      20 + MediaQuery.of(ctx).viewInsets.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount field
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 4,
                                ),
                                child: Text(
                                  '₹',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: amountCtrl,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: GoogleFonts.spaceGrotesk(
                                      color: Colors.grey.shade400,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  onChanged: (_) =>
                                      setModal(() => selectedQuick = null),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Quick chips
                        Wrap(
                          spacing: 8,
                          children: ['100', '200', '500', '1000', '2000'].map((
                            amt,
                          ) {
                            final sel = selectedQuick == amt;
                            return GestureDetector(
                              onTap: () => setModal(() {
                                selectedQuick = amt;
                                amountCtrl.text = amt;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.primary
                                      : (isDark
                                            ? Colors.white.withOpacity(0.08)
                                            : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(20),
                                  border: sel
                                      ? null
                                      : Border.all(
                                          color: Colors.grey.withOpacity(0.2),
                                        ),
                                ),
                                child: Text(
                                  '₹$amt',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white70
                                              : Colors.black54),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // Note field
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.grey.withOpacity(
                                isDark ? 0.15 : 0.12,
                              ),
                            ),
                          ),
                          child: TextField(
                            controller: noteCtrl,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.sticky_note_2_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                              hintText: 'Add a note (optional)',
                              hintStyle: GoogleFonts.spaceGrotesk(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Send button
                        GestureDetector(
                          onTap: () async {
                            final amount = amountCtrl.text.trim();
                            final amountDouble = double.tryParse(amount);
                            if (amount.isEmpty || amountDouble == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please enter a valid amount',
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

                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;

                            // ─── Unified Multi-Step Payment Process ────────────────
                            // 1. Show Confirmation Sheet (Rewards + Bank + Auth Choice)
                            final confirmation =
                                await PaymentConfirmationSheet.show(
                                  context,
                                  user.uid,
                                  amountDouble,
                                );

                            if (confirmation == null)
                              return; // Cancelled or Limit Failure inside sheet

                            if (!context.mounted) return;

                            // 2. Authentication Verification
                            bool verified = false;
                            final auth = AuthService();
                            final selectedBank = confirmation.bankAccount;

                            if (confirmation.useInstantPay) {
                              // Double check limits (sheet already did it, but good for safety)
                              if (auth.canProcessInstantPay(amountDouble)) {
                                verified = true;
                                await auth.recordInstantPayUsage(amountDouble);
                              } else {
                                // Explicitly fail as per user request
                                await PaymentResultDialog.show(
                                  context,
                                  success: false,
                                  title: 'Transfer Failed',
                                  subtitle:
                                      'Instant Payment limit exceeded. Cumulative daily limit is ₹2000.',
                                  amount: amount,
                                  recipient: name,
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
                            if (!context.mounted) return;

                            // 3. Deduct balance from the specific bank account
                            await FirestoreService().updateBankAccountBalance(
                              user.uid,
                              selectedBank.id,
                              -amountDouble,
                            );

                            TransactionManager().addTransaction(
                              Transaction(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                title: 'Sent to $name',
                                date: DateTime.now(),
                                amount: amountDouble,
                                isPositive: false,
                                icon: Icons.person,
                                color: AppColors.primary,
                                details: noteCtrl.text.isEmpty
                                    ? (confirmation.applyRewards
                                          ? 'Transfer (Rewards Applied)'
                                          : 'Transfer')
                                    : noteCtrl.text,
                                category: TransactionCategory.transfer,
                              ),
                            );

                            Navigator.pop(ctx);
                            await PaymentResultDialog.show(
                              context,
                              success: true,
                              title: 'Payment Sent!',
                              subtitle:
                                  'Your payment was successfully sent to $name.',
                              amount: amount,
                              recipient: name,
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Send Now',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                size: 13,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '256-bit encrypted & secure',
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
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── State machine ───────────────────────────────────────────────────────────
enum _ContactsState {
  idle,
  loading,
  needsPermission,
  permanentlyDenied,
  loaded,
  error,
}

// ─── Permission Prompt Widget ────────────────────────────────────────────────
class _PermissionPrompt extends StatelessWidget {
  final VoidCallback onAllow;
  final bool isDark;
  final bool permanent;

  const _PermissionPrompt({
    required this.onAllow,
    required this.isDark,
    this.permanent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon bubble
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.contacts_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              permanent ? 'Contacts Access Blocked' : 'Access Your Contacts',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              permanent
                  ? 'You permanently denied contacts access. Please enable it in Settings → App Permissions → Contacts.'
                  : 'Allow AI Wallet to access your contacts so you can quickly send money to the people you know.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: Colors.grey,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: onAllow,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    permanent ? 'Open Settings' : 'Allow Access',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            if (!permanent) ...[
              const SizedBox(height: 14),
              Text(
                'Your contacts never leave your device.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Main Contacts View ──────────────────────────────────────────────────────
class _ContactsView extends StatelessWidget {
  final List<Contact> recent;
  final List<Contact> filtered;
  final TextEditingController searchCtrl;
  final bool isDark;
  final void Function(String name) onPay;

  const _ContactsView({
    required this.recent,
    required this.filtered,
    required this.searchCtrl,
    required this.isDark,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: searchCtrl,
              style: GoogleFonts.spaceGrotesk(
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                icon: Icon(Icons.search, color: Colors.grey[500]),
                hintText: 'Search name or phone',
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                suffixIcon: searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed: () => searchCtrl.clear(),
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Recent bubbles (only when not searching)
        if (searchCtrl.text.isEmpty && recent.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'RECENT',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 82,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recent.length,
              itemBuilder: (_, i) {
                final c = recent[i];
                final color = _colorForName(c.displayName);
                return GestureDetector(
                  onTap: () => onPay(c.displayName),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              c.displayName[0].toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: 56,
                          child: Text(
                            c.displayName.split(' ').first,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Section label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                searchCtrl.text.isEmpty ? 'ALL CONTACTS' : 'RESULTS',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${filtered.length}',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Contact list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No contacts found',
                    style: GoogleFonts.spaceGrotesk(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final phone = c.phones.isNotEmpty
                        ? c.phones.first.number
                        : 'No number';
                    final color = _colorForName(c.displayName);
                    return GestureDetector(
                      onTap: () => onPay(c.displayName),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.grey.withOpacity(0.1),
                          ),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                c.displayName[0].toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            c.displayName,
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            phone,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.send_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
