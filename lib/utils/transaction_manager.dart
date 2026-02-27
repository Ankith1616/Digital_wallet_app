import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import '../models/transaction.dart';
import '../models/app_notification.dart';
import 'budget_manager.dart';
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

      // Trigger transaction notification
      _triggerTransactionNotification(uid, transaction);

      // Check budget alerts
      if (!transaction.isPositive) {
        _checkBudgetAlerts(uid, transaction);
      }
    }
  }

  void _triggerTransactionNotification(String uid, Transaction transaction) {
    String title = transaction.isPositive
        ? "Cashback Received! 💰"
        : "Payment Successful! ✅";
    String message = transaction.isPositive
        ? "You've earned ₹${transaction.amount.toStringAsFixed(2)} cashback on ${transaction.title}."
        : "You've successfully paid ₹${transaction.amount.toStringAsFixed(2)} to ${transaction.title}.";
    NotificationType type = transaction.isPositive
        ? NotificationType.cashback
        : NotificationType.payment;

    FirestoreService().addNotification(
      uid,
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        date: DateTime.now(),
        type: type,
      ),
    );
  }

  void _checkBudgetAlerts(String uid, Transaction transaction) {
    final budgetManager = BudgetManager();
    if (!budgetManager.hasData) return;

    final budget = budgetManager.budgetData!;
    final category = transaction.category;
    final limit = budget.getLimitForCategory(category);
    if (limit <= 0) return;

    // Calculate total spent in this category for the current month
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final totalSpent =
        getCategorySpending(startOfMonth, endOfMonth)[category] ?? 0;
    final previousSpent = totalSpent - transaction.amount;

    final currentPercent = (totalSpent / limit) * 100;
    final previousPercent = (previousSpent / limit) * 100;

    // Check thresholds: 75%, 90%, 100%
    int? thresholdTriggered;
    if (currentPercent >= 100 && previousPercent < 100) {
      thresholdTriggered = 100;
    } else if (currentPercent >= 90 && previousPercent < 90) {
      thresholdTriggered = 90;
    } else if (currentPercent >= 75 && previousPercent < 75) {
      thresholdTriggered = 75;
    }

    if (thresholdTriggered != null) {
      String title = "Budget Alert: $thresholdTriggered% Reached! 📊";
      String message = thresholdTriggered == 100
          ? "You've reached your 100% limit for ${category.name} (₹${limit.toStringAsFixed(0)}). Avoid further spending."
          : "You've spent $thresholdTriggered% of your ${category.name} budget (₹${totalSpent.toStringAsFixed(0)} / ₹${limit.toStringAsFixed(0)}).";

      FirestoreService().addNotification(
        uid,
        AppNotification(
          id: "${DateTime.now().millisecondsSinceEpoch}_budget",
          title: title,
          message: message,
          date: DateTime.now(),
          type: NotificationType.budget,
        ),
      );
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

  double getMonthlyIncome(int month, int year) {
    return _transactions
        .where(
          (t) => t.isPositive && t.date.month == month && t.date.year == year,
        )
        .map((t) => t.amount)
        .sum;
  }

  double getMonthlyExpense(int month, int year) {
    return _transactions
        .where(
          (t) => !t.isPositive && t.date.month == month && t.date.year == year,
        )
        .map((t) => t.amount)
        .sum;
  }

  double getAverageMonthlyIncome() {
    if (_transactions.isEmpty) return 0;
    final groups = groupBy(
      _transactions.where((t) => t.isPositive),
      (t) => "${t.date.year}-${t.date.month}",
    );
    if (groups.isEmpty) return 0;
    final totals = groups.values.map((list) => list.map((t) => t.amount).sum);
    return totals.sum / totals.length;
  }

  double getAverageMonthlyExpense() {
    if (_transactions.isEmpty) return 0;
    final groups = groupBy(
      _transactions.where((t) => !t.isPositive),
      (t) => "${t.date.year}-${t.date.month}",
    );
    if (groups.isEmpty) return 0;
    final totals = groups.values.map((list) => list.map((t) => t.amount).sum);
    return totals.sum / totals.length;
  }
}
