import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';
import 'pin_screen.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _biometricLogin = true;
  bool _twoFactorAuth = false;
  bool _screenLock = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Privacy & Security",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Change Password
            _actionTile(
              context,
              Icons.lock_outline,
              "Change Password",
              "Update your account password",
              isDark,
              () => _showChangePasswordDialog(context, isDark),
            ),
            const SizedBox(height: 10),
            _actionTile(
              context,
              Icons.pin,
              "Change Transaction PIN",
              "Update your transaction PIN",
              isDark,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PinScreen(mode: PinMode.change),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "SECURITY OPTIONS",
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            _toggleTile(
              Icons.fingerprint,
              "Biometric Login",
              "Login with fingerprint or face",
              _biometricLogin,
              (v) => setState(() => _biometricLogin = v),
              isDark,
            ),
            const SizedBox(height: 10),
            _toggleTile(
              Icons.verified_user,
              "Two-Factor Auth",
              "Extra layer of security",
              _twoFactorAuth,
              (v) => setState(() => _twoFactorAuth = v),
              isDark,
            ),
            const SizedBox(height: 10),
            _toggleTile(
              Icons.screen_lock_portrait,
              "App Lock",
              "Lock app when switching",
              _screenLock,
              (v) => setState(() => _screenLock = v),
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, bool isDark) {
    final oldPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Change Password",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              _dialogField(
                ctx,
                "Current Password",
                oldPwdCtrl,
                isDark,
                obscure: true,
              ),
              const SizedBox(height: 12),
              _dialogField(
                ctx,
                "New Password",
                newPwdCtrl,
                isDark,
                obscure: true,
              ),
              const SizedBox(height: 12),
              _dialogField(
                ctx,
                "Confirm Password",
                confirmPwdCtrl,
                isDark,
                obscure: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Password changed successfully!"),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Update Password",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _dialogField(
    BuildContext context,
    String hint,
    TextEditingController controller,
    bool isDark, {
    bool obscure = false,
    bool isNumber = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.06),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _toggleTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.06),
        ),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
