import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:skydash_financial_tracker/src/features/achievements/achievements_screen.dart';

class NotificationHelper {
  static void showSuccess(BuildContext context, {required String title, required String message}) {
    Flushbar(
      title: title,
      message: message,
      icon: Icon(Icons.check_circle_outline, color: Colors.white, size: 28.0),
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.green.shade700,
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
  }

  static void showError(BuildContext context, {required String title, required String message}) {
    Flushbar(
      title: title,
      message: message,
      icon: Icon(Icons.error_outline, color: Colors.white, size: 28.0),
      duration: const Duration(seconds: 4),
      backgroundColor: Colors.red.shade700,
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
  }

  static void showAchievementUnlocked(BuildContext context, {required Map<String, dynamic> achievement}) {
    Flushbar(
      title: '🏆 Pencapaian Terbuka!',
      message: achievement['name'],
      icon: const Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 32.0),
      duration: const Duration(seconds: 5),
      backgroundGradient: LinearGradient(
        colors: [Colors.purple.shade800, Colors.purple.shade600],
      ),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      mainButton: TextButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AchievementsScreen()));
        },
        child: const Text('LIHAT', style: TextStyle(color: Colors.amber)),
      ),
    ).show(context);
  }
}