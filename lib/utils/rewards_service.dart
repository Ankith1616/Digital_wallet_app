import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

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
    // Fetch current balance first
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
}
