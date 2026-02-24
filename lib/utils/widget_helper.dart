import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallet_g/utils/transaction_manager.dart';

class WidgetHelper {
  static const String appGroupId =
      'group.digitalwallet.widget'; // Change for iOS
  static const String androidWidgetName =
      'com.example.wallet_g.DigitalWalletWidget';

  /// Saves data to be consumed by the home widget
  static Future<void> updateWidgetData({
    required String title,
    required String message,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('widget_title', title);
      await HomeWidget.saveWidgetData<String>('widget_message', message);
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        qualifiedAndroidName: androidWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  /// Captures a widget as an image and saves it for the home widget
  static Future<String?> saveWidgetImage(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = '${directory.path}/widget_chart.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(pngBytes);

        // Save the path for the widget
        await HomeWidget.saveWidgetData<String>('widget_chart', imagePath);

        // Refresh the widget to show the new image
        await HomeWidget.updateWidget(
          name: androidWidgetName,
          androidName: androidWidgetName,
          qualifiedAndroidName: androidWidgetName,
        );

        return imagePath;
      }
    } catch (e) {
      debugPrint('Error saving widget image: $e');
    }
    return null;
  }

  /// Requests the OS to pin the widget to the home screen (Android only)
  static Future<void> requestPinWidget() async {
    try {
      // qualifiedAndroidName must match the fully-qualified receiver
      // class registered in AndroidManifest.xml
      await HomeWidget.requestPinWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        qualifiedAndroidName: androidWidgetName,
      );
    } catch (e) {
      debugPrint('Error pinning widget: $e');
      rethrow; // Let the caller handle the error UI
    }
  }

  /// Helper to update just the spending text on the widget
  /// Useful for immediate updates when transactions are added
  static Future<void> updateWidgetSpending() async {
    try {
      final txManager = TransactionManager();
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      final tomorrow = now.add(const Duration(days: 1));
      final monthlySpent = txManager.getTotalSpent(thisMonth, tomorrow);

      await updateWidgetData(
        title: 'Monthly Spending',
        message: '₹${monthlySpent.toInt()}',
      );
    } catch (e) {
      debugPrint('Error updating widget spending: $e');
    }
  }
}
