import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../widgets/bottom_navigation.dart';
import '../widgets/stat_card.dart';
import '../widgets/action_card.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../services/template_service.dart';
import '../models/form_model.dart';
import '../services/app_logger_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _db = DatabaseService();
  final TemplateService _templateService = TemplateService();
  final _uuid = const Uuid();
  Map<String, dynamic>? _stats;
  List<FormModel> _recentForms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AppLoggerService().logScreenEvent('DashboardScreen', 'Initialized');
    _loadData();
  }

  @override
  void dispose() {
    AppLoggerService().logScreenEvent('DashboardScreen', 'Disposed');
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when screen becomes visible
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load stats and recent forms in parallel
    final stats = await _analytics.getDashboardStats();
    final allForms = await _db.getAllForms();
    
    // Get the 3 most recent forms
    final recentForms = allForms.take(3).toList();
    
    setState(() {
      _stats = stats;
      _recentForms = recentForms;
      _isLoading = false;
    });
  }

  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Last updated 1 day ago';
      } else if (difference.inDays < 7) {
        return 'Last updated ${difference.inDays} days ago';
      } else {
        return 'Last updated ${DateFormat('MMM d').format(date)}';
      }
    } else if (difference.inHours > 0) {
      return 'Last updated ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return 'Last updated ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
  
  String _getStatusText(FormModel form) {
    // Treat forms with 100% progress as completed
    final isCompleted = form.status == 'completed' || 
                        form.status == 'submitted' || 
                        form.progress >= 100.0;
    
    if (isCompleted) {
      if (form.submittedAt != null) {
        return 'Submitted';
      }
      return 'Completed';
    } else if (form.status == 'in_progress') {
      // Progress is already stored as 0-100, so just convert to int
      return '${form.progress.toInt()}%';
    }
    return 'Draft';
  }

  Future<void> _startFormFromTemplate(String templateId) async {
    try {
      // Get template by ID
      final template = await _templateService.getTemplateById(templateId);
      if (template == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template not found')),
          );
        }
        return;
      }

      // Increment usage count
      await _templateService.incrementUsageCount(templateId);
      
      // Get template structure
      final formStructureJson = template['formStructure'] as String? ?? '{}';
      final formStructure = jsonDecode(formStructureJson) as Map<String, dynamic>;
      final fields = formStructure['fields'] as List<dynamic>? ?? [];
      
      // Initialize form data with empty values for each field
      // Also build metadata with required field information
      final formData = <String, dynamic>{};
      final fieldMetadata = <String, dynamic>{};
      int pageNumber = 1;
      const fieldsPerPage = 6;
      int fieldsInCurrentPage = 0;
      
      for (var field in fields) {
        final fieldMap = field as Map<String, dynamic>;
        final fieldName = fieldMap['name'] as String;
        final fieldType = fieldMap['type'] as String? ?? 'text';
        final isRequired = fieldMap['required'] == true;
        
        // Store field metadata including required flag and page number
        fieldMetadata[fieldName] = {
          'type': fieldType,
          'required': isRequired,
          'page': pageNumber,
          'options': fieldMap['options'],
          'description': fieldMap['description'],
        };
        
        // Set default empty values based on field type
        switch (fieldType) {
          case 'number':
            formData[fieldName] = null;
            break;
          case 'date':
            formData[fieldName] = null;
            break;
          case 'textarea':
            formData[fieldName] = '';
            break;
          case 'radio':
          case 'dropdown':
          case 'select':
            formData[fieldName] = null;
            break;
          case 'checkbox':
            formData[fieldName] = <String>[];
            break;
          default:
            formData[fieldName] = '';
        }
        
        // Organize fields into pages
        fieldsInCurrentPage++;
        if (fieldsInCurrentPage >= fieldsPerPage) {
          pageNumber++;
          fieldsInCurrentPage = 0;
        }
      }
      
      // Store metadata in description
      String? description = template['description'] as String?;
      final metadataJson = jsonEncode(fieldMetadata);
      description = description != null 
          ? '$description\n__METADATA__:$metadataJson'
          : '__METADATA__:$metadataJson';
      
      // Create new form from template
      final formId = _uuid.v4();
      final form = FormModel(
        id: formId,
        title: template['name'] as String,
        description: description,
        formData: formData,
        status: 'in_progress',
        progress: 0.0,
        createdAt: DateTime.now(),
        templateId: templateId,
      );
      
      // Save form to database
      await _db.insertForm(form);
      
      // Navigate directly to conversational form
      if (mounted) {
        AppLoggerService().logFormAction('Opening form from dashboard', 
          formId: formId);
        context.go('/conversational-form?formId=$formId&from=dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting form: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Calculate bottom navigation height: 
    // top margin (12) + vertical padding (24) + nav item height (~48 including FAB) + bottom margin (12 + bottomPadding)
    // Approximate total: ~96px + system bottom padding
    final bottomNavHeight = 96 + bottomPadding;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: 24.0 + bottomNavHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Forms',
                              style: theme.textTheme.displaySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'What form are we tackling today?',
                              style: theme.textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No new notifications'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.person_outline),
                            onPressed: () => context.go('/settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Quick Stats
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _stats == null
                          ? const SizedBox()
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: StatCard(
                                    icon: Icons.check_circle_outline_rounded,
                                    value: '${_stats!['completed'] ?? 0}',
                                    label: 'Completed',
                                    onTap: () {
                                      context.go('/history?status=completed');
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StatCard(
                                    icon: Icons.trending_up_rounded,
                                    value: '${_stats!['inProgress'] ?? 0}',
                                    label: 'In Progress',
                                    onTap: () {
                                      context.go('/history?status=in_progress');
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StatCard(
                                    icon: Icons.access_time_rounded,
                                    value: '${_stats!['totalTimeSaved'] ?? 0}m',
                                    label: 'Time Saved',
                                  ),
                                ),
                              ],
                            ),
                  const SizedBox(height: 32),
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      ActionCard(
                        icon: Icons.school_rounded,
                        label: 'Scholarship',
                        onTap: () => _startFormFromTemplate('scholarship'),
                      ),
                      ActionCard(
                        icon: Icons.credit_card_rounded,
                        label: 'Passport',
                        onTap: () => _startFormFromTemplate('passport'),
                      ),
                      ActionCard(
                        icon: Icons.cast_for_education_rounded,
                        label: 'Admission',
                        onTap: () => _startFormFromTemplate('admission'),
                      ),
                      ActionCard(
                        icon: Icons.work_outline_rounded,
                        label: 'Job Application',
                        onTap: () => _startFormFromTemplate('job'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // AI Tip Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyMedium,
                              children: [
                                const TextSpan(
                                  text: 'Tip: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(
                                  text: 'First upload your documents for faster form filling !!!',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Recent Forms
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Recent Forms',
                          style: theme.textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/history'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _recentForms.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No forms yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your first form to get started',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            ...List.generate(
                              _recentForms.length,
                              (index) {
                                final form = _recentForms[index];
                                // Treat forms with 100% progress as completed
                                final isCompleted = form.status == 'completed' || 
                                                    form.status == 'submitted' || 
                                                    form.progress >= 100.0;
                                String dateText;
                                if (form.submittedAt != null) {
                                  final diff = DateTime.now().difference(form.submittedAt!);
                                  if (diff.inDays == 0) {
                                    dateText = 'Submitted today';
                                  } else if (diff.inDays == 1) {
                                    dateText = 'Submitted 1 day ago';
                                  } else if (diff.inDays < 7) {
                                    dateText = 'Submitted ${diff.inDays} days ago';
                                  } else {
                                    dateText = 'Submitted ${DateFormat('MMM d').format(form.submittedAt!)}';
                                  }
                                } else if (form.updatedAt != null) {
                                  dateText = _formatDate(form.updatedAt!);
                                } else {
                                  dateText = _formatDate(form.createdAt);
                                }
                                
                                return Padding(
                                  padding: EdgeInsets.only(bottom: index < _recentForms.length - 1 ? 12 : 0),
                                  child: _FormCard(
                                    title: form.title,
                                    date: dateText,
                                    progress: form.progress,
                                    status: _getStatusText(form),
                                    isCompleted: isCompleted,
                                    onTap: () {
                                      if (isCompleted) {
                                        AppLoggerService().logFormAction('Opening form for review from dashboard', 
                                          formId: form.id,
                                          formTitle: form.title);
                                        context.go('/review?formId=${form.id}&from=dashboard');
                                      } else {
                                        AppLoggerService().logFormAction('Opening form to fill from dashboard', 
                                          formId: form.id,
                                          formTitle: form.title);
                                        context.go('/conversational-form?formId=${form.id}&from=dashboard');
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                ],
              ),
            ),
            // Bottom Navigation
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavigation(currentRoute: '/dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final String date;
  final double progress;
  final String status;
  final bool isCompleted;
  final VoidCallback onTap;

  const _FormCard({
    required this.title,
    required this.date,
    required this.progress,
    required this.status,
    this.isCompleted = false,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.withOpacity(0.1)
                            : theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCompleted) ...[
                            Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              status,
                              style: TextStyle(
                                color: isCompleted
                                    ? Colors.green
                                    : theme.colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: isCompleted ? 1.0 : (progress / 100.0).clamp(0.0, 1.0),
                  backgroundColor: theme.dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted
                        ? Colors.green
                        : theme.colorScheme.primary,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

