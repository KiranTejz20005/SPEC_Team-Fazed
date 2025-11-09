import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  String _selectedLanguage = 'English';

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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // AI Character
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 60,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  // Pulse animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 1.5),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Container(
                        width: 120 * value,
                        height: 120 * value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3 / value),
                            width: 2,
                          ),
                        ),
                      );
                    },
                    onEnd: () {
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to Fillora.in',
                style: theme.textTheme.displayMedium,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Text(
                'Your Compassionate Partner for Effortless Forms',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _StatItem(number: '10K+', label: 'Forms Completed'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatItem(number: '98%', label: 'Accuracy Rate'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatItem(number: '6+', label: 'Languages'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Feature Carousel
              SizedBox(
                height: 200,
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
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            feature['icon'] as IconData,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          feature['title'] as String,
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            feature['description'] as String,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _features.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Language Selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Your Language',
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: _languages.map((lang) {
                      return DropdownMenuItem(
                        value: lang,
                        child: Text(
                          lang,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Trust Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Your data is encrypted and secure',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // CTA Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    // Mark onboarding as seen
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('has_seen_onboarding', true);
                    if (mounted) {
                      context.go('/signin');
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.brightness == Brightness.dark
                        ? theme.colorScheme.surface
                        : theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String number;
  final String label;

  const _StatItem({
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          number,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }
}

