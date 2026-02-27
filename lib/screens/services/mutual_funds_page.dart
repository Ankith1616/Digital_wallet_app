import 'package:flutter/material.dart';
import 'service_page_template.dart';

class MutualFundsPage extends StatelessWidget {
  const MutualFundsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicePageTemplate(
      title: 'Mutual Funds',
      icon: Icons.savings,
      themeColor: Color(0xFF4CAF50),
      providers: [
        ServiceProvider(name: 'SBI MF', icon: Icons.trending_up),
        ServiceProvider(name: 'HDFC MF', icon: Icons.trending_up),
        ServiceProvider(name: 'Axis MF', icon: Icons.trending_up),
        ServiceProvider(name: 'ICICI MF', icon: Icons.trending_up),
      ],
      fields: [
        ServiceField(
          label: 'Folio Number',
          hint: 'Enter folio number',
          icon: Icons.confirmation_number,
          keyboardType: TextInputType.number,
        ),
        ServiceField(
          label: 'SIP / Lumpsum Amount',
          hint: 'Enter amount to invest',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
      ],
      quickAmounts: ['500', '1000', '2000', '5000', '10000'],
      buttonLabel: 'Invest Now',
    );
  }
}

