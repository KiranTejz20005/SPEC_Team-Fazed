import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/app_logger_service.dart';

class BackButtonHandler extends StatelessWidget {
  final Widget child;
  static const MethodChannel _channel = MethodChannel('fillora.app/background');

  const BackButtonHandler({
    super.key,
    required this.child,
  });

  static Future<void> _handleBackButton(BuildContext context) async {
    final router = GoRouter.of(context);
    
    // Get current location from router - use path instead of full URI
    String currentLocation;
    String? queryParam;
    String? formId;
    try {
      final uri = router.routerDelegate.currentConfiguration.uri;
      currentLocation = uri.path;
      queryParam = uri.queryParameters['from'];
      formId = uri.queryParameters['formId'];
    } catch (e) {
      // Fallback: try to get from router location
      final fullUri = router.routerDelegate.currentConfiguration.uri.toString();
      // Remove query params if any
      if (fullUri.contains('?')) {
        final parts = fullUri.split('?');
        currentLocation = parts[0];
        if (parts.length > 1) {
          final queryString = parts[1];
          if (queryString.contains('from=')) {
            queryParam = queryString.split('from=')[1].split('&')[0];
          }
          if (queryString.contains('formId=')) {
            formId = queryString.split('formId=')[1].split('&')[0];
          }
        }
      } else {
        currentLocation = fullUri;
      }
    }
    
    AppLoggerService().logUserInteraction('Back button pressed', 
      details: 'From: $currentLocation');
    
    // Check if we can pop the navigation stack
    if (router.canPop()) {
      router.pop();
      return;
    }
    
    // Define bottom navigation routes (accessed directly from bottom nav)
    final bottomNavRoutes = [
      '/history',
      '/settings',
    ];
    
    // Handle different route types
    String? targetRoute;
    if (currentLocation == '/form-selection') {
      // Start a New Form: navigate to templates page
      targetRoute = '/templates';
    } else if (currentLocation == '/document-upload') {
      // Document Upload: navigate back to form selection
      targetRoute = '/form-selection';
    } else if (currentLocation == '/templates') {
      // Templates: check if we came from form-selection via query param
      if (queryParam == 'form-selection') {
        // Came from form-selection, go back to form-selection
        targetRoute = '/form-selection';
      } else {
        // Came from bottom nav, go to dashboard
        targetRoute = '/dashboard';
      }
    } else if (bottomNavRoutes.contains(currentLocation)) {
      // Bottom nav routes (history, settings): navigate to dashboard when using gesture back
      targetRoute = '/dashboard';
    } else if (currentLocation == '/conversational-form' || 
               currentLocation == '/review') {
      // Form filling flow: check where we came from
      if (queryParam == 'templates') {
        // Came from templates, go back to templates
        targetRoute = '/templates';
      } else if (queryParam == 'form-selection' || queryParam == 'url') {
        // Came from form selection or URL, go back to form selection
        targetRoute = '/form-selection';
      } else if (queryParam == 'history') {
        // Came from history, go back to history
        targetRoute = '/history';
      } else if (queryParam == 'dashboard') {
        // Came from dashboard, go back to dashboard
        targetRoute = '/dashboard';
      } else {
        // Default: navigate back to document upload
        targetRoute = '/document-upload';
      }
    } else if (currentLocation == '/dashboard') {
      // Dashboard: move to background instead of closing
      AppLoggerService().logAppLifecycle('App moving to background');
      try {
        await _channel.invokeMethod('moveToBackground');
      } catch (e) {
        debugPrint('Method channel error: $e');
        // If method channel fails, try alternative approach
        SystemNavigator.pop();
      }
      return;
    } else if (currentLocation == '/profile') {
      // Profile: navigate to dashboard
      targetRoute = '/dashboard';
    } else if (currentLocation == '/onboarding' ||
               currentLocation == '/signin' ||
               currentLocation == '/signup') {
      // At entry points, allow app to close
      AppLoggerService().logAppLifecycle('App closing');
      SystemNavigator.pop();
      return;
    } else {
      // Unknown route: navigate to dashboard
      targetRoute = '/dashboard';
    }
    
    if (targetRoute != null) {
      AppLoggerService().logNavigation(currentLocation, targetRoute);
      router.go(targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the child with PopScope to intercept back button
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _handleBackButton(context);
        }
      },
      child: child,
    );
  }
}
