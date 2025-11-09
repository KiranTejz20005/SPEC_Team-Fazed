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
import '../services/auth_service.dart';
import '../models/form_model.dart';
import '../services/app_logger_service.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  final DatabaseService _db = DatabaseService();
  final TemplateService _templateService = TemplateService();
  final AuthService _authService = AuthService();
  final _uuid = const Uuid();
  Map<String, dynamic>? _stats;
  List<FormModel> _recentForms = [];
  bool _isLoading = true;
  String _userName = 'User';
  String _greeting = 'Good Morning';

  @override
  void initState() {
    super.initState();
    AppLoggerService().logScreenEvent('DashboardScreen', 'Initialized');
    _loadUserData();
    _loadData();
    _updateGreeting();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      setState(() => _greeting = 'Good Morning');
    } else if (hour < 17) {
      setState(() => _greeting = 'Good Afternoon');
    } else {
      setState(() => _greeting = 'Good Evening');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _userName = user['name']?.toString().split(' ').first ?? 'User';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    AppLoggerService().logScreenEvent('DashboardScreen', 'Disposed');
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final stats = await _analytics.getDashboardStats();
    final allForms = await _db.getAllForms();
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
    final isCompleted = form.status == 'completed' || 
                        form.status == 'submitted' || 
                        form.progress >= 100.0;
    
    if (isCompleted) {
      if (form.submittedAt != null) {
        return 'Submitted';
      }
      return 'Completed';
    } else if (form.status == 'in_progress') {
      return '${form.progress.toInt()}%';
    }
    return 'Draft';
  }

  Future<void> _startFormFromTemplate(String templateId) async {
    try {
      final template = await _templateService.getTemplateById(templateId);
      if (template == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template not found')),
          );
        }
        return;
      }

      await _templateService.incrementUsageCount(templateId);
      
      final formStructureJson = template['formStructure'] as String? ?? '{}';
      final formStructure = jsonDecode(formStructureJson) as Map<String, dynamic>;
      final fields = formStructure['fields'] as List<dynamic>? ?? [];
      
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
        
        fieldMetadata[fieldName] = {
          'type': fieldType,
          'required': isRequired,
          'page': pageNumber,
          'options': fieldMap['options'],
          'description': fieldMap['description'],
        };
        
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
        
        fieldsInCurrentPage++;
        if (fieldsInCurrentPage >= fieldsPerPage) {
          pageNumber++;
          fieldsInCurrentPage = 0;
        }
      }
      
      String? description = template['description'] as String?;
      final metadataJson = jsonEncode(fieldMetadata);
      description = description != null 
          ? '$description\n__METADATA__:$metadataJson'
          : '__METADATA__:$metadataJson';
      
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
      
      await _db.insertForm(form);
      
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
    final bottomNavHeight = 96 + bottomPadding;
    final timeNow = DateFormat('HH:mm').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 16.0,
                bottom: 24.0 + bottomNavHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                timeNow,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                _greeting,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search),
                            color: Colors.white,
                            onPressed: () {},
                          ),
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined),
                                color: Colors.white,
                                onPressed: () {},
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryOrange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            color: Colors.white,
                            onPressed: () => context.go('/settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Greeting with Orange Name
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(text: '$_greeting '),
                        TextSpan(
                          text: '$_userName!',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status Indicator
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primaryOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'All systems operational',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Quick Access Section
                  Text(
                    'Quick access',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      _QuickAccessCard(
                        icon: Icons.document_scanner,
                        title: 'Scan Document',
                        isActive: false,
                        onTap: () => context.push('/document-upload'),
                      ),
                      _QuickAccessCard(
                        icon: Icons.flash_on,
                        title: 'Lightning Fill Mode',
                        isActive: false,
                        onTap: () {},
                      ),
                      _QuickAccessCard(
                        icon: Icons.description,
                        title: 'Fillora Forms',
                        subtitle: 'Ready to assist',
                        isActive: true,
                        onTap: () => context.push('/form-selection'),
                      ),
                      _QuickAccessCard(
                        icon: Icons.bar_chart,
                        title: '0 Progress',
                        subtitle: 'Track forms',
                        isActive: false,
                        onTap: () => context.go('/history'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Smart Features Section
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Smart Features',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      _QuickAccessCard(
                        icon: Icons.camera_alt,
                        title: 'Camera Scan',
                        isActive: false,
                        onTap: () {},
                      ),
                      _QuickAccessCard(
                        icon: Icons.psychology,
                        title: 'AI Assistant',
                        isActive: false,
                        onTap: () {},
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

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isActive;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.darkSurface.withOpacity(0.8)
              : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.primaryOrange.withOpacity(0.3)
                : AppColors.darkBorder,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppColors.primaryOrange,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.white60,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
