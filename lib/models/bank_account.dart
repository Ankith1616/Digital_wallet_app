import 'package:flutter/material.dart';
import '../utils/icon_helper.dart';

class BankAccount {
  final String id;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final double balance;
  final String pinHash;
  final bool isPrimary;
  final IconData icon;
  final Color color;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    this.balance = 0.0,
    required this.pinHash,
    this.isPrimary = false,
    required this.icon,
    required this.color,
  });

  BankAccount copyWith({
    String? id,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    double? balance,
    String? pinHash,
    bool? isPrimary,
    IconData? icon,
    Color? color,
  }) {
    return BankAccount(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      balance: balance ?? this.balance,
      pinHash: pinHash ?? this.pinHash,
      isPrimary: isPrimary ?? this.isPrimary,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'balance': balance,
      'pinHash': pinHash,
      'isPrimary': isPrimary,
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
      pinHash: map['pinHash'] ?? '',
      isPrimary: map['isPrimary'] ?? false,
      icon: IconHelper.getIcon(
        map['iconCodePoint'] as int? ?? Icons.account_balance.codePoint,
        map['iconFontFamily'] as String?,
      ),
      color: Color(map['colorValue'] as int? ?? Colors.blue.toARGB32()),
    );
  }
}
