import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class AppLockService {
  static final AppLockService _instance = AppLockService._internal();
  factory AppLockService() => _instance;
  AppLockService._internal();

  static const String _appLockEnabledKey = 'app_lock_enabled';
  static const String _appLockTypeKey = 'app_lock_type'; // 'pin' or 'password'
  static const String _appLockHashKey = 'app_lock_hash';
  static const String _appLockSaltKey = 'app_lock_salt';
  static const String _appLockedKey = 'app_locked';
  static const String _lastUnlockTimeKey = 'last_unlock_time';
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Check if app lock is enabled
  Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appLockEnabledKey) ?? false;
  }

  /// Get the app lock type ('pin' or 'password')
  Future<String?> getAppLockType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_appLockTypeKey);
  }

  /// Check if app is currently locked
  Future<bool> isAppLocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appLockedKey) ?? false;
  }

  /// Set app lock enabled/disabled
  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, enabled);
    
    if (!enabled) {
      // Clear lock data when disabling
      await prefs.remove(_appLockTypeKey);
      await prefs.remove(_appLockHashKey);
      await prefs.remove(_appLockSaltKey);
      await prefs.setBool(_appLockedKey, false);
    }
  }

  /// Set up PIN lock
  Future<bool> setupPin(String pin) async {
    if (pin.length < 4) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final salt = _generateSalt();
    final hash = _hashPassword(pin, salt);

    await prefs.setString(_appLockTypeKey, 'pin');
    await prefs.setString(_appLockHashKey, hash);
    await prefs.setString(_appLockSaltKey, salt);
    await prefs.setBool(_appLockEnabledKey, true);
    await prefs.setBool(_appLockedKey, false); // Don't lock immediately after setup

    return true;
  }

  /// Set up password lock
  Future<bool> setupPassword(String password) async {
    if (password.length < 6) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);

    await prefs.setString(_appLockTypeKey, 'password');
    await prefs.setString(_appLockHashKey, hash);
    await prefs.setString(_appLockSaltKey, salt);
    await prefs.setBool(_appLockEnabledKey, true);
    await prefs.setBool(_appLockedKey, false); // Don't lock immediately after setup

    return true;
  }

  /// Verify PIN or password
  Future<bool> verifyLock(String input) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = prefs.getString(_appLockHashKey);
    final salt = prefs.getString(_appLockSaltKey);

    if (hash == null || salt == null) {
      return false;
    }

    final inputHash = _hashPassword(input, salt);
    final isValid = inputHash == hash;

    if (isValid) {
      // Update last unlock time and unlock the app
      await prefs.setBool(_appLockedKey, false);
      await prefs.setString(_lastUnlockTimeKey, DateTime.now().toIso8601String());
    }

    return isValid;
  }

  /// Lock the app
  Future<void> lockApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockedKey, true);
  }

  /// Unlock the app
  Future<void> unlockApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockedKey, false);
    await prefs.setString(_lastUnlockTimeKey, DateTime.now().toIso8601String());
  }

  /// Check if PIN/password is already set
  Future<bool> hasLockSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_appLockHashKey) != null;
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Set biometric authentication enabled/disabled
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  /// Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    if (newPin.length < 4) {
      return false;
    }

    final isValid = await verifyLock(oldPin);
    if (!isValid) {
      return false;
    }

    return await setupPin(newPin);
  }

  /// Change password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (newPassword.length < 6) {
      return false;
    }

    final isValid = await verifyLock(oldPassword);
    if (!isValid) {
      return false;
    }

    return await setupPassword(newPassword);
  }

  /// Generate a random salt
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Hash password/PIN with salt
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

