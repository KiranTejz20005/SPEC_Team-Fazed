import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/onboarding_utils.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  String _selectedLanguage = 'English';
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.description_rounded,
      'title': 'Smart Auto-Fill',
      'description': 'Automatically extract and fill form data from your documents',
    },
    {
      'icon': Icons.chat_bubble_outline_rounded,
      'title': 'AI Guidance',
      'description': 'Get step-by-step help understanding complex questions',
    },
    {
      'icon': Icons.language_rounded,
      'title': 'Multi-Language',
      'description': 'Complete forms in your preferred language',
    },
  ];

  final List<String> _languages = [
    'English',
    'Hindi (हिंदी)',
    'Tamil (தமிழ்)',
    'Bengali (বাংলা)',
    'Telugu (తెలుగు)',
    'Marathi (मराठी)',
  ];

  @override
  void initState() {
    super.initState();
    
    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );
    
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    // Fade in animation for content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );
    
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                const SizedBox(height: 40),
                // Logo with animation
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Container(
                      width: 160,
                      height: 160,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withOpacity(0.4),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'Logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryOrange,
                                        AppColors.primaryOrange.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 80,
                                    color: Colors.white,
                        ),
                      );
                    },
                            );
                    },
                        ),
                      ),
                    ),
                  ),
              ),
                const SizedBox(height: 40),
                // Welcome Text
              Text(
                  'Welcome to',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                  maxLines: 1,
              ),
              const SizedBox(height: 8),
              Text(
                  'Fillora.in',
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Compassionate Partner for Effortless Forms',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.white60,
                    height: 1.5,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
                const SizedBox(height: 60),
              // Feature Carousel
              SizedBox(
                  height: 280,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _features.length,
                  itemBuilder: (context, index) {
                    final feature = _features[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.darkSurface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryOrange.withOpacity(0.3),
                                    width: 2,
                                  ),
                          ),
                          child: Icon(
                            feature['icon'] as IconData,
                            size: 40,
                                  color: AppColors.primaryOrange,
                          ),
                        ),
                              const SizedBox(height: 24),
                        Text(
                          feature['title'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                              const SizedBox(height: 12),
                              Text(
                            feature['description'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.white70,
                                  height: 1.5,
                                ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                    );
                  },
                ),
              ),
                const SizedBox(height: 24),
                // Page Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _features.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      color: _currentPage == index
                            ? AppColors.primaryOrange
                            : Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Language Selector
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      Row(
                        children: [
                          Icon(
                            Icons.language_rounded,
                            color: AppColors.primaryOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                  Text(
                            'Select Language',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                    overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                  ),
                      const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                        dropdownColor: AppColors.darkSurface,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                    decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.darkSurfaceVariant,
                          hintText: 'Select language',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.white60,
                          ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primaryOrange,
                              width: 2,
                            ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70,
                        ),
                        items: _languages.map((language) {
                          return DropdownMenuItem(
                            value: language,
                            child: Text(
                              language,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                          if (value != null) {
                      setState(() {
                              _selectedLanguage = value;
                      });
                          }
                    },
                  ),
                ],
              ),
                ),
                const SizedBox(height: 32),
                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await OnboardingUtils.markOnboardingSeen();
                      if (mounted) {
                        context.go('/signin');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: AppColors.primaryOrange.withOpacity(0.4),
                    ),
                    child: Text(
                      'Get Started',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Skip Button
                TextButton(
                  onPressed: () async {
                    await OnboardingUtils.markOnboardingSeen();
                    if (mounted) {
                      context.go('/signin');
                    }
                  },
                  child: Text(
                    'Skip for now',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.white60,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
