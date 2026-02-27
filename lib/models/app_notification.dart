import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { budget, security, payment, cashback }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final NotificationType type;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'date': Timestamp.fromDate(date),
      'type': type.name,
      'isRead': isRead,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.payment,
      ),
      isRead: map['isRead'] ?? false,
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.budget:
        return Icons.pie_chart;
      case NotificationType.security:
        return Icons.security;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.cashback:
        return Icons.account_balance_wallet;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.budget:
        return Colors.orange;
      case NotificationType.security:
        return Colors.blue;
      case NotificationType.payment:
        return Colors.purple;
      case NotificationType.cashback:
        return Colors.green;
    }
  }
}
