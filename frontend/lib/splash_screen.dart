import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ota_update/ota_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skydash_financial_tracker/src/constants/app_colors.dart';
import 'package:skydash_financial_tracker/src/features/auth/login_screen.dart';
import 'package:skydash_financial_tracker/src/features/main_screen.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';
import 'package:skydash_financial_tracker/src/services/local_auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();
  static final logger = Logger();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));
    final updateInfo = await _apiService.checkForUpdate();
    if (updateInfo != null && mounted) {
      _showUpdateDialog(updateInfo);
    } else {
      _checkAuthStatus();
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
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.track_changes, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Skydash.NET',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Financial Tracker',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
