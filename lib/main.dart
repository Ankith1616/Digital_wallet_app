import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/budget_bot_screen.dart';
import 'utils/theme_manager.dart';
import 'utils/fcm_service.dart';
import 'utils/locale_manager.dart';
import 'utils/auth_manager.dart';
import 'utils/localization_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FcmService.registerBackgroundHandler();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocaleManager().init();
  await AuthService().init();
  runApp(const DigitalWalletApp());
}

class DigitalWalletApp extends StatelessWidget {
  const DigitalWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager().themeMode,
      builder: (context, mode, child) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LocaleManager().locale,
          builder: (context, locale, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Digital Wallet',
              theme: AppThemes.lightTheme,
              darkTheme: AppThemes.darkTheme,
              themeMode: mode,
              locale: locale,
              home: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasData) return const MainLayout();
                  return const LoginScreen();
                },
              ),
            );
          },
        );
      },
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  StreamSubscription? _widgetClickSubscription;

  final List<Widget> _pages = [
    const DashboardTab(),
    const StatsTab(),
    const ScannerTab(),
    const TransactionHistoryScreen(showAppBar: false),
    const ExpensyaChatbotScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      // Listen for taps on the home screen widget and switch to Insights tab
      _widgetClickSubscription = HomeWidget.widgetClicked.listen((uri) {
        if (mounted) setState(() => _currentIndex = 1);
      });
      // Also handle the initial launch URI (cold start from widget tap)
      HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
        if (uri != null && mounted) setState(() => _currentIndex = 1);
      });
    }
  }

  @override
  void dispose() {
    _widgetClickSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.primary.withOpacity(0.06)
                  : Colors.black.withOpacity(0.07),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.darkBorder.withOpacity(0.5)
                  : Colors.black.withOpacity(0.05),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, L10n.s('home'), 0),
                _buildNavItem(Icons.auto_graph_rounded, L10n.s('insights'), 1),
                _buildScanButton(),
                _buildNavItem(Icons.receipt_long_rounded, L10n.s('history'), 3),
                _buildNavItem(Icons.chat_bubble_rounded, L10n.s('chatbot'), 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final isDark = ThemeManager().themeMode.value == ThemeMode.dark;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: isSelected ? 76 : 58,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(isDark ? 0.15 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : const Color(0xFF4A5580),
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.spaceGrotesk(
                fontSize: isSelected ? 10 : 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? AppColors.primary : const Color(0xFF4A5580),
                letterSpacing: isSelected ? 0.2 : 0,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    final isSelected = _currentIndex == 2;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(isSelected ? 0.55 : 0.35),
              blurRadius: isSelected ? 20 : 12,
              spreadRadius: isSelected ? 2 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
