import 'package:flutter/material.dart';
import 'service_page_template.dart';

class RentPage extends StatelessWidget {
  const RentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicePageTemplate(
      title: 'Pay Rent',
      icon: Icons.home,
      themeColor: Color(0xFF795548),
      fields: [
        ServiceField(
          label: 'Landlord Name',
          hint: 'Enter landlord / owner name',
          icon: Icons.person,
        ),
        ServiceField(
          label: 'Landlord UPI ID / Account',
          hint: 'e.g. name@upi or account no.',
          icon: Icons.account_balance,
        ),
        ServiceField(
          label: 'Amount',
          hint: 'Enter rent amount',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
      ],
      quickAmounts: ['5000', '8000', '10000', '15000', '20000'],
      buttonLabel: 'Pay Rent',
    );
  }
}

