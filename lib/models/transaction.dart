import 'package:flutter/material.dart';

enum TransactionCategory {
  transfer,
  food,
  shopping,
  bills,
  entertainment,
  transport,
  health,
  other,
}

class Transaction {
  final String id;
  final String title;
  final DateTime date;
  final double amount;
  final bool isPositive;
  final IconData icon;
  final Color color;
  final String details;
  final TransactionCategory category;

  Transaction({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.isPositive,
    required this.icon,
    required this.color,
    this.details = '',
    this.category = TransactionCategory.other,
  });

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  String get formattedAmount {
    return '${isPositive ? "+ " : "- "}₹${amount.abs().toStringAsFixed(0)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'amount': amount,
      'isPositive': isPositive,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.toARGB32(),
      'details': details,
      'category': category.name,
    };
  }
}

