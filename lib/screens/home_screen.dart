import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/theme_manager.dart';
import 'send_money_screen.dart';
import 'wallet_screen.dart';
import 'more_services_screen.dart';
import 'transaction_history_screen.dart';
import '../utils/transaction_manager.dart';
import '../utils/budget_manager.dart';
import '../utils/widget_helper.dart';
import 'split_bill_screen.dart';
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
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white24,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hello, Vamsidhar 👋",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
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
                      const SizedBox(height: 24),
                      // Dynamic Balance Card
                      ValueListenableBuilder<List<Transaction>>(
                        valueListenable:
                            TransactionManager().transactionsNotifier,
                        builder: (context, transactions, _) {
                          final totalSpent = TransactionManager().getTotalSpent(
                            DateTime.now().subtract(const Duration(days: 30)),
                            DateTime.now(),
                          );
                          final balance =
                              12500.0 - totalSpent; // Mock initial balance
                          return Column(
                            children: [
                              Text(
                                "Total Balance",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "₹${balance.toStringAsFixed(0)}",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                  color: Colors.white.withValues(alpha: 0.6),
                                  size: 18,
                                ),
                              ],
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
                        Icons.account_balance,
                        "To Bank",
                        const Color(0xFF6EE9FF), // cyan light
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
                              builder: (_) => const WalletScreen(),
                            ),
                          );
                        },
                      ),
                      _circleAction(
                        context,
                        Icons.account_balance_wallet,
                        "Balance",
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
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _contactBubble("Alex", Colors.blueAccent),
            _contactBubble("Sam", Colors.orangeAccent),
            _contactBubble("Kate", AppColors.primary),
            _contactBubble("Mom", Colors.teal),
            _contactBubble("Dad", Colors.redAccent),
            _contactBubble("Mike", Colors.green),
          ],
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
    return Container(
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: ValueListenableBuilder<List<Transaction>>(
        valueListenable: TransactionManager().transactionsNotifier,
        builder: (context, transactions, _) {
          double totalSpent = 0;
          double totalReceived = 0;
          for (var t in transactions) {
            if (t.isPositive) {
              totalReceived += t.amount;
            } else {
              totalSpent += t.amount;
            }
          }

          final spending = TransactionManager().getCategorySpending(
            DateTime.now().subtract(const Duration(days: 30)),
            DateTime.now(),
          );

          final budget = BudgetManager().budgetData;
          final savingsGoal = budget?.savingsGoal ?? 0;
          final disposable =
              (budget?.salary ?? 0) -
              (budget?.rent ?? 0) -
              (budget?.bills ?? 0) -
              savingsGoal;
          final savedSoFar = totalReceived - totalSpent;

          final tip = _getDynamicTip(totalSpent, disposable, spending);

          return CustomScrollView(
            slivers: [
              // === HEADER ===
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(gradient: AppColors.headerGradient),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "AI Insights",
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Your spending summary for this month",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _summaryChip(
                                  "Spent",
                                  "₹${totalSpent.toInt()}",
                                  Colors.red,
                                  Icons.trending_down,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _summaryChip(
                                  "Received",
                                  "₹${totalReceived.toInt()}",
                                  Colors.green,
                                  Icons.trending_up,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _summaryChip(
                                  "Txns",
                                  "${transactions.length}",
                                  Colors.white70,
                                  Icons.swap_horiz,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // === AI TIP ===
                      _buildAITipCard(tip, isDark),
                      const SizedBox(height: 20),

                      // === WEEKLY BAR CHART ===
                      _sectionHeader("Weekly Spending", "Last 7 days"),
                      const SizedBox(height: 12),
                      _buildWeeklyBarChart(transactions, isDark),
                      const SizedBox(height: 24),

                      // === DONUT + LEGEND ===
                      _sectionHeader("Spending by Category", null),
                      const SizedBox(height: 12),
                      _buildDonutWithLegend(spending, isDark),
                      const SizedBox(height: 24),

                      // === CATEGORY PROGRESS BARS ===
                      _sectionHeader("Budget Limits", "This month"),
                      const SizedBox(height: 12),
                      _buildCategoryListWithLimits(context, transactions),
                      const SizedBox(height: 24),

                      // === SAVINGS GOAL ===
                      if (savingsGoal > 0) ...[
                        _sectionHeader("Savings Goal", null),
                        const SizedBox(height: 12),
                        _buildSavingsGoalCard(savingsGoal, savedSoFar, isDark),
                        const SizedBox(height: 24),
                      ],

                      // === BUDGET BOT BANNER ===
                      _buildBudgetBotBanner(context),
                      const SizedBox(height: 16),

                      // === HOME WIDGET ===
                      _buildWidgetPinCard(context, isDark),
                      const SizedBox(height: 16),

                      // === SPLIT EXPENSE ===
                      InteractiveScale(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SplitBillScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: AppColors.nebulaGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.call_split,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Split an Expense with Friends",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String? subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
          ),
      ],
    );
  }

  String _getDynamicTip(
    double spent,
    double disposable,
    Map<TransactionCategory, double> spending,
  ) {
    if (disposable > 0 && spent > disposable * 0.9) {
      return "⚠️ You're close to your monthly limit! Try to reduce discretionary spending.";
    }
    final topCat = spending.entries.isNotEmpty
        ? spending.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;
    if (topCat != null) {
      return "💡 Your biggest spend is ${topCat.key.name} (₹${topCat.value.toInt()}). Try setting a stricter limit there.";
    }
    return "✅ Great job tracking your expenses! Review your categories below.";
  }

  Widget _buildAITipCard(String tip, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4B45CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Saving Tip",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ─── Helper: category color ───────────────────────────────────────────────
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

  /// ─── Weekly Bar Chart (real data per day) ─────────────────────────────────
  Widget _buildWeeklyBarChart(List<Transaction> transactions, bool isDark) {
    // Build spending per weekday for the last 7 days
    final now = DateTime.now();
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<double> dailySpend = List.filled(7, 0);
    for (final t in transactions) {
      if (!t.isPositive) {
        final diff = now.difference(t.date).inDays;
        if (diff < 7) {
          final idx = t.date.weekday - 1; // Mon=0 … Sun=6
          dailySpend[idx] += t.amount;
        }
      }
    }
    final maxY = dailySpend.reduce((a, b) => a > b ? a : b);
    final chartMax = (maxY < 100 ? 1000.0 : maxY * 1.25);

    return RepaintBoundary(
      key: _chartKey,
      child: Container(
        height: 220,
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: BarChart(
          BarChartData(
            maxY: chartMax,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(
                color: Colors.grey.withValues(alpha: 0.15),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= 7) return const SizedBox();
                    return Text(
                      dayLabels[idx],
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            barGroups: List.generate(7, (i) {
              final colors = [
                AppColors.primary,
                AppColors.primaryLight,
                AppColors.accent,
                AppColors.primary,
                AppColors.warning,
                AppColors.primaryLight,
                AppColors.accent,
              ];
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: dailySpend[i] == 0 ? 10 : dailySpend[i],
                    color: colors[i],
                    width: 16,
                    borderRadius: BorderRadius.circular(6),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: chartMax,
                      color: Colors.grey.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  /// ─── Donut Chart + Legend ─────────────────────────────────────────────────
  Widget _buildDonutWithLegend(
    Map<TransactionCategory, double> spending,
    bool isDark,
  ) {
    if (spending.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            "No spending data yet",
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
      );
    }

    final total = spending.values.fold(0.0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 55,
                startDegreeOffset: -90,
                sections: spending.entries.map((entry) {
                  final pct = (entry.value / total * 100).toStringAsFixed(1);
                  return PieChartSectionData(
                    color: _catColor(entry.key),
                    value: entry.value,
                    title: '$pct%',
                    radius: 50,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: spending.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _catColor(entry.key),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.key.name[0].toUpperCase()}${entry.key.name.substring(1)} ₹${entry.value.toInt()}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// ─── Savings Goal Card ────────────────────────────────────────────────────
  Widget _buildSavingsGoalCard(double goal, double savedSoFar, bool isDark) {
    final progress = (savedSoFar / goal).clamp(0.0, 1.0);
    final pctText = '${(progress * 100).toStringAsFixed(0)}%';
    final isOnTrack = savedSoFar >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  Icon(
                    Icons.savings_outlined,
                    color: const Color(0xFF4CAF50),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Monthly Savings Goal",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
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
              backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
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

  /// ─── Category List with Budget Limits ─────────────────────────────────────
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
                            color: color.withValues(alpha: 0.12),
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
                  backgroundColor: color.withValues(alpha: 0.1),
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

  /// ─── Set Limit Dialog ──────────────────────────────────────────────────────
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
                      color: Colors.grey.withValues(alpha: 0.3),
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
                    fillColor: color.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: color.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: color.withValues(alpha: 0.3),
                      ),
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
                          side: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.4),
                          ),
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
              color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
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
                color: Colors.white.withValues(alpha: 0.2),
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
                      color: Colors.white.withValues(alpha: 0.8),
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
      // Push current spending data so the widget shows live numbers
      final txManager = TransactionManager();
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      final tomorrow = now.add(const Duration(days: 1));
      final monthlySpent = txManager.getTotalSpent(thisMonth, tomorrow);

      // Capture the latest chart image
      await _captureWidgetImage();

      await WidgetHelper.updateWidgetData(
        title: 'Monthly Spending',
        message: '₹${monthlySpent.toInt()}',
      );

      // Now open the OS pin-widget sheet
      await WidgetHelper.requestPinWidget();

      // Re-push data after the pin dialog resolves so the widget shows live
      // numbers immediately (closes the race where onUpdate runs before prefs
      // are committed on first pin).
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
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
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
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
