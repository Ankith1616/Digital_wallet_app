import 'package:flutter/material.dart';

class IconHelper {
  /// Maps a codePoint back to a constant IconData.
  /// This is necessary for Flutter's icon tree shaking in release builds.
  static IconData getIcon(int codePoint, [String? fontFamily]) {
    // If it's a known icon from our list, return the constant version.
    // This allows the compiler to "see" that these icons are used.
    switch (codePoint) {
      case 0xe047:
        return Icons.account_balance;
      case 0xe406:
        return Icons.account_balance_wallet;
      case 0xe4a2:
        return Icons.phone_android;
      case 0xe5d5:
        return Icons.swap_horiz;
      case 0xf016e:
        return Icons.settings_suggest_outlined;
      case 0xe54d:
        return Icons.lightbulb;
      case 0xe6e4:
        return Icons.water_drop;
      case 0xe687:
        return Icons.tv;
      case 0xe1d7:
        return Icons.directions_car;
      case 0xe6df:
        return Icons.wifi;
      case 0xe3ab:
        return Icons.local_gas_station;
      case 0xe412:
        return Icons.more_horiz;
      case 0xe138:
        return Icons.card_giftcard;
      case 0xe5ad:
        return Icons.stars;
      case 0xe135:
        return Icons.call_split;
      case 0xe226:
        return Icons.credit_card;
      case 0xe525:
        return Icons.shopping_bag;
      case 0xe556:
        return Icons.restaurant;
      case 0xe23a:
        return Icons.receipt_long;
      case 0xe532:
        return Icons.movie;
      case 0xe62c:
        return Icons.health_and_safety;
      case 0xe571:
        return Icons.train;
      case 0xe332:
        return Icons.image;
      case 0xe491:
        return Icons.person;

      default:
        // Fallback to a default constant icon rather than dynamic construction
        // if possible, to avoid the error. If we MUST support dynamic, we'll
        // have to use --no-tree-shake-icons, but this list covers 99% of our app.
        return Icons.account_balance;
    }
  }
}

