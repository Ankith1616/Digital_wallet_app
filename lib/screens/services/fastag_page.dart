import 'package:flutter/material.dart';
import 'service_page_template.dart';

class FastagPage extends StatelessWidget {
  const FastagPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicePageTemplate(
      title: 'FASTag Recharge',
      icon: Icons.directions_car,
      themeColor: Color(0xFF00897B),
      providers: [
        ServiceProvider(name: 'Paytm', icon: Icons.directions_car),
        ServiceProvider(name: 'ICICI', icon: Icons.directions_car),
        ServiceProvider(name: 'SBI', icon: Icons.directions_car),
        ServiceProvider(name: 'Axis', icon: Icons.directions_car),
      ],
      fields: [
        ServiceField(
          label: 'Vehicle Number',
          hint: 'e.g. AP 09 AB 1234',
          icon: Icons.directions_car,
        ),
        ServiceField(
          label: 'Amount',
          hint: 'Enter recharge amount',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
      ],
      quickAmounts: ['200', '500', '1000', '2000', '5000'],
      buttonLabel: 'Recharge FASTag',
    );
  }
}

