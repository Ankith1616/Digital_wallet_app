import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/bank_account.dart';
import '../models/app_notification.dart';
import '../utils/icon_helper.dart';

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

  /// Update user profile data
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  // ─── Notifications ─────────────────────────────────────────────

  /// Add a notification to Firestore
  Future<void> addNotification(String uid, AppNotification notification) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());
  }

  /// Live stream of notifications for a user, newest first
  Stream<List<AppNotification>> notificationsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AppNotification.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String uid, String notificationId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String uid) async {
    final batch = _db.batch();
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Delete all notifications for a user
  Future<void> clearAllNotifications(String uid) async {
    final batch = _db.batch();
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Delete a specific notification
  Future<void> deleteNotification(String uid, String notificationId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();
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
              icon: IconHelper.getIcon(
                d['iconCodePoint'] as int,
                d['iconFontFamily'] as String,
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
        icon: IconHelper.getIcon(
          d['iconCodePoint'] as int,
          d['iconFontFamily'] as String,
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

  // ─── Bank Accounts ─────────────────────────────────────────────

  /// Link a new bank account
  Future<void> addBankAccount(String uid, BankAccount bank) async {
    // Check if any other bank accounts exist for this user
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('bank_accounts')
        .limit(1)
        .get();

    final bool isFirstAccount = snapshot.docs.isEmpty;
    final accountToSave = isFirstAccount
        ? bank.copyWith(isPrimary: true)
        : bank;

    await _db
        .collection('users')
        .doc(uid)
        .collection('bank_accounts')
        .doc(accountToSave.id)
        .set(accountToSave.toMap());

    // Trigger notification
    await addNotification(
      uid,
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "Bank Account Added 🏦",
        message:
            "${bank.bankName} account (****${bank.accountNumber.substring(bank.accountNumber.length - 4)}) has been linked.",
        date: DateTime.now(),
        type: NotificationType.security,
      ),
    );
  }

  /// Live stream of linked bank accounts
  Stream<List<BankAccount>> linkedBanksStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('bank_accounts')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => BankAccount.fromMap(doc.data())).toList(),
        );
  }

  /// Update the balance of a specific linked bank account
  Future<void> updateBankAccountBalance(
    String uid,
    String bankId,
    double delta,
  ) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('bank_accounts')
        .doc(bankId)
        .update({'balance': FieldValue.increment(delta)});
  }

  /// Delete a specific linked bank account
  Future<void> deleteBankAccount(String uid, String bankId) async {
    // Fetch bank info before deleting for the notification
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('bank_accounts')
        .doc(bankId)
        .get();

    final bankData = doc.data();

    await _db
        .collection('users')
        .doc(uid)
        .collection('bank_accounts')
        .doc(bankId)
        .delete();

    if (bankData != null) {
      final bankName = bankData['bankName'] ?? 'Bank Account';
      final accNum = bankData['accountNumber'] as String? ?? '';
      final lastFour = accNum.length > 4
          ? accNum.substring(accNum.length - 4)
          : '';

      // Trigger notification
      await addNotification(
        uid,
        AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: "Bank Account Removed ⚠️",
          message:
              "$bankName (****$lastFour) has been unlinked from your wallet.",
          date: DateTime.now(),
          type: NotificationType.security,
        ),
      );
    }
  }

  /// Set a specific bank account as the primary one
  Future<void> setPrimaryBankAccount(String uid, String bankId) async {
    final batch = _db.batch();
    final collectionRef = _db
        .collection('users')
        .doc(uid)
        .collection('bank_accounts');

    // Fetch all current bank accounts to unset any existing primary flags
    final querySnapshot = await collectionRef.get();

    for (var doc in querySnapshot.docs) {
      if (doc.id == bankId) {
        batch.update(doc.reference, {'isPrimary': true});
      } else if (doc.data()['isPrimary'] == true) {
        batch.update(doc.reference, {'isPrimary': false});
      }
    }

    await batch.commit();
  }

  /// Update the transaction PIN for a specific bank account
  Future<void> updateBankAccountPin(
    String uid,
    String bankId,
    String newPinHash,
  ) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('bank_accounts')
        .doc(bankId)
        .update({'pinHash': newPinHash});

    // Trigger notification
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('bank_accounts')
        .doc(bankId)
        .get();
    final bankData = doc.data();
    if (bankData != null) {
      final bankName = bankData['bankName'] ?? 'Bank Account';
      final accNum = bankData['accountNumber'] as String? ?? '';
      final lastFour = accNum.length > 4
          ? accNum.substring(accNum.length - 4)
          : '';

      await addNotification(
        uid,
        AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: "Bank PIN Updated 🔐",
          message:
              "Transaction PIN for $bankName (****$lastFour) has been updated.",
          date: DateTime.now(),
          type: NotificationType.security,
        ),
      );
    }
  }
}
