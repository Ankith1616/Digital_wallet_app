import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firestore_service.dart';
import '../models/transaction.dart';
import 'transaction_manager.dart';

/// Central service for calculating and managing cashback / rewards.
class RewardsService {
  static final RewardsService _instance = RewardsService._internal();
  factory RewardsService() => _instance;
  RewardsService._internal();

  /// Cashback rate: 1 % of transaction amount
  static const double _cashbackRate = 0.01;

  /// Maximum cashback per single transaction (₹50)
  static const double _maxPerTx = 50.0;

  /// Minimum transaction amount to earn cashback (₹10)
  static const double _minTxAmount = 10.0;

  /// Auto-apply threshold for Expensya Wallet
  static const double autoApplyThreshold = 20.0;

  // ─── Calculation ──────────────────────────────────────────────────

  /// Returns the cashback amount for a given transaction value.
  /// Returns 0 if amount is below minimum threshold.
  double calculateCashback(double txAmount) {
    if (txAmount < _minTxAmount) return 0.0;
    final cashback = txAmount * _cashbackRate;
    return cashback > _maxPerTx ? _maxPerTx : cashback;
  }

  // ─── Persistence ──────────────────────────────────────────────────

  /// Award cashback to the signed-in user for a completed transaction.
  /// Call this after every successful payment.
  Future<void> awardCashback(double txAmount) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final earned = calculateCashback(txAmount);
    if (earned <= 0) return;
    await FirestoreService().addCashback(uid, earned);
  }

  /// Redeem [amount] from the user's cashback balance.
  /// Returns the actual amount deducted (may be less if balance is insufficient).
  Future<double> redeemCashback(double amount) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0.0;
    final profile = await FirestoreService().getUserProfile(uid);
    final balance = (profile?['cashbackBalance'] as num?)?.toDouble() ?? 0.0;
    final deduct = amount > balance ? balance : amount;
    if (deduct <= 0) return 0.0;
    await FirestoreService().redeemRewards(uid, deduct);
    return deduct;
  }

  /// Fetch the current cashback balance for the signed-in user.
  Future<double> getCashbackBalance() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0.0;
    final profile = await FirestoreService().getUserProfile(uid);
    return (profile?['cashbackBalance'] as num?)?.toDouble() ?? 0.0;
  }

  // ─── Expensya Auto-Apply ──────────────────────────────────────────

  /// Auto-apply cashback discount if Expensya Wallet is activated and
  /// balance ≥ ₹20. Returns the discount amount applied (0 if none).
  /// Call this after every successful payment.
  Future<double> autoApplyCashback() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0.0;

    // Check if wallet is activated
    final activated = await FirestoreService().isExpensyaActivated(uid);
    if (!activated) return 0.0;

    // Check balance
    final balance = await getCashbackBalance();
    if (balance < autoApplyThreshold) return 0.0;

    // Redeem ₹20
    final redeemed = await redeemCashback(autoApplyThreshold);
    if (redeemed <= 0) return 0.0;

    // Record as a transaction
    TransactionManager().addTransaction(
      Transaction(
        id: 'cashback_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Expensya Cashback Applied',
        date: DateTime.now(),
        amount: redeemed,
        isPositive: true,
        icon: Icons.redeem,
        color: const Color(0xFF00E5A0),
        details: 'Auto-applied from Expensya Wallet',
        category: TransactionCategory.other,
      ),
    );

    return redeemed;
  }
}
