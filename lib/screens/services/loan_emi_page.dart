import 'package:flutter/material.dart';
import 'service_page_template.dart';

class LoanEmiPage extends StatelessWidget {
  const LoanEmiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicePageTemplate(
      title: 'Loan EMI Payment',
      icon: Icons.account_balance,
      themeColor: Color(0xFF5F259F),
      providers: [
        ServiceProvider(name: 'SBI', icon: Icons.account_balance),
        ServiceProvider(name: 'HDFC', icon: Icons.account_balance),
        ServiceProvider(name: 'ICICI', icon: Icons.account_balance),
        ServiceProvider(name: 'Axis', icon: Icons.account_balance),
      ],
      fields: [
        ServiceField(
          label: 'Loan Account Number',
          hint: 'Enter loan account number',
          icon: Icons.confirmation_number,
          keyboardType: TextInputType.number,
        ),
        ServiceField(
          label: 'EMI Amount',
          hint: 'Enter EMI amount',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
      ],
      buttonLabel: 'Pay EMI',
    );
  }
}
