import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MoreServicesScreen extends StatelessWidget {
  const MoreServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {'icon': Icons.phone_android, 'label': 'Recharge'},
      {'icon': Icons.lightbulb, 'label': 'Electricity'},
      {'icon': Icons.water_drop, 'label': 'Water'},
      {'icon': Icons.tv, 'label': 'DTH'},
      {'icon': Icons.directions_car, 'label': 'Fastag'},
      {'icon': Icons.health_and_safety, 'label': 'Insurance'},
      {'icon': Icons.movie, 'label': 'Tickets'},
      {'icon': Icons.flight, 'label': 'Travel'},
      {'icon': Icons.shopping_bag, 'label': 'Shopping'},
      {'icon': Icons.more_horiz, 'label': 'Others'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Services",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          itemCount: services.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 15,
            mainAxisSpacing: 20,
            childAspectRatio: 0.9, // Adjust height
          ),
          itemBuilder: (context, index) {
            return Column(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    services[index]['icon'],
                    color: const Color(0xFF6C63FF),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  services[index]['label'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
