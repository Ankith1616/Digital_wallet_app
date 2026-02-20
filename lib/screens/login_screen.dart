import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../utils/theme_manager.dart';
import '../utils/auth_manager.dart';
import 'pin_screen.dart';
import '../widgets/interactive_scale.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(gradient: AppColors.headerGradient),
          ),

          // Decorative circles
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Digital Wallet",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Pay, Transfer & Manage",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Phone Number Field
                  _buildField(
                    Icons.phone_outlined,
                    "Mobile Number",
                    TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  // Password Field
                  _buildField(
                    Icons.lock_outline,
                    "Password",
                    TextInputType.visiblePassword,
                    obscure: true,
                  ),

                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        "Forgot Password?",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sign In Button
                  InteractiveScale(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MainLayout()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "Sign In",
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white24)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "OR",
                          style: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white24)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Social logins
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialButton(
                        context,
                        Icons.g_mobiledata,
                        "Google",
                        onTap: () {},
                      ),
                      const SizedBox(width: 20),
                      _socialButton(
                        context,
                        Icons.fingerprint,
                        "Biometric",
                        onTap: () => _handleBiometricLogin(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      InteractiveScale(
                        onTap: () {},
                        child: Text(
                          "Register",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    IconData icon,
    String hint,
    TextInputType type, {
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: TextField(
        keyboardType: type,
        obscureText: obscure,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white38),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.white30),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _socialButton(
    BuildContext context,
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return InteractiveScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBiometricLogin(BuildContext context) async {
    final auth = AuthService();
    // Check if user has enabled biometrics (or default to true for demo if available)
    bool authenticated = await auth.authenticateBiometrics();

    if (authenticated) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      }
    } else {
      // Fallback to PIN if biometric fails/unavailable
      if (context.mounted) {
        bool hasPin = await auth.hasPin();
        if (hasPin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Biometric failed. Please use PIN.")),
          );
          // Ideally show PIN dialog or navigate to PinScreen
          // For now, we can just show a message or redirect to PIN screen
          // In a real app, you might want a specific flow here.
          // Let's offer to login with PIN
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PinScreen(
                mode: PinMode.verify,
                onSuccess: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainLayout()),
                  );
                },
              ),
            ),
          );
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Biometric auth failed and no PIN set."),
              ),
            );
          }
        }
      }
    }
  }
}
