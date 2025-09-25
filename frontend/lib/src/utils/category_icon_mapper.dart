import 'package:flutter/material.dart';

class CategoryVisual {
  final IconData icon;
  final Color color;

  CategoryVisual({required this.icon, required this.color});
}

class CategoryIconMapper {
  static CategoryVisual getVisual(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'gaji':
        return CategoryVisual(icon: Icons.wallet, color: Colors.green);
      case 'bonus':
        return CategoryVisual(icon: Icons.card_giftcard, color: Colors.teal);
      case 'investasi':
        return CategoryVisual(icon: Icons.trending_up, color: Colors.blue);

      case 'makanan & minuman':
        return CategoryVisual(icon: Icons.fastfood, color: Colors.orange);
      case 'transportasi':
        return CategoryVisual(icon: Icons.directions_car, color: Colors.indigo);
      case 'tagihan':
        return CategoryVisual(icon: Icons.receipt_long, color: Colors.red);
      case 'hiburan':
        return CategoryVisual(icon: Icons.movie, color: Colors.purple);
      case 'belanja':
        return CategoryVisual(icon: Icons.shopping_bag, color: Colors.pink);
      case 'kesehatan':
        return CategoryVisual(icon: Icons.health_and_safety, color: Colors.redAccent);
      case 'pendidikan':
        return CategoryVisual(icon: Icons.school, color: Colors.blueGrey);
      case 'keluarga':
        return CategoryVisual(icon: Icons.people, color: Colors.brown);
      case 'liburan':
        return CategoryVisual(icon: Icons.beach_access, color: Colors.cyan);
      case 'hadiah':
        return CategoryVisual(icon: Icons.card_giftcard, color: Colors.pinkAccent);
      case 'lainnya':
        return CategoryVisual(icon: Icons.category, color: Colors.grey);
      default:
        return CategoryVisual(icon: Icons.label, color: Colors.grey);
    }
  }
}