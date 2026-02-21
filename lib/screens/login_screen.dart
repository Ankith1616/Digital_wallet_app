import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme_manager.dart';
import '../utils/auth_manager.dart';
import '../utils/firebase_auth_service.dart';
import '../utils/fcm_service.dart';
import 'pin_screen.dart';
import '../widgets/interactive_scale.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sign In controllers
  final _signInEmailCtrl = TextEditingController();
  final _signInPasswordCtrl = TextEditingController();

  // Sign Up controllers
  final _signUpNameCtrl = TextEditingController();
  final _signUpEmailCtrl = TextEditingController();
  final _signUpPasswordCtrl = TextEditingController();

  bool _obscureSignIn = true;
  bool _obscureSignUp = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailCtrl.dispose();
    _signInPasswordCtrl.dispose();
    _signUpNameCtrl.dispose();
    _signUpEmailCtrl.dispose();
    _signUpPasswordCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.spaceGrotesk()),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.spaceGrotesk()),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    final email = _signInEmailCtrl.text.trim();
    final password = _signInPasswordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    setState(() => _loading = true);
    try {
      final credential = await FirebaseAuthService().signInWithEmail(
        email: email,
        password: password,
      );
      // Init FCM for this user
      if (credential.user != null) {
        await FcmService().init(uid: credential.user!.uid);
      }
      // StreamBuilder in main.dart will auto-navigate to MainLayout
    } on FirebaseAuthException catch (e) {
      _showError(FirebaseAuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSignUp() async {
    final name = _signUpNameCtrl.text.trim();
    final email = _signUpEmailCtrl.text.trim();
    final password = _signUpPasswordCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    setState(() => _loading = true);
    try {
      final credential = await FirebaseAuthService().signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );
      // Init FCM for this user
      if (credential.user != null) {
        await FcmService().init(uid: credential.user!.uid);
      }
      _showSuccess('Account created! Welcome, $name 🎉');
      // StreamBuilder in main.dart will auto-navigate to MainLayout
    } on FirebaseAuthException catch (e) {
      _showError(FirebaseAuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
                    'Digital Wallet',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Pay, Transfer & Manage',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.white54,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelStyle: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'Sign In'),
                        Tab(text: 'Sign Up'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab views
                  SizedBox(
                    height: 320,
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildSignInTab(), _buildSignUpTab()],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // OR divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white24)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white24)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Biometric button
                  _socialButton(
                    Icons.fingerprint,
                    'Continue with Biometrics',
                    onTap: () => _handleBiometricLogin(),
                  ),
                ],
              ),
            ),
          ),

          // Full-screen loading overlay
          if (_loading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSignInTab() {
    return Column(
      children: [
        _buildField(
          controller: _signInEmailCtrl,
          icon: Icons.email_outlined,
          hint: 'Email Address',
          type: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _signInPasswordCtrl,
          icon: Icons.lock_outline,
          hint: 'Password',
          type: TextInputType.visiblePassword,
          obscure: _obscureSignIn,
          onToggleObscure: () =>
              setState(() => _obscureSignIn = !_obscureSignIn),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _handleForgotPassword,
            child: Text(
              'Forgot Password?',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _primaryButton('Sign In', _handleSignIn),
      ],
    );
  }

  Widget _buildSignUpTab() {
    return Column(
      children: [
        _buildField(
          controller: _signUpNameCtrl,
          icon: Icons.person_outline_rounded,
          hint: 'Full Name',
          type: TextInputType.name,
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _signUpEmailCtrl,
          icon: Icons.email_outlined,
          hint: 'Email Address',
          type: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _signUpPasswordCtrl,
          icon: Icons.lock_outline,
          hint: 'Password (min. 6 chars)',
          type: TextInputType.visiblePassword,
          obscure: _obscureSignUp,
          onToggleObscure: () =>
              setState(() => _obscureSignUp = !_obscureSignUp),
        ),
        const SizedBox(height: 20),
        _primaryButton('Create Account', _handleSignUp),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required TextInputType type,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        style: GoogleFonts.spaceGrotesk(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          suffixIcon: onToggleObscure != null
              ? IconButton(
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white38,
                    size: 20,
                  ),
                )
              : null,
          hintText: hint,
          hintStyle: GoogleFonts.spaceGrotesk(
            color: Colors.white30,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return InteractiveScale(
      onTap: onTap,
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
            label,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return InteractiveScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _signInEmailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('Enter your email above first.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSuccess('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      _showError(FirebaseAuthService.friendlyError(e));
    }
  }

  Future<void> _handleBiometricLogin() async {
    final auth = AuthService();
    final nav = Navigator.of(context);
    bool authenticated = await auth.authenticateBiometrics();
    if (authenticated) {
      // StreamBuilder in main.dart will auto-navigate to MainLayout
    } else {
      if (!mounted) return;
      bool hasPin = await auth.hasPin();
      if (hasPin) {
        nav.push(
          MaterialPageRoute(
            builder: (_) => PinScreen(
              mode: PinMode.verify,
              onSuccess: () {
                // StreamBuilder in main.dart will auto-navigate to MainLayout
              },
            ),
          ),
        );
      } else {
        _showError('Biometric auth failed and no PIN set.');
      }
    }
  }
}
