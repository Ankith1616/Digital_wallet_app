import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import '../models/transaction.dart';
import 'widget_helper.dart';

class TransactionManager extends ChangeNotifier {
  static final TransactionManager _instance = TransactionManager._internal();
  factory TransactionManager() => _instance;
  TransactionManager._internal();

  final List<Transaction> _transactions = [];

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
