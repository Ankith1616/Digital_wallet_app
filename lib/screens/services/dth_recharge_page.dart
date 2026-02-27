import 'package:flutter/material.dart';
import 'service_page_template.dart';

class DthRechargePage extends StatelessWidget {
  const DthRechargePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicePageTemplate(
      title: 'DTH Recharge',
      icon: Icons.tv,
      themeColor: Color(0xFFE91E63),
      providers: [
        ServiceProvider(name: 'Tata Play', icon: Icons.tv),
        ServiceProvider(name: 'Airtel\nDigital', icon: Icons.tv),
        ServiceProvider(name: 'D2H', icon: Icons.tv),
        ServiceProvider(name: 'Sun\nDirect', icon: Icons.tv),
      ],
      fields: [
        ServiceField(
          label: 'Subscriber ID',
          hint: 'Enter your subscriber ID',
          icon: Icons.confirmation_number,
          keyboardType: TextInputType.number,
        ),
        ServiceField(
          label: 'Amount',
          hint: 'Enter amount',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
      ],
      quickAmounts: ['150', '200', '300', '500', '750', '999'],
      buttonLabel: 'Recharge Now',
    );
  }
}

