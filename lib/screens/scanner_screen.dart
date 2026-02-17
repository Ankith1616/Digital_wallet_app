import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';

class ScannerTab extends StatelessWidget {
  const ScannerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fake camera background
          Container(
            color: Colors.black,
            child: const Center(
              child: Text(
                "Camera Feed Active",
                style: TextStyle(color: Colors.white12, fontSize: 18),
              ),
            ),
          ),

          // Overlay with scanner
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

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Scan any QR code",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.image_outlined,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Flashlight
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: const Icon(
                      Icons.flashlight_on,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _quickAction(Icons.contacts, "Pay\nContacts"),
                      _quickAction(Icons.phone_android, "Pay Phone\nNumber"),
                      _quickAction(Icons.swap_horiz, "Self\nTransfer"),
                      _quickAction(Icons.account_balance, "Bank\nTransfer"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

// Custom QR Scanner Overlay
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

    // Corner brackets
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
