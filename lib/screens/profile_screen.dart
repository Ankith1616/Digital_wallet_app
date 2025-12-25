import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'personal_info_screen.dart';
import 'bank_accounts_screen.dart';
import 'notifications_settings_screen.dart';
import 'privacy_security_screen.dart';
import 'wallet_screen.dart';
import 'theme_selection_screen.dart';

// Used for direct navigation (Push)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: const ProfileTab(isNested: false),
    );
  }
}

// Used in Bottom Navigation Tab
class ProfileTab extends StatelessWidget {
  final bool isNested;
  const ProfileTab({super.key, this.isNested = true});

  @override
  Widget build(BuildContext context) {
    // If nested in tabs, we might not want extra padding at top if the design flows well
    // But consistent padding is good.
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(
              height: isNested ? 0 : 10,
            ), // Use ternary instead of collection-if
            // Premium Profile Header
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6C63FF).withOpacity(0.5),
                        const Color(0xFF2D2D44).withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.5),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFF2D2D44),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                        // backgroundImage: NetworkImage("https://i.pravatar.cc/300"), // Optional: Real image
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Vamsidhar",
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF6C63FF).withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        "Gold Member",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF6C63FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Settings Sections
            _buildSectionHeader("Account"),
            _buildProfileItem(
              context,
              Icons.person_outline,
              "Personal Info",
              const PersonalInfoScreen(),
            ),
            _buildProfileItem(
              context,
              Icons.credit_card,
              "My Cards",
              const WalletScreen(),
            ),
            _buildProfileItem(
              context,
              Icons.account_balance,
              "Bank Accounts",
              const BankAccountsScreen(),
            ),

            const SizedBox(height: 20),
            _buildSectionHeader("Settings"),
            _buildProfileItem(
              context,
              Icons.notifications_outlined,
              "Notifications",
              const NotificationsSettingsScreen(),
            ),
            _buildProfileItem(
              context,
              Icons.lock_outline,
              "Privacy & Security",
              const PrivacySecurityScreen(),
            ),
            _buildProfileItem(
              context,
              Icons.language,
              "Language",
              null,
            ), // Placeholder
            _buildProfileItem(
              context,
              Icons.dark_mode_outlined,
              "Theme",
              const ThemeSelectionScreen(),
            ),

            const SizedBox(height: 20),
            // Logout
            Container(
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: Text(
                  "Logout",
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  // Ensure we don't pop if we can't
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            // Bottom cushioning for nav bar
            SizedBox(height: isNested ? 80 : 0),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget? destination,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).iconTheme.color, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
        onTap: () {
          if (destination != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Feature coming soon!")),
            );
          }
        },
      ),
    );
  }
}
