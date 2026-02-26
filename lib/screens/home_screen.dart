import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/transaction.dart';
import '../utils/theme_manager.dart';
import 'send_money_screen.dart';
import 'self_transfer_screen.dart';
import 'setup_screen.dart';
import 'wallet_screen.dart';
import 'pin_screen.dart';
import 'more_services_screen.dart';
import 'transaction_history_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../utils/transaction_manager.dart';
import '../utils/budget_manager.dart';

import '../utils/widget_helper.dart';

import '../widgets/interactive_scale.dart';
import 'profile_screen.dart';
import 'services/mobile_recharge_page.dart';
import 'services/electricity_page.dart';
import 'services/water_page.dart';
import 'services/dth_recharge_page.dart';
import 'services/fastag_page.dart';
import 'services/broadband_page.dart';
import 'services/piped_gas_page.dart';
import 'notifications_screen.dart';
import 'help_support_screen.dart';
import 'budget_bot_screen.dart';
import 'offers_rewards_screen.dart';

// ============================================
// 1. DASHBOARD / HOME SCREEN (PhonePe style)
// ============================================
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // Banner carousel state
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  // Contacts state
  List<Contact> _contacts = [];
  bool _hasPermission = false;

  // Avatar colors
  final List<Color> _avatarColors = const [
    Color(0xFF6C63FF),
    Color(0xFFFF6584),
    Color(0xFF43C59E),
    Color(0xFFF7B731),
    Color(0xFF45AAF2),
    Color(0xFFFC5C65),
    Color(0xFF26DE81),
    Color(0xFFFD9644),
  ];

  final List<_BannerData> _banners = const [
    _BannerData(
      gradient: [Color(0xFF00D4FF), Color(0xFF0055FF)], // cyan → blue
      icon: Icons.local_offer,
      title: '50% Cashback',
      subtitle: 'On your first UPI transaction!\nUse code: FIRST50',
    ),
    _BannerData(
      gradient: [Color(0xFF00E5A0), Color(0xFF00897B)], // teal neon
      icon: Icons.people_alt,
      title: 'Refer & Earn ₹200',
      subtitle: 'Invite friends and earn rewards\nfor every referral!',
    ),
    _BannerData(
      gradient: [Color(0xFFFFD166), Color(0xFFFF8C42)], // gold → amber
      icon: Icons.receipt_long,
      title: 'Pay Bills & Win',
      subtitle: 'Pay electricity, water & gas bills\nand win scratch cards!',
    ),
    _BannerData(
      gradient: [Color(0xFF7B2FBE), Color(0xFF00D4FF)], // nebula purple → cyan
      icon: Icons.card_giftcard,
      title: 'Rewards Unlocked!',
      subtitle: 'You have 3 unclaimed rewards\nRedeem now →',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _checkContactsPermission();
  }

  Future<void> _checkContactsPermission() async {
    // Permission.contacts is not supported on web — skip entirely
    if (kIsWeb) return;

    final granted = await Permission.contacts.isGranted;
    if (granted) {
      try {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );
        if (mounted) {
          setState(() {
            _hasPermission = true;
            _contacts = contacts
                .where((c) => c.displayName.isNotEmpty)
                .take(10)
                .toList();
          });
        }
      } catch (e) {
        debugPrint('Error loading contacts on home: $e');
      }
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_currentBannerIndex + 1) % _banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Purple gradient header
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(gradient: AppColors.headerGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    children: [
                      // Top bar: profile, greeting, notification
                      Row(
                        children: [
                          InteractiveScale(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            ),
                            child: StreamBuilder<User?>(
                              stream: FirebaseAuth.instance.userChanges(),
                              builder: (context, snapshot) {
                                final photoUrl = snapshot.data?.photoURL;
                                return CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.white24,
                                  backgroundImage: photoUrl != null
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 22,
                                        )
                                      : null,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StreamBuilder<User?>(
                                  stream: FirebaseAuth.instance.userChanges(),
                                  builder: (context, snapshot) {
                                    final user = snapshot.data;
                                    final name =
                                        user?.displayName ??
                                        user?.email?.split('@').first ??
                                        'User';
                                    return Text(
                                      "Hello, $name 👋",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  "Welcome back!",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                            ),
                          ),
                          // Dark / Light mode toggle
                          ValueListenableBuilder<ThemeMode>(
                            valueListenable: ThemeManager().themeMode,
                            builder: (context, mode, _) {
                              final isDark = mode == ThemeMode.dark;
                              return IconButton(
                                onPressed: () {
                                  ThemeManager().toggleTheme(!isDark);
                                },
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, anim) =>
                                      RotationTransition(
                                        turns: anim,
                                        child: child,
                                      ),
                                  child: Icon(
                                    isDark ? Icons.light_mode : Icons.dark_mode,
                                    key: ValueKey(isDark),
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HelpSupportScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.help_outline,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // === PROMOTIONAL BANNER CAROUSEL ===
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  SizedBox(
                    height: 150,
                    child: PageView.builder(
                      controller: _bannerController,
                      itemCount: _banners.length,
                      onPageChanged: (index) {
                        setState(() => _currentBannerIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final banner = _banners[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: InteractiveScale(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OffersRewardsScreen(),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: banner.gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: banner.gradient.first.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        banner.icon,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            banner.title,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            banner.subtitle,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
                                              fontSize: 12,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_banners.length, (index) {
                      final isActive = index == _currentBannerIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // Body content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === MONEY TRANSFER SECTION ===
                  _sectionTitle("Money Transfer"),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _circleAction(
                        context,
                        Icons.phone_android,
                        "To Mobile",
                        AppColors.primary,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SendMoneyScreen(),
                            ),
                          );
                        },
                      ),
                      _circleAction(
                        context,
                        Icons.swap_horiz,
                        "To Self",
                        const Color(0xFF00E5A0), // teal neon
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SelfTransferScreen(),
                            ),
                          );
                        },
                      ),
                      _circleAction(
                        context,
                        Icons.settings_suggest_outlined,
                        "Setup",
                        const Color(0xFF6C63FF), // purple
                        () async {
                          final verified = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const PinScreen(mode: PinMode.verify),
                            ),
                          );

                          if (verified == true && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SetupScreen(),
                              ),
                            );
                          }
                        },
                      ),
                      _circleAction(
                        context,
                        Icons.account_balance_wallet,
                        "Check Balance",
                        const Color(0xFFFFD166), // gold
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WalletScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // === PEOPLE SECTION ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle("People"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SendMoneyScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "View All",
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildPeopleList(isDark),

                  const SizedBox(height: 24),

                  // === RECHARGE & BILLS ===
                  _sectionTitle("Recharge & Pay Bills"),
                  const SizedBox(height: 12),
                  _buildServicesGrid(context),

                  const SizedBox(height: 24),

                  // === PROMOTIONS ===
                  _sectionTitle("Offers & Rewards"),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _promoCard(
                          "Flat ₹100 Cashback",
                          "On first UPI payment",
                          const Color(0xFF00D4FF), // cyan
                          Icons.card_giftcard,
                        ),
                        _promoCard(
                          "5% Off Recharge",
                          "On mobile prepaid",
                          const Color(0xFF7B2FBE), // nebula purple
                          Icons.phone_android,
                        ),
                        _promoCard(
                          "Win Rewards",
                          "Pay & earn scratch cards",
                          const Color(0xFFFFD166), // gold
                          Icons.stars,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // === RECENT TRANSACTIONS ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle("Recent Transactions"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransactionHistoryScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "View All",
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<List<Transaction>>(
                    valueListenable: TransactionManager().transactionsNotifier,
                    builder: (context, transactions, _) {
                      if (transactions.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              "No recent transactions",
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: transactions.take(5).map((t) {
                          return TransactionItem(
                            icon: t.icon,
                            color: t.color,
                            title: t.title,
                            date: t.formattedDate,
                            amount: t.formattedAmount,
                            isPositive: t.isPositive,
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 80), // Bottom padding for nav bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget _circleAction(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        InteractiveScale(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildPeopleList(bool isDark) {
    if (!_hasPermission || _contacts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          _hasPermission ? "No contacts found" : "Permission required",
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _contacts.map((c) {
          final color =
              _avatarColors[c.displayName.codeUnitAt(0) % _avatarColors.length];
          return _contactBubble(c.displayName, color);
        }).toList(),
      ),
    );
  }

  Widget _contactBubble(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InteractiveScale(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SendMoneyScreen()),
          );
        },
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withOpacity(0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 60,
              child: Text(
                name.split(' ').first,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    final services = [
      {
        'icon': Icons.phone_android,
        'label': 'Recharge',
        'color': AppColors.primary, // electric cyan
      },
      {
        'icon': Icons.lightbulb,
        'label': 'Electricity',
        'color': const Color(0xFFFFD166), // gold
      },
      {
        'icon': Icons.water_drop,
        'label': 'Water',
        'color': const Color(0xFF6EE9FF), // light cyan
      },
      {
        'icon': Icons.tv,
        'label': 'DTH',
        'color': const Color(0xFFFF4F6D),
      }, // coral rose
      {
        'icon': Icons.directions_car,
        'label': 'FASTag',
        'color': const Color(0xFF00E5A0), // teal neon
      },
      {
        'icon': Icons.wifi,
        'label': 'Broadband',
        'color': const Color(0xFF7B2FBE), // nebula purple
      },
      {
        'icon': Icons.local_gas_station,
        'label': 'Gas',
        'color': const Color(0xFFFF8C42), // amber
      },
      {
        'icon': Icons.more_horiz,
        'label': 'More',
        'color': const Color(0xFF4A5580),
      },
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final svc = services[index];
        final color = svc['color'] as Color;
        return InteractiveScale(
          onTap: () {
            final label = svc['label'] as String;
            if (label == 'More') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MoreServicesScreen()),
              );
            } else if (label == 'Recharge') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MobileRechargePage()),
              );
            } else if (label == 'Electricity') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ElectricityPage()),
              );
            } else if (label == 'Water') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WaterPage()),
              );
            } else if (label == 'DTH') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DthRechargePage()),
              );
            } else if (label == 'FASTag') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FastagPage()),
              );
            } else if (label == 'Broadband') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BroadbandPage()),
              );
            } else if (label == 'Gas') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PipedGasPage()),
              );
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(svc['icon'] as IconData, color: color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                svc['label'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _promoCard(String title, String subtitle, Color color, IconData icon) {
    return InteractiveScale(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OffersRewardsScreen()),
      ),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 32),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// TRANSACTION ITEM WIDGET (Shared)
// ============================================
class TransactionItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String date;
  final String amount;
  final bool isPositive;

  const TransactionItem({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.date,
    required this.amount,
    this.isPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: FaIcon(icon, color: color, size: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              color: isPositive
                  ? AppColors.success
                  : Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// 2. AI STATS / INSIGHTS SCREEN
// ============================================
class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  final GlobalKey _chartKey = GlobalKey();
  bool _isPinning = false;
  String _selectedPeriod = 'Monthly';

  @override
  void initState() {
    super.initState();
    // Capture initial frame after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureWidgetImage();
    });

    // Automatically update graph image when data changes
    TransactionManager().transactionsNotifier.addListener(_onDataChange);
  }

  @override
  void dispose() {
    TransactionManager().transactionsNotifier.removeListener(_onDataChange);
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) {
      _captureWidgetImage();
    }
  }

  Future<void> _captureWidgetImage() async {
    try {
      // Small delay to ensure chart is fully rendered
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final path = await WidgetHelper.saveWidgetImage(_chartKey);
      if (path != null) {
        debugPrint('Widget image saved to: $path');
      }
    } catch (e) {
      debugPrint('Error capturing widget image: $e');
    }
  }

  List<Transaction> _getFilteredTransactions(
    List<Transaction> allTransactions,
  ) {
    final now = DateTime.now();
    DateTime start;

    switch (_selectedPeriod) {
      case 'Weekly':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'Monthly':
        start = now.subtract(const Duration(days: 30));
        break;
      case '6 Months':
        start = now.subtract(const Duration(days: 180));
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        break;
      default:
        start = now.subtract(const Duration(days: 30));
    }

    return allTransactions.where((t) => t.date.isAfter(start)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: ValueListenableBuilder<List<Transaction>>(
        valueListenable: TransactionManager().transactionsNotifier,
        builder: (context, allTransactions, _) {
          final transactions = _getFilteredTransactions(allTransactions);
          double totalSpent = 0;
          double totalReceived = 0;
          Set<String> uniquePayees = {};
          for (var t in transactions) {
            if (t.isPositive) {
              totalReceived += t.amount;
            } else {
              totalSpent += t.amount;
            }
            uniquePayees.add(t.title);
          }

          return CustomScrollView(
            slivers: [
              // === DASHBOARD HEADER ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Insights",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1B3B52),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showDownloadOptions,
                        icon: const Icon(Icons.description_outlined, size: 16),
                        label: Text(
                          "FULL REPORT",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5A0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // === AI TIP SECTION ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: _buildAITipSection(isDark),
                ),
              ),

              // === SAVINGS GOAL ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _buildSavingsGoalCard(5000, 3200, isDark),
                ),
              ),

              // === MAIN LINE CHART ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _buildMainLineChart(transactions, isDark),
                ),
              ),

              // === INFO GRID & BALANCE OVERVIEW ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side: 4 info cards
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _buildGridInfoCard(
                                      "This Month Income",
                                      "₹${totalReceived.toInt()}",
                                      "+ 38%",
                                      const Color(0xFF00E5A0).withOpacity(0.2),
                                      isDark,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildGridInfoCard(
                                      "Avg. Monthly Income",
                                      "₹11,466",
                                      null,
                                      isDark
                                          ? AppColors.darkCard
                                          : Colors.white,
                                      isDark,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildGridInfoCard(
                                      "This Month Expense",
                                      "₹${totalSpent.toInt()}",
                                      null,
                                      isDark
                                          ? AppColors.darkCard
                                          : Colors.white,
                                      isDark,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildGridInfoCard(
                                      "Avg. Monthly Expense",
                                      "₹6,545",
                                      null,
                                      isDark
                                          ? AppColors.darkCard
                                          : Colors.white,
                                      isDark,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Bottom: Balance Overview & Full Report
                      _buildBottomBalanceSection(
                        totalReceived - totalSpent,
                        totalReceived,
                        totalSpent,
                        isDark,
                      ),
                      const SizedBox(height: 30),
                      // Category Budget Limits
                      Row(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF1B3B52),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Category Budget Limits",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1B3B52),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryListWithLimits(context, transactions),
                    ],
                  ),
                ),
              ),
              // === BUDGET BOT BANNER ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  child: _buildBudgetBotBanner(context),
                ),
              ),

              // === WIDGET PINNING ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: _buildWidgetPinCard(context, isDark),
                ),
              ),

              SliverToBoxAdapter(child: const SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generatePdf(DateTime start, DateTime end) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E2C)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const CircularProgressIndicator(color: Color(0xFF00E5A0)),
        ),
      ),
    );

    try {
      final allTransactions = TransactionManager().transactions;
      final filtered = allTransactions.where((t) {
        return t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(end.add(const Duration(days: 1)));
      }).toList();

      if (filtered.isEmpty) {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No transactions found for the selected period"),
            ),
          );
        }
        return;
      }

      final pdf = pw.Document();
      pw.Font? font;
      pw.Font? fontBold;

      try {
        font = await PdfGoogleFonts.spaceGroteskRegular();
        fontBold = await PdfGoogleFonts.spaceGroteskBold();
      } catch (e) {
        font = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                color: PdfColors.grey700,
                font: font,
                fontSize: 10,
              ),
            ),
          ),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Transaction Statement",
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 26,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Digital Wallet Analysis",
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    width: 60,
                    height: 60,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.teal,
                      shape: pw.BoxShape.circle,
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      "W",
                      style: pw.TextStyle(
                        font: fontBold,
                        color: PdfColors.white,
                        fontSize: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(
                color: PdfColors.teal50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Report Period:",
                    style: pw.TextStyle(font: fontBold, fontSize: 12),
                  ),
                  pw.Text(
                    "${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}",
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.TableHelper.fromTextArray(
              headers: ['DATE', 'TITLE', 'CATEGORY', 'AMOUNT'],
              data: filtered.map((t) {
                return [
                  DateFormat('dd/MM/yy').format(t.date),
                  t.title,
                  t.category.name.toUpperCase(),
                  t.formattedAmount,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                font: fontBold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              cellStyle: pw.TextStyle(font: font, fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FixedColumnWidth(80),
                1: const pw.FlexColumnWidth(),
                2: const pw.FixedColumnWidth(80),
                3: const pw.FixedColumnWidth(100),
              },
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerHeight: 30,
              cellPadding: const pw.EdgeInsets.all(8),
            ),
            pw.SizedBox(height: 40),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                "Thank you for using our Digital Wallet service!",
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context);

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Wallet_Statement_${DateFormat('ddMMyy').format(start)}.pdf',
      );
    } catch (e) {
      debugPrint("PDF Generation Error: $e");
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not generate report: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showDownloadOptions() {
    DateTime start = DateTime.now().subtract(const Duration(days: 30));
    DateTime end = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Generate Statement",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Select the duration for your transaction report",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "FROM",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: start,
                              firstDate: DateTime(2020),
                              lastDate: end,
                            );
                            if (date != null) setModalState(() => start = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: Color(0xFF00E5A0),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  DateFormat('dd MMM yyyy').format(start),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TO",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: end,
                              firstDate: start,
                              lastDate: DateTime.now(),
                            );
                            if (date != null) setModalState(() => end = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: Color(0xFF00E5A0),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  DateFormat('dd MMM yyyy').format(end),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _generatePdf(start, end);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5A0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Download Statement",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodDropdown(bool isDark) {
    final periods = ['Weekly', 'Monthly', '6 Months', 'This Year'];

    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() => _selectedPeriod = value);
      },
      itemBuilder: (context) => periods.map((period) {
        return PopupMenuItem(
          value: period,
          child: Text(
            period,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF1B3B52),
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A3D) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedPeriod,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF1B3B52),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  List<String> _getChartLabels() {
    switch (_selectedPeriod) {
      case 'Weekly':
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 'Monthly':
        return ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
      case '6 Months':
        final now = DateTime.now();
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        List<String> lastSix = [];
        for (int i = 5; i >= 0; i--) {
          int monthIdx = (now.month - i - 1) % 12;
          if (monthIdx < 0) monthIdx += 12;
          lastSix.add(months[monthIdx]);
        }
        return lastSix;
      case 'This Year':
        return [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
      default:
        return [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
    }
  }

  List<FlSpot> _getChartSpots(List<Transaction> transactions, bool isIncome) {
    final labelsCount = _getChartLabels().length;
    final now = DateTime.now();
    List<double> values = List.filled(labelsCount, 0.0);

    for (var tx in transactions) {
      if (tx.isPositive != isIncome) continue;

      int index = -1;

      switch (_selectedPeriod) {
        case 'Weekly':
          // weekday is 1 (Mon) to 7 (Sun). Index 0 is Mon.
          index = tx.date.weekday - 1;
          break;
        case 'Monthly':
          // ['Week 1', 'Week 2', 'Week 3', 'Week 4']
          if (tx.date.day <= 7) {
            index = 0;
          } else if (tx.date.day <= 14) {
            index = 1;
          } else if (tx.date.day <= 21) {
            index = 2;
          } else {
            index = 3;
          }
          break;
        case '6 Months':
          // Index 0 is 5 months ago, index 5 is current month
          final monthDiff =
              (now.year - tx.date.year) * 12 + (now.month - tx.date.month);
          if (monthDiff >= 0 && monthDiff < 6) {
            index = 5 - monthDiff;
          }
          break;
        case 'This Year':
          // Jan is 0
          if (tx.date.year == now.year) {
            index = tx.date.month - 1;
          }
          break;
      }

      if (index >= 0 && index < labelsCount) {
        // Values in graph are usually shown in "K" (thousands) for readability if high,
        // but here we just use the raw amount or scale it if necessary.
        // The original dummy data used values around 5-22.
        // Let's use amount / 1000 to fit that scale, or just raw amount if it's small.
        values[index] += tx.amount / 1000;
      }
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < labelsCount; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }
    return spots;
  }

  Widget _buildMainLineChart(List<Transaction> transactions, bool isDark) {
    final labels = _getChartLabels();
    return RepaintBoundary(
      key: _chartKey,
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _chartLegendItem("Income", const Color(0xFF00E5A0)),
                const SizedBox(width: 20),
                _chartLegendItem("Expense", const Color(0xFF6EE9FF)),
                const Spacer(),
                _buildPeriodDropdown(isDark),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          "${value.toInt()}K",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < labels.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 10,
                              child: Text(
                                labels[value.toInt()],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  minX: 0,
                  maxX: (labels.length - 1).toDouble(),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getChartSpots(transactions, true),
                      isCurved: true,
                      color: const Color(0xFF00E5A0),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF00E5A0).withOpacity(0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: _getChartSpots(transactions, false),
                      isCurved: true,
                      color: const Color(0xFF6EE9FF),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF6EE9FF).withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGridInfoCard(
    String label,
    String value,
    String? trend,
    Color bgColor,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDark ? Colors.white70 : const Color(0xFF1B3B52),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1B3B52),
                      ),
                    ),
                  ),
                ),
                if (trend != null) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_upward,
                    size: 12,
                    color: Color(0xFF00E5A0),
                  ),
                  Flexible(
                    child: Text(
                      trend,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF00E5A0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBalanceSection(
    double balance,
    double income,
    double expense,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFF1B3B52),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Balance Overview",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₹${balance.toInt()}",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _balanceRow(
                      "Income",
                      "₹${income.toInt()}",
                      const Color(0xFF00E5A0),
                    ),
                    const SizedBox(height: 8),
                    _balanceRow(
                      "Expense",
                      "₹${expense.toInt()}",
                      const Color(0xFF6EE9FF),
                    ),
                  ],
                ),
              ),
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10, width: 8),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: 0.67,
                          strokeWidth: 8,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF00E5A0),
                          ),
                        ),
                      ),
                      Text(
                        "67%",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.arrow_upward,
                size: 14,
                color: Color(0xFF00E5A0),
              ),
              const SizedBox(width: 4),
              Text(
                "36% vs last month",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _balanceRow(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Color _catColor(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food:
        return const Color(0xFF4CAF50);
      case TransactionCategory.shopping:
        return const Color(0xFFFF9800);
      case TransactionCategory.entertainment:
        return const Color(0xFFE91E63);
      case TransactionCategory.bills:
        return const Color(0xFF6C63FF);
      case TransactionCategory.transport:
        return const Color(0xFF00BCD4);
      case TransactionCategory.health:
        return const Color(0xFF8BC34A);
      default:
        return const Color(0xFF90A4AE);
    }
  }

  Widget _buildSavingsGoalCard(double goal, double savedSoFar, bool isDark) {
    final progress = (savedSoFar / goal).clamp(0.0, 1.0);
    final pctText = '${(progress * 100).toStringAsFixed(0)}%';
    final isOnTrack = savedSoFar >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.savings_outlined,
                    color: Color(0xFF4CAF50),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Monthly Savings Goal",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1B3B52),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isOnTrack
                      ? const Color(0xFF4CAF50).withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOnTrack ? "On track" : "Over budget",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isOnTrack ? const Color(0xFF4CAF50) : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "₹${savedSoFar.toInt()} saved",
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
              ),
              Text(
                "Goal: ₹${goal.toInt()}",
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? Colors.amber : const Color(0xFF4CAF50),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$pctText of savings goal reached",
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryListWithLimits(
    BuildContext context,
    List<Transaction> transactions,
  ) {
    final spending = TransactionManager().getCategorySpending(
      DateTime.now().subtract(const Duration(days: 30)),
      DateTime.now(),
    );

    if (spending.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "No category data yet",
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
      );
    }

    final budget = BudgetManager().budgetData;

    return Column(
      children: spending.entries.map((entry) {
        final limit = budget?.getLimitForCategory(entry.key) ?? 3000.0;
        final progress = (entry.value / limit).clamp(0.0, 1.0);
        final color = _catColor(entry.key);
        final isOver = progress > 0.9;
        final catName =
            entry.key.name[0].toUpperCase() + entry.key.name.substring(1);

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        catName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        "₹${entry.value.toInt()}",
                        style: GoogleFonts.poppins(
                          color: isOver ? Colors.red : color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        " / ₹${limit.toInt()}",
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _showSetLimitDialog(
                          context,
                          entry.key,
                          catName,
                          limit,
                          color,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(
                    isOver ? Colors.red : color,
                  ),
                ),
              ),
              if (isOver)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "⚠️ Budget limit reached!",
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.red),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showSetLimitDialog(
    BuildContext context,
    TransactionCategory category,
    String catName,
    double currentLimit,
    Color color,
  ) {
    final controller = TextEditingController(
      text: currentLimit.toInt().toString(),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Set $catName Limit",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Max you want to spend on $catName per month.",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                // Amount field
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  decoration: InputDecoration(
                    prefixText: "₹  ",
                    prefixStyle: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    hintText: "0",
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 22,
                      color: Colors.grey.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: color.withOpacity(0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: color.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: color.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: color, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Cancel / Save
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final newLimit = double.tryParse(
                            controller.text.trim(),
                          );
                          if (newLimit != null && newLimit > 0) {
                            BudgetManager().setCategoryLimit(
                              category,
                              newLimit,
                            );
                            Navigator.pop(sheetCtx);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "$catName limit set to ₹${newLimit.toInt()}",
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: color,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Save Limit",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAITipSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
              : [const Color(0xFFE0F7FA), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5A0).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Color(0xFF00E5A0),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Financial Tip",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1B3B52),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "You spent 15% less on dining this week. Save that ₹1,200 to reach your goal faster!",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetBotBanner(BuildContext context) {
    return InteractiveScale(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BudgetBotScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF4B45CC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/Expensya.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Budget Assistant",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Chat with Expensya to plan your month",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Future<void> _pinWidget() async {
    if (!mounted) return;
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Home Widget pinning is only available on Android.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isPinning = true);
    try {
      final txManager = TransactionManager();
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      final tomorrow = now.add(const Duration(days: 1));
      final monthlySpent = txManager.getTotalSpent(thisMonth, tomorrow);

      await _captureWidgetImage();

      await WidgetHelper.updateWidgetData(
        title: 'Monthly Spending',
        message: '₹${monthlySpent.toInt()}',
      );

      await WidgetHelper.requestPinWidget();

      await WidgetHelper.updateWidgetData(
        title: 'Monthly Spending',
        message: '₹${monthlySpent.toInt()}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tap "Add" on the dialog to pin the widget!',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF6C63FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not pin widget: $e',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPinning = false);
    }
  }

  Widget _buildWidgetPinCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.widgets_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Home Widget",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1B3B52),
                  ),
                ),
                Text(
                  "Pin your spending chart to the home screen",
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _isPinning ? null : _pinWidget,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: _isPinning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF6C63FF)),
                    ),
                  )
                : Text(
                    "Pin",
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Banner data model
class _BannerData {
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;

  const _BannerData({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
