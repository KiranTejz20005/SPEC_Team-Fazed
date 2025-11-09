import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/onboarding_utils.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

/// Simple splash screen with clean logo animation
class SplashScreen extends StatefulWidget {
  final VoidCallback? onInitializationComplete;
  final String theme;
  
  const SplashScreen({
    super.key,
    this.onInitializationComplete,
    this.theme = 'dark',
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
    
    // Start pulse animation after main animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
    
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    try {
      // Check if user has seen onboarding using utility
      final hasSeenOnboarding = await OnboardingUtils.hasSeenOnboarding();
      
      // Check if user is authenticated
      final authService = AuthService();
      final isAuthenticated = await authService.isAuthenticated();
      
      if (isAuthenticated) {
        // User is logged in, go directly to dashboard
        if (mounted) {
          context.go('/dashboard');
        }
      } else if (!hasSeenOnboarding) {
        // New user, show onboarding
        if (mounted) {
          context.go('/onboarding');
        }
      } else {
        // Returning user who has seen onboarding, go to signin
        if (mounted) {
          context.go('/signin');
        }
      }
      
      // Call callback if provided
      if (widget.onInitializationComplete != null) {
        widget.onInitializationComplete!();
      }
    } catch (e) {
      // If there's an error, default to signin
      if (mounted) {
        context.go('/signin');
      }
      if (widget.onInitializationComplete != null) {
        widget.onInitializationComplete!();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme == 'dark';
    final backgroundColor = isDark 
        ? AppColors.darkBackground 
        : AppColors.lightBackground;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Try fallback path
                          return Image.asset(
                            'Logo.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Simple fallback logo
                              return Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF8A1E), 
                                      Color(0xFFFFB627),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.description_rounded,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
