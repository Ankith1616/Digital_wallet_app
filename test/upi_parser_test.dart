import 'package:flutter_test/flutter_test.dart';

// Helper function copied from scanner_screen.dart logic for testing
String getPayeeName(String data) {
  try {
    final uri = Uri.parse(data);
    if (uri.scheme == 'upi') {
      // Extract PN (Payee Name)
      final pn = uri.queryParameters['pn'];
      if (pn != null && pn.isNotEmpty) {
        return Uri.decodeComponent(pn);
      }
      // Fallback to PA (Payee Address/VPA)
      final pa = uri.queryParameters['pa'];
      if (pa != null && pa.isNotEmpty) {
        return pa;
      }
    }
  } catch (_) {}
  return data;
}

void main() {
  group('UPI Parser Tests', () {
    test('Extracts name from pn parameter', () {
      const link = 'upi://pay?pa=7842795306@fam&pn=Revanthsai';
      expect(getPayeeName(link), 'Revanthsai');
    });

    test('Extracts name with encoded characters', () {
      const link = 'upi://pay?pa=test@upi&pn=John%20Doe';
      expect(getPayeeName(link), 'John Doe');
    });

    test('Falls back to pa if pn is missing', () {
      const link = 'upi://pay?pa=jack@oksbi';
      expect(getPayeeName(link), 'jack@oksbi');
    });

    test('Returns original data if not a UPI link', () {
      const data = 'https://google.com';
      expect(getPayeeName(data), 'https://google.com');
    });

    test('Returns original data for random text', () {
      const data = 'Hello World';
      expect(getPayeeName(data), 'Hello World');
    });
  });
}
