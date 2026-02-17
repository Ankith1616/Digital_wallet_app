import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';
import 'home_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final bool showAppBar;
  const TransactionHistoryScreen({super.key, this.showAppBar = true});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ["All", "Received", "Sent", "Bills"];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: widget.showAppBar
                  ? BoxDecoration(gradient: AppColors.headerGradient)
                  : null,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.showAppBar) ...[
                        Row(
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
                              "Transaction History",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          "History",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilterIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilterIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.darkCard : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _filters[index],
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Date section: Today
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                "Today",
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: const [
                  TransactionItem(
                    icon: Icons.movie_creation,
                    color: Colors.red,
                    title: "Netflix Subscription",
                    date: "12:30 PM",
                    amount: "-₹499",
                  ),
                  TransactionItem(
                    icon: Icons.fastfood,
                    color: Colors.orange,
                    title: "Zomato",
                    date: "10:15 AM",
                    amount: "-₹320",
                  ),
                ],
              ),
            ),
          ),

          // Date section: Yesterday
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                "Yesterday",
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: const [
                  TransactionItem(
                    icon: Icons.music_note,
                    color: Colors.green,
                    title: "Spotify Premium",
                    date: "2:15 PM",
                    amount: "-₹119",
                  ),
                  TransactionItem(
                    icon: Icons.arrow_downward,
                    color: Color(0xFF5F259F),
                    title: "Received from Mike",
                    date: "11:00 AM",
                    amount: "+₹5,000",
                    isPositive: true,
                  ),
                ],
              ),
            ),
          ),

          // Date section: Earlier
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                "Earlier this week",
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: const [
                  TransactionItem(
                    icon: Icons.shopping_cart,
                    color: Colors.orange,
                    title: "Amazon",
                    date: "Mon, 10:00 AM",
                    amount: "-₹1,299",
                  ),
                  TransactionItem(
                    icon: Icons.local_gas_station,
                    color: Colors.blueGrey,
                    title: "HP Fuel Station",
                    date: "Sun, 6:30 PM",
                    amount: "-₹2,500",
                  ),
                  TransactionItem(
                    icon: Icons.phone_android,
                    color: Color(0xFF5F259F),
                    title: "Mobile Recharge",
                    date: "Sat, 9:00 AM",
                    amount: "-₹599",
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
