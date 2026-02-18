import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';

// Service pages
import 'services/mobile_recharge_page.dart';
import 'services/dth_recharge_page.dart';
import 'services/broadband_page.dart';
import 'services/fastag_page.dart';
import 'services/electricity_page.dart';
import 'services/water_page.dart';
import 'services/piped_gas_page.dart';
import 'services/rent_page.dart';
import 'services/loan_emi_page.dart';
import 'services/insurance_page.dart';
import 'services/credit_card_bill_page.dart';
import 'services/mutual_funds_page.dart';
import 'services/flights_page.dart';
import 'services/train_page.dart';
import 'services/bus_page.dart';
import 'services/hotels_page.dart';

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
                      'page': const MobileRechargePage(),
                    },
                    {
                      'icon': Icons.tv,
                      'label': 'DTH',
                      'color': const Color(0xFFE91E63),
                      'page': const DthRechargePage(),
                    },
                    {
                      'icon': Icons.wifi,
                      'label': 'Broadband',
                      'color': const Color(0xFF7B1FA2),
                      'page': const BroadbandPage(),
                    },
                    {
                      'icon': Icons.directions_car,
                      'label': 'FASTag',
                      'color': const Color(0xFF00897B),
                      'page': const FastagPage(),
                    },
                  ], isDark),
                  const SizedBox(height: 24),
                  _serviceSection(context, "Utilities", [
                    {
                      'icon': Icons.lightbulb,
                      'label': 'Electricity',
                      'color': const Color(0xFFF39C12),
                      'page': const ElectricityPage(),
                    },
                    {
                      'icon': Icons.water_drop,
                      'label': 'Water',
                      'color': const Color(0xFF2196F3),
                      'page': const WaterPage(),
                    },
                    {
                      'icon': Icons.local_gas_station,
                      'label': 'Piped Gas',
                      'color': const Color(0xFFFF5722),
                      'page': const PipedGasPage(),
                    },
                    {
                      'icon': Icons.home,
                      'label': 'Rent',
                      'color': const Color(0xFF795548),
                      'page': const RentPage(),
                    },
                  ], isDark),
                  const SizedBox(height: 24),
                  _serviceSection(context, "Financial Services", [
                    {
                      'icon': Icons.account_balance,
                      'label': 'Loan EMI',
                      'color': const Color(0xFF5F259F),
                      'page': const LoanEmiPage(),
                    },
                    {
                      'icon': Icons.receipt_long,
                      'label': 'Insurance',
                      'color': const Color(0xFF009688),
                      'page': const InsurancePage(),
                    },
                    {
                      'icon': Icons.credit_card,
                      'label': 'Credit Card\nBill',
                      'color': const Color(0xFFC62828),
                      'page': const CreditCardBillPage(),
                    },
                    {
                      'icon': Icons.savings,
                      'label': 'Mutual\nFunds',
                      'color': const Color(0xFF4CAF50),
                      'page': const MutualFundsPage(),
                    },
                  ], isDark),
                  const SizedBox(height: 24),
                  _serviceSection(context, "Travel", [
                    {
                      'icon': Icons.flight,
                      'label': 'Flights',
                      'color': const Color(0xFF1565C0),
                      'page': const FlightsPage(),
                    },
                    {
                      'icon': Icons.train,
                      'label': 'Train',
                      'color': const Color(0xFFFF6F00),
                      'page': const TrainPage(),
                    },
                    {
                      'icon': Icons.directions_bus,
                      'label': 'Bus',
                      'color': const Color(0xFF2E7D32),
                      'page': const BusPage(),
                    },
                    {
                      'icon': Icons.hotel,
                      'label': 'Hotels',
                      'color': const Color(0xFF6A1B9A),
                      'page': const HotelsPage(),
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
              color: Theme.of(context).dividerColor.withValues(alpha: 0.06),
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
        if (svc['page'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => svc['page'] as Widget),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${svc['label']} — coming soon!")),
          );
        }
      },
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
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
