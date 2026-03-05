import 'dart:math';
import 'package:flutter/material.dart';
import 'service_page_template.dart';
import 'travel_booking_template.dart';

class BusPage extends StatelessWidget {
  const BusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TravelBookingTemplate(
      title: 'Book Bus',
      icon: Icons.directions_bus,
      themeColor: const Color(0xFF2E7D32),
      searchButtonLabel: 'Search Buses',
      fields: const [
        ServiceField(
          label: 'From',
          hint: 'Departure city',
          icon: Icons.location_on,
        ),
        ServiceField(
          label: 'To',
          hint: 'Destination city',
          icon: Icons.flag,
        ),
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
      resultGenerator: (fields) {
        final from = fields['From'] ?? '';
        final to = fields['To'] ?? '';
        final seats = int.tryParse(fields['Seats'] ?? '1') ?? 1;
        final rng = Random();
        final operators = [
          'SRS Travels',
          'VRL Travels',
          'KPN Travels',
          'Orange Travels',
          'Greenline',
        ];
        final types = ['AC Sleeper', 'Non-AC Seater', 'AC Seater', 'Volvo Multi-Axle', 'AC Semi-Sleeper'];
        final durations = ['5h 30m', '7h 00m', '8h 15m', '6h 45m', '9h 20m'];
        operators.shuffle(rng);
        return List.generate(operators.length, (i) {
          final base = 300 + rng.nextInt(700);
          return BookingResult(
            title: operators[i],
            subtitle: '$from → $to',
            duration: durations[i],
            price: (base * seats).toDouble(),
            rating: 3.0 + rng.nextDouble() * 2.0,
            tags: [types[i]],
          );
        });
      },
    );
  }
}

