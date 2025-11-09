import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/app_logger_service.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF8A00), // Fallback color
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFB84D), // Lighter orange at top
              Color(0xFFFF8A00), // Deeper orange at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and Tagline
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fillora.',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Forms, Filled in Seconds.',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                // Welcome Section
                Text(
                  'Welcome back',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 40),
                // Email Input Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.grey[600],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Continue Button (Black)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      if (_emailController.text.trim().isNotEmpty) {
                        setState(() => _isLoading = true);
                        AppLoggerService().logAuth('Email sign-in attempted', provider: 'email');
                        await _authService.updateUserProfile({
                          'provider': 'email',
                          'email': _emailController.text.trim(),
                          'name': _emailController.text.trim().split('@').first,
                        });
                        AppLoggerService().logAuth('Email sign-in successful', provider: 'email', success: true);
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (mounted) {
                          context.go('/dashboard');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Continue',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                // OR Separator
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.black.withOpacity(0.2),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.black.withOpacity(0.2),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Continue with Google Button (White)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () async {
                      await _handleGoogleSignIn();
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'G',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Sign Up Link
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          TextSpan(
                            text: 'Sign Up',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Extra padding at bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    AppLoggerService().logAuth('Google sign-in attempted', provider: 'google');
    try {
      final result = await _authService.signInWithGoogle();
      if (!mounted) return;

      if (result != null && result['success'] == true) {
        AppLoggerService().logAuth('Google sign-in successful', provider: 'google', success: true);
        if (mounted) {
          context.go('/dashboard');
        }
      } else if (result != null) {
        AppLoggerService().logAuth('Google sign-in failed', provider: 'google', success: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['error'] ?? 'Sign in failed'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      AppLoggerService().logError('Google sign-in', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
