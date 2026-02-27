import 'package:flutter/material.dart';
import 'service_page_template.dart';

class BusPage extends StatelessWidget {
  const BusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicePageTemplate(
      title: 'Book Bus',
      icon: Icons.directions_bus,
      themeColor: Color(0xFF2E7D32),
      fields: [
        ServiceField(
          label: 'From',
          hint: 'Departure city',
          icon: Icons.location_on,
        ),
        ServiceField(label: 'To', hint: 'Destination city', icon: Icons.flag),
        ServiceField(
          label: 'Date of Journey',
          hint: 'DD/MM/YYYY',
          icon: Icons.calendar_today,
        ),
        ServiceField(
          label: 'Seats',
          hint: 'Number of seats',
          icon: Icons.event_seat,
          keyboardType: TextInputType.number,
        ),
      ],
      buttonLabel: 'Search Buses',
    );
  }
}

