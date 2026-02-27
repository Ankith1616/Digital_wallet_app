import 'package:flutter/material.dart';
import 'service_page_template.dart';

class FlightsPage extends StatelessWidget {
  const FlightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicePageTemplate(
      title: 'Book Flight',
      icon: Icons.flight,
      themeColor: Color(0xFF1565C0),
      fields: [
        ServiceField(
          label: 'From',
          hint: 'Departure city / airport',
          icon: Icons.flight_takeoff,
        ),
        ServiceField(
          label: 'To',
          hint: 'Arrival city / airport',
          icon: Icons.flight_land,
        ),
        ServiceField(
          label: 'Date of Journey',
          hint: 'DD/MM/YYYY',
          icon: Icons.calendar_today,
        ),
        ServiceField(
          label: 'Passengers',
          hint: 'Number of passengers',
          icon: Icons.people,
          keyboardType: TextInputType.number,
        ),
      ],
      buttonLabel: 'Search Flights',
    );
  }
}

