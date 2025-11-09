import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'theme/app_theme.dart';
import 'services/language_service.dart';
import 'services/auth_service.dart';
import 'widgets/back_button_handler.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/templates_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/form_selection_screen.dart';
import 'screens/document_upload_screen.dart';
import 'screens/conversational_form_screen.dart';
import 'screens/review_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/security_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/app_lock_screen.dart';
import 'screens/app_lock_setup_screen.dart';
import 'services/app_lock_service.dart';
import 'widgets/floating_debug_button.dart';
import 'services/app_logger_service.dart';

// Navigation observer to log all navigation events
class _NavigationObserver extends NavigatorObserver {
  String? _lastKnownRoute;
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final routeName = _getRouteName(route);
    final previousName = _lastKnownRoute ?? _getRouteName(previousRoute) ?? 'none';
    _lastKnownRoute = routeName;
    if (routeName != null) {
      AppLoggerService().logNavigation(previousName, routeName);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final routeName = _getRouteName(route);
    final previousName = _lastKnownRoute ?? _getRouteName(previousRoute) ?? 'none';
    _lastKnownRoute = previousName;
    if (routeName != null) {
      AppLoggerService().logNavigation(routeName, previousName);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final newRouteName = _getRouteName(newRoute);
    final oldRouteName = _lastKnownRoute ?? _getRouteName(oldRoute);
    if (newRouteName != null) {
      _lastKnownRoute = newRouteName;
      AppLoggerService().logNavigation(oldRouteName ?? 'unknown', newRouteName);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    final removedRoute = _getRouteName(route);
    final previousName = _lastKnownRoute ?? _getRouteName(previousRoute) ?? 'none';
    if (removedRoute != null) {
      _lastKnownRoute = previousName;
      AppLoggerService().logNavigation(removedRoute, previousName);
    }
  }

  String? _getRouteName(Route<dynamic>? route) {
    if (route == null) return null;
    
    // First try: route name from settings
    if (route.settings.name != null && route.settings.name!.isNotEmpty) {
      return route.settings.name;
    }
    
    // Second try: extract from route arguments
    if (route.settings.arguments is Map) {
      final args = route.settings.arguments as Map;
      if (args.containsKey('route') && args['route'] != null) {
        return args['route'].toString();
      }
    }
    
    // Third try: extract from route string representation
    final routeStr = route.toString();
    // Look for patterns like "/dashboard", "/conversational-form", etc.
    final pathMatch = RegExp(r'\/[\w\-]+(?:\?[^\s\)]*)?').firstMatch(routeStr);
    if (pathMatch != null) {
      final path = pathMatch.group(0);
      // Remove query parameters for cleaner logging
      if (path != null && path.contains('?')) {
        return path.split('?').first;
      }
      return path;
    }
    
    // Fourth try: check if it's a GoRoute by looking for location info
    final locationMatch = RegExp(r'location[:\s]+([\/\w\-]+)').firstMatch(routeStr);
    if (locationMatch != null) {
      return locationMatch.group(1);
    }
    
    return null;
  }
}

// Overlay widget that provides Navigator context to the debug button
class _DebugButtonOverlay extends StatelessWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  
  const _DebugButtonOverlay({
    required this.child,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Floating debug button with navigator key
        FloatingDebugButton(navigatorKey: navigatorKey),
      ],
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const FilloraApp());
}

class FilloraApp extends StatefulWidget {
  const FilloraApp({super.key});

  @override
  State<FilloraApp> createState() => _FilloraAppState();
}

class _FilloraAppState extends State<FilloraApp> with WidgetsBindingObserver {
  String _currentTheme = 'light';
  final AppTheme _appTheme = AppTheme();
  final LanguageService _languageService = LanguageService();
  final AuthService _authService = AuthService();
  final AppLockService _appLockService = AppLockService();
  Locale _currentLocale = const Locale('en', 'US');
  String _initialRoute = '/onboarding';
  bool _isLoading = true;
  bool _showSplash = true;
  GoRouter? _router;
  AppLifecycleState? _lastLifecycleState;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String? _lastLoggedRoute; // Track last logged route for navigation logging

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Log lifecycle changes
    AppLoggerService().logAppLifecycle(state.toString());
    
    // Lock app when it goes to background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _appLockService.lockApp();
    }
    
    _lastLifecycleState = state;
  }

  Future<void> _initializeApp() async {
    try {
      AppLoggerService().logAppLifecycle('App starting');
      
      // Load preferences first to get theme
      await _loadPreferences();
      
      // Start initialization timer
      final initStartTime = DateTime.now();
      
      await _checkAuthState();
      _router = _createRouter();
      
      AppLoggerService().logRouteChange(_initialRoute);
      AppLoggerService().logAppLifecycle('App initialized');
      
      // Calculate elapsed time
      final elapsedTime = DateTime.now().difference(initStartTime);
      final minSplashDuration = const Duration(milliseconds: 2000);
      
      // Wait for minimum splash duration if initialization was too fast
      if (elapsedTime < minSplashDuration) {
        await Future.delayed(minSplashDuration - elapsedTime);
      }
      
      // Add a small delay for smooth fade out transition
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Wait a bit then fade out splash smoothly
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) {
            setState(() {
              _showSplash = false;
            });
          }
        });
      }
    } catch (e) {
      print('Error initializing app: $e');
      // Fallback to default route if initialization fails
      _initialRoute = '/onboarding';
      _router = _createRouter();
      
      // Ensure minimum splash duration even on error
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // Add fade out delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _showSplash = false;
            });
          }
        });
      }
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _currentTheme = prefs.getString('theme') ?? 'light';
      });
      await _languageService.loadLocale();
      setState(() {
        _currentLocale = _languageService.currentLocale;
      });
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  Future<void> _checkAuthState() async {
    try {
      final isAuthenticated = await _authService.isAuthenticated();
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      
      // Check app lock status
      final isAppLockEnabled = await _appLockService.isAppLockEnabled();
      if (isAppLockEnabled && isAuthenticated) {
        // Lock the app on startup if app lock is enabled
        await _appLockService.lockApp();
      }
      
      if (isAuthenticated) {
        _initialRoute = '/dashboard';
      } else if (hasSeenOnboarding) {
        _initialRoute = '/signin';
      } else {
        _initialRoute = '/onboarding';
      }
    } catch (e) {
      print('Error checking auth state: $e');
      _initialRoute = '/onboarding';
    }
  }

  void changeTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
    setState(() {
      _currentTheme = theme;
    });
  }

  GoRouter _createRouter() {
    // Capture 'this' reference for use in router
    final themeChangeCallback = changeTheme;
    final appLogger = AppLoggerService();
    
    return GoRouter(
      navigatorKey: _navigatorKey,
      initialLocation: _initialRoute,
      observers: [
        // Log navigation events
        _NavigationObserver(),
      ],
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const BackButtonHandler(
            child: OnboardingScreen(),
          ),
        ),
        GoRoute(
          path: '/signin',
          builder: (context, state) => const BackButtonHandler(
            child: SignInScreen(),
          ),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const BackButtonHandler(
            child: SignUpScreen(),
          ),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const BackButtonHandler(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/templates',
          builder: (context, state) => const BackButtonHandler(
            child: TemplatesScreen(),
          ),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) {
            final status = state.uri.queryParameters['status'];
            return BackButtonHandler(
              child: HistoryScreen(initialStatus: status),
            );
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) {
            return BackButtonHandler(
              child: SettingsScreen(
                onThemeChanged: themeChangeCallback,
              ),
            );
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const BackButtonHandler(
            child: ProfileScreen(),
          ),
        ),
        GoRoute(
          path: '/security',
          builder: (context, state) => const BackButtonHandler(
            child: SecurityScreen(),
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const BackButtonHandler(
            child: NotificationsScreen(),
          ),
        ),
        GoRoute(
          path: '/form-selection',
          builder: (context, state) => const BackButtonHandler(
            child: FormSelectionScreen(),
          ),
        ),
        GoRoute(
          path: '/document-upload',
          builder: (context, state) => const BackButtonHandler(
            child: DocumentUploadScreen(),
          ),
        ),
        GoRoute(
          path: '/conversational-form',
          builder: (context, state) {
            final formId = state.uri.queryParameters['formId'];
            return BackButtonHandler(
              child: ConversationalFormScreen(formId: formId),
            );
          },
        ),
        GoRoute(
          path: '/review',
          builder: (context, state) {
            final formId = state.uri.queryParameters['formId'];
            return BackButtonHandler(
              child: ReviewScreen(formId: formId),
            );
          },
        ),
        GoRoute(
          path: '/app-lock',
          builder: (context, state) => const AppLockScreen(),
        ),
        GoRoute(
          path: '/app-lock-setup',
          builder: (context, state) {
            final type = state.uri.queryParameters['type'] ?? 'pin';
            return AppLockSetupScreen(
              lockType: type,
              isChanging: false,
            );
          },
        ),
      ],
      onException: (context, state, exception) {
        AppLoggerService().logError('Navigation', exception);
        return null;
      },
      redirect: (context, state) async {
        // Log route changes - GoRouter calls redirect on every route change
        final currentPath = state.uri.path.isNotEmpty ? state.uri.path : state.matchedLocation;
        if (currentPath.isNotEmpty && currentPath != _lastLoggedRoute) {
          // Log navigation if route changed
          if (_lastLoggedRoute != null) {
            appLogger.logNavigation(_lastLoggedRoute!, currentPath, 
              params: state.uri.queryParameters);
          }
          appLogger.logRouteChange(currentPath);
          _lastLoggedRoute = currentPath;
        }
        
        // Log navigation redirects (when path differs from matched location)
        if (state.uri.path != state.matchedLocation && 
            state.matchedLocation.isNotEmpty && 
            state.uri.path.isNotEmpty) {
          appLogger.logNavigation(state.matchedLocation, state.uri.path, 
            params: state.uri.queryParameters);
        }
        // Don't redirect if already on lock screen or setup screen
        if (state.uri.path == '/app-lock' || state.uri.path == '/app-lock-setup') {
          return null;
        }
        
        // Don't redirect if on auth screens
        if (state.uri.path == '/onboarding' || 
            state.uri.path == '/signin' || 
            state.uri.path == '/signup') {
          return null;
        }
        
        // Check if user is authenticated
        final isAuthenticated = await _authService.isAuthenticated();
        if (!isAuthenticated) {
          return null; // Don't check app lock if not authenticated
        }
        
        // Check if app lock is enabled and app is locked
        final appLockService = AppLockService();
        final isEnabled = await appLockService.isAppLockEnabled();
        final isLocked = await appLockService.isAppLocked();
        
        // If app lock is enabled and app is locked, redirect to lock screen
        if (isEnabled && isLocked) {
          return '/app-lock';
        }
        
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _appTheme.getTheme(_currentTheme);
    
    // Show splash screen while loading or if explicitly set
    if (_showSplash || _isLoading || _router == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: themeData, // Apply theme to splash screen
        locale: _currentLocale,
        supportedLocales: LanguageService.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SplashScreen(
          key: const ValueKey('splash'),
          theme: _currentTheme,
          onInitializationComplete: () {
            // This will be called when splash completes
          },
        ),
      );
    }
    
    return MaterialApp.router(
      title: 'Fillora.in',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      locale: _currentLocale,
      supportedLocales: LanguageService.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router!,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: _DebugButtonOverlay(
            child: child!,
            navigatorKey: _navigatorKey,
          ),
        );
      },
    );
  }
}


