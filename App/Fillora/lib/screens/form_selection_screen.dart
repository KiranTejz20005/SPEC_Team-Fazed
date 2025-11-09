import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/url_form_service.dart' show UrlFormService, GoogleFormAuthenticationRequiredException;
import '../services/debug_log_service.dart';
import '../widgets/debug_console_widget.dart';
import '../services/debug_console_service.dart';
import 'google_form_webview_screen.dart';
import '../services/app_logger_service.dart';
import '../services/database_service.dart';
import 'google_account_selection_dialog.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class FormSelectionScreen extends StatefulWidget {
  const FormSelectionScreen({super.key});

  @override
  State<FormSelectionScreen> createState() => _FormSelectionScreenState();
}

class _FormSelectionScreenState extends State<FormSelectionScreen> {
  final UrlFormService _urlFormService = UrlFormService();
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/dashboard');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Start a New Form',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How would you like to begin?',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),
                    _OptionCard(
                      icon: Icons.upload_file_rounded,
                      title: 'Upload Form Template',
                      subtitle: 'PDF or Image',
                      onTap: () => context.push('/document-upload'),
                    ),
                    const SizedBox(height: 16),
                    _OptionCard(
                      icon: Icons.link_rounded,
                      title: 'Enter Form URL',
                      subtitle: 'Web Form',
                      onTap: () {
                        _showUrlDialog(context);
                      },
                    ),
                    const SizedBox(height: 16),
                    _OptionCard(
                      icon: Icons.folder_outlined,
                      title: 'Browse Common Forms',
                      subtitle: 'Library of templates',
                      onTap: () => context.push('/templates?from=form-selection'),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Fillora.in will analyze your form to understand its requirements.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _UrlDialogContent(
          key: ValueKey('url_dialog_${DateTime.now().millisecondsSinceEpoch}'),
          isAnalyzing: _isAnalyzing,
          onAnalyze: (url) async {
            setState(() => _isAnalyzing = true);
            
            // Don't clear logs - preserve history
            DebugLogService().info('Starting form analysis for: $url');
            
            // Show simple loading dialog (no debug console - use floating button instead)
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (loadingContext) {
                return AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Analyzing Form',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        url,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Check the debug console for detailed logs',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            );

            try {
              // Analyze URL and create form
              final form = await _urlFormService.analyzeUrlAndCreateForm(url);
              
              if (!context.mounted) return;
              
              if (form != null) {
                DebugLogService().success('✓ Form created successfully with ${form.formData?.length ?? 0} fields');
                // Wait longer to show the success message and allow user to see logs
                await Future.delayed(const Duration(seconds: 2));
                
                // Close loading dialog
                if (context.mounted) {
                  Navigator.of(context).pop();
                  
                  // Navigate to conversational form with the created form ID and source
                  AppLoggerService().logFormAction('Form created from URL', 
                    formId: form.id, 
                    formTitle: form.title);
                  context.go('/conversational-form?formId=${form.id}&from=url');
                }
              } else {
                DebugLogService().error('✗ Failed to create form');
                DebugLogService().info('Please review the logs above. Close this dialog when done.');
                // Don't auto-close on error - let user review logs and close manually
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to analyze form. Check the debug console for details.'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
                // Dialog stays open - user can close manually using the Close button
              }
            } catch (e) {
              if (!context.mounted) return;
              
              // Check if it's an authentication required error
              // Check both the exception type and message
              final isAuthException = e is GoogleFormAuthenticationRequiredException;
              final errorMessage = e.toString();
              final isAuthError = isAuthException || 
                  errorMessage.contains('requires authentication') || 
                  errorMessage.contains('Please select a Google account') ||
                  errorMessage.contains('Google Form requires authentication');
              
              if (isAuthError) {
                // Close loading dialog first
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                
                // Show WebView for Google Form authentication
                DebugLogService().info('Google Form requires authentication. Opening WebView for sign-in...');
                AppLoggerService().logAuth('Opening WebView for Google Form authentication', provider: 'google');
                
                // Navigate to WebView screen
                final extractedHtml = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (context) => GoogleFormWebViewScreen(formUrl: url),
                    fullscreenDialog: true,
                  ),
                );
                
                if (extractedHtml == null || !context.mounted) {
                  // User cancelled or closed the WebView
                  if (mounted) setState(() => _isAnalyzing = false);
                  return;
                }
                
                // Retry form analysis with the extracted HTML
                DebugLogService().info('Retrying form analysis with HTML from WebView...');
                AppLoggerService().logFormAction('Retrying form analysis with WebView HTML');
                
                // Show loading dialog again
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingContext2) {
                    return AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Analyzing Form',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Processing form data...',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                );
                
                try {
                  // Use the URL form service to analyze the extracted HTML
                  // Pass the HTML content directly to the service
                  DebugLogService().info('Analyzing form with extracted HTML (${extractedHtml.length} chars)...');
                  final form = await _urlFormService.analyzeUrlAndCreateForm(url, htmlContent: extractedHtml);
                  
                  if (!context.mounted) return;
                  
                  // Close loading dialog
                  Navigator.of(context).pop();
                  
                  if (form != null) {
                    DebugLogService().success('✓ Form created successfully with ${form.formData?.length ?? 0} fields');
                    DebugLogService().info('Form ID: ${form.id}');
                    DebugLogService().info('Form Title: ${form.title}');
                    DebugLogService().info('Form Status: ${form.status}');
                    DebugLogService().info('Form saved to database: ${form.id}');
                    await Future.delayed(const Duration(seconds: 1));
                    
                    AppLoggerService().logFormAction('Form created from URL (WebView)', 
                      formId: form.id, 
                      formTitle: form.title);
                    
                    // Ensure form is saved to database before navigation
                    final dbService = DatabaseService();
                    await dbService.insertForm(form);
                    DebugLogService().info('Form confirmed saved to database: ${form.id}');
                    
                    context.go('/conversational-form?formId=${form.id}&from=url');
                  } else {
                    DebugLogService().error('✗ Failed to create form');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to analyze form. Please try again.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                } catch (retryError) {
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  DebugLogService().error('✗ Error: ${retryError.toString()}');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${retryError.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isAnalyzing = false);
                }
                
                return;
              } else {
                // Other error
                DebugLogService().error('✗ Error: ${e.toString()}');
                DebugLogService().info('Please review the logs above. Close this dialog when done.');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error occurred. Check the debug console for details.'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            } finally {
              if (mounted) {
                setState(() => _isAnalyzing = false);
              }
            }
          },
        );
      },
    );
  }
}

class _UrlDialogContent extends StatefulWidget {
  final bool isAnalyzing;
  final Function(String) onAnalyze;

  _UrlDialogContent({
    super.key,
    required this.isAnalyzing,
    required this.onAnalyze,
  });

  @override
  State<_UrlDialogContent> createState() => _UrlDialogContentState();
}

class _UrlDialogContentState extends State<_UrlDialogContent> {
  late final TextEditingController _urlController;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    // Create a fresh controller - always empty
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      // Clear the controller first to remove text
      _urlController.clear();
      // Dispose the controller - Flutter will handle removing it from TextField
      _urlController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Form URL'),
      content: TextField(
        controller: _urlController,
        decoration: const InputDecoration(
          hintText: 'Enter / Paste the URL of the form',
          labelText: 'Form URL',
          helperText: 'Enter a Google Forms URL or any web form URL',
        ),
        keyboardType: TextInputType.url,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        Builder(
          builder: (context) {
            final theme = Theme.of(context);
            
            return FilledButton.icon(
              onPressed: widget.isAnalyzing ? null : () {
                if (_disposed) return;
                
                // Get the URL before popping the dialog
                final url = _urlController.text.trim();
                if (url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a URL')),
                  );
                  return;
                }

                // Pop dialog first, then call the callback
                Navigator.of(context).pop();
                // Use a post-frame callback to ensure dialog is fully closed
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onAnalyze(url);
                });
              },
              icon: widget.isAnalyzing 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(widget.isAnalyzing ? 'Analyzing...' : 'Analyze'),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.disabled)) {
                      return theme.colorScheme.surface.withOpacity(0.3);
                    }
                    // Use lighter grey for dark theme, primary color for other themes
                    return theme.brightness == Brightness.dark
                        ? const Color(0xFF333333) // Grey (20% white, 80% black) as requested
                        : theme.colorScheme.primary;
                  },
                ),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

