import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Get current user
  GoogleSignInAccount? get currentGoogleUser => _googleSignIn.currentUser;
  
  // Check if user is signed in
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Sign in with Google
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web implementation
        final GoogleSignInAccount? account = await _googleSignIn.signIn();
        if (account == null) {
          return null; // User cancelled
        }

        final GoogleSignInAuthentication auth = await account.authentication;
        
        // Save user data
        await _saveUserData({
          'provider': 'google',
          'id': account.id,
          'email': account.email,
          'name': account.displayName,
          'photoUrl': account.photoUrl,
          'idToken': auth.idToken,
          'accessToken': auth.accessToken,
        });

        return {
          'success': true,
          'provider': 'google',
          'user': {
            'id': account.id,
            'email': account.email,
            'name': account.displayName,
            'photoUrl': account.photoUrl,
          },
          'idToken': auth.idToken,
          'accessToken': auth.accessToken,
        };
      } else {
        // Mobile implementation
        final GoogleSignInAccount? account = await _googleSignIn.signIn();
        if (account == null) {
          return null; // User cancelled
        }

        final GoogleSignInAuthentication auth = await account.authentication;
        
        // Save user data
        await _saveUserData({
          'provider': 'google',
          'id': account.id,
          'email': account.email,
          'name': account.displayName,
          'photoUrl': account.photoUrl,
          'idToken': auth.idToken,
          'accessToken': auth.accessToken,
        });

        return {
          'success': true,
          'provider': 'google',
          'user': {
            'id': account.id,
            'email': account.email,
            'name': account.displayName,
            'photoUrl': account.photoUrl,
          },
          'idToken': auth.idToken,
          'accessToken': auth.accessToken,
        };
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Sign in with Facebook
  Future<Map<String, dynamic>?> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        // Get the access token
        final AccessToken accessToken = result.accessToken!;
        
        // Get user data
        final userData = await FacebookAuth.instance.getUserData(
          fields: 'email,name,picture.width(200)',
        );

        // Save user data
        await _saveUserData({
          'provider': 'facebook',
          'id': userData['id'],
          'email': userData['email'],
          'name': userData['name'],
          'photoUrl': userData['picture']?['data']?['url'],
          'accessToken': accessToken.tokenString,
        });

        return {
          'success': true,
          'provider': 'facebook',
          'user': {
            'id': userData['id'],
            'email': userData['email'],
            'name': userData['name'],
            'photoUrl': userData['picture']?['data']?['url'],
          },
          'accessToken': accessToken.tokenString,
        };
      } else if (result.status == LoginStatus.cancelled) {
        return null; // User cancelled
      } else {
        return {
          'success': false,
          'error': result.message ?? 'Facebook login failed',
        };
      }
    } catch (e) {
      print('Error signing in with Facebook: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google
      if (_googleSignIn.currentUser != null) {
        await _googleSignIn.signOut();
      }

      // Sign out from Facebook
      await FacebookAuth.instance.logOut();

      // Clear saved user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('auth_provider');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');
      if (userDataJson != null) {
        return json.decode(userDataJson) as Map<String, dynamic>;
      }
      
      // If no saved data but Google user is signed in, get from Google
      if (_googleSignIn.currentUser != null) {
        final account = _googleSignIn.currentUser!;
        final auth = await account.authentication;
        return {
          'provider': 'google',
          'id': account.id,
          'email': account.email ?? '',
          'name': account.displayName ?? '',
          'photoUrl': account.photoUrl,
          'idToken': auth.idToken,
          'accessToken': auth.accessToken,
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Save user data locally
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_provider', userData['provider'] ?? '');
      await prefs.setBool('is_signed_in', true);
      
      // Save full user data as JSON
      final userDataJson = json.encode(userData);
      await prefs.setString('user_data', userDataJson);
      
      // Save member since date if not already set
      if (!prefs.containsKey('member_since')) {
        await prefs.setString('member_since', DateTime.now().toIso8601String());
      }
    } catch (e) {
      print('Error saving user data: $e');
    }
  }
  
  /// Update user profile data
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');
      
      Map<String, dynamic> currentUser;
      if (userDataJson != null) {
        currentUser = json.decode(userDataJson) as Map<String, dynamic>;
      } else {
        // If no user data exists, create a new one
        currentUser = {
          'provider': 'email',
          'id': '',
          'email': '',
          'name': '',
        };
      }
      
      // Update with new values
      currentUser.addAll(updates);
      
      // Save updated user data
      final updatedUserDataJson = json.encode(currentUser);
      await prefs.setString('user_data', updatedUserDataJson);
      
      // Ensure is_signed_in is set if updating profile
      final isSignedIn = prefs.getBool('is_signed_in') ?? false;
      if (!isSignedIn) {
        await prefs.setBool('is_signed_in', true);
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_signed_in') ?? false;
    } catch (e) {
      return false;
    }
  }
}

