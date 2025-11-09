import '../services/debug_log_service.dart';
import 'package:go_router/go_router.dart';

/// Service to log all app events comprehensively
class AppLoggerService {
  static final AppLoggerService _instance = AppLoggerService._internal();
  factory AppLoggerService() => _instance;
  AppLoggerService._internal();

  final DebugLogService _logService = DebugLogService();

  /// Log app lifecycle events
  void logAppLifecycle(String state) {
    _logService.info('App lifecycle: $state');
  }

  /// Log navigation events
  void logNavigation(String from, String to, {Map<String, String>? params}) {
    final paramsStr = params != null && params.isNotEmpty 
        ? ' (params: ${params.entries.map((e) => '${e.key}=${e.value}').join(', ')})'
        : '';
    _logService.info('Navigation: $from → $to$paramsStr');
  }

  /// Log route changes
  void logRouteChange(String route) {
    _logService.info('Route changed to: $route');
  }

  /// Log user interactions
  void logUserInteraction(String action, {String? details}) {
    final detailsStr = details != null ? ' - $details' : '';
    _logService.info('User interaction: $action$detailsStr');
  }

  /// Log template operations
  void logTemplateAction(String action, {String? templateId, String? templateName}) {
    final idStr = templateId != null ? ' (ID: $templateId)' : '';
    final nameStr = templateName != null ? ' - $templateName' : '';
    _logService.info('Template: $action$idStr$nameStr');
  }

  /// Log form operations
  void logFormAction(String action, {String? formId, String? formTitle, Map<String, dynamic>? details}) {
    final idStr = formId != null ? ' (ID: $formId)' : '';
    final titleStr = formTitle != null ? ' - $formTitle' : '';
    final detailsStr = details != null && details.isNotEmpty 
        ? ' (${details.entries.map((e) => '${e.key}=${e.value}').join(', ')})'
        : '';
    _logService.info('Form: $action$idStr$titleStr$detailsStr');
  }

  /// Log page transitions
  void logPageTransition(String fromPage, String toPage, {int? pageNumber, int? totalPages}) {
    final pageStr = pageNumber != null && totalPages != null 
        ? ' (Page $pageNumber/$totalPages)'
        : '';
    _logService.info('Page transition: $fromPage → $toPage$pageStr');
  }

  /// Log swipe gestures
  void logSwipe(String direction, {String? context}) {
    final contextStr = context != null ? ' in $context' : '';
    _logService.info('Swipe: $direction$contextStr');
  }

  /// Log screen events
  void logScreenEvent(String screen, String event, {Map<String, dynamic>? details}) {
    final detailsStr = details != null && details.isNotEmpty 
        ? ' (${details.entries.map((e) => '${e.key}=${e.value}').join(', ')})'
        : '';
    _logService.info('Screen [$screen]: $event$detailsStr');
  }

  /// Log field interactions
  void logFieldInteraction(String fieldName, String action, {String? value, String? fieldType}) {
    final typeStr = fieldType != null ? ' ($fieldType)' : '';
    final valueStr = value != null ? ' = "$value"' : '';
    _logService.info('Field $fieldName$typeStr: $action$valueStr');
  }

  /// Log API calls
  void logApiCall(String endpoint, String method, {Map<String, dynamic>? params, int? statusCode}) {
    final paramsStr = params != null && params.isNotEmpty 
        ? ' (${params.entries.take(3).map((e) => '${e.key}=${e.value}').join(', ')}${params.length > 3 ? '...' : ''})'
        : '';
    final statusStr = statusCode != null ? ' → $statusCode' : '';
    _logService.info('API: $method $endpoint$paramsStr$statusStr');
  }

  /// Log errors
  void logError(String context, dynamic error, {StackTrace? stackTrace}) {
    _logService.error('Error in $context: $error');
    if (stackTrace != null) {
      _logService.error('Stack trace: $stackTrace');
    }
  }

  /// Log authentication events
  void logAuth(String action, {String? provider, bool? success}) {
    final providerStr = provider != null ? ' via $provider' : '';
    final successStr = success != null ? (success ? ' (success)' : ' (failed)') : '';
    _logService.info('Auth: $action$providerStr$successStr');
  }
}

