import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/theme_manager.dart';
import '../utils/transaction_manager.dart';
import '../utils/auth_manager.dart';
import '../models/transaction.dart';
import '../utils/firestore_service.dart';
import '../widgets/payment_confirmation_sheet.dart';
import 'pin_screen.dart';
import '../widgets/payment_result_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/localization_helper.dart';
import '../utils/rewards_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ScannerTab — QR scanner with torch only (no gallery, no quick-action buttons)
// ─────────────────────────────────────────────────────────────────────────────
class ScannerTab extends StatefulWidget {
  const ScannerTab({super.key});

  @override
  State<ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<ScannerTab> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _hasScanned = true);
    _controller.stop();
    _showScanResult(barcode.rawValue!);
  }

  String _getPayeeName(String data) {
    try {
      final uri = Uri.parse(data);
      if (uri.scheme == 'upi') {
        final pn = uri.queryParameters['pn'];
        if (pn != null && pn.isNotEmpty) return Uri.decodeComponent(pn);
        final pa = uri.queryParameters['pa'];
        if (pa != null && pa.isNotEmpty) return pa;
      }
    } catch (_) {}
    return data;
  }

  void _showScanResult(String data) {
    final amountController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _getPayeeName(data);

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
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // QR success icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                L10n.s("qr_detected"),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),

              // Payee info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            L10n.s("paying_to"),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(ctx).textTheme.bodyLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Amount field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(ctx).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    prefixText: "₹ ",
                    prefixStyle: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    hintText: L10n.s("enter_amount"),
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 18,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Pay Now button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = amountController.text.trim();
                    final amountDouble = double.tryParse(amount);
                    if (amount.isEmpty ||
                        amountDouble == null ||
                        amountDouble <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            L10n.s("enter_valid_amount"),
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

                    // 1. Confirmation sheet
                    final confirmation = await PaymentConfirmationSheet.show(
                      ctx,
                      user.uid,
                      amountDouble,
                    );
                    if (confirmation == null) return;
                    if (!ctx.mounted) return;

                    // 2. Authentication
                    bool verified = false;
                    final auth = AuthService();
                    final selectedBank = confirmation.bankAccount;

                    if (confirmation.useInstantPay) {
                      if (auth.canProcessInstantPay(amountDouble)) {
                        verified = true;
                        await auth.recordInstantPayUsage(amountDouble);
                      } else {
                        if (ctx.mounted) Navigator.pop(ctx);
                        _showPaymentFailure('Instant Pay limit exceeded.');
                        return;
                      }
                    } else if (confirmation.useBiometric ||
                        auth.requiresBiometric(amountDouble)) {
                      verified = await auth.authenticateBiometrics();
                      if (!verified && ctx.mounted) {
                        // Fallback to PIN
                        final result = await Navigator.push(
                          ctx,
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
                      // Default: PIN
                      final result = await Navigator.push(
                        ctx,
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
                    if (!ctx.mounted) return;

                    // 3. Deduct balance
                    await FirestoreService().updateBankAccountBalance(
                      user.uid,
                      selectedBank.id,
                      -amountDouble,
                    );

                    // 4. Record transaction
                    TransactionManager().addTransaction(
                      Transaction(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: '${L10n.s("paid_to")} $name',
                        date: DateTime.now(),
                        amount: amountDouble,
                        isPositive: false,
                        icon: Icons.person,
                        color: AppColors.primary,
                        details: confirmation.applyRewards
                            ? L10n.s("rewards_applied")
                            : L10n.s("upi_payment"),
                      ),
                    );

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);

                    // 5. Award cashback & show result
                    await RewardsService().awardCashback(amountDouble);
                    _showPaymentSuccess(amountController.text, data);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    L10n.s("pay_now"),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Scan Again
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _resetScanner();
                },
                child: Text(
                  L10n.s("scan_again"),
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      if (_hasScanned) _resetScanner();
    });
  }

  void _showPaymentSuccess(String amount, String recipient) {
    PaymentResultDialog.show(
      context,
      success: true,
      title: L10n.s("payment_successful"),
      subtitle: L10n.s("transaction_completed"),
      amount: amount,
      recipient: recipient,
      onDone: () => _resetScanner(),
    );
  }

  void _showPaymentFailure(String reason) {
    PaymentResultDialog.show(
      context,
      success: false,
      title: 'Payment Failed',
      subtitle: reason,
      amount: '',
      recipient: '',
      onDone: () => _resetScanner(),
    );
  }

  void _resetScanner() {
    setState(() => _hasScanned = false);
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Live camera feed
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Overlay with scanner cutout
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: AppColors.primary,
                borderRadius: 16,
                borderLength: 32,
                borderWidth: 5,
                cutOutSize: 280,
              ),
            ),
          ),

          // Top bar — centered title only
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    L10n.s("scan_any_qr"),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Scanning hint text
          if (!_hasScanned)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 320),
                  Text(
                    L10n.s("point_camera_qr"),
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // Bottom — torch toggle only
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 50),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (context, state, child) {
                      final torchOn = state.torchState == TorchState.on;
                      return GestureDetector(
                        onTap: () => _controller.toggleTorch(),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: torchOn
                                ? AppColors.primary.withOpacity(0.35)
                                : Colors.white.withOpacity(0.15),
                          ),
                          child: Icon(
                            torchOn
                                ? Icons.flashlight_on
                                : Icons.flashlight_off,
                            color: torchOn
                                ? AppColors.primaryLight
                                : Colors.white,
                            size: 26,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Torch',
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 11,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom QR scanner overlay shape (semi-transparent overlay with a cutout)
// ─────────────────────────────────────────────────────────────────────────────
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderRadius = 10,
    this.borderLength = 30,
    this.borderWidth = 10,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRect(rect)
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(
          RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        ),
      ),
      backgroundPaint,
    );

    final double r = borderRadius;
    // Top Left
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cutOutRect.left,
        cutOutRect.top,
        cutOutRect.left + borderLength,
        cutOutRect.top + borderWidth,
        topLeft: Radius.circular(r),
      ),
      boxPaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cutOutRect.left,
        cutOutRect.top,
        cutOutRect.left + borderWidth,
        cutOutRect.top + borderLength,
        topLeft: Radius.circular(r),
      ),
      boxPaint,
    );
    // Top Right
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cutOutRect.right - borderLength,
        cutOutRect.top,
        cutOutRect.right,
        cutOutRect.top + borderWidth,
        topRight: Radius.circular(r),
      ),
      boxPaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cutOutRect.right - borderWidth,
        cutOutRect.top,
        cutOutRect.right,
        cutOutRect.top + borderLength,
        topRight: Radius.circular(r),
      ),
      boxPaint,
    );
    // Bottom Left
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cutOutRect.left,
        cutOutRect.bottom - borderWidth,
        cutOutRect.left + borderLength,
        cutOutRect.bottom,
        bottomLeft: Radius.circular(r),
      ),
      boxPaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cutOutRect.left,
        cutOutRect.bottom - borderLength,
        cutOutRect.left + borderWidth,
        cutOutRect.bottom,
        bottomLeft: Radius.circular(r),
      ),
      boxPaint,
    );
    // Bottom Right
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cutOutRect.right - borderLength,
        cutOutRect.bottom - borderWidth,
        cutOutRect.right,
        cutOutRect.bottom,
        bottomRight: Radius.circular(r),
      ),
      boxPaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cutOutRect.right - borderWidth,
        cutOutRect.bottom - borderLength,
        cutOutRect.right,
        cutOutRect.bottom,
        bottomRight: Radius.circular(r),
      ),
      boxPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
