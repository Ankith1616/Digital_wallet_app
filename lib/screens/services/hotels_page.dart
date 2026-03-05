import 'dart:math';
import 'package:flutter/material.dart';
import 'service_page_template.dart';
import 'travel_booking_template.dart';
import '../../models/transaction.dart';

class HotelsPage extends StatelessWidget {
  const HotelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TravelBookingTemplate(
      title: 'Book Hotel',
      icon: Icons.hotel,
      themeColor: const Color(0xFF6A1B9A),
      searchButtonLabel: 'Search Hotels',
      category: TransactionCategory.other,
      fields: const [
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
      resultGenerator: (fields) {
        final city = fields['City / Location'] ?? 'City';
        final rng = Random();
        final hotels = [
          'Taj Hotel',
          'OYO Rooms',
          'Radisson Blu',
          'Lemon Tree',
          'Treebo Trend',
          'FabHotel Prime',
        ];
        final amenities = [
          ['Wi-Fi', 'Pool'],
          ['Breakfast'],
          ['Wi-Fi', 'Gym'],
          ['Parking'],
          ['AC', 'Wi-Fi'],
          ['Breakfast', 'AC'],
        ];
        hotels.shuffle(rng);
        return List.generate(min(5, hotels.length), (i) {
          final price = 1200 + rng.nextInt(4800);
          return BookingResult(
            title: hotels[i],
            subtitle: city,
            duration: 'per night',
            price: price.toDouble(),
            rating: 3.0 + rng.nextDouble() * 2.0,
            tags: amenities[i % amenities.length],
          );
        });
      },
    );
  }
}

