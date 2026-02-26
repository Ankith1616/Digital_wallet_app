import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';
import '../widgets/interactive_scale.dart';

class OffersRewardsScreen extends StatelessWidget {
  const OffersRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with gradient
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(gradient: AppColors.headerGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Offers & Rewards",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader("Your Rewards"),
                  const SizedBox(height: 12),
                  _buildScratchCards(),
                  const SizedBox(height: 24),
                  _sectionHeader("Trending Offers"),
                  const SizedBox(height: 12),
                  _buildOfferList(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildScratchCards() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _scratchCard(const Color(0xFF6C63FF), "UPI Reward"),
          _scratchCard(const Color(0xFF00E5A0), "Merchant Pay"),
          _scratchCard(const Color(0xFFFF6584), "Bill Payment"),
        ],
      ),
    );
  }

  Widget _scratchCard(Color color, String label) {
    return InteractiveScale(
      onTap: () {}, // Handled by visual feedback for now
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard, color: color, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.stars, color: color.withOpacity(0.5), size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferList(bool isDark) {
    final offers = [
      {
        'title': 'Domino\'s Pizza',
        'subtitle': 'Flat 40% OFF on all orders',
        'code': 'OFFER40',
        'color': Colors.redAccent,
        'icon': Icons.local_pizza,
      },
      {
        'title': 'Amazon Pay',
        'subtitle': '₹50 Cashback on utility bills',
        'code': 'BILL50',
        'color': Colors.orangeAccent,
        'icon': Icons.flash_on,
      },
      {
        'title': 'MakeMyTrip',
        'subtitle': '₹1000 OFF on international flights',
        'code': 'MMTWORLD',
        'color': Colors.blueAccent,
        'icon': Icons.flight,
      },
    ];

    return Column(children: offers.map((o) => _offerItem(o, isDark)).toList());
  }

  Widget _offerItem(Map<String, dynamic> o, bool isDark) {
    final color = o['color'] as Color;
    return InteractiveScale(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A3D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(o['icon'] as IconData, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    o['title'] as String,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    o['subtitle'] as String,
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade300,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Text(
                      "CODE: ${o['code']}",
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }
}
