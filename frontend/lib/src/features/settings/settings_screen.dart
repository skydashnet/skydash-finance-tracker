import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skydash_financial_tracker/src/features/achievements/achievements_screen.dart';
import 'package:skydash_financial_tracker/src/features/auth/login_screen.dart';
import 'package:skydash_financial_tracker/src/providers/theme_provider.dart';
import 'package:skydash_financial_tracker/src/providers/user_provider.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';
import 'package:skydash_financial_tracker/src/services/local_auth_service.dart';
import 'package:skydash_financial_tracker/src/utils/notification_helper.dart';

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
    if (mounted) {
      setState(() {
        _isBiometricEnabled = prefs.getBool('isBiometricEnabled') ?? false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      final canAuth = await LocalAuthService.canAuthenticate();
      if (canAuth && mounted) {
        await prefs.setBool('isBiometricEnabled', true);
        setState(() => _isBiometricEnabled = true);
        NotificationHelper.showSuccess(context, title: 'Berhasil', message: 'Login Biometrik diaktifkan!');
      } else if (mounted) {
        NotificationHelper.showError(context, title: 'Gagal', message: 'Perangkat tidak mendukung biometrik.');
      }
    } else {
      await prefs.setBool('isBiometricEnabled', false);
      if (mounted) {
        setState(() => _isBiometricEnabled = false);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
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
                    if (result['statusCode'] == 200) {
                      NotificationHelper.showSuccess(
                        context,
                        title: 'Berhasil',
                        message: result['body']['message'],
                      );
                    } else {
                      NotificationHelper.showError(
                        context,
                        title: 'Gagal',
                        message: result['body']['message'],
                      );
                    }
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
    final theme = Theme.of(context);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userProvider.username, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(userProvider.email, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.8))),
                  ],
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingsGroup(
                  context: context,
                  title: 'Akun & Keamanan',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Ubah Password'),
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint),
                      title: const Text('Login dengan Biometrik'),
                      value: _isBiometricEnabled,
                      onChanged: _toggleBiometric,
                    ),
                  ],
                ),

                _buildSettingsGroup(
                  context: context,
                  title: 'Tampilan',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.brightness_6_outlined),
                      title: const Text('Tema Aplikasi'),
                      subtitle: Text(
                        themeProvider.themeMode == ThemeMode.light ? 'Terang' :
                        themeProvider.themeMode == ThemeMode.dark ? 'Gelap' : 'Mengikuti Sistem'
                      ),
                      onTap: () => _showThemeDialog(context, themeProvider),
                    ),
                  ],
                ),
                
                _buildSettingsGroup(
                  context: context,
                  title: 'Lainnya',
                  children: [
                     ListTile(
                      leading: const Icon(Icons.emoji_events_outlined),
                      title: const Text('Pencapaian'),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AchievementsScreen()));
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    onPressed: () => _logout(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 16.0),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}