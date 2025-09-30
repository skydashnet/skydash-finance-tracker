import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skydash_financial_tracker/src/providers/user_provider.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'egg':
        return Icons.egg_alt_outlined;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'savings':
        return Icons.savings_outlined;
      default:
        return Icons.star_border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final achievements = userProvider.achievements;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencapaian'),
      ),
      body: achievements.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1 / 1.2,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                final bool isUnlocked = achievement['unlocked_at'] != null;

                return Card(
                  color: isUnlocked ? Theme.of(context).cardColor : Colors.grey[800],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIconFromString(achievement['icon_name']),
                          size: 48,
                          color: isUnlocked ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          achievement['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? null : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          achievement['description'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isUnlocked ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}