import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';

class SendMoneyScreen extends StatelessWidget {
  const SendMoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Send Money",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey[500]),
                  hintText: "Name, phone, or UPI ID",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Contacts
            Text(
              "RECENT",
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _contactBubble(context, "Alex", Colors.blueAccent),
                  _contactBubble(context, "Sam", Colors.orangeAccent),
                  _contactBubble(context, "Kate", AppColors.primary),
                  _contactBubble(context, "Mom", Colors.teal),
                  _contactBubble(context, "Dad", Colors.redAccent),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // All Contacts
            Text(
              "ALL CONTACTS",
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _contactRow(context, "Alexander", "+91 98765 43210", isDark),
                  _contactRow(
                    context,
                    "Emily Johnson",
                    "+91 87654 32109",
                    isDark,
                  ),
                  _contactRow(
                    context,
                    "Michael Brown",
                    "+91 76543 21098",
                    isDark,
                  ),
                  _contactRow(
                    context,
                    "Sophia Davis",
                    "+91 65432 10987",
                    isDark,
                  ),
                  _contactRow(
                    context,
                    "Daniel Wilson",
                    "+91 54321 09876",
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactBubble(BuildContext context, String name, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.15),
            child: Text(
              name[0],
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(
    BuildContext context,
    String name,
    String phone,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.06),
        ),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            name[0],
            style: GoogleFonts.poppins(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          phone,
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Pay $name — feature coming soon!")),
          );
        },
      ),
    );
  }
}
