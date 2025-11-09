import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import '../services/app_logger_service.dart';

/// Dialog to let user select a Google account for accessing Google Forms
class GoogleAccountSelectionDialog extends StatefulWidget {
  final String formUrl;
  
  const GoogleAccountSelectionDialog({
    super.key,
    required this.formUrl,
  });

  @override
  State<GoogleAccountSelectionDialog> createState() => _GoogleAccountSelectionDialogState();
}

class _GoogleAccountSelectionDialogState extends State<GoogleAccountSelectionDialog> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  /// Sign in with Google and return the access token
  /// This doesn't change the app's main authentication state
  Future<String?> _selectGoogleAccount() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      AppLoggerService().logAuth('Google account selection for form access', provider: 'google');
      
      // Use GoogleSignIn to show account selector
      // Create a new instance to avoid interfering with app auth
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile', 'https://www.googleapis.com/auth/drive.readonly'],
      );

      // Sign in (this shows the account picker)
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      
      if (account == null) {
        // User cancelled
        AppLoggerService().logAuth('Google account selection cancelled', provider: 'google');
        setState(() {
          _isLoading = false;
        });
        return null;
      }

      // Get authentication tokens
      final GoogleSignInAuthentication auth = await account.authentication;
      
      AppLoggerService().logAuth('Google account selected for form access - Account: ${account.email}', 
        provider: 'google', 
        success: true);

      // Sign out from this temporary instance so it doesn't interfere with app auth
      await googleSignIn.signOut();

      setState(() {
        _isLoading = false;
      });

      return auth.accessToken;
    } catch (e) {
      AppLoggerService().logError('Google account selection', e);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to sign in: ${e.toString()}';
      });
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                // Google logo
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335)],
                      stops: [0.0, 0.33, 0.66, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign in to Google',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose an account',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Info message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This Google Form requires authentication. Please select a Google account to continue.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Sign in button
            FilledButton.icon(
              onPressed: _isLoading ? null : () async {
                final accessToken = await _selectGoogleAccount();
                if (accessToken != null && mounted) {
                  Navigator.of(context).pop(accessToken);
                }
              },
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.account_circle),
              label: Text(_isLoading ? 'Signing in...' : 'Choose Google Account'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            // Cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

