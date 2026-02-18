import 'package:flutter/material.dart';
import 'service_page_template.dart';

class TrainPage extends StatelessWidget {
  const TrainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicePageTemplate(
      title: 'Book Train',
      icon: Icons.train,
      themeColor: Color(0xFFFF6F00),
      fields: [
        ServiceField(
          label: 'From Station',
          hint: 'Departure station',
          icon: Icons.train,
        ),
        ServiceField(
          label: 'To Station',
          hint: 'Arrival station',
          icon: Icons.location_on,
        ),
        ServiceField(
          label: 'Date of Journey',
          hint: 'DD/MM/YYYY',
          icon: Icons.calendar_today,
        ),
        ServiceField(
          label: 'Class',
          hint: 'e.g. Sleeper, 3AC, 2AC, 1AC',
          icon: Icons.airline_seat_recline_normal,
        ),
      ],
      buttonLabel: 'Search Trains',
    );
  }
}
