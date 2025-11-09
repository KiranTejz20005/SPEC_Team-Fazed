import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Custom Animation Curves
class AppCurves {
  static const Curve easeInOutCubic = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve elasticOut = ElasticOutCurve(0.8);
  static const Curve easeOutBack = Cubic(0.34, 1.56, 0.64, 1.0);
}

// Color Scheme
class AppColors {
  // Primary Colors
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryOrange = Color(0xFFFF8A00);
  
  // Background Colors
  static const Color darkBackground = Color(0xFF0B0B0C);
  static const Color darkSurface = Color(0xFF1A1A1B);
  static const Color darkSurfaceVariant = Color(0xFF252526);
  
  // Light Theme Colors (for compatibility)
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6C757D);
  
  // Border Colors
  static const Color darkBorder = Color(0xFF2A2A2B);
  static const Color lightBorder = Color(0xFFE0E0E0);
  
  // Glassmorphism Colors
  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
}

class AppTheme {
  // Animation Durations
  static const Duration pageTransitionDuration = Duration(milliseconds: 600);
  static const Duration navBarTransitionDuration = Duration(milliseconds: 200);
  static const Duration buttonAnimationDuration = Duration(milliseconds: 300);
  
  // Border Radius
  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 20.0;
  static const double borderRadiusXLarge = 28.0;

  ThemeData getTheme(String themeName) {
    final isDark = themeName == 'dark';
    
    // Use Indigo as primary, Orange for active states
    final primaryColor = AppColors.primaryIndigo;
    final accentColor = AppColors.primaryOrange;
    
    // Get Poppins font family
    final textTheme = GoogleFonts.poppinsTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      
      // Color Scheme
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: accentColor,
        onSecondary: Colors.white,
        tertiary: accentColor,
        onTertiary: Colors.white,
        error: const Color(0xFFE74C3C),
        onError: Colors.white,
        surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        onSurface: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        surfaceVariant: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
        onSurfaceVariant: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        outline: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
      
      // Background Colors
      scaffoldBackgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      cardColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      dividerColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      
      // Typography with Poppins
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
      
      // Transparent App Bar with glassmorphism
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        titleTextStyle: GoogleFonts.poppins(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Card Theme with rounded corners
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Elevated Button with gradient shadows
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusSmall),
          ),
          shadowColor: primaryColor.withOpacity(0.3),
        ).copyWith(
          elevation: MaterialStateProperty.resolveWith<double>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return 0;
              }
              return 0; // Flat design with custom shadows
            },
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusSmall),
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusSmall),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          borderSide: BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          borderSide: const BorderSide(
            color: Color(0xFFE74C3C),
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          borderSide: const BorderSide(
            color: Color(0xFFE74C3C),
            width: 2,
          ),
        ),
      ),
      
      // Page Transitions
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _CustomPageTransitionsBuilder(),
          TargetPlatform.iOS: _CustomPageTransitionsBuilder(),
        },
      ),
    );
  }
}

// Custom Page Transition Builder with smooth animations
class _CustomPageTransitionsBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade transition with scale
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: AppCurves.easeInOutCubic,
      ),
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: AppCurves.easeInOutCubic,
        ),
        child: child,
      ),
    );
  }
}

// Glassmorphism Widget Helper
class Glassmorphism extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;

  const Glassmorphism({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.borderRadiusMedium),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassBackground.withOpacity(opacity),
            borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.borderRadiusMedium),
            border: Border.all(
              color: borderColor ?? AppColors.glassBorder,
              width: borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
