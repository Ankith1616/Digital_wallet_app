import 'package:flutter/material.dart';
import '../utils/icon_helper.dart';

class BankAccount {
  final String id;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final double balance;
  final IconData icon;
  final Color color;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    this.balance = 0.0,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'balance': balance,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.toARGB32(),
    };
  }

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
      id: map['id'] ?? '',
      bankName: map['bankName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      ifscCode: map['ifscCode'] ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      icon: IconHelper.getIcon(
        map['iconCodePoint'] as int? ?? Icons.account_balance.codePoint,
        map['iconFontFamily'] as String?,
      ),
      color: Color(map['colorValue'] as int? ?? Colors.blue.toARGB32()),
    );
  }
}
