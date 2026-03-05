class NotificationPreferences {
  final bool transactionSuccess;
  final bool transactionFailed;
  final bool cashbackEarned;
  final bool rewardsOffers;
  final bool promotionalOffers;
  final bool securityAlerts;
  final bool pushNotifications;

  NotificationPreferences({
    this.transactionSuccess = true,
    this.transactionFailed = true,
    this.cashbackEarned = true,
    this.rewardsOffers = true,
    this.promotionalOffers = false,
    this.securityAlerts = true,
    this.pushNotifications = true,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      transactionSuccess: map['transactionSuccess'] ?? true,
      transactionFailed: map['transactionFailed'] ?? true,
      cashbackEarned: map['cashbackEarned'] ?? true,
      rewardsOffers: map['rewardsOffers'] ?? true,
      promotionalOffers: map['promotionalOffers'] ?? false,
      securityAlerts: map['securityAlerts'] ?? true,
      pushNotifications: map['pushNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transactionSuccess': transactionSuccess,
      'transactionFailed': transactionFailed,
      'cashbackEarned': cashbackEarned,
      'rewardsOffers': rewardsOffers,
      'promotionalOffers': promotionalOffers,
      'securityAlerts': securityAlerts,
      'pushNotifications': pushNotifications,
    };
  }

  NotificationPreferences copyWith({
    bool? transactionSuccess,
    bool? transactionFailed,
    bool? cashbackEarned,
    bool? rewardsOffers,
    bool? promotionalOffers,
    bool? securityAlerts,
    bool? pushNotifications,
  }) {
    return NotificationPreferences(
      transactionSuccess: transactionSuccess ?? this.transactionSuccess,
      transactionFailed: transactionFailed ?? this.transactionFailed,
      cashbackEarned: cashbackEarned ?? this.cashbackEarned,
      rewardsOffers: rewardsOffers ?? this.rewardsOffers,
      promotionalOffers: promotionalOffers ?? this.promotionalOffers,
      securityAlerts: securityAlerts ?? this.securityAlerts,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }
}
