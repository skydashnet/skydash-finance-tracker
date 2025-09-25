import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skydash_financial_tracker/src/services/local_auth_service.dart';
import 'package:skydash_financial_tracker/src/features/auth/login_screen.dart';
import 'package:skydash_financial_tracker/src/providers/theme_provider.dart';
import 'package:skydash_financial_tracker/src/providers/user_provider.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricSetting();
  }

  Future<void> _loadBiometricSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBiometricEnabled = prefs.getBool('isBiometricEnabled') ?? false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      final canAuth = await LocalAuthService.canAuthenticate();
      if (canAuth && mounted) { // <-- PERBAIKAN
      await prefs.setBool('isBiometricEnabled', true);
      setState(() => _isBiometricEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Biometrik diaktifkan!'), backgroundColor: Colors.green),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perangkat tidak mendukung biometrik.'), backgroundColor: Colors.red),
        );
      }
    } else {
      await prefs.setBool('isBiometricEnabled', false);
      setState(() => _isBiometricEnabled = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      
      Provider.of<UserProvider>(context, listen: false).clearUser();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showThemeDialog(BuildContext context, ThemeProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Tema'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Terang'),
                value: ThemeMode.light,
                groupValue: provider.themeMode,
                onChanged: (value) {
                  if (value != null) provider.setTheme(value);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Gelap'),
                value: ThemeMode.dark,
                groupValue: provider.themeMode,
                onChanged: (value) {
                  if (value != null) provider.setTheme(value);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Mengikuti Sistem'),
                value: ThemeMode.system,
                groupValue: provider.themeMode,
                onChanged: (value) {
                  if (value != null) provider.setTheme(value);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final apiService = ApiService();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Password'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password Lama'),
                    validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password Baru'),
                    validator: (value) => (value?.length ?? 0) < 6 ? 'Minimal 6 karakter' : null,
                  ),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru'),
                    validator: (value) => value != newPasswordController.text ? 'Password tidak cocok' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final result = await apiService.changePassword(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['body']['message']),
                        backgroundColor: result['statusCode'] == 200 ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(userProvider.username),
            subtitle: Text(userProvider.email),
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Tema Aplikasi'),
            subtitle: Text(
              themeProvider.themeMode == ThemeMode.light ? 'Terang' :
              themeProvider.themeMode == ThemeMode.dark ? 'Gelap' : 'Mengikuti Sistem'
            ),
            onTap: () => _showThemeDialog(context, themeProvider),
          ),
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Ubah Password'),
            onTap: () => _showChangePasswordDialog(context),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Login dengan Biometrik'),
            subtitle: const Text('Gunakan sidik jari atau wajah'),
            value: _isBiometricEnabled,
            onChanged: _toggleBiometric,
          ),
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}