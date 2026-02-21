import 'package:flutter/material.dart';
import 'service_page_template.dart';

class MobileRechargePage extends StatelessWidget {
  const MobileRechargePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicePageTemplate(
      title: 'Mobile Recharge',
      icon: Icons.phone_android,
      themeColor: Color(0xFF00D4FF), // electric cyan
      providers: [
        ServiceProvider(name: 'Jio', icon: Icons.sim_card),
        ServiceProvider(name: 'Airtel', icon: Icons.sim_card),
        ServiceProvider(name: 'Vi', icon: Icons.sim_card),
        ServiceProvider(name: 'BSNL', icon: Icons.sim_card),
      ],
      fields: [
        ServiceField(
          label: 'Mobile Number',
          hint: 'Enter 10-digit number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        ServiceField(
          label: 'Amount',
          hint: 'Enter amount',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
      ],
      quickAmounts: ['49', '149', '199', '299', '399', '599'],
      buttonLabel: 'Recharge Now',
    );
  }
}
