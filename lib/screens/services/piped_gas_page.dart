import 'package:flutter/material.dart';
import 'service_page_template.dart';

class PipedGasPage extends StatelessWidget {
  const PipedGasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicePageTemplate(
      title: 'Piped Gas Bill',
      icon: Icons.local_gas_station,
      themeColor: Color(0xFFFF5722),
      providers: [
        ServiceProvider(
          name: 'Mahanagar\nGas',
          icon: Icons.local_fire_department,
        ),
        ServiceProvider(name: 'Adani\nGas', icon: Icons.local_fire_department),
        ServiceProvider(name: 'IGL', icon: Icons.local_fire_department),
        ServiceProvider(name: 'GAIL', icon: Icons.local_fire_department),
      ],
      fields: [
        ServiceField(
          label: 'Customer ID',
          hint: 'Enter your customer ID',
          icon: Icons.confirmation_number,
          keyboardType: TextInputType.number,
        ),
        ServiceField(
          label: 'Amount',
          hint: 'Enter bill amount',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
      ],
      quickAmounts: ['200', '500', '800', '1200', '2000'],
      buttonLabel: 'Pay Gas Bill',
    );
  }
}

