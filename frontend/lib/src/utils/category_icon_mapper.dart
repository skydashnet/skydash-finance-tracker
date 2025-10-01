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
        return CategoryVisual(icon: Icons.wallet_outlined, color: Colors.green.shade600);
      case 'bonus':
        return CategoryVisual(icon: Icons.card_giftcard_outlined, color: Colors.teal.shade600);
      case 'investasi':
        return CategoryVisual(icon: Icons.show_chart, color: Colors.blue.shade600);
      case 'hadiah':
        return CategoryVisual(icon: Icons.redeem, color: Colors.lightGreen.shade700);
      case 'lainnya':
        return CategoryVisual(icon: Icons.more_horiz, color: Colors.grey.shade600);
      case 'makan siang':
        return CategoryVisual(icon: Icons.lunch_dining_outlined, color: Colors.orange.shade800);
      case 'kopi':
        return CategoryVisual(icon: Icons.coffee_outlined, color: Colors.brown.shade600);
      case 'restoran':
        return CategoryVisual(icon: Icons.restaurant_outlined, color: Colors.orange.shade600);
      case 'snack':
        return CategoryVisual(icon: Icons.icecream_outlined, color: Colors.amber.shade700);
      case 'supermarket':
        return CategoryVisual(icon: Icons.shopping_cart_outlined, color: Colors.blue.shade800);
      case 'kebutuhan rumah':
        return CategoryVisual(icon: Icons.home_work_outlined, color: Colors.lightBlue.shade700);
      case 'minimarket':
        return CategoryVisual(icon: Icons.store_mall_directory_outlined, color: Colors.cyan.shade700);
      case 'bbm':
        return CategoryVisual(icon: Icons.local_gas_station_outlined, color: Colors.grey.shade800);
      case 'parkir':
        return CategoryVisual(icon: Icons.local_parking_outlined, color: Colors.grey.shade700);
      case 'tol':
        return CategoryVisual(icon: Icons.add_road_outlined, color: Colors.blueGrey.shade600);
      case 'ojek online':
        return CategoryVisual(icon: Icons.two_wheeler_outlined, color: Colors.green.shade800);
      case 'tiket transportasi':
        return CategoryVisual(icon: Icons.airplane_ticket_outlined, color: Colors.indigo.shade600);
      case 'nonton film':
        return CategoryVisual(icon: Icons.theaters_outlined, color: Colors.purple.shade600);
      case 'game':
        return CategoryVisual(icon: Icons.games_outlined, color: Colors.deepPurple.shade600);
      case 'musik':
        return CategoryVisual(icon: Icons.music_note_outlined, color: Colors.purpleAccent.shade400);
      case 'langganan streaming':
        return CategoryVisual(icon: Icons.subscriptions_outlined, color: Colors.red.shade700);
      case 'obat':
        return CategoryVisual(icon: Icons.medication_outlined, color: Colors.redAccent.shade400);
      case 'dokter':
        return CategoryVisual(icon: Icons.medical_services_outlined, color: Colors.red.shade800);
      case 'vitamin':
        return CategoryVisual(icon: Icons.vaccines_outlined, color: Colors.pinkAccent.shade200);
      case 'asuransi kesehatan':
        return CategoryVisual(icon: Icons.health_and_safety_outlined, color: Colors.red.shade400);
      case 'buku':
        return CategoryVisual(icon: Icons.book_outlined, color: Colors.brown.shade400);
      case 'kursus':
        return CategoryVisual(icon: Icons.school_outlined, color: Colors.brown.shade700);
      case 'sekolah/kuliah':
        return CategoryVisual(icon: Icons.account_balance_outlined, color: Colors.brown.shade900);
      case 'listrik':
        return CategoryVisual(icon: Icons.electrical_services_outlined, color: Colors.amber.shade800);
      case 'air':
        return CategoryVisual(icon: Icons.water_drop_outlined, color: Colors.lightBlue.shade400);
      case 'internet':
        return CategoryVisual(icon: Icons.wifi, color: Colors.blue.shade700);
      case 'pulsa/paket data':
        return CategoryVisual(icon: Icons.phone_android, color: Colors.indigoAccent.shade400);
      case 'pakaian':
        return CategoryVisual(icon: Icons.checkroom_outlined, color: Colors.pink.shade400);
      case 'aksesoris':
        return CategoryVisual(icon: Icons.watch_outlined, color: Colors.pinkAccent.shade400);
      case 'skincare':
        return CategoryVisual(icon: Icons.spa_outlined, color: Colors.pink.shade200);
      case 'donasi':
        return CategoryVisual(icon: Icons.volunteer_activism_outlined, color: Colors.red.shade400);
      case 'hadiah ulang tahun':
        return CategoryVisual(icon: Icons.cake_outlined, color: Colors.pink.shade300);
      case 'sumbangan':
        return CategoryVisual(icon: Icons.group_add_outlined, color: Colors.orange.shade300);
      case 'pengeluaran lain':
        return CategoryVisual(icon: Icons.more_horiz, color: Colors.grey.shade600);

      default:
        return CategoryVisual(icon: Icons.label_important_outline, color: Colors.grey.shade500);
    }
  }
}