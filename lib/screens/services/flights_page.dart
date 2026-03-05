import 'dart:math';
import 'package:flutter/material.dart';
import 'service_page_template.dart';
import 'travel_booking_template.dart';

class FlightsPage extends StatelessWidget {
  const FlightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TravelBookingTemplate(
      title: 'Book Flight',
      icon: Icons.flight,
      themeColor: const Color(0xFF1565C0),
      searchButtonLabel: 'Search Flights',
      fields: const [
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
      resultGenerator: (fields) {
        final from = fields['From'] ?? '';
        final to = fields['To'] ?? '';
        final pax = int.tryParse(fields['Passengers'] ?? '1') ?? 1;
        final rng = Random();
        final airlines = [
          'IndiGo', 'Air India', 'SpiceJet', 'Vistara', 'Akasa Air',
        ];
        final durations = ['1h 45m', '2h 10m', '2h 30m', '3h 05m', '1h 55m'];
        final tags = [
          ['Non-stop'],
          ['Non-stop', 'Meal'],
          ['1 Stop'],
          ['Non-stop', 'Wi-Fi'],
          ['1 Stop', 'Refundable'],
        ];
        airlines.shuffle(rng);
        return List.generate(airlines.length, (i) {
          final base = 2500 + rng.nextInt(5500);
          return BookingResult(
            title: airlines[i],
            subtitle: '$from → $to',
            duration: durations[i],
            price: (base * pax).toDouble(),
            rating: 3.5 + rng.nextDouble() * 1.5,
            tags: tags[i],
          );
        });
      },
    );
  }
}

