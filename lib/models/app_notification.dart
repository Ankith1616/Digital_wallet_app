import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  budget,
  security,
  paymentSuccess,
  paymentFailed,
  cashback,
  rewards,
  promo,
}

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
        orElse: () => NotificationType.paymentSuccess,
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
      case NotificationType.paymentSuccess:
        return Icons.check_circle_outline;
      case NotificationType.paymentFailed:
        return Icons.error_outline;
      case NotificationType.cashback:
        return Icons.card_giftcard_outlined;
      case NotificationType.rewards:
        return Icons.star_outline_rounded;
      case NotificationType.promo:
        return Icons.local_offer_outlined;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.budget:
        return Colors.orange;
      case NotificationType.security:
        return Colors.blue;
      case NotificationType.paymentSuccess:
        return Colors.green;
      case NotificationType.paymentFailed:
        return Colors.red;
      case NotificationType.cashback:
        return Colors.orange;
      case NotificationType.rewards:
        return Colors.blue;
      case NotificationType.promo:
        return Colors.purple;
    }
  }
}
