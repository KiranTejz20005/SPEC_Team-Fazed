import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../services/pdf_service.dart';
import '../services/export_service.dart';
import '../services/database_service.dart';
import '../models/form_model.dart';

class ReviewScreen extends StatefulWidget {
  final String? formId;
  
  const ReviewScreen({super.key, this.formId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final DatabaseService _dbService = DatabaseService();
  FormModel? _form;
  Map<String, dynamic> _fieldMetadata = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.formId != null) {
      _loadForm();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadForm() async {
    if (widget.formId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final form = await _dbService.getFormById(widget.formId!);
      if (form != null && mounted) {
        // Parse field metadata from description
        _parseFieldMetadata(form.description);
        
        setState(() {
          _form = form;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Form not found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading form: $e')),
        );
      }
    }
  }

  void _parseFieldMetadata(String? description) {
    if (description == null) return;
    
    try {
      // Look for metadata in description
      final metadataMatch = RegExp(r'__METADATA__:(.+)').firstMatch(description);
      if (metadataMatch != null) {
        final metadataJson = metadataMatch.group(1);
        if (metadataJson != null) {
          _fieldMetadata = jsonDecode(metadataJson) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print('Error parsing metadata: $e');
    }
  }

  List<Map<String, dynamic>> _getFormFields() {
    if (_form == null || _form!.formData == null) return [];
    
    final fields = <Map<String, dynamic>>[];
    final formData = _form!.formData!;
    
    // Get all fields and their values
    for (var entry in formData.entries) {
      final fieldName = entry.key;
      final fieldValue = entry.value;
      final fieldMeta = _fieldMetadata[fieldName] as Map<String, dynamic>?;
      final fieldType = fieldMeta?['type'] as String? ?? 'text';
      
      // Skip static fields
      if (fieldType == 'static') continue;
      
      String displayValue = '';
      if (fieldValue == null) {
        displayValue = 'Not provided';
      } else if (fieldValue is List) {
        // For checkboxes, join the list
        displayValue = fieldValue.isEmpty ? 'Not provided' : fieldValue.join(', ');
      } else {
        displayValue = fieldValue.toString().trim();
        if (displayValue.isEmpty) {
          displayValue = 'Not provided';
        }
      }
      
      fields.add({
        'originalKey': fieldName, // Store original key for metadata lookup
        'label': _formatFieldLabel(fieldName),
        'value': displayValue,
      });
    }
    
    return fields;
  }

  String _formatFieldLabel(String fieldKey) {
    // Convert camelCase or snake_case to Title Case
    return fieldKey
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty 
            ? '' 
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ')
        .trim();
  }

  List<Map<String, dynamic>> _groupFieldsIntoSections() {
    final fields = _getFormFields();
    if (fields.isEmpty) return [];
    
    // Group fields by page if metadata has page information
    final sections = <String, Map<String, dynamic>>{};
    bool hasPageInfo = false;
    final fieldsWithoutPage = <Map<String, String>>[];
    
    for (var field in fields) {
      final originalKey = field['originalKey'] as String;
      final fieldMeta = _fieldMetadata[originalKey] as Map<String, dynamic>?;
      final page = fieldMeta?['page'] as int?;
      
      final fieldMap = {
        'label': field['label'] as String,
        'value': field['value'] as String,
      };
      
      if (page != null) {
        hasPageInfo = true;
        final sectionKey = 'Section $page';
        if (!sections.containsKey(sectionKey)) {
          sections[sectionKey] = {
            'title': 'Section $page',
            'fields': <Map<String, String>>[],
          };
        }
        (sections[sectionKey]!['fields'] as List).add(fieldMap);
      } else {
        fieldsWithoutPage.add(fieldMap);
      }
    }
    
    // If no page info at all, create a single section with form title
    if (!hasPageInfo) {
      final sectionTitle = _form?.title ?? 'Form Details';
      return [{
        'title': sectionTitle,
        'fields': fields.map((f) => {
          'label': f['label'] as String,
          'value': f['value'] as String,
        }).toList(),
      }];
    }
    
    // Convert to list and sort by page number
    final sectionsList = sections.values.toList();
    sectionsList.sort((a, b) {
      final aPage = int.tryParse(a['title'].toString().replaceAll('Section ', '')) ?? 0;
      final bPage = int.tryParse(b['title'].toString().replaceAll('Section ', '')) ?? 0;
      return aPage.compareTo(bPage);
    });
    
    // If we have page info but also fields without page, add them to the first section
    if (fieldsWithoutPage.isNotEmpty && sectionsList.isNotEmpty) {
      (sectionsList[0]['fields'] as List).addAll(fieldsWithoutPage);
    }
    
    // Replace first section title with form title if available
    if (sectionsList.isNotEmpty && _form?.title != null) {
      sectionsList[0]['title'] = _form!.title;
    }
    
    return sectionsList;
  }

  bool _isFormSubmitted() {
    if (_form == null) return false;
    return _form!.status == 'completed' ||
           _form!.status == 'submitted' ||
           _form!.progress >= 100.0 ||
           _form!.submittedAt != null;
  }

  Future<void> _submitForm() async {
    if (_form == null || widget.formId == null) return;
    
    try {
      // Update form status to completed
      final submittedForm = FormModel(
        id: _form!.id,
        title: _form!.title,
        description: _form!.description,
        formData: _form!.formData,
        status: 'completed',
        progress: 100.0,
        createdAt: _form!.createdAt,
        updatedAt: DateTime.now(),
        submittedAt: DateTime.now(),
        templateId: _form!.templateId,
        formType: _form!.formType,
      );
      
      // Save to database
      await _dbService.insertForm(submittedForm);
      
      // Reload form to update state
      await _loadForm();
      
      if (mounted) {
        _showSuccessDialog(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting form: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
                      'Review & Finalize',
                      style: theme.textTheme.displaySmall,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _form == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Form not found',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please go back and try again',
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Almost done! Please review your form.',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 32),
                              // Form Sections - dynamically generated
                              ..._groupFieldsIntoSections().map((section) => Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: _ReviewSection(
                                      title: section['title'] as String,
                                      fields: (section['fields'] as List<Map<String, String>>),
                                    ),
                                  )),
                              const SizedBox(height: 32),
                              // Action Buttons
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (widget.formId != null) {
                                      context.go('/conversational-form?formId=${widget.formId}');
                                    } else if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/dashboard');
                                    }
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit Form'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.surface,
                                    foregroundColor: theme.colorScheme.onSurface,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    if (_form == null) return;
                                    
                                    final pdfService = PdfService();
                                    try {
                                      // Convert form data to Map<String, String> for PDF
                                      final formDataMap = <String, String>{};
                                      if (_form!.formData != null) {
                                        for (var entry in _form!.formData!.entries) {
                                          final fieldMeta = _fieldMetadata[entry.key] as Map<String, dynamic>?;
                                          final fieldType = fieldMeta?['type'] as String? ?? 'text';
                                          
                                          if (fieldType == 'static') continue;
                                          
                                          String value = '';
                                          if (entry.value == null) {
                                            value = 'Not provided';
                                          } else if (entry.value is List) {
                                            value = (entry.value as List).isEmpty 
                                                ? 'Not provided' 
                                                : (entry.value as List).join(', ');
                                          } else {
                                            value = entry.value.toString().trim();
                                            if (value.isEmpty) value = 'Not provided';
                                          }
                                          
                                          formDataMap[_formatFieldLabel(entry.key)] = value;
                                        }
                                      }
                                      
                                      final pdfFile = await pdfService.generatePdf(
                                        title: _form!.title,
                                        formData: formDataMap,
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('PDF generated successfully!'),
                                            action: SnackBarAction(
                                              label: 'Share',
                                              onPressed: () => pdfService.sharePdf(pdfFile),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error generating PDF: $e'),
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text('Download PDF'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.onSurface,
                                    side: BorderSide(color: theme.colorScheme.outline),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                              // Only show Submit button if form is not already submitted
                              if (!_isFormSubmitted()) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _submitForm,
                                    icon: const Icon(Icons.send),
                                    label: const Text('Submit Form'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.surface,
                                      foregroundColor: theme.colorScheme.onSurface,
                                      side: BorderSide(color: theme.colorScheme.outline),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Success!'),
          ],
        ),
        content: const Text('Your form has been submitted successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/dashboard');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final List<Map<String, String>> fields;

  const _ReviewSection({
    required this.title,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
            const Divider(height: 24),
            ...fields.map((field) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          field['label']!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          field['value']!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

