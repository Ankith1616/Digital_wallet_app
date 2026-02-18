import 'package:flutter/material.dart';

class Transaction {
  final String id;
  final String title;
  final String date;
  final String amount;
  final bool isPositive;
  final IconData icon;
  final Color color;
  final String details; // e.g., "Food", "Bill", "Split"

  Transaction({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.isPositive,
    required this.icon,
    required this.color,
    this.details = '',
  });
}

class TransactionManager {
  static final TransactionManager _instance = TransactionManager._internal();
  factory TransactionManager() => _instance;
  TransactionManager._internal();

  final ValueNotifier<List<Transaction>> transactionsNotifier = ValueNotifier([
    Transaction(
      id: '1',
      title: 'Netflix Subscription',
      date: 'Today, 10:30 AM',
      amount: '- ₹199',
      isPositive: false,
      icon: Icons.movie_creation,
      color: Colors.red,
      details: 'Subscription',
    ),
    Transaction(
      id: '2',
      title: 'Received from Vamsi',
      date: 'Yesterday, 8:45 PM',
      amount: '+ ₹5,000',
      isPositive: true,
      icon: Icons.person,
      color: Colors.green,
      details: 'Transfer',
    ),
    Transaction(
      id: '3',
      title: 'Electricity Bill',
      date: '15 Feb, 1:20 PM',
      amount: '- ₹1,250',
      isPositive: false,
      icon: Icons.lightbulb,
      color: Colors.orange,
      details: 'Utility',
    ),
  ]);

  void addTransaction(Transaction transaction) {
    // Add to the beginning of the list
    final currentList = List<Transaction>.from(transactionsNotifier.value);
    currentList.insert(0, transaction);
    transactionsNotifier.value = currentList;
  }

  // Calculate split amount
  double calculateSplit(double amount, int people) {
    if (people <= 0) return 0;
    return amount / people;
  }

  // Add a split transaction (e.g., received split share)
  void addSplitTransaction(String title, double amount) {
    addTransaction(
      Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        date: 'Just Now',
        amount: '+ ₹${amount.toStringAsFixed(2)}',
        isPositive: true,
        icon: Icons.call_split,
        color: Colors.blue,
        details: 'Split',
      ),
    );
  }
}
