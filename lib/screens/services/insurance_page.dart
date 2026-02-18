import 'package:flutter/material.dart';
import 'service_page_template.dart';

class InsurancePage extends StatelessWidget {
  const InsurancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicePageTemplate(
      title: 'Insurance Premium',
      icon: Icons.receipt_long,
      themeColor: Color(0xFF009688),
      providers: [
        ServiceProvider(name: 'LIC', icon: Icons.shield),
        ServiceProvider(name: 'SBI Life', icon: Icons.shield),
        ServiceProvider(name: 'HDFC\nLife', icon: Icons.shield),
        ServiceProvider(name: 'ICICI\nPru', icon: Icons.shield),
      ],
      fields: [
        ServiceField(
          label: 'Policy Number',
          hint: 'Enter your policy number',
          icon: Icons.policy,
          keyboardType: TextInputType.number,
        ),
        ServiceField(
          label: 'Premium Amount',
          hint: 'Enter premium amount',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
      ],
      buttonLabel: 'Pay Premium',
    );
  }
}
