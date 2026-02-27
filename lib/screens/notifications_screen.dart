import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme_manager.dart';
import '../utils/firestore_service.dart';
import '../models/app_notification.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Notifications")),
        body: _buildEmptyState(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () =>
                FirestoreService().markAllNotificationsAsRead(user.uid),
            icon: const Icon(Icons.done_all, size: 18),
            label: Text("Read All", style: GoogleFonts.poppins(fontSize: 12)),
          ),
          IconButton(
            onPressed: () => _confirmClearAll(context, user.uid),
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: "Clear All",
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: FirestoreService().notificationsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _buildNotificationCard(context, item, isDark, user.uid);
            },
          );
        },
      ),
    );
  }

  void _confirmClearAll(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear All?", style: GoogleFonts.poppins()),
        content: Text(
          "This will delete all your notifications permanently.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              FirestoreService().clearAllNotifications(uid);
              Navigator.pop(context);
            },
            child: Text(
              "CLEAR ALL",
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
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
    AppNotification item,
    bool isDark,
    String uid,
  ) {
    // Basic time formatting
    final now = DateTime.now();
    final diff = now.difference(item.date);
    String timeStr;
    if (diff.inMinutes < 1) {
      timeStr = "Just now";
    } else if (diff.inMinutes < 60) {
      timeStr = "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      timeStr = "${diff.inHours}h ago";
    } else {
      timeStr = "${diff.inDays}d ago";
    }
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
              timeStr,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!item.isRead)
              IconButton(
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 20,
                ),
                onPressed: () =>
                    FirestoreService().markNotificationAsRead(uid, item.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red.withOpacity(0.7),
                size: 20,
              ),
              onPressed: () =>
                  FirestoreService().deleteNotification(uid, item.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        onTap: () {
          if (!item.isRead) {
            FirestoreService().markNotificationAsRead(uid, item.id);
          }
        },
      ),
    );
  }
}

// Deleted _NotificationItem class as it is replaced by AppNotification model
