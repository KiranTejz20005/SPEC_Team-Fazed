import 'package:shared_preferences/shared_preferences.dart';

/// Utility class for managing onboarding state
class OnboardingUtils {
  static const String _key = 'has_seen_onboarding';

  /// Check if user has seen onboarding
  static Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark onboarding as seen
  static Future<void> markOnboardingSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Reset onboarding (for testing)
  static Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      // Ignore errors
    }
  }
}

