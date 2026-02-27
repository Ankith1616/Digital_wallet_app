import 'package:flutter/material.dart';
import '../models/transaction.dart';

class BudgetData {
  final double salary;
  final double rent;
  final double bills;
  final double savingsGoal;
  final DateTime updatedAt;
  final Map<TransactionCategory, double> categoryLimits;

  BudgetData({
    required this.salary,
    required this.rent,
    required this.bills,
    required this.savingsGoal,
    required this.updatedAt,
    this.categoryLimits = const {},
  });

  double get totalFixedCosts => rent + bills;
  double get disposableIncome => salary - totalFixedCosts - savingsGoal;
  double get dailyLimit => disposableIncome / 30;

  double getLimitForCategory(TransactionCategory category) {
    if (categoryLimits.containsKey(category)) return categoryLimits[category]!;
    // Default fallback limits if not specified
    switch (category) {
      case TransactionCategory.entertainment:
        return 3000;
      case TransactionCategory.food:
        return 5000;
      case TransactionCategory.shopping:
        return 7000;
      case TransactionCategory.bills:
        return bills;
      default:
        return 2000;
    }
  }
}

class BudgetManager extends ChangeNotifier {
  static final BudgetManager _instance = BudgetManager._internal();
  factory BudgetManager() => _instance;
  BudgetManager._internal();

  BudgetData? _budgetData;
  BudgetData? get budgetData => _budgetData;

  void updateBudget({
    required double salary,
    required double rent,
    required double bills,
    required double savingsGoal,
    Map<TransactionCategory, double>? categoryLimits,
  }) {
    _budgetData = BudgetData(
      salary: salary,
      rent: rent,
      bills: bills,
      savingsGoal: savingsGoal,
      updatedAt: DateTime.now(),
      categoryLimits: categoryLimits ?? _budgetData?.categoryLimits ?? {},
    );
    notifyListeners();
  }

  void setCategoryLimit(TransactionCategory category, double limit) {
    final existing = _budgetData;
    final updatedLimits = Map<TransactionCategory, double>.from(
      existing?.categoryLimits ?? {},
    )..[category] = limit;

    _budgetData = BudgetData(
      salary: existing?.salary ?? 0,
      rent: existing?.rent ?? 0,
      bills: existing?.bills ?? 0,
      savingsGoal: existing?.savingsGoal ?? 0,
      updatedAt: DateTime.now(),
      categoryLimits: updatedLimits,
    );
    notifyListeners();
  }

  bool get hasData => _budgetData != null;
}

