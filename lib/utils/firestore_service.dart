import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/material.dart';
import 'transaction_manager.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── User Profile ──────────────────────────────────────────────

  /// Create a new user document on sign-up
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'walletBalance': 10000.0, // starter balance
      'createdAt': FieldValue.serverTimestamp(),
      'fcmToken': '',
    });
  }

  /// Fetch the user profile document once
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Live stream of wallet balance
  Stream<double> walletBalanceStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map(
          (doc) => (doc.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0,
        );
  }

  /// Atomically update wallet balance (delta can be negative for debits)
  Future<void> updateWalletBalance(String uid, double delta) async {
    await _db.collection('users').doc(uid).update({
      'walletBalance': FieldValue.increment(delta),
    });
  }

  /// Save FCM token to user doc
  Future<void> saveFcmToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  // ─── Transactions ───────────────────────────────────────────────

  /// Write a transaction to Firestore
  Future<void> addTransaction(String uid, Transaction tx) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc(tx.id)
        .set({
          'id': tx.id,
          'title': tx.title,
          'amount': tx.amount,
          'isPositive': tx.isPositive,
          'details': tx.details,
          'category': tx.category.name,
          'iconCodePoint': tx.icon.codePoint,
          'iconFontFamily': tx.icon.fontFamily ?? 'MaterialIcons',
          'colorValue': tx.color.toARGB32(),
          'date': Timestamp.fromDate(tx.date),
        });
  }

  /// Live stream of all transactions for a user, newest first
  Stream<List<Transaction>> transactionsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final d = doc.data();
            return Transaction(
              id: d['id'] as String,
              title: d['title'] as String,
              date: (d['date'] as Timestamp).toDate(),
              amount: (d['amount'] as num).toDouble(),
              isPositive: d['isPositive'] as bool,
              icon: IconData(
                d['iconCodePoint'] as int,
                fontFamily: d['iconFontFamily'] as String,
              ),
              color: Color(d['colorValue'] as int),
              details: d['details'] as String? ?? '',
              category: TransactionCategory.values.firstWhere(
                (c) => c.name == d['category'],
                orElse: () => TransactionCategory.other,
              ),
            );
          }).toList(),
        );
  }

  /// Load transactions once (used for initial cache hydration)
  Future<List<Transaction>> fetchTransactionsOnce(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .limit(100)
        .get();

    return snap.docs.map((doc) {
      final d = doc.data();
      return Transaction(
        id: d['id'] as String,
        title: d['title'] as String,
        date: (d['date'] as Timestamp).toDate(),
        amount: (d['amount'] as num).toDouble(),
        isPositive: d['isPositive'] as bool,
        icon: IconData(
          d['iconCodePoint'] as int,
          fontFamily: d['iconFontFamily'] as String,
        ),
        color: Color(d['colorValue'] as int),
        details: d['details'] as String? ?? '',
        category: TransactionCategory.values.firstWhere(
          (c) => c.name == d['category'],
          orElse: () => TransactionCategory.other,
        ),
      );
    }).toList();
  }
}
