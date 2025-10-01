import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // IMPORT PAKET ANIMASI
import 'package:ota_update/ota_update.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skydash_financial_tracker/src/constants/app_colors.dart';
import 'package:skydash_financial_tracker/src/features/auth/login_screen.dart';
import 'package:skydash_financial_tracker/src/features/main_screen.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';
import 'package:skydash_financial_tracker/src/services/local_auth_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();
  final Logger logger = Logger();
  String _loadingText = 'Checking for updates...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final updateInfo = await _apiService.checkForUpdate();
    if (updateInfo != null && mounted) {
      _showUpdateDialog(updateInfo);
    } else {
      await Future.delayed(const Duration(seconds: 2));
      if(mounted) {
        _checkAuthStatus();
      }
    }
  }

  void _showUpdateDialog(Map<String, String> updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Update Tersedia: v${updateInfo['version']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: updateInfo['notes']!,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkAuthStatus();
            },
            child: const Text('NANTI SAJA'),
          ),
          ElevatedButton(
            onPressed: () {
              _startUpdate(updateInfo['url']!);
            },
            child: const Text('UPDATE SEKARANG'),
          ),
        ],
      ),
    );
  }

  void _startUpdate(String url) {
    try {
      OtaUpdate()
          .execute(url, destinationFilename: 'skydash-finance-tracker.apk')
          .listen((OtaEvent event) {
            logger.i('OTA EVENT: ${event.status} : ${event.value}');
          });
    } catch (e) {
      logger.e('Failed to start OTA update: $e');
    }
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isBiometricEnabled =
        prefs.getBool('isBiometricEnabled') ?? false;
    final String? token = prefs.getString('token');

    await Future.delayed(const Duration(seconds: 1));

    if (isBiometricEnabled && token != null) {
      final didAuthenticate = await LocalAuthService.authenticate();
      if (didAuthenticate && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
        return;
      }
    }

    if (token != null && token.isNotEmpty && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF121212) 
          : AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- BAGIAN ANIMASI ---
            const Icon(
              Icons.track_changes,
              size: 100,
              color: Colors.white,
            )
            .animate()
            .fade(duration: 900.ms)
            .scale(delay: 300.ms, duration: 600.ms, curve: Curves.elasticOut),

            const SizedBox(height: 20),

            const Text(
              'SkydashNET',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            )
            .animate()
            .fade(delay: 500.ms, duration: 800.ms)
            .slideY(begin: 1.0, duration: 800.ms, curve: Curves.easeOutCubic),
            
            const Text(
              'Finance Tracker',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 1,
              ),
            )
            .animate()
            .fade(delay: 700.ms, duration: 800.ms)
            .slideY(begin: 1.0, duration: 800.ms, curve: Curves.easeOutCubic),
            
            // --- PROGRESS INDICATOR DIHAPUS ---
          ],
        ),
      ),
    );
  }
}