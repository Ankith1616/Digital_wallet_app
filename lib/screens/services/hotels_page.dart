import 'package:flutter/material.dart';
import 'service_page_template.dart';

class HotelsPage extends StatelessWidget {
  const HotelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicePageTemplate(
      title: 'Book Hotel',
      icon: Icons.hotel,
      themeColor: Color(0xFF6A1B9A),
      fields: [
        ServiceField(
          label: 'City / Location',
          hint: 'Where are you going?',
          icon: Icons.location_city,
        ),
        ServiceField(
          label: 'Check-in Date',
          hint: 'DD/MM/YYYY',
          icon: Icons.calendar_today,
        ),
        ServiceField(
          label: 'Check-out Date',
          hint: 'DD/MM/YYYY',
          icon: Icons.calendar_month,
        ),
        ServiceField(
          label: 'Guests & Rooms',
          hint: 'e.g. 2 Guests, 1 Room',
          icon: Icons.people,
        ),
      ],
      buttonLabel: 'Search Hotels',
    );
  }
}
