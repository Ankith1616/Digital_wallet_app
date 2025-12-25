import 'dart:ui' as ui; // Needed for PathMetric if not directly exposed
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'send_money_screen.dart';
import 'request_money_screen.dart';
import 'wallet_screen.dart';
import 'more_services_screen.dart';
import 'transaction_history_screen.dart';
import 'add_card_screen.dart';

import 'profile_screen.dart';

// 1. DASHBOARD SCREEN
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  int _currentCardIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello,",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color:
                            Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.grey,
                      ),
                    ),
                    Text(
                      "Vamsidhar",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor, // Adaptive color
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF6C63FF),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2D2D44)
                          : Colors.grey[200],
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Credit Card Widget
            // Cards Section
            SizedBox(
              height: 240, // Match Card Height
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentCardIndex = index;
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: CreditCardWidget(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: CreditCardWidget(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: AddCardWidget(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Dot Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentCardIndex == index ? 20 : 8,
                  decoration: BoxDecoration(
                    color: _currentCardIndex == index
                        ? const Color(0xFF6C63FF)
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 30),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _actionButton(context, Icons.north_east, "Send", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SendMoneyScreen(),
                      ),
                    );
                  }),
                ),
                Expanded(
                  child: _actionButton(
                    context,
                    Icons.south_west,
                    "Request",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RequestMoneyScreen(),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _actionButton(
                    context,
                    Icons.account_balance_wallet,
                    "Check Balance",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WalletScreen(),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _actionButton(context, Icons.more_horiz, "More", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MoreServicesScreen(),
                      ),
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Recent Transactions header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Transactions",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionHistoryScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "View All",
                    style: TextStyle(color: Color(0xFF6C63FF)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Transaction List
            const TransactionItem(
              icon: Icons
                  .movie_creation, // Fallback as brand icon missing in package
              color: Colors.red,
              title: "Netflix Subscription",
              date: "Today, 12:30 PM",
              amount: "-₹499",
            ),
            const TransactionItem(
              icon: FontAwesomeIcons.spotify,
              color: Colors.green,
              title: "Spotify Premium",
              date: "Yesterday, 2:15 PM",
              amount: "-₹119",
            ),
            const TransactionItem(
              icon: Icons
                  .apple, // Replaced FontAwesomeIcons.apple (Icons.apple exists in standard set usually, if not we fall back to something else)
              color: Colors.grey,
              title: "Apple Services",
              date: "Jun 24, 9:00 AM",
              amount: "-₹99",
            ),
            const TransactionItem(
              icon: Icons.arrow_downward, // Replaced FontAwesomeIcons.arrowDown
              color: Color(0xFF6C63FF),
              title: "Received from Mike",
              date: "Jun 22, 4:30 PM",
              amount: "+₹5,000",
              isPositive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Theme.of(context).iconTheme.color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
} // End of _DashboardTabState

class CreditCardWidget extends StatelessWidget {
  const CreditCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 240, // Increased height
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E2E3E),
            Color(0xFF000000),
          ], // Sleek black card (Original)
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        // Shadow removed as per user request to fix "shades" issue
        image: const DecorationImage(
          image: NetworkImage(
            "https://www.transparenttextures.com/patterns/cubes.png",
          ), // Subtle texture
          opacity: 0.1,
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Bank Name and Tier
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E88E5), // SBI Blue
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 14, // Inner circle
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 5, // The keyhole slot
                            height: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SBI Card",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Text(
                        "Debit",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                "Platinum",
                style: GoogleFonts.playfairDisplay(
                  // Using a fancier font if available, or fallback
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Balance / Name with Rotated WiFi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "VAMSIDHAR M",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const RotatedBox(
                quarterTurns: 1, // Face right
                child: Icon(Icons.wifi, color: Colors.white54, size: 28),
              ),
            ],
          ),

          const Spacer(),

          // Bottom Row: Number, Expiry, Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "**** **** **** 3942",
                    style: GoogleFonts.sourceCodePro(
                      color: Colors.white,
                      fontSize: 18, // Increased size
                      fontWeight: FontWeight.bold, // Bolder
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "VALID THRU 12/26",
                    style: GoogleFonts.sourceCodePro(
                      color: Colors.white70,
                      fontSize: 12, // Increased size
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Icon(
                FontAwesomeIcons.ccVisa,
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Softer shadow
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(child: FaIcon(icon, color: color, size: 24)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    date,
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: GoogleFonts.poppins(
                color: isPositive
                    ? const Color(0xFF00BFA5)
                    : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. AI STATS SCREEN
class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              "AI Insights",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 50),
            Container(
              height: 250,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
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
                    makeGroupData(1, 5, const Color(0xFF6C63FF)),
                    makeGroupData(2, 8, Colors.redAccent),
                    makeGroupData(3, 6, const Color(0xFF00BFA5)),
                    makeGroupData(4, 10, const Color(0xFF6C63FF)),
                    makeGroupData(5, 7, Colors.orange),
                    makeGroupData(6, 4, const Color(0xFF6C63FF)),
                    makeGroupData(7, 9, const Color(0xFF00BFA5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Weekly Spending Analysis",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData makeGroupData(int x, double y, Color color) {
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
}

class AddCardWidget extends StatelessWidget {
  const AddCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddCardScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        height: 240, // Match Card Height
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D44).withOpacity(0.3),
          borderRadius: BorderRadius.circular(25),
        ),
        child: CustomPaint(
          painter: DottedBorderPainter(
            color: Colors.white24,
            strokeWidth: 2,
            gap: 5,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 10),
                Text(
                  "Add Card",
                  style: GoogleFonts.poppins(
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                        Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DottedBorderPainter({
    required this.color,
    this.strokeWidth = 2,
    this.gap = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(25),
        ),
      );

    // Simplified manual dot drawing
    Path metricPath = path;
    for (ui.PathMetric metric in metricPath.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        // Draw a dot
        // We want dots, so drawCircle is better than drawPath(rect)
        // Extract position
        final ui.Tangent? tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          canvas.drawCircle(
            tangent.position,
            strokeWidth / 2,
            paint..style = PaintingStyle.fill,
          );
        }
        distance += gap + strokeWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
