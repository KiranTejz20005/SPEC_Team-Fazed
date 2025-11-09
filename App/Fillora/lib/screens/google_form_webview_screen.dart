import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'dart:convert';
import '../services/debug_log_service.dart';
import '../services/app_logger_service.dart';

/// Screen that opens Google Form in a WebView to allow user to sign in
/// and then extracts the form HTML for processing
class GoogleFormWebViewScreen extends StatefulWidget {
  final String formUrl;
  
  const GoogleFormWebViewScreen({
    super.key,
    required this.formUrl,
  });

  @override
  State<GoogleFormWebViewScreen> createState() => _GoogleFormWebViewScreenState();
}

class _GoogleFormWebViewScreenState extends State<GoogleFormWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  String? _extractedHtml;
  final Completer<String?> _htmlCompleter = Completer<String?>();
  Timer? _urlCheckTimer;
  bool _isExtracting = false;

  @override
  void initState() {
    super.initState();
    AppLoggerService().logScreenEvent('GoogleFormWebViewScreen', 'Initialized', 
      details: {'formUrl': widget.formUrl});
    
    _initializeWebView();
    _startUrlCheckTimer();
  }

  @override
  void dispose() {
    _urlCheckTimer?.cancel();
    super.dispose();
  }

  /// Start a periodic timer to check if we've navigated to the form page
  /// This helps catch cases where onPageFinished doesn't fire or we're on a security page
  void _startUrlCheckTimer() {
    _urlCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_extractedHtml != null || !mounted) {
        timer.cancel();
        return;
      }
      
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      try {
        final currentUrl = await _controller.currentUrl();
        if (currentUrl != null && _isFormPage(currentUrl) && mounted) {
          DebugLogService().info('URL check timer: Detected form page, extracting...');
          timer.cancel();
          if (mounted) {
            await _extractFormHtml();
          }
        }
      } catch (e) {
        // Ignore errors during URL check
        if (!mounted) {
          timer.cancel();
        }
      }
    });
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null; // Clear any previous errors
            });
            DebugLogService().info('WebView: Page started loading - $url');
            AppLoggerService().logRouteChange('WebView: $url');
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });
            DebugLogService().info('WebView: Page finished loading - $url');
            AppLoggerService().logRouteChange('WebView finished: $url');
            
            // Wait a bit for dynamic content to load
            await Future.delayed(const Duration(seconds: 2));
            
            // Check for "prompt expired" or error pages
            try {
              final pageText = await _controller.runJavaScriptReturningResult('document.body.innerText');
              if (pageText != null) {
                final text = pageText.toString().toLowerCase();
                if (text.contains('prompt has expired') || 
                    text.contains('this prompt has expired') ||
                    text.contains('session expired')) {
                  DebugLogService().warning('Detected expired prompt - user may need to retry');
                  // Don't show error, just log it - user can reload
                }
              }
            } catch (e) {
              // Ignore errors checking page content
            }
            
            // Check if we're on the actual form page (not sign-in, security checkup, or password change pages)
            if (_isFormPage(url)) {
              DebugLogService().info('Detected form page, starting extraction...');
              // Wait a bit more for the form to fully render and JavaScript to initialize
              await Future.delayed(const Duration(seconds: 3));
              // Automatically extract the form HTML
              await _extractFormHtml();
            } else if (_isSecurityOrAccountPage(url)) {
              // We're on a security checkup, password change, or account selection page
              // These pages should eventually redirect to the form, so we just wait
              DebugLogService().info('WebView: On security/account page, waiting for redirect to form...');
            } else if (url.contains('accounts.google.com') || url.contains('signin')) {
              // We're on a sign-in page, wait for user to complete sign-in
              DebugLogService().info('WebView: On sign-in page, waiting for user action...');
            }
          },
          onWebResourceError: (WebResourceError error) {
            DebugLogService().error('WebView error: ${error.description} (code: ${error.errorCode})');
            AppLoggerService().logError('WebView resource error', Exception('${error.description} (code: ${error.errorCode})'));
            
            // Some error codes are recoverable or expected during navigation
            // -2: ERROR_HOST_LOOKUP (DNS failure)
            // -6: ERROR_CONNECT (connection failure)
            // -8: ERROR_TIMEOUT
            // -14: ERROR_PROXY_AUTHENTICATION_REQUIRED
            // -1: ERR_FAILED (generic failure, often occurs when app goes to background)
            // Only show critical errors immediately, and be lenient with network errors
            if (error.errorCode == -2 || error.errorCode == -6 || error.errorCode == -8 || error.errorCode == -1) {
              // Network errors or generic failures - might be temporary (e.g., app went to background)
              // Wait a bit and check if page is still loading
              Future.delayed(const Duration(seconds: 2), () async {
                if (mounted && _errorMessage == null && _extractedHtml == null) {
                  // Check if we can still access the current URL (page might have loaded)
                  try {
                    final currentUrl = await _controller.currentUrl();
                    if (currentUrl != null && currentUrl.isNotEmpty) {
                      // Page is accessible, might have been a transient error
                      DebugLogService().info('Page is accessible after error, continuing...');
                      return;
                    }
                  } catch (e) {
                    // Can't access URL, show error
                  }
                  
                  // Only show error if page is truly not accessible
                  if (mounted) {
                    setState(() {
                      _errorMessage = 'Network error: ${error.description}\n\nPlease check your internet connection and try again.';
                      _isLoading = false;
                    });
                  }
                }
              });
            } else {
              // Other errors - show immediately
              if (mounted) {
                setState(() {
                  _errorMessage = 'Failed to load page: ${error.description}';
                  _isLoading = false;
                });
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            DebugLogService().info('WebView: Navigation requested to ${request.url}');
            // Allow all navigation
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'HtmlExtractor',
        onMessageReceived: (JavaScriptMessage message) {
          final html = message.message;
          if (html.isNotEmpty && !_htmlCompleter.isCompleted && mounted) {
            DebugLogService().info('Received HTML via JavaScriptChannel (${html.length} chars)');
            if (mounted) {
              setState(() {
                _extractedHtml = html;
                _isExtracting = false;
              });
            }
            _urlCheckTimer?.cancel();
            _htmlCompleter.complete(html);
            // Automatically close the WebView and return the HTML after a short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.of(context).pop(html);
              }
            });
          }
        },
      );
    
    // Load the URL
    _controller.loadRequest(Uri.parse(widget.formUrl));
  }

  Future<void> _extractFormHtml() async {
    if (_isExtracting) {
      DebugLogService().info('Extraction already in progress, skipping...');
      return;
    }
    
    try {
      setState(() {
        _isExtracting = true;
      });
      
      // Wait a bit for the page to fully render and any dynamic content to load
      await Future.delayed(const Duration(seconds: 2));
      
      // First, check if we're actually on a form page
      final currentUrl = await _controller.currentUrl();
      if (currentUrl == null || !_isFormPage(currentUrl)) {
        DebugLogService().warning('Not on form page yet (current URL: $currentUrl), not extracting HTML');
        setState(() {
          _isExtracting = false;
        });
        return;
      }
      
      DebugLogService().info('Starting HTML extraction from form page: $currentUrl');
      
      // Wait for page to be fully loaded and JavaScript to execute
      // Check multiple times to ensure dynamic content is loaded
      bool hasFormContent = false;
      for (int attempt = 0; attempt < 5; attempt++) {
        final contentCheck = await _controller.runJavaScriptReturningResult('''
          (function() {
            if (!document.body) return false;
            
            // Check for Google Forms specific selectors
            const hasGoogleFormContent = (
              document.querySelector('.freebirdFormviewerViewFormContentWrapper') !== null ||
              document.querySelector('[data-viewid]') !== null ||
              document.querySelector('.freebirdFormviewerViewItemsItemItem') !== null ||
              document.querySelector('form[action*="forms"]') !== null ||
              document.querySelector('.freebirdFormviewerViewNavigationNavigateButton') !== null ||
              document.querySelector('.freebirdFormviewerViewItemsItemItemTitle') !== null ||
              document.querySelector('[data-params]') !== null
            );
            
            // Check for Google Forms data in script tags
            const hasFormData = (function() {
              const scripts = document.querySelectorAll('script');
              for (let i = 0; i < scripts.length; i++) {
                if (scripts[i].innerHTML && scripts[i].innerHTML.includes('FB_PUBLIC_LOAD_DATA')) {
                  return true;
                }
              }
              return false;
            })();
            
            // Check for generic form indicators
            const hasGenericForm = (
              document.querySelector('form') !== null ||
              document.querySelector('[role="form"]') !== null
            );
            
            // Check page title for form indicators
            const title = document.title.toLowerCase();
            const hasFormTitle = title.includes('form') || title.includes('survey') || title.includes('questionnaire');
            
            return hasGoogleFormContent || hasFormData || (hasGenericForm && hasFormTitle);
          })();
        ''');
        
        if (contentCheck != null && contentCheck.toString().toLowerCase() == 'true') {
          hasFormContent = true;
          DebugLogService().info('Form content detected on attempt ${attempt + 1}');
          break;
        }
        
        if (attempt < 4) {
          DebugLogService().info('Form content not yet detected, waiting... (attempt ${attempt + 1}/5)');
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      
      if (!hasFormContent) {
        DebugLogService().warning('Form content not detected after multiple attempts, proceeding anyway...');
      }
      
      // Additional wait to ensure all JavaScript has executed and DOM is ready
      await Future.delayed(const Duration(seconds: 2));
      
      // Use JavaScriptChannel to extract HTML (more reliable for large HTML)
      // First, check if the channel is available
      final channelCheck = await _controller.runJavaScriptReturningResult('''
        (function() {
          return typeof HtmlExtractor !== 'undefined';
        })();
      ''');
      
      if (channelCheck != null && channelCheck.toString().toLowerCase() == 'true') {
        DebugLogService().info('JavaScriptChannel is available, using it for extraction...');
        // Inject JavaScript that sends HTML via the channel
        await _controller.runJavaScript('''
          (function() {
            try {
              const html = document.documentElement.outerHTML;
              if (html && html.length > 100) {
                console.log('Sending HTML via JavaScriptChannel, length: ' + html.length);
                // Send HTML via JavaScriptChannel (will be received by HtmlExtractor)
                HtmlExtractor.postMessage(html);
              } else {
                console.error('HTML extraction failed: HTML too short or empty');
              }
            } catch(e) {
              console.error('HTML extraction error: ' + e.message);
            }
          })();
        ''');
        
        // Wait a bit for the JavaScriptChannel message to be received
        // The HTML will be set via the channel callback
        await Future.delayed(const Duration(seconds: 3));
      } else {
        DebugLogService().warning('JavaScriptChannel not available, using fallback method...');
      }
      
      // If HTML wasn't received via channel, try fallback method
      if (_extractedHtml == null) {
        DebugLogService().warning('HTML not received via channel, trying fallback method...');
        // Fallback: Try to get HTML using base64 encoding to avoid string length issues
        final htmlBase64 = await _controller.runJavaScriptReturningResult('''
          (function() {
            try {
              const html = document.documentElement.outerHTML;
              return btoa(html);
            } catch(e) {
              return '';
            }
          })();
        ''');
        
        if (htmlBase64 != null && htmlBase64.toString().isNotEmpty) {
          try {
            // Decode base64
            final htmlBytes = base64Decode(htmlBase64.toString().replaceAll('"', '').replaceAll("'", ''));
            final htmlString = utf8.decode(htmlBytes);
            
            if (htmlString.length > 100 && htmlString.contains('<html')) {
              if (mounted) {
                setState(() {
                  _extractedHtml = htmlString;
                  _isExtracting = false;
                });
              }
              
              DebugLogService().success('Successfully extracted HTML via fallback method (${htmlString.length} chars)');
              AppLoggerService().logFormAction('Form HTML extracted from WebView (fallback)', 
                details: {'htmlLength': htmlString.length});
              
              if (!_htmlCompleter.isCompleted) {
                _urlCheckTimer?.cancel();
                _htmlCompleter.complete(htmlString);
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    Navigator.of(context).pop(htmlString);
                  }
                });
              }
            }
          } catch (e) {
            DebugLogService().error('Error decoding base64 HTML: $e');
          }
        }
      }
      
      if (_extractedHtml == null) {
        DebugLogService().error('Failed to extract HTML - all methods failed');
        if (mounted) {
          setState(() {
            _isExtracting = false;
          });
        }
      }
    } catch (e, stackTrace) {
      DebugLogService().error('Error extracting HTML: $e');
      AppLoggerService().logError('HTML extraction error', e);
      if (mounted) {
        setState(() {
          _isExtracting = false;
        });
      }
      if (!_htmlCompleter.isCompleted) {
        _htmlCompleter.completeError(e);
      }
    }
  }

  Future<String?> getExtractedHtml() => _htmlCompleter.future;

  /// Check if the current URL is the actual form page (not sign-in, security, etc.)
  bool _isFormPage(String url) {
    // Must be a Google Forms URL
    if (!url.contains('docs.google.com/forms')) {
      return false;
    }
    
    // Must NOT be an accounts/sign-in page
    if (url.contains('accounts.google.com') || 
        url.contains('signin') || 
        url.contains('ServiceLogin') ||
        url.contains('InteractiveLogin')) {
      return false;
    }
    
    // Must NOT be a security checkup or password change page
    if (url.contains('security') || 
        url.contains('changepassword') || 
        url.contains('speedbump') ||
        url.contains('CheckCook')) {
      return false;
    }
    
    // Should contain viewform or edit in the path
    if (url.contains('/viewform') || url.contains('/edit')) {
      return true;
    }
    
    return false;
  }

  /// Check if the current URL is a security or account management page
  bool _isSecurityOrAccountPage(String url) {
    return url.contains('security') || 
           url.contains('changepassword') || 
           url.contains('speedbump') ||
           url.contains('CheckCook') ||
           url.contains('myaccount.google.com');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in to Google'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (!_htmlCompleter.isCompleted) {
              _htmlCompleter.complete(null);
            }
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _extractedHtml = null;
                _isLoading = true;
              });
              _controller.reload();
            },
            tooltip: 'Reload page',
          ),
          if (_extractedHtml != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop(_extractedHtml);
              },
              tooltip: 'Use this form',
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: theme.scaffoldBackgroundColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Google Form...',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please sign in if prompted',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_errorMessage != null)
            Container(
              color: theme.scaffoldBackgroundColor,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _isLoading = true;
                        });
                        // Reload the page
                        _controller.reload();
                        // Also try to restore navigation if needed
                        Future.delayed(const Duration(seconds: 1), () {
                          if (mounted && widget.formUrl.isNotEmpty) {
                            _controller.loadRequest(Uri.parse(widget.formUrl));
                          }
                        });
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF333333), // 20% white, 80% black (lighter grey)
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          if (_extractedHtml != null && !_isLoading)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.green,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Form extracted successfully! Closing...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

