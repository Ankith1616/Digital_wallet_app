import 'dart:math';
import 'package:flutter/material.dart';
import 'service_page_template.dart';
import 'travel_booking_template.dart';

class TrainPage extends StatelessWidget {
  const TrainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TravelBookingTemplate(
      title: 'Book Train',
      icon: Icons.train,
      themeColor: const Color(0xFFFF6F00),
      searchButtonLabel: 'Search Trains',
      fields: const [
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
      resultGenerator: (fields) {
        final from = fields['From Station'] ?? '';
        final to = fields['To Station'] ?? '';
        final travelClass = fields['Class'] ?? 'Sleeper';
        final rng = Random();
        final trains = [
          ('Rajdhani Express', '12301'),
          ('Shatabdi Express', '12002'),
          ('Duronto Express', '12213'),
          ('Garib Rath', '12909'),
          ('Superfast Express', '12625'),
        ];
        final durations = ['6h 30m', '8h 15m', '12h 40m', '5h 10m', '10h 20m'];
        final basePrices = {'Sleeper': 400, '3AC': 900, '2AC': 1400, '1AC': 2500};
        final base = basePrices[travelClass] ?? 700;
        trains.shuffle(rng);
        return List.generate(trains.length, (i) {
          final price = base + rng.nextInt(800);
          final avail = rng.nextInt(120) + 1;
          return BookingResult(
            title: '${trains[i].$1} (${trains[i].$2})',
            subtitle: '$from → $to',
            duration: durations[i],
            price: price.toDouble(),
            tags: [
              travelClass,
              'Avail: $avail',
            ],
          );
        });
      },
    );
  }
}

