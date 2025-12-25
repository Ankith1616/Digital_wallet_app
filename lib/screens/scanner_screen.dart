import 'package:flutter/material.dart';

class ScannerTab extends StatelessWidget {
  const ScannerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Camera background simulation
      body: Stack(
        children: [
          // 1. Fake Camera View (Placeholder Text)
          const Center(
            child: Text(
              "Camera Feed Active",
              style: TextStyle(color: Colors.white24, fontSize: 20),
            ),
          ),

          // 2. The Overlay (Dark background with transparent cutout)
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: const Color(0xFF6C63FF),
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),

          // 3. Instruction Text
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  "Align QR Code within frame",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 20),
                // Flashlight Button
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    icon: const Icon(Icons.flashlight_on, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for the QR cutout effect
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
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return Path()
      ..addRect(rect)
      ..addRect(
        Rect.fromCenter(
          center: rect.center,
          width: cutOutSize,
          height: cutOutSize,
        ),
      );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    // Draw background with cutout
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

    // Draw Corners (Simulated)
    // Top Left
    canvas.drawRect(
      Rect.fromLTWH(cutOutRect.left, cutOutRect.top, borderLength, borderWidth),
      boxPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(cutOutRect.left, cutOutRect.top, borderWidth, borderLength),
      boxPaint,
    );
    // Top Right
    canvas.drawRect(
      Rect.fromLTWH(
        cutOutRect.right - borderLength,
        cutOutRect.top,
        borderLength,
        borderWidth,
      ),
      boxPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        cutOutRect.right - borderWidth,
        cutOutRect.top,
        borderWidth,
        borderLength,
      ),
      boxPaint,
    );
    // Bottom Left
    canvas.drawRect(
      Rect.fromLTWH(
        cutOutRect.left,
        cutOutRect.bottom - borderWidth,
        borderLength,
        borderWidth,
      ),
      boxPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        cutOutRect.left,
        cutOutRect.bottom - borderLength,
        borderWidth,
        borderLength,
      ),
      boxPaint,
    );
    // Bottom Right
    canvas.drawRect(
      Rect.fromLTWH(
        cutOutRect.right - borderLength,
        cutOutRect.bottom - borderWidth,
        borderLength,
        borderWidth,
      ),
      boxPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        cutOutRect.right - borderWidth,
        cutOutRect.bottom - borderLength,
        borderWidth,
        borderLength,
      ),
      boxPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
