import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:skydash_financial_tracker/src/providers/user_provider.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  IconData _getIconFromString(String? iconName) {
    switch (iconName) {
      case 'egg': return Icons.egg_alt_outlined;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'savings': return Icons.savings_outlined;
      case 'looks_3': return Icons.looks_3_outlined;
      case 'whatshot': return Icons.whatshot_outlined;
      case 'trending_up': return Icons.trending_up_outlined;
      case 'check_circle': return Icons.check_circle_outline;
      case 'collections_bookmark': return Icons.collections_bookmark_outlined;
      case 'nights_stay': return Icons.nights_stay_outlined;
      case 'light_mode': return Icons.light_mode_outlined;
      default: return Icons.star_border_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context)..fetchAchievements();
    final achievements = userProvider.achievements;
    final theme = Theme.of(context);

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
                childAspectRatio: 1 / 1.25,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                final bool isUnlocked = achievement['unlocked_at'] != null;
                
                final icon = _getIconFromString(achievement['icon_name']);
                final name = achievement['name'];
                final description = achievement['description'];
                final color = theme.colorScheme.primary;
                final descriptionColor = theme.textTheme.bodyMedium?.color;

                Widget cardContent = Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 48, color: isUnlocked ? color : Colors.grey[700]),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? theme.textTheme.bodyLarge?.color : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: (descriptionColor != null)
                            ? Color.fromRGBO(0, 0, 0, 0.698)
                            : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );

                return Card(
                  elevation: isUnlocked ? 6 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: isUnlocked 
                      ? BorderSide(color: color, width: 1.5) 
                      : BorderSide(color: theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isUnlocked
                      ? Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: RadialGradient(
                              center: Alignment.topLeft,
                              radius: 1.2,
                              colors: [Color.fromRGBO(0, 0, 0, 0.2), theme.cardColor],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: cardContent,
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                              child: Opacity(
                                opacity: 0.5,
                                child: cardContent,
                              ),
                            ),
                            Icon(
                              Icons.lock_outline,
                              size: 56,
                              color: const Color.fromRGBO(0, 0, 0, 0.702),
                            ),
                          ],
                        ),
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: (100 * index).ms)
                .slideY(begin: 0.2, curve: Curves.easeOut);
              },
            ),
    );
  }
}