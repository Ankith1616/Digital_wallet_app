import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/bank_account.dart';
import '../models/app_notification.dart' as model;
import '../models/notification_preferences.dart';
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
    await _db.collection('users').doc(uid).update({'deviceToken': token});
  }

  /// Update user profile data
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  // ─── Notification Settings ─────────────────────────────────────

  /// Update notification preferences in Firestore
  Future<void> updateNotificationPreferences(
    String uid,
    NotificationPreferences prefs,
  ) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notificationPreferences')
        .set(prefs.toMap());
  }

  /// Fetch notification preferences from Firestore once
  Future<NotificationPreferences> getNotificationPreferences(String uid) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notificationPreferences')
        .get();

    if (!doc.exists) return NotificationPreferences();
    return NotificationPreferences.fromMap(doc.data()!);
  }

  /// Stream notification preferences from Firestore
  Stream<NotificationPreferences> notificationPreferencesStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notificationPreferences')
        .snapshots()
        .map((snap) {
          if (!snap.exists) return NotificationPreferences();
          return NotificationPreferences.fromMap(snap.data()!);
        });
  }

  // ─── Notifications ─────────────────────────────────────────────

  /// Add a notification to Firestore, respecting user preferences
  Future<void> addNotification(
    String uid,
    model.AppNotification notification,
  ) async {
    // Fetch preferences from Firestore
    final p = await getNotificationPreferences(uid);

    // 1. Check Master Push Toggle
    if (!p.pushNotifications) return;

    // 2. Check Category Preference
    bool categoryEnabled = true;
    switch (notification.type) {
      case model.NotificationType.paymentSuccess:
        categoryEnabled = p.transactionSuccess;
        break;
      case model.NotificationType.paymentFailed:
        categoryEnabled = p.transactionFailed;
        break;
      case model.NotificationType.cashback:
        categoryEnabled = p.cashbackEarned;
        break;
      case model.NotificationType.rewards:
        categoryEnabled = p.rewardsOffers;
        break;
      case model.NotificationType.promo:
        categoryEnabled = p.promotionalOffers;
        break;
      case model.NotificationType.security:
        categoryEnabled = p.securityAlerts;
        break;
      case model.NotificationType.budget:
        // Budget alerts are currently not in settings, default to master toggle
        categoryEnabled = true;
        break;
    }

    if (!categoryEnabled) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());
  }

  /// Live stream of notifications for a user, newest first
  Stream<List<model.AppNotification>> notificationsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => model.AppNotification.fromMap(doc.data()))
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
    final accountToSave = bank.copyWith(
      isPrimary: isFirstAccount ? true : bank.isPrimary,
      balance: 100000.0, // default starter balance for every new account
    );

    await _db
        .collection('users')
        .doc(uid)
        .collection('bank_accounts')
        .doc(accountToSave.id)
        .set(accountToSave.toMap());

    // Trigger notification
    await addNotification(
      uid,
      model.AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "Bank Account Added 🏦",
        message:
            "${bank.bankName} account (****${bank.accountNumber.substring(bank.accountNumber.length - 4)}) has been linked.",
        date: DateTime.now(),
        type: model.NotificationType.security,
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
        model.AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: "Bank Account Removed ⚠️",
          message:
              "$bankName (****$lastFour) has been unlinked from your wallet.",
          date: DateTime.now(),
          type: model.NotificationType.security,
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
        model.AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: "Bank PIN Updated 🔐",
          message:
              "Transaction PIN for $bankName (****$lastFour) has been updated.",
          date: DateTime.now(),
          type: model.NotificationType.security,
        ),
      );
    }
  }

  // ─── Rewards & Cashback ────────────────────────────────────────

  /// Live stream of the user's rewards data {cashbackBalance, totalEarned}
  Stream<Map<String, double>> rewardsStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data() ?? {};
      return {
        'cashbackBalance': (data['cashbackBalance'] as num?)?.toDouble() ?? 0.0,
        'totalEarned': (data['totalEarned'] as num?)?.toDouble() ?? 0.0,
      };
    });
  }

  /// Credit cashback to user (increments both cashbackBalance and totalEarned)
  Future<void> addCashback(String uid, double amount) async {
    if (amount <= 0) return;
    await _db.collection('users').doc(uid).set({
      'cashbackBalance': FieldValue.increment(amount),
      'totalEarned': FieldValue.increment(amount),
    }, SetOptions(merge: true));
  }

  /// Deduct [amount] from cashback balance (never goes below 0)
  Future<void> redeemRewards(String uid, double amount) async {
    if (amount <= 0) return;
    // Fetch current balance to guard against going negative
    final doc = await _db.collection('users').doc(uid).get();
    final current = (doc.data()?['cashbackBalance'] as num?)?.toDouble() ?? 0.0;
    final deduct = amount > current ? current : amount;
    if (deduct <= 0) return;
    await _db.collection('users').doc(uid).update({
      'cashbackBalance': FieldValue.increment(-deduct),
    });
  }

  // ─── Expensya Wallet Activation ──────────────────────────────────

  /// Set Expensya Wallet activation status
  Future<void> setExpensyaActivated(String uid, bool activated) async {
    await _db.collection('users').doc(uid).set({
      'expensyaActivated': activated,
    }, SetOptions(merge: true));
  }

  /// Check if Expensya Wallet is activated
  Future<bool> isExpensyaActivated(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return (doc.data()?['expensyaActivated'] as bool?) ?? false;
  }

  /// Fetch the user's primary bank account (falls back to first linked account)
  Future<BankAccount?> getPrimaryBankAccount(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('bank_accounts')
        .get();
    if (snap.docs.isEmpty) return null;
    final primaryDocs = snap.docs
        .where((d) => d.data()['isPrimary'] == true)
        .toList();
    final doc = primaryDocs.isNotEmpty ? primaryDocs.first : snap.docs.first;
    return BankAccount.fromMap(doc.data());
  }
}
