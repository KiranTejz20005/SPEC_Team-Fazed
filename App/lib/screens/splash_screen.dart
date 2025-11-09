import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onInitializationComplete;
  final String theme;
  
  const SplashScreen({
    super.key,
    required this.onInitializationComplete,
    this.theme = 'light',
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _fadeOutAnimation;
  bool _isFadingOut = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Fade in animation
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Fade out animation (for smooth transition)
    _fadeOutAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start fade in animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _fadeOutAndComplete() {
    if (!_isFadingOut) {
      setState(() {
        _isFadingOut = true;
      });
      // Start fade out animation
      _animationController.forward(from: 0.7);
      // Complete after fade out
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.onInitializationComplete();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme();
    final isDark = widget.theme == 'dark';
    final backgroundColor = isDark 
        ? AppTheme.darkBackground 
        : AppTheme.lightBackground;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // Use fade out animation if fading out, otherwise use fade in
          final opacity = _isFadingOut 
              ? _fadeOutAnimation.value 
              : _fadeInAnimation.value;
          
          return Opacity(
            opacity: opacity,
            child: Container(
              color: backgroundColor,
              child: Center(
                child: Container(
                  width: 150,
                  height: 150,
                  child: Image.asset(
                    'Logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Try fallback path
                      return Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Final fallback if both paths fail
                          return Icon(
                            Icons.description,
                            size: 100,
                            color: isDark ? Colors.white : Colors.black,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
}

