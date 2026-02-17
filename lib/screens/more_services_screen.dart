import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';

class MoreServicesScreen extends StatelessWidget {
  const MoreServicesScreen({super.key});

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
                        "All Services",
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _serviceSection(context, "Recharge", [
                    {
                      'icon': Icons.phone_android,
                      'label': 'Mobile\nRecharge',
                      'color': AppColors.primary,
                    },
                    {
                      'icon': Icons.tv,
                      'label': 'DTH',
                      'color': const Color(0xFFE91E63),
                    },
                    {
                      'icon': Icons.wifi,
                      'label': 'Broadband',
                      'color': const Color(0xFF7B1FA2),
                    },
                    {
                      'icon': Icons.directions_car,
                      'label': 'FASTag',
                      'color': const Color(0xFF00897B),
                    },
                  ], isDark),
                  const SizedBox(height: 24),
                  _serviceSection(context, "Utilities", [
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
                    {
                      'icon': Icons.local_gas_station,
                      'label': 'Piped Gas',
                      'color': const Color(0xFFFF5722),
                    },
                    {
                      'icon': Icons.home,
                      'label': 'Rent',
                      'color': const Color(0xFF795548),
                    },
                  ], isDark),
                  const SizedBox(height: 24),
                  _serviceSection(context, "Financial Services", [
                    {
                      'icon': Icons.account_balance,
                      'label': 'Loan EMI',
                      'color': const Color(0xFF5F259F),
                    },
                    {
                      'icon': Icons.receipt_long,
                      'label': 'Insurance',
                      'color': const Color(0xFF009688),
                    },
                    {
                      'icon': Icons.credit_card,
                      'label': 'Credit Card\nBill',
                      'color': const Color(0xFFC62828),
                    },
                    {
                      'icon': Icons.savings,
                      'label': 'Mutual\nFunds',
                      'color': const Color(0xFF4CAF50),
                    },
                  ], isDark),
                  const SizedBox(height: 24),
                  _serviceSection(context, "Travel", [
                    {
                      'icon': Icons.flight,
                      'label': 'Flights',
                      'color': const Color(0xFF1565C0),
                    },
                    {
                      'icon': Icons.train,
                      'label': 'Train',
                      'color': const Color(0xFFFF6F00),
                    },
                    {
                      'icon': Icons.directions_bus,
                      'label': 'Bus',
                      'color': const Color(0xFF2E7D32),
                    },
                    {
                      'icon': Icons.hotel,
                      'label': 'Hotels',
                      'color': const Color(0xFF6A1B9A),
                    },
                  ], isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceSection(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> items,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.06),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((svc) => _serviceItem(context, svc)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _serviceItem(BuildContext context, Map<String, dynamic> svc) {
    final color = svc['color'] as Color;
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${svc['label']} — coming soon!")),
        );
      },
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(svc['icon'] as IconData, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              svc['label'] as String,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
