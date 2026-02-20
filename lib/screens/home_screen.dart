import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';
import 'send_money_screen.dart';

import 'wallet_screen.dart';
import 'more_services_screen.dart';
import 'transaction_history_screen.dart';
import '../utils/transaction_manager.dart';
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

  final List<_BannerData> _banners = const [
    _BannerData(
      gradient: [Color(0xFF6C63FF), Color(0xFF4834DF)],
      icon: Icons.local_offer,
      title: '50% Cashback',
      subtitle: 'On your first UPI transaction!\nUse code: FIRST50',
    ),
    _BannerData(
      gradient: [Color(0xFF00B894), Color(0xFF00897B)],
      icon: Icons.people_alt,
      title: 'Refer & Earn ₹200',
      subtitle: 'Invite friends and earn rewards\nfor every referral!',
    ),
    _BannerData(
      gradient: [Color(0xFFE17055), Color(0xFFD63031)],
      icon: Icons.receipt_long,
      title: 'Pay Bills & Win',
      subtitle: 'Pay electricity, water & gas bills\nand win scratch cards!',
    ),
    _BannerData(
      gradient: [Color(0xFF0984E3), Color(0xFF6C5CE7)],
      icon: Icons.card_giftcard,
      title: 'Rewards Unlocked!',
      subtitle: 'You have 3 unclaimed rewards\nRedeem now →',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
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
                            onPressed: () {},
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
                            onPressed: () {},
                            icon: const Icon(
                              Icons.help_outline,
                              color: Colors.white,
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
                                    color: Colors.white.withValues(alpha: 0.2),
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
                              : Colors.grey.withValues(alpha: 0.3),
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
                        const Color(0xFF1565C0),
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
                        const Color(0xFF00897B),
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
                        const Color(0xFFEF6C00),
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
                  SingleChildScrollView(
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
                  ),

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
                          const Color(0xFF5F259F),
                          Icons.card_giftcard,
                        ),
                        _promoCard(
                          "5% Off Recharge",
                          "On mobile prepaid",
                          const Color(0xFF1565C0),
                          Icons.phone_android,
                        ),
                        _promoCard(
                          "Win Rewards",
                          "Pay & earn scratch cards",
                          const Color(0xFF00897B),
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
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
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

  Widget _contactBubble(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.15),
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

  Widget _buildServicesGrid(BuildContext context) {
    final services = [
      {
        'icon': Icons.phone_android,
        'label': 'Recharge',
        'color': const Color(0xFF5F259F),
      },
      {
        'icon': Icons.lightbulb,
        'label': 'Electricity',
        'color': const Color(0xFFF39C12),
      },
      {
        'icon': Icons.water_drop,
        'label': 'Water',
        'color': const Color(0xFF2196F3),
      },
      {'icon': Icons.tv, 'label': 'DTH', 'color': const Color(0xFFE91E63)},
      {
        'icon': Icons.directions_car,
        'label': 'FASTag',
        'color': const Color(0xFF00897B),
      },
      {
        'icon': Icons.wifi,
        'label': 'Broadband',
        'color': const Color(0xFF7B1FA2),
      },
      {
        'icon': Icons.local_gas_station,
        'label': 'Gas',
        'color': const Color(0xFFFF5722),
      },
      {'icon': Icons.more_horiz, 'label': 'More', 'color': Colors.grey},
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
                  color: color.withValues(alpha: 0.12),
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
          color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
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
class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(gradient: AppColors.headerGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Text(
                    "AI Insights",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                  ValueListenableBuilder<List<Transaction>>(
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

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _insightCard(
                                  "Total Spent",
                                  "₹${totalSpent.toStringAsFixed(0)}",
                                  Icons.trending_down,
                                  AppColors.error,
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _insightCard(
                                  "Total Received",
                                  "₹${totalReceived.toStringAsFixed(0)}",
                                  Icons.trending_up,
                                  AppColors.success,
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade400,
                                    Colors.purple.shade700,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withValues(alpha: 0.3),
                                    blurRadius: 8,
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
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Weekly Spending",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.08),
                      ),
                    ),
                    child: BarChart(
                      BarChartData(
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const style = TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                );
                                String text;
                                switch (value.toInt()) {
                                  case 1:
                                    text = 'Mon';
                                    break;
                                  case 2:
                                    text = 'Tue';
                                    break;
                                  case 3:
                                    text = 'Wed';
                                    break;
                                  case 4:
                                    text = 'Thu';
                                    break;
                                  case 5:
                                    text = 'Fri';
                                    break;
                                  case 6:
                                    text = 'Sat';
                                    break;
                                  case 7:
                                    text = 'Sun';
                                    break;
                                  default:
                                    text = '';
                                }
                                return Text(text, style: style);
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
                        barGroups: [
                          _barGroup(1, 5, AppColors.primary),
                          _barGroup(2, 8, AppColors.primaryLight),
                          _barGroup(3, 6, AppColors.accent),
                          _barGroup(4, 10, AppColors.primary),
                          _barGroup(5, 7, AppColors.warning),
                          _barGroup(6, 4, AppColors.primaryLight),
                          _barGroup(7, 9, AppColors.accent),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Spending by Category",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<List<Transaction>>(
                    valueListenable: TransactionManager().transactionsNotifier,
                    builder: (context, transactions, _) {
                      return _buildCategoryList(context, transactions);
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    List<Transaction> transactions,
  ) {
    final spending = TransactionManager().getCategorySpending(
      DateTime.now().subtract(const Duration(days: 30)),
      DateTime.now(),
    );

    if (spending.isEmpty) {
      return const Center(child: Text("No expenses yet"));
    }

    final total = spending.values.fold(0.0, (sum, val) => sum + val);

    return Column(
      children: spending.entries.map((entry) {
        final pct = total == 0 ? 0.0 : entry.value / total;
        Color color;
        switch (entry.key) {
          case TransactionCategory.food:
            color = Colors.green;
            break;
          case TransactionCategory.shopping:
            color = Colors.orange;
            break;
          case TransactionCategory.entertainment:
            color = Colors.red;
            break;
          case TransactionCategory.bills:
            color = AppColors.primary;
            break;
          default:
            color = Colors.blue;
        }

        return _categoryRow(
          context,
          entry.key.name.toUpperCase(),
          "₹${entry.value.toStringAsFixed(0)}",
          pct,
          color,
        );
      }).toList(),
    );
  }

  Widget _insightCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 12,
            color: Colors.black12,
          ),
        ),
      ],
    );
  }

  Widget _categoryRow(
    BuildContext context,
    String name,
    String amount,
    double pct,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
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
