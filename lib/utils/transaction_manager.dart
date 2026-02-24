import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import 'package:wallet_g/utils/widget_helper.dart';

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
    // Simple formatter, can use split_bill implementation for better date formatting if needed
    // For now keeping it simple as per original string based date
    // Note: In real app use DateFormat
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  String get formattedAmount {
    return '${isPositive ? "+ " : "- "}₹${amount.abs().toStringAsFixed(0)}';
  }
}

class TransactionManager extends ChangeNotifier {
  static final TransactionManager _instance = TransactionManager._internal();
  factory TransactionManager() => _instance;
  TransactionManager._internal();

  final List<Transaction> _transactions = [
    Transaction(
      id: '1',
      title: 'Netflix Subscription',
      date: DateTime.now(),
      amount: 199.0,
      isPositive: false,
      icon: Icons.movie_creation,
      color: Colors.red,
      details: 'Subscription',
      category: TransactionCategory.entertainment,
    ),
    Transaction(
      id: '2',
      title: 'Received from Vamsi',
      date: DateTime.now().subtract(const Duration(days: 1)),
      amount: 5000.0,
      isPositive: true,
      icon: Icons.person,
      color: Colors.green,
      details: 'Transfer',
      category: TransactionCategory.transfer,
    ),
    Transaction(
      id: '3',
      title: 'Electricity Bill',
      date: DateTime.now().subtract(const Duration(days: 3)),
      amount: 1250.0,
      isPositive: false,
      icon: Icons.lightbulb,
      color: Colors.orange,
      details: 'Utility',
      category: TransactionCategory.bills,
    ),
    Transaction(
      id: '4',
      title: 'Grocery Mart',
      date: DateTime.now().subtract(const Duration(days: 2)),
      amount: 850.0,
      isPositive: false,
      icon: Icons.shopping_basket,
      color: Colors.blue,
      details: 'Food',
      category: TransactionCategory.food,
    ),
  ];

  List<Transaction> get transactions => List.unmodifiable(_transactions);
  late final ValueNotifier<List<Transaction>> transactionsNotifier =
      ValueNotifier(_transactions);

  void addTransaction(Transaction transaction) {
    _transactions.insert(0, transaction);
    transactionsNotifier.value = List.from(_transactions);
    notifyListeners();

    // Update Home Widget text immediately
    WidgetHelper.updateWidgetSpending();

    // Sync to Firestore if user is logged in
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirestoreService().addTransaction(uid, transaction);
    }
  }

  /// Load transactions from Firestore and replace local cache
  Future<void> loadFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final remote = await FirestoreService().fetchTransactionsOnce(uid);
      if (remote.isNotEmpty) {
        _transactions
          ..clear()
          ..addAll(remote);
        transactionsNotifier.value = List.from(_transactions);
        notifyListeners();

        // Update widget with newly loaded data
        WidgetHelper.updateWidgetSpending();
      }
    } catch (_) {
      // Silently fall back to local data if Firestore fails
    }
  }

  // Calculate split amount
  double calculateSplit(double amount, int people) {
    if (people <= 0) return 0;
    return amount / people;
  }

  // Add a split transaction
  void addSplitTransaction(String title, double amount, int people) {
    // Adding separate incoming transactions for each person (simulated)
    // In real app, you would probably track "Pending Requests"
    addTransaction(
      Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        date: DateTime.now(),
        amount: amount,
        isPositive: true,
        icon: Icons.call_split,
        color: Colors.blue,
        details: 'Split (1/$people)',
        category: TransactionCategory.transfer,
      ),
    );
  }

  // Insights Logic
  double getTotalSpent(DateTime start, DateTime end) {
    return _transactions
        .where(
          (t) =>
              !t.isPositive && !t.date.isBefore(start) && !t.date.isAfter(end),
        )
        .map((t) => t.amount)
        .sum;
  }

  Map<TransactionCategory, double> getCategorySpending(
    DateTime start,
    DateTime end,
  ) {
    final Map<TransactionCategory, double> spending = {};

    final filtered = _transactions.where(
      (t) => !t.isPositive && t.date.isAfter(start) && t.date.isBefore(end),
    );

    for (var t in filtered) {
      spending[t.category] = (spending[t.category] ?? 0) + t.amount;
    }
    return spending;
  }
}
