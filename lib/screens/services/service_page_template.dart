import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme_manager.dart';
import '../../utils/transaction_manager.dart';
import '../../utils/auth_manager.dart';
import '../pin_screen.dart';

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
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fast, secure & instant',
                            style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
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
                                style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
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
                          style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
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
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        decoration: InputDecoration(
          labelText: field.label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
          hintText: field.hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
          prefixIcon: Icon(field.icon, color: widget.themeColor, size: 20),
          border: InputBorder.none,
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
    // 1. Find amount
    String amount = '0';
    for (var key in _controllers.keys) {
      if (key.toLowerCase().contains('amount') ||
          key.toLowerCase().contains('price')) {
        amount = _controllers[key]?.text ?? '0';
        break;
      }
    }
    if (amount.isEmpty) amount = '0';

    // PIN Verification
    final auth = AuthService();
    final hasPin = await auth.hasPin();
    if (mounted) {
      final mode = hasPin ? PinMode.verify : PinMode.create;
      final verified = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PinScreen(mode: mode)),
      );
      if (verified != true) return;
    }

    if (!mounted) return;

    // 2. Add Transaction
    TransactionManager().addTransaction(
      Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: widget.title,
        date: DateTime.now(),
        amount: -(double.tryParse(amount) ?? 0.0),
        isPositive: false,
        icon: widget.icon,
        color: widget.themeColor,
        details: 'Service Payment',
        category: TransactionCategory.bills,
      ),
    );

    // 3. Show Success
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Request Submitted!',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ${widget.title.toLowerCase()} request has been processed successfully.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data model for a form field in a service page.
class ServiceField {
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType keyboardType;

  const ServiceField({
    required this.label,
    this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });
}

/// Data model for a provider (operator / company).
class ServiceProvider {
  final String name;
  final IconData icon;

  const ServiceProvider({required this.name, required this.icon});
}
