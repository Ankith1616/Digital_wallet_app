import 'package:flutter/material.dart';
import 'service_page_template.dart';

class WaterPage extends StatelessWidget {
  const WaterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicePageTemplate(
      title: 'Water Bill',
      icon: Icons.water_drop,
      themeColor: Color(0xFF2196F3),
      fields: [
        ServiceField(
          label: 'Consumer ID / RR Number',
          hint: 'Enter your consumer ID',
          icon: Icons.confirmation_number,
          keyboardType: TextInputType.number,
        ),
        ServiceField(
          label: 'Board / Authority',
          hint: 'e.g. HMWS, CMWSS',
          icon: Icons.business,
        ),
        ServiceField(
          label: 'Amount',
          hint: 'Enter bill amount',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
        ),
      ],
      quickAmounts: ['100', '250', '500', '1000', '1500'],
      buttonLabel: 'Pay Water Bill',
    );
  }
}
