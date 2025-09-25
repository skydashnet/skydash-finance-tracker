import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  static final _auth = LocalAuthentication();

  static Future<bool> canAuthenticate() async {
    return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
  }

  static Future<bool> authenticate() async {
    try {
      if (!await canAuthenticate()) return false;

      return await _auth.authenticate(
        localizedReason: 'Login ke Akun Skydash.NET Anda',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true, 
        ),
      );
    } on PlatformException catch (e) {
      print(e);
      return false;
    }
  }
}