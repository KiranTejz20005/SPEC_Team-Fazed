import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../widgets/bottom_navigation.dart';
import '../services/template_service.dart';
import '../services/database_service.dart';
import '../services/profile_autofill_service.dart';
import '../models/form_model.dart';
import '../services/app_logger_service.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final TemplateService _templateService = TemplateService();
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final _uuid = const Uuid();
  List<Map<String, dynamic>> _templates = [];
  List<Map<String, dynamic>> _filteredTemplates = [];
  String? _selectedCategory;
  bool _isLoading = true;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    AppLoggerService().logScreenEvent('TemplatesScreen', 'Initialized');
    _loadTemplates();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    AppLoggerService().logScreenEvent('TemplatesScreen', 'Disposed');
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    setState(() {
      _isSearchActive = _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;
    });
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final templates = await _templateService.getAllTemplates();
      if (mounted) {
        setState(() {
          _templates = templates;
          _filteredTemplates = templates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading templates: $e')),
          );
        }
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      AppLoggerService().logUserInteraction('Search', details: 'Query: "$query"');
    }
    setState(() {
      _isSearchActive = _searchFocusNode.hasFocus || query.isNotEmpty;
    });
    _filterTemplates(query, _selectedCategory);
  }

  void _filterTemplates(String query, String? category) async {
    List<Map<String, dynamic>> filtered;
    
    if (query.isNotEmpty) {
      filtered = await _templateService.searchTemplates(query);
    } else {
      filtered = List.from(_templates);
    }
    
    if (category != null) {
      filtered = filtered.where((t) => t['category'] == category).toList();
    }
    
    setState(() {
      _filteredTemplates = filtered;
    });
  }

  void _selectCategory(String? category) {
    if (category != null) {
      AppLoggerService().logUserInteraction('Category selected', details: category);
    }
    setState(() {
      _selectedCategory = category;
    });
    _filterTemplates(_searchController.text, category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
                          'Templates',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Search Templates'),
                              content: TextField(
                                controller: _searchController,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: 'Search templates...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Clear'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search templates...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white60,
                            ),
                            prefixIcon: const Icon(Icons.search, color: Colors.white70),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.white70),
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchFocusNode.unfocus();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.darkSurface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white30),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primaryOrange,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Category Filter
                        FutureBuilder<List<String>>(
                          future: _templateService.getCategories(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox();
                            final categories = snapshot.data!;
                            return SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _CategoryChip(
                                    label: 'All',
                                    isSelected: _selectedCategory == null,
                                    onTap: () => _selectCategory(null),
                                  ),
                                  const SizedBox(width: 8),
                                  ...categories.map((category) => Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: _CategoryChip(
                                          label: category,
                                          isSelected: _selectedCategory == category,
                                          onTap: () => _selectCategory(category),
                                        ),
                                      )),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Featured Templates - Only show when search is not active
                        if (!_isSearchActive) ...[
                          Text(
                            'Featured Templates',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _getFeaturedTemplates().length,
                              itemBuilder: (context, index) {
                                final featured = _getFeaturedTemplates()[index];
                                return Container(
                                  width: 280,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Card(
                                    color: AppColors.darkSurface,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: Colors.white10,
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            featured['icon'] as IconData,
                                            size: 40,
                                            color: AppColors.primaryOrange,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            featured['title'] as String,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: Text(
                                              featured['description'] as String,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.white70,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 3,
                                            ),
                                          ),
                                          const Spacer(),
                                          FilledButton(
                                            onPressed: () async {
                                              await _startFormFromFeatured(featured);
                                            },
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AppColors.primaryOrange,
                                              foregroundColor: Colors.white,
                                              minimumSize: const Size.fromHeight(40),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              'Use Template',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                        // All Templates
                        Text(
                          'All Templates',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 16),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _filteredTemplates.isEmpty
                                ? Center(
                                    child: Text(
                                      'No templates found',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                  )
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.1, // Increased to prevent overflow
                                    ),
                                    itemCount: _filteredTemplates.length,
                                    itemBuilder: (context, index) {
                                      final template = _filteredTemplates[index];
                                      final iconName = template['icon'] as String? ?? 'description';
                                      final icon = _getIconFromString(iconName);
                                      return Card(
                                        color: AppColors.darkSurface,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: BorderSide(
                                            color: Colors.white10,
                                            width: 1,
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: () async {
                                            await _startFormFromTemplate(template);
                                          },
                                          borderRadius: BorderRadius.circular(16),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  icon,
                                                  size: 40,
                                                  color: AppColors.primaryOrange,
                                                ),
                                                const SizedBox(height: 12),
                                                Flexible(
                                                  child: Text(
                                                    template['name'] as String,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (template['usageCount'] != null &&
                                                    (template['usageCount'] as int) > 0)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4),
                                                    child: Text(
                                                      '${template['usageCount']} uses',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 11,
                                                        color: AppColors.primaryOrange,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Bottom Navigation
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavigation(currentRoute: '/templates'),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFeaturedTemplates() {
    return [
      {
        'icon': Icons.school_rounded,
        'title': 'Scholarship Application',
        'description': 'Complete scholarship forms quickly',
        'templateId': 'scholarship',
      },
      {
        'icon': Icons.credit_card_rounded,
        'title': 'Passport Application',
        'description': 'Renew or apply for passport with ease',
        'templateId': 'passport',
      },
      {
        'icon': Icons.work_outline_rounded,
        'title': 'Job Application',
        'description': 'Streamline your job applications',
        'templateId': 'job',
      },
    ];
  }

  Future<void> _startFormFromFeatured(Map<String, dynamic> featured) async {
    final templateId = featured['templateId'] as String;
    final templateName = featured['title'] as String? ?? 'Unknown';
    AppLoggerService().logTemplateAction('Opening featured template', 
      templateId: templateId,
      templateName: templateName);
    
    final template = await _templateService.getTemplateById(templateId);
    if (template != null) {
      await _startFormFromTemplate(template);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template not found')),
        );
      }
    }
  }

  Future<void> _startFormFromTemplate(Map<String, dynamic> template) async {
    try {
      final templateId = template['id'] as String;
      final templateName = template['title'] as String? ?? 'Unknown';
      AppLoggerService().logTemplateAction('Opening template', 
        templateId: templateId,
        templateName: templateName);
      
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
      
      // Auto-fill form data with profile information
      final profileAutofillService = ProfileAutofillService();
      final autofilledFormData = await profileAutofillService.autofillFormData(
        formData,
        fieldMetadata,
      );
      
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
        formData: autofilledFormData,
        status: 'in_progress',
        progress: 0.0,
        createdAt: DateTime.now(),
        templateId: template['id'] as String,
      );
      
      // Save form to database
      await _dbService.insertForm(form);
      
      // Navigate to conversational form with the form ID and source
      if (mounted) {
        AppLoggerService().logFormAction('Opening form from template', 
          formId: formId,
          formTitle: template['title'] as String?);
        context.go('/conversational-form?formId=$formId&from=templates');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting form: $e')),
        );
      }
    }
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'cast_for_education':
        return Icons.cast_for_education;
      case 'account_balance':
        return Icons.account_balance;
      case 'flight':
        return Icons.flight;
      case 'card_membership':
        return Icons.card_membership;
      case 'directions_car':
        return Icons.directions_car;
      case 'work':
        return Icons.work;
      case 'description':
        return Icons.description;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'home':
        return Icons.home;
      case 'credit_card':
        return Icons.credit_card;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'medical_services':
        return Icons.medical_services;
      case 'healing':
        return Icons.healing;
      case 'badge':
        return Icons.badge;
      case 'how_to_vote':
        return Icons.how_to_vote;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'gavel':
        return Icons.gavel;
      case 'report_problem':
        return Icons.report_problem;
      case 'bolt':
        return Icons.bolt;
      case 'water_drop':
        return Icons.water_drop;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'apartment':
        return Icons.apartment;
      case 'home_work':
        return Icons.home_work;
      default:
        return Icons.description;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primaryOrange : Colors.white70,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryOrange.withOpacity(0.2),
      checkmarkColor: AppColors.primaryOrange,
      backgroundColor: AppColors.darkSurface,
      side: BorderSide(
        color: isSelected ? AppColors.primaryOrange : Colors.white30,
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

