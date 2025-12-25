import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart'; // Reuse TransactionItem

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ["All", "Received", "Sent"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "History",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isSelected = _selectedFilterIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilterIndex = index),
                  child: Chip(
                    backgroundColor: isSelected
                        ? const Color(0xFF6C63FF)
                        : Theme.of(context).cardColor,
                    label: Text(
                      _filters[index],
                      style: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Transaction List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                TransactionItem(
                  icon: Icons.movie_creation,
                  color: Colors.red,
                  title: "Netflix Subscription",
                  date: "Today, 12:30 PM",
                  amount: "-₹499",
                ),
                TransactionItem(
                  icon: Icons.music_note,
                  color: Colors.green,
                  title: "Spotify Premium",
                  date: "Yesterday, 2:15 PM",
                  amount: "-₹119",
                ),
                TransactionItem(
                  icon: Icons.apple,
                  color: Colors.grey,
                  title: "Apple Services",
                  date: "Jun 24, 9:00 AM",
                  amount: "-₹99",
                ),
                TransactionItem(
                  icon: Icons.arrow_downward,
                  color: Color(0xFF6C63FF),
                  title: "Received from Mike",
                  date: "Jun 22, 4:30 PM",
                  amount: "+₹5,000",
                  isPositive: true,
                ),
                TransactionItem(
                  icon: Icons.shopping_cart,
                  color: Colors.orange,
                  title: "Amazon",
                  date: "Jun 20, 10:00 AM",
                  amount: "-₹1,299",
                ),
                TransactionItem(
                  icon: Icons.fastfood,
                  color: Colors.redAccent,
                  title: "Zomato",
                  date: "Jun 19, 8:45 PM",
                  amount: "-₹450",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
