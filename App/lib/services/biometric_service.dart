import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      print('Error checking device support: $e');
      return false;
    }
  }

  /// Check if biometrics are available (enrolled and ready)
  Future<bool> isBiometricsAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (e) {
      print('Error checking biometrics availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({
    String reason = 'Please authenticate to unlock the app',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await isBiometricsAvailable();
      if (!isAvailable) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true, // Only use biometrics, not device credentials
        ),
      );
    } on PlatformException catch (e) {
      print('Biometric authentication error: $e');
      return false;
    } catch (e) {
      print('Error during biometric authentication: $e');
      return false;
    }
  }

  /// Stop authentication (if in progress)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      print('Error stopping authentication: $e');
    }
  }

  /// Get biometric type name for display
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }

  /// Get primary biometric type name for display
  Future<String> getPrimaryBiometricTypeName() async {
    final available = await getAvailableBiometrics();
    if (available.isEmpty) {
      return 'Biometric';
    }

    // Prefer face over fingerprint
    if (available.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (available.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (available.isNotEmpty) {
      return getBiometricTypeName(available.first);
    }

    return 'Biometric';
  }
}

