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
      ],
      buttonLabel: 'Fetch Bill & Pay',
    );
  }
}
