import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<_NotificationItem> notifications = [
      _NotificationItem(
        title: "Cashback Received! 💰",
        message: "You've earned ₹50 cashback on your last recharge.",
        time: "2 mins ago",
        icon: Icons.account_balance_wallet,
        color: Colors.green,
        isRead: false,
      ),
      _NotificationItem(
        title: "Security Alert 🛡️",
        message: "Your account was logged in from a new device (Windows).",
        time: "1 hour ago",
        icon: Icons.security,
        color: Colors.blue,
        isRead: false,
      ),
      _NotificationItem(
        title: "Bill Payment Reminder 📝",
        message: "Your Electricity bill of ₹2,450 is due in 3 days.",
        time: "5 hours ago",
        icon: Icons.receipt_long,
        color: Colors.orange,
        isRead: true,
      ),
      _NotificationItem(
        title: "Referral Bonus 🎁",
        message: "Your friend Rahul just joined! You both earned ₹100.",
        time: "Yesterday",
        icon: Icons.card_giftcard,
        color: Colors.purple,
        isRead: true,
      ),
      _NotificationItem(
        title: "System Update ⚙️",
        message: "Version 1.0.0 is now live with enhanced security.",
        time: "2 days ago",
        icon: Icons.system_update,
        color: Colors.grey,
        isRead: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _buildNotificationCard(context, item, isDark);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No notifications yet",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          Text(
            "Stay tuned for updates and alerts!",
            style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    _NotificationItem item,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: Theme.of(
            context,
          ).dividerColor.withOpacity(item.isRead ? 0.03 : 0.08),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            if (!item.isRead)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.title,
                style: GoogleFonts.poppins(
                  fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              item.time,
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            item.message,
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
        onTap: () {
          // Handle tap
        },
      ),
    );
  }
}

class _NotificationItem {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  final bool isRead;

  _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    required this.isRead,
  });
}
