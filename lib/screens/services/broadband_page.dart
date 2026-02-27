import 'package:flutter/material.dart';
import 'service_page_template.dart';

class BroadbandPage extends StatelessWidget {
  const BroadbandPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicePageTemplate(
      title: 'Broadband',
      icon: Icons.wifi,
      themeColor: Color(0xFF7B1FA2),
      providers: [
        ServiceProvider(name: 'Jio Fiber', icon: Icons.wifi),
        ServiceProvider(name: 'Airtel\nXstream', icon: Icons.wifi),
        ServiceProvider(name: 'ACT', icon: Icons.wifi),
        ServiceProvider(name: 'BSNL', icon: Icons.wifi),
      ],
      fields: [
        ServiceField(
          label: 'Account Number',
          hint: 'Enter broadband account no.',
          icon: Icons.account_circle,
          keyboardType: TextInputType.number,
        ),
        ServiceField(
          label: 'Amount',
          hint: 'Enter amount',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
      ],
      quickAmounts: ['399', '599', '799', '999', '1499'],
      buttonLabel: 'Pay Now',
    );
  }
}

