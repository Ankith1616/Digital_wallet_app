import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../utils/theme_manager.dart';
import '../screens/split_bill_screen.dart';
import '../screens/transaction_history_screen.dart';

/// A polished full-screen-style dialog for payment success or failure results.
/// Call via [PaymentResultDialog.show] for convenience.
class PaymentResultDialog extends StatefulWidget {
  final bool success;
  final String title;
  final String subtitle;
  final String amount;
  final String recipient;
  final VoidCallback? onDone;

  const PaymentResultDialog({
    super.key,
    required this.success,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.recipient,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required bool success,
    required String title,
    required String subtitle,
    required String amount,
    required String recipient,
    VoidCallback? onDone,
  }) {
    return showGeneralDialog(
      context: context,
      pageBuilder: (ctx2, anim1, anim2) => PaymentResultDialog(
        success: success,
        title: title,
        subtitle: subtitle,
        amount: amount,
        recipient: recipient,
        onDone: onDone,
      ),
      transitionBuilder: (ctx2, anim, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      barrierDismissible: false,
      barrierLabel: 'PaymentResult',
      barrierColor: Colors.black54,
    );
  }

  @override
  State<PaymentResultDialog> createState() => _PaymentResultDialogState();
}

class _PaymentResultDialogState extends State<PaymentResultDialog>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _particleController;
  late Animation<double> _iconScale;
  late Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _iconScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeOut));

    _ringOpacity = Tween(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 100), () {
      _iconController.forward();
      if (widget.success) _particleController.repeat(reverse: false);
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successColor = const Color(0xFF00D97E);
    final failColor = AppColors.error;
    final color = widget.success ? successColor : failColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon with ring pulse
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulse ring
                    AnimatedBuilder(
                      animation: _iconController,
                      builder: (ctx, _) => Opacity(
                        opacity: _ringOpacity.value * 0.4,
                        child: Container(
                          width: 110 * (0.7 + _iconScale.value * 0.4),
                          height: 110 * (0.7 + _iconScale.value * 0.4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 2),
                          ),
                        ),
                      ),
                    ),
                    // Confetti particles (success only)
                    if (widget.success)
                      AnimatedBuilder(
                        animation: _particleController,
                        builder: (ctx, _) {
                          return CustomPaint(
                            size: const Size(110, 110),
                            painter: _ParticlePainter(
                              _particleController.value,
                              successColor,
                            ),
                          );
                        },
                      ),
                    // Main icon
                    ScaleTransition(
                      scale: _iconScale,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: widget.success
                                ? [successColor, const Color(0xFF00B362)]
                                : [failColor, const Color(0xFFCA0B3A)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.45),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.success
                              ? Icons.check_rounded
                              : Icons.close_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                widget.title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              // Transaction summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.08 : 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    _summaryRow(
                      'Amount',
                      '₹${widget.amount}',
                      isDark,
                      highlight: true,
                      highlightColor: color,
                    ),
                    const SizedBox(height: 10),
                    _summaryRow('To', widget.recipient, isDark),
                    const SizedBox(height: 10),
                    _summaryRow(
                      'Status',
                      widget.success ? 'Successful' : 'Failed',
                      isDark,
                      statusColor: color,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Done button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onDone?.call();
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: widget.success
                        ? LinearGradient(
                            colors: [successColor, const Color(0xFF00B362)],
                          )
                        : LinearGradient(
                            colors: [failColor, const Color(0xFFCA0B3A)],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.success ? 'Done' : 'Try Again',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              if (widget.success) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    _actionButton(
                      icon: Icons.call_split_rounded,
                      label: 'Split',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SplitBillScreen(
                              initialAmount: double.tryParse(widget.amount),
                              initialNote:
                                  'Split payment for ${widget.recipient}',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _actionButton(
                      icon: Icons.history_rounded,
                      label: 'History',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransactionHistoryScreen(
                              initialSearchQuery: widget.recipient,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _actionButton(
                      icon: Icons.share_rounded,
                      label: 'Share',
                      onTap: _generateReceiptAndShare,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sanitizes text to avoid PDF font issues with Unicode characters.
  String _sanitize(String text) {
    return text.replaceAll(RegExp(r'[^\x00-\x7F]'), '?');
  }

  Future<void> _generateReceiptAndShare() async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(now);
      final txnId = 'TXN${now.millisecondsSinceEpoch.toString().substring(7)}';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a6,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      'AI WALLET RECEIPT',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  _pdfRow('Transaction ID', txnId),
                  _pdfRow('Date', dateStr),
                  _pdfRow('Recipient', _sanitize(widget.recipient)),
                  _pdfRow('Status', 'SUCCESSFUL'),
                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.Text(
                      'Amount Paid',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                  pw.Center(
                    child: pw.Text(
                      'INR ${widget.amount}',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Text(
                      'Thank you for using AI Wallet!',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Receipt_$txnId.pdf');
      await file.writeAsBytes(pdfBytes);

      final shareText =
          'Sent ₹${widget.amount} to ${widget.recipient} successfully via AI Wallet. Transaction ID: $txnId';

      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: 'Payment Receipt - AI Wallet',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing receipt: $e')));
      }
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
    bool isDark, {
    bool highlight = false,
    Color? highlightColor,
    Color? statusColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(fontSize: 13, color: Colors.grey),
        ),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: highlight ? 20 : 13,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            color:
                statusColor ??
                (highlight
                    ? (highlightColor ??
                          (isDark ? Colors.white : Colors.black87))
                    : (isDark ? Colors.white : Colors.black87)),
          ),
        ),
      ],
    );
  }
}

// Confetti particle painter
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ParticlePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    final colors = [
      color,
      const Color(0xFFFFD700),
      const Color(0xFF00D4FF),
      const Color(0xFFFF6B6B),
      const Color(0xFF7B2FBE),
    ];

    for (int i = 0; i < 18; i++) {
      final angle = (i / 18) * math.pi * 2 + rng.nextDouble() * 0.5;
      final dist = (40 + rng.nextDouble() * 30) * progress;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final x = center.dx + math.cos(angle) * dist;
      final y = center.dy + math.sin(angle) * dist;
      paint.color = colors[i % colors.length].withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), 3 + rng.nextDouble() * 3, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
