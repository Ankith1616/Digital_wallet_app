import 'package:flutter/material.dart';
import 'service_page_template.dart';

class ElectricityPage extends StatelessWidget {
  const ElectricityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicePageTemplate(
      title: 'Electricity Bill',
      icon: Icons.lightbulb,
      themeColor: Color(0xFFF39C12),
      providers: [
        ServiceProvider(name: 'APSPDCL', icon: Icons.electric_bolt),
        ServiceProvider(name: 'TSSPDCL', icon: Icons.electric_bolt),
        ServiceProvider(name: 'BESCOM', icon: Icons.electric_bolt),
        ServiceProvider(name: 'TNEB', icon: Icons.electric_bolt),
      ],
      fields: [
        ServiceField(
          label: 'Consumer Number',
          hint: 'Enter your consumer number',
          icon: Icons.confirmation_number,
          keyboardType: TextInputType.number,
        ),
        ServiceField(
          label: 'Billing Unit',
          hint: 'Enter billing unit name',
          icon: Icons.location_on,
        ),
        ServiceField(
          label: 'Amount',
          hint: 'Enter amount to pay',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
      ],
      quickAmounts: ['500', '1000', '1500', '2000', '3000', '5000'],
      buttonLabel: 'Pay Electricity Bill',
    );
  }
}
