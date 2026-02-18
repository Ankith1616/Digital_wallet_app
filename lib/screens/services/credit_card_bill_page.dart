import 'package:flutter/material.dart';
import 'service_page_template.dart';

class CreditCardBillPage extends StatelessWidget {
  const CreditCardBillPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicePageTemplate(
      title: 'Credit Card Bill',
      icon: Icons.credit_card,
      themeColor: Color(0xFFC62828),
      providers: [
        ServiceProvider(name: 'SBI Card', icon: Icons.credit_card),
        ServiceProvider(name: 'HDFC', icon: Icons.credit_card),
        ServiceProvider(name: 'ICICI', icon: Icons.credit_card),
        ServiceProvider(name: 'Axis', icon: Icons.credit_card),
      ],
      fields: [
        ServiceField(
          label: 'Card Number (last 4 digits)',
          hint: 'XXXX',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
        ),
        ServiceField(
          label: 'Amount Due',
          hint: 'Enter payment amount',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
      ],
      buttonLabel: 'Pay Credit Card Bill',
    );
  }
}
