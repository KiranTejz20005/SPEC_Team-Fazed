import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ai_chat_service.dart';
import '../services/voice_service.dart';
import '../services/database_service.dart';
import '../services/profile_autofill_service.dart';
import '../models/form_model.dart';
import '../widgets/debug_console_widget.dart';
import '../services/debug_log_service.dart';
import '../services/debug_console_service.dart';
import '../services/app_logger_service.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ConversationalFormScreen extends StatefulWidget {
  final String? formId;
  
  const ConversationalFormScreen({super.key, this.formId});

  @override
  State<ConversationalFormScreen> createState() =>
      _ConversationalFormScreenState();
}

class _ConversationalFormScreenState extends State<ConversationalFormScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final Map<String, TextEditingController> _fieldControllers = {};
  final Map<String, FocusNode> _fieldFocusNodes = {};
  final AiChatService _aiService = AiChatService();
  final VoiceService _voiceService = VoiceService();
  final DatabaseService _dbService = DatabaseService();
  final List<Map<String, dynamic>> _messages = [];
  bool _isListening = false;
  String? _formTitle;
  FormModel? _form;
  TextEditingController? _activeController;
  Map<String, dynamic> _fieldMetadata = {};
  Map<int, List<String>> _fieldsByPage = {};
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isChatOpen = false; // Track if chat interface is open
  final ScrollController _chatScrollController = ScrollController(); // Controller for chat messages
  bool _isSubmitting = false; // Track if form is being submitted

  @override
  void initState() {
    super.initState();
    AppLoggerService().logScreenEvent('ConversationalFormScreen', 'Initialized', 
      details: {'formId': widget.formId ?? 'new'});
    _voiceService.initialize();
    _loadForm();
    // Listen to message controller focus
    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus) {
        setState(() {
          _activeController = _messageController;
        });
        AppLoggerService().logUserInteraction('Focus', details: 'Message input field');
      }
    });
  }


  Future<void> _loadForm() async {
    if (widget.formId != null) {
      try {
        AppLoggerService().logFormAction('Loading form', formId: widget.formId);
        print('Loading form with ID: ${widget.formId}');
        final form = await _dbService.getFormById(widget.formId!);
        if (form != null && mounted) {
          AppLoggerService().logFormAction('Form loaded', 
            formId: widget.formId, 
            formTitle: form.title,
            details: {'fields': form.formData?.keys.length ?? 0});
          print('Form loaded: ${form.title}');
          print('Form description length: ${form.description?.length ?? 0}');
          print('Form data keys: ${form.formData?.keys.toList() ?? []}');
          
          // Parse field metadata from description
          _parseFieldMetadata(form.description);
          
          // Auto-fill empty fields with profile data
          final profileAutofillService = ProfileAutofillService();
          final formDataToUse = form.formData ?? <String, dynamic>{};
          final autofilledFormData = await profileAutofillService.autofillFormData(
            formDataToUse,
            _fieldMetadata,
          );
          
          // Update form data in database if auto-fill added any values
          bool formDataUpdated = false;
          for (var entry in autofilledFormData.entries) {
            final key = entry.key;
            final newValue = entry.value;
            final oldValue = formDataToUse[key];
            
            // Check if value was filled by auto-fill (was empty/null, now has value)
            if ((oldValue == null || oldValue == '' || (oldValue is List && (oldValue as List).isEmpty)) &&
                newValue != null && newValue != '' && !(newValue is List && (newValue as List).isEmpty)) {
              formDataUpdated = true;
              break;
            }
          }
          
          // Save updated form data if auto-fill filled any fields
          if (formDataUpdated) {
            final updatedForm = FormModel(
              id: form.id,
              title: form.title,
              description: form.description,
              formData: autofilledFormData,
              status: form.status,
              progress: form.progress,
              createdAt: form.createdAt,
              updatedAt: DateTime.now(),
              submittedAt: form.submittedAt,
              formType: form.formType,
              tags: form.tags,
              templateId: form.templateId,
            );
            await _dbService.updateForm(updatedForm);
          }
          
          setState(() {
            _form = formDataUpdated 
                ? FormModel(
                    id: form.id,
                    title: form.title,
                    description: form.description,
                    formData: autofilledFormData,
                    status: form.status,
                    progress: form.progress,
                    createdAt: form.createdAt,
                    updatedAt: DateTime.now(),
                    submittedAt: form.submittedAt,
                    formType: form.formType,
                    tags: form.tags,
                    templateId: form.templateId,
                  )
                : form;
            _formTitle = form.title;
            
            // Initialize form field controllers with existing data (including auto-filled)
            final dataToUse = formDataUpdated ? autofilledFormData : (form.formData ?? {});
            if (dataToUse.isNotEmpty) {
              for (var entry in dataToUse.entries) {
                final fieldKey = entry.key;
                final fieldValue = entry.value;
                final fieldMeta = _fieldMetadata[fieldKey] as Map<String, dynamic>?;
                final fieldType = fieldMeta?['type'] as String? ?? 'text';
                
                if (fieldType == 'static') continue; // Skip static fields for controller initialization
                
                final controller = _getFieldController(fieldKey);
                if (fieldValue != null) {
                  if (fieldType == 'checkbox' && fieldValue is List) {
                    // Checkboxes are handled differently
                  } else {
                    controller.text = fieldValue.toString();
                  }
                }
              }
            }
            
            // Initialize with a welcome message
            if (_messages.isEmpty) {
              _messages.add({
                'text': 'Welcome! I\'ll help you fill out your ${form.title}. Let\'s get started!',
                'isAI': true,
              });
            }
          });
          
          // Organize fields by page AFTER form is set
          _organizeFieldsByPage();
          
          // Update state again to reflect page organization
          if (mounted) {
            setState(() {
              print('State updated after field organization');
              print('Current page fields count: ${_getCurrentPageFields().length}');
            });
          }
        } else {
          print('WARNING: Form not found with ID: ${widget.formId}');
        }
      } catch (e) {
        print('Error loading form: $e');
        if (mounted) {
          setState(() {
            _messages.add({
              'text': 'Welcome! I\'ll help you fill out this form. Let\'s get started!',
              'isAI': true,
            });
          });
        }
      }
    } else {
      // Default welcome message if no form ID
      setState(() {
        _messages.add({
          'text': 'Welcome! I\'ll help you fill out this form. Let\'s get started!',
          'isAI': true,
        });
      });
    }
  }
  
  void _parseFieldMetadata(String? description) {
    _fieldMetadata = {};
    if (description == null) return;
    
    try {
      // Look for metadata in description
      if (description.contains('__METADATA__:')) {
        final parts = description.split('__METADATA__:');
        if (parts.length > 1) {
          final metadataJson = parts[1].trim();
          _fieldMetadata = jsonDecode(metadataJson) as Map<String, dynamic>;
          print('=== Metadata Parsed ===');
          print('Metadata keys: ${_fieldMetadata.keys.toList()}');
          for (var key in _fieldMetadata.keys) {
            final meta = _fieldMetadata[key] as Map<String, dynamic>?;
            print('  $key: required=${meta?['required']}, type=${meta?['type']}');
          }
          print('=== End Metadata Parse ===');
        }
      }
    } catch (e) {
      print('Error parsing field metadata: $e');
    }
  }
  
  void _organizeFieldsByPage() {
    _fieldsByPage = {};
    
    // Only use fields that are in the metadata (exclude leftover/default fields)
    // If metadata exists, use it as the source of truth
    final fieldList = <String>[];
    
    if (_fieldMetadata.isNotEmpty) {
      // Use metadata as source of truth - only include fields that are in metadata
      for (var fieldName in _fieldMetadata.keys) {
        final fieldMeta = _fieldMetadata[fieldName] as Map<String, dynamic>?;
        final fieldType = fieldMeta?['type'] as String? ?? 'text';
        // Exclude static fields from page organization (they're displayed separately)
        if (fieldType != 'static') {
          fieldList.add(fieldName);
        }
      }
    } else if (_form?.formData != null) {
      // Fallback: if no metadata, use formData keys
      fieldList.addAll(_form!.formData!.keys);
    }
    
    // Debug: Print what we have
    print('=== Field Organization Debug ===');
    print('Total fields found: ${fieldList.length}');
    print('Fields from metadata: ${_fieldMetadata.keys.length}');
    print('Field names: ${fieldList.join(", ")}');
    
    // If no fields at all, return early
    if (fieldList.isEmpty) {
      print('WARNING: No fields found!');
      _totalPages = 1;
      return;
    }
    
    // Group fields by page number from metadata, preserving order
    final fieldsWithPages = <String, Map<String, dynamic>>{}; // Store both page and order
    final fieldsWithoutPages = <String>[];
    
    for (var fieldName in fieldList) {
      final fieldMeta = _fieldMetadata[fieldName] as Map<String, dynamic>?;
      if (fieldMeta != null && fieldMeta.containsKey('page')) {
        final page = (fieldMeta['page'] as num?)?.toInt() ?? 1;
        final order = (fieldMeta['order'] as num?)?.toInt() ?? 0;
        fieldsWithPages[fieldName] = {'page': page, 'order': order};
      } else {
        fieldsWithoutPages.add(fieldName);
      }
    }
    
    print('Fields with pages: ${fieldsWithPages.length}');
    print('Fields without pages: ${fieldsWithoutPages.length}');
    
    // Sort fields by order to preserve original sequence
    final sortedFields = fieldsWithPages.entries.toList()
      ..sort((a, b) {
        final orderA = a.value['order'] as int;
        final orderB = b.value['order'] as int;
        return orderA.compareTo(orderB);
      });
    
    // Organize fields with page numbers in order
    for (var entry in sortedFields) {
      final fieldName = entry.key;
      final page = entry.value['page'] as int;
      
      if (!_fieldsByPage.containsKey(page)) {
        _fieldsByPage[page] = [];
      }
      _fieldsByPage[page]!.add(fieldName);
    }
    
    // If no fields have page numbers in metadata, auto-organize into pages
    if (fieldsWithPages.isEmpty && fieldsWithoutPages.isNotEmpty) {
      // Auto-organize: 5-7 fields per page
      const fieldsPerPage = 6;
      int currentPage = 1;
      int fieldsInCurrentPage = 0;
      
      for (var fieldName in fieldsWithoutPages) {
        if (!_fieldsByPage.containsKey(currentPage)) {
          _fieldsByPage[currentPage] = [];
        }
        _fieldsByPage[currentPage]!.add(fieldName);
        fieldsInCurrentPage++;
        
        if (fieldsInCurrentPage >= fieldsPerPage) {
          currentPage++;
          fieldsInCurrentPage = 0;
        }
      }
    } else if (fieldsWithoutPages.isNotEmpty) {
      // Some fields have pages, some don't - add unassigned to page 1
      // But only if page 1 doesn't already exist or if it's empty
      if (!_fieldsByPage.containsKey(1)) {
        _fieldsByPage[1] = [];
      }
      for (var fieldName in fieldsWithoutPages) {
        // Only add if not already in page 1
        if (!_fieldsByPage[1]!.contains(fieldName)) {
          _fieldsByPage[1]!.add(fieldName);
        }
      }
    }
    
    // Calculate total pages
    if (_fieldsByPage.isNotEmpty) {
      _totalPages = _fieldsByPage.keys.reduce((a, b) => a > b ? a : b);
    } else {
      _totalPages = 1;
    }
    
    AppLoggerService().logScreenEvent('ConversationalFormScreen', 'Pages organized', 
      details: {'totalPages': _totalPages, 'fields': _fieldsByPage.values.expand((e) => e).length});
    
    // Ensure current page is valid
    if (_currentPage > _totalPages || _currentPage < 1) {
      _currentPage = 1;
    }
    
    // Debug: Print field organization
    print('Fields organized into $_totalPages pages:');
    for (var page in _fieldsByPage.keys.toList()..sort()) {
      print('  Page $page (${_fieldsByPage[page]!.length} fields): ${_fieldsByPage[page]!.join(", ")}');
    }
    print('Current page: $_currentPage');
    print('Current page fields: ${_getCurrentPageFields().join(", ")}');
    print('=== End Field Organization Debug ===');
  }
  
  List<String> _getCurrentPageFields() {
    return _fieldsByPage[_currentPage] ?? [];
  }
  
  Map<String, dynamic> _getCurrentFormData() {
    // Start with existing form data to preserve radio/checkbox/dropdown values
    final currentFormData = Map<String, dynamic>.from(_form?.formData ?? {});
    
    // Update form data with current field values from controllers (text fields)
    for (var entry in _fieldControllers.entries) {
      final fieldKey = entry.key;
      final fieldMeta = _fieldMetadata[fieldKey] as Map<String, dynamic>?;
      final fieldType = fieldMeta?['type'] as String? ?? 'text';
      
      // Update text-based fields from controllers
      if (fieldType == 'text' || fieldType == 'email' || fieldType == 'phone' || 
          fieldType == 'textarea' || fieldType == 'number' || fieldType == 'date') {
        final textValue = entry.value.text.trim();
        currentFormData[fieldKey] = textValue.isEmpty ? null : textValue;
      }
    }
    
    return currentFormData;
  }

  double _calculateProgress(Map<String, dynamic> formData) {
    // Get all fields that should be counted for progress (exclude static fields)
    final fieldsToCount = <String>[];
    
    // Get fields from formData
    if (formData.isNotEmpty) {
      for (var fieldName in formData.keys) {
        final fieldMeta = _fieldMetadata[fieldName] as Map<String, dynamic>?;
        final fieldType = fieldMeta?['type'] as String? ?? 'text';
        
        // Exclude static fields from progress calculation
        if (fieldType != 'static') {
          fieldsToCount.add(fieldName);
        }
      }
    }
    
    // If no fields to count, return 0
    if (fieldsToCount.isEmpty) {
      return 0.0;
    }
    
    // Count filled fields
    int filledCount = 0;
    for (var fieldName in fieldsToCount) {
      final fieldMeta = _fieldMetadata[fieldName] as Map<String, dynamic>?;
      final fieldType = fieldMeta?['type'] as String? ?? 'text';
      final fieldValue = formData[fieldName];
      
      bool isFilled = false;
      
      switch (fieldType) {
        case 'text':
        case 'email':
        case 'phone': // Added phone type
        case 'textarea':
          // Text-based fields: check if not null and not empty
          isFilled = fieldValue != null && 
                     fieldValue.toString().trim().isNotEmpty;
          break;
        case 'number':
        case 'date':
          // Number and date: check if not null
          isFilled = fieldValue != null;
          break;
        case 'radio':
        case 'dropdown':
        case 'select':
          // Single selection: check if not null
          isFilled = fieldValue != null;
          break;
        case 'checkbox':
          // Multiple selection: check if list is not empty
          if (fieldValue is List) {
            isFilled = fieldValue.isNotEmpty;
          } else {
            isFilled = false;
          }
          break;
        default:
          // For unknown types, consider filled if not null
          isFilled = fieldValue != null;
      }
      
      if (isFilled) {
        filledCount++;
      }
    }
    
    // Calculate progress as percentage
    return (filledCount / fieldsToCount.length) * 100.0;
  }
  
  Future<void> _saveFormData() async {
    if (_form == null || widget.formId == null) return;
    
    try {
      // Start with existing form data to preserve radio/checkbox/dropdown values
      final updatedFormData = Map<String, dynamic>.from(_form!.formData ?? {});
      
      // Update form data with current field values from controllers (text fields)
      for (var entry in _fieldControllers.entries) {
        final fieldKey = entry.key;
        final fieldMeta = _fieldMetadata[fieldKey] as Map<String, dynamic>?;
        final fieldType = fieldMeta?['type'] as String? ?? 'text';
        
        // Update text-based fields from controllers
        if (fieldType == 'text' || fieldType == 'email' || fieldType == 'phone' || 
            fieldType == 'textarea' || fieldType == 'number' || fieldType == 'date') {
          final textValue = entry.value.text.trim();
          updatedFormData[fieldKey] = textValue.isEmpty ? null : textValue;
        }
      }
      
      // Calculate progress based on filled fields
      final calculatedProgress = _calculateProgress(updatedFormData);
      
      // Update the form model with calculated progress
      // Preserve submittedAt if form was already submitted
      final updatedForm = FormModel(
        id: _form!.id,
        title: _form!.title,
        description: _form!.description,
        formData: updatedFormData,
        status: _form!.status,
        progress: calculatedProgress,
        createdAt: _form!.createdAt,
        updatedAt: DateTime.now(),
        submittedAt: _form!.submittedAt, // Preserve submittedAt if already set
        templateId: _form!.templateId,
        formType: _form!.formType,
      );
      
      // Save to database
      await _dbService.insertForm(updatedForm);
      
      if (mounted) {
        setState(() {
          _form = updatedForm;
        });
      }
    } catch (e) {
      print('Error saving form data: $e');
    }
  }
  
  /// Validate required fields on the current page only
  List<String> _validateCurrentPageRequiredFields() {
    final emptyRequiredFields = <String>[];
    final currentPageFields = _getCurrentPageFields();
    
    // Get all fields from metadata for current page only
    for (var fieldName in currentPageFields) {
      if (!_fieldMetadata.containsKey(fieldName)) continue;
      
      final fieldMeta = _fieldMetadata[fieldName] as Map<String, dynamic>?;
      final isRequired = fieldMeta?['required'] == true;
      final fieldType = fieldMeta?['type'] as String? ?? 'text';
      
      // Skip static fields
      if (fieldType == 'static') continue;
      
      if (isRequired) {
        // Check both formData and controller values
        var fieldValue = _form?.formData?[fieldName];
        
        // For text-based fields, check controller first (most up-to-date)
        if (fieldType == 'text' || fieldType == 'email' || fieldType == 'phone' || 
            fieldType == 'textarea' || fieldType == 'number' || fieldType == 'date') {
          if (_fieldControllers.containsKey(fieldName)) {
            final controller = _fieldControllers[fieldName]!;
            final controllerText = controller.text.trim();
            if (controllerText.isNotEmpty) {
              fieldValue = controllerText;
            } else {
              fieldValue = null;
            }
          }
        }
        
        bool isEmpty = false;
        
        switch (fieldType) {
          case 'text':
          case 'email':
          case 'phone':
          case 'textarea':
            if (fieldValue == null) {
              isEmpty = true;
            } else {
              final textValue = fieldValue.toString().trim();
              isEmpty = textValue.isEmpty;
            }
            break;
          case 'number':
          case 'date':
            isEmpty = fieldValue == null;
            break;
          case 'radio':
          case 'dropdown':
          case 'select':
            isEmpty = fieldValue == null;
            break;
          case 'checkbox':
            if (fieldValue is List) {
              isEmpty = fieldValue.isEmpty;
            } else {
              isEmpty = true;
            }
            break;
          default:
            isEmpty = fieldValue == null;
        }
        
        if (isEmpty) {
          emptyRequiredFields.add(fieldName);
        }
      }
    }
    
    return emptyRequiredFields;
  }

  List<String> _validateRequiredFields() {
    final emptyRequiredFields = <String>[];
    
    print('=== Validation Debug ===');
    print('Metadata keys: ${_fieldMetadata.keys.toList()}');
    print('FormData keys: ${_form?.formData?.keys.toList() ?? []}');
    
    // Get all fields from metadata
    for (var fieldName in _fieldMetadata.keys) {
      final fieldMeta = _fieldMetadata[fieldName] as Map<String, dynamic>?;
      final isRequired = fieldMeta?['required'] == true;
      final fieldType = fieldMeta?['type'] as String? ?? 'text';
      
      print('Field: $fieldName, Required: $isRequired, Type: $fieldType');
      
      // Skip static fields
      if (fieldType == 'static') continue;
      
      if (isRequired) {
        // Check both formData and controller values
        // Priority: controller value (most up-to-date) > formData value
        var fieldValue = _form?.formData?[fieldName];
        
        // For text-based fields, check controller first (most up-to-date)
        if (fieldType == 'text' || fieldType == 'email' || fieldType == 'phone' || 
            fieldType == 'textarea' || fieldType == 'number' || fieldType == 'date') {
          if (_fieldControllers.containsKey(fieldName)) {
            final controller = _fieldControllers[fieldName]!;
            final controllerText = controller.text.trim();
            if (controllerText.isNotEmpty) {
              fieldValue = controllerText;
            } else {
              // Controller is empty, so field is empty
              fieldValue = null;
            }
          }
        }
        
        bool isEmpty = false;
        
        switch (fieldType) {
          case 'text':
          case 'email':
          case 'phone': // Added phone type
          case 'textarea':
            // Text-based fields: check if null or empty
            if (fieldValue == null) {
              isEmpty = true;
            } else {
              final textValue = fieldValue.toString().trim();
              isEmpty = textValue.isEmpty;
            }
            break;
          case 'number':
          case 'date':
            // Number and date: check if null
            isEmpty = fieldValue == null;
            break;
          case 'radio':
          case 'dropdown':
          case 'select':
            // Single selection: check if null
            isEmpty = fieldValue == null;
            break;
          case 'checkbox':
            // Multiple selection: check if list is empty
            if (fieldValue is List) {
              isEmpty = fieldValue.isEmpty;
            } else {
              isEmpty = true;
            }
            break;
          default:
            isEmpty = fieldValue == null;
        }
        
        print('  Field $fieldName: value=$fieldValue, isEmpty=$isEmpty');
        
        if (isEmpty) {
          emptyRequiredFields.add(fieldName);
        }
      }
    }
    
    print('Empty required fields: $emptyRequiredFields');
    print('=== End Validation Debug ===');
    
    return emptyRequiredFields;
  }
  
  Future<void> _submitForm() async {
    // Prevent multiple submissions
    if (_isSubmitting) return;
    
    // Validate required fields first
    final emptyRequiredFields = _validateRequiredFields();
    
    if (emptyRequiredFields.isNotEmpty) {
      // Show error message
      if (mounted) {
        final fieldNames = emptyRequiredFields.map((name) {
          // Format field name for display
          return name.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
              .replaceAll('_', ' ')
              .split(' ')
              .map((word) => word.isEmpty 
                  ? '' 
                  : word[0].toUpperCase() + word.substring(1).toLowerCase())
              .join(' ')
              .trim();
        }).join(', ');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all required fields: $fieldNames'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Scroll to first empty required field
        if (emptyRequiredFields.isNotEmpty) {
          final firstEmptyField = emptyRequiredFields.first;
          final fieldFocusNode = _getFieldFocusNode(firstEmptyField);
          if (fieldFocusNode.canRequestFocus) {
            fieldFocusNode.requestFocus();
          }
        }
      }
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    // Save form data first
    await _saveFormData();
    
    if (_form == null || widget.formId == null) {
      setState(() {
        _isSubmitting = false;
      });
      return;
    }
    
    try {
      // Update form status to completed
      AppLoggerService().logFormAction('Form submission started', 
        formId: _form!.id,
        formTitle: _form!.title);
      
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
      
      AppLoggerService().logFormAction('Form submitted successfully', 
        formId: _form!.id,
        formTitle: _form!.title);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            context.go('/dashboard');
          }
        });
      }
    } catch (e) {
      AppLoggerService().logError('Form submission', e);
      setState(() {
        _isSubmitting = false;
      });
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
  void dispose() {
    AppLoggerService().logScreenEvent('ConversationalFormScreen', 'Disposed');
    _messageController.dispose();
    _messageFocusNode.dispose();
    _chatScrollController.dispose();
    for (var controller in _fieldControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _fieldFocusNodes.values) {
      focusNode.dispose();
    }
    _voiceService.dispose();
    super.dispose();
  }

  TextEditingController _getFieldController(String fieldKey) {
    if (!_fieldControllers.containsKey(fieldKey)) {
      _fieldControllers[fieldKey] = TextEditingController();
      
      // Update progress display when field value changes
      _fieldControllers[fieldKey]!.addListener(() {
        final value = _fieldControllers[fieldKey]!.text;
        if (value.isNotEmpty) {
          final fieldMeta = _fieldMetadata[fieldKey];
          final fieldType = fieldMeta is Map<String, dynamic> 
              ? fieldMeta['type'] as String? ?? 'text' 
              : 'text';
          AppLoggerService().logFieldInteraction(fieldKey, 'Changed', 
            value: value.length > 50 ? '${value.substring(0, 50)}...' : value,
            fieldType: fieldType);
        }
        if (mounted) {
          setState(() {
            // Progress will be recalculated in build method
          });
        }
      });
      
      _fieldFocusNodes[fieldKey] = FocusNode()
        ..addListener(() {
          if (_fieldFocusNodes[fieldKey]!.hasFocus) {
            setState(() {
              _activeController = _fieldControllers[fieldKey];
            });
          }
        });
      
      // Save form data when field loses focus
      _fieldFocusNodes[fieldKey]!.addListener(() {
        if (!_fieldFocusNodes[fieldKey]!.hasFocus) {
          _saveFormData();
        }
      });
    }
    return _fieldControllers[fieldKey]!;
  }

  FocusNode _getFieldFocusNode(String fieldKey) {
    if (!_fieldFocusNodes.containsKey(fieldKey)) {
      _getFieldController(fieldKey); // This will create both
    }
    return _fieldFocusNodes[fieldKey]!;
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    // Log user message
    AppLoggerService().logUserInteraction('Chat', details: 'User sent message: "$userMessage"');
    debugPrint('=== AI ASSISTANT CONVERSATION LOG ===');
    debugPrint('[USER MESSAGE] $userMessage');
    debugPrint('Total messages before: ${_messages.length}');
    print('=== AI ASSISTANT CONVERSATION LOG ===');
    print('[USER MESSAGE] $userMessage');
    print('Total messages before: ${_messages.length}');

    setState(() {
      _messages.add({
        'text': userMessage,
        'isAI': false,
      });
    });

    // Get AI response with context and conversation history
    final aiContext = {
      'formTitle': _formTitle,
    };
    
    // Pass conversation history (excluding the message we just added, as it will be included in the API call)
    // We need to pass all previous messages for context
    final conversationHistory = List<Map<String, dynamic>>.from(_messages);
    
    // Log conversation history being sent
    debugPrint('[CONVERSATION HISTORY] Sending ${conversationHistory.length} messages to AI:');
    print('[CONVERSATION HISTORY] Sending ${conversationHistory.length} messages to AI:');
    for (int i = 0; i < conversationHistory.length; i++) {
      final msg = conversationHistory[i];
      final role = msg['isAI'] == true ? 'AI' : 'USER';
      final text = msg['text'] as String;
      final msgText = '  [$i] [$role]: ${text.length > 100 ? text.substring(0, 100) + "..." : text}';
      debugPrint(msgText);
      print(msgText);
    }
    debugPrint('[CONTEXT] Form Title: ${aiContext['formTitle'] ?? "N/A"}');
    print('[CONTEXT] Form Title: ${aiContext['formTitle'] ?? "N/A"}');
    
    debugPrint('[AI REQUEST] Calling Gemini API...');
    print('[AI REQUEST] Calling Gemini API...');
    try {
      final aiResponse = await _aiService.getResponse(userMessage, aiContext, conversationHistory: conversationHistory);
      
      // Log AI response
      debugPrint('[AI RESPONSE] Received ${aiResponse.length} characters');
      debugPrint('[AI RESPONSE TEXT] $aiResponse');
      debugPrint('Total messages after: ${_messages.length + 1}');
      debugPrint('=== END CONVERSATION LOG ===');
      print('[AI RESPONSE] Received ${aiResponse.length} characters');
      print('[AI RESPONSE TEXT] $aiResponse');
      print('Total messages after: ${_messages.length + 1}');
      print('=== END CONVERSATION LOG ===');
      
      AppLoggerService().logUserInteraction('Chat', details: 'AI responded: "${aiResponse.length > 50 ? aiResponse.substring(0, 50) + "..." : aiResponse}"');
      
      if (mounted) {
        setState(() {
          _messages.add({
            'text': aiResponse,
            'isAI': true,
          });
        });
      }
    } catch (e) {
      debugPrint('❌ ERROR: Failed to get AI response: $e');
      debugPrint('Error type: ${e.runtimeType}');
      print('❌ ERROR: Failed to get AI response: $e');
      print('Error type: ${e.runtimeType}');
      if (mounted) {
        // Show actual error message to help debug
        String errorMessage = 'Failed to get AI response. ';
        if (e.toString().contains('API')) {
          errorMessage += 'API Error: ${e.toString()}';
        } else if (e.toString().contains('SocketException') || e.toString().contains('Network')) {
          errorMessage += 'Network error. Please check your internet connection.';
        } else {
          errorMessage += 'Error: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
    
    if (mounted) {
      // Scroll to bottom after adding message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_chatScrollController.hasClients) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // Helper method to get button color that matches the theme
  // This method is kept for backward compatibility but now returns the primary color
  Color _getButtonColor(Color primaryColor, Brightness brightness) {
    // Use the theme's primary color for buttons to match the app's color scheme
    return primaryColor;
  }

  Future<void> _startListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
      return;
    }

    // Determine which controller to update based on focus
    // If no field is focused, focus on the first form field (fatherName)
    TextEditingController controllerToUpdate;
    if (_activeController != null) {
      controllerToUpdate = _activeController!;
    } else if (_fieldControllers.isNotEmpty) {
      // Focus on the first form field if no field is currently focused
      final firstFieldKey = _fieldControllers.keys.first;
      controllerToUpdate = _fieldControllers[firstFieldKey]!;
      _fieldFocusNodes[firstFieldKey]!.requestFocus();
      _activeController = controllerToUpdate;
    } else {
      // Fallback to message controller
      controllerToUpdate = _messageController;
      _messageFocusNode.requestFocus();
      _activeController = controllerToUpdate;
    }

    setState(() => _isListening = true);
    await _voiceService.startListening(
      onPartialResult: (partialText) {
        // Update text in real-time as user speaks
        if (mounted) {
          setState(() {
            controllerToUpdate.text = partialText;
          });
        }
      },
      onResult: (result) {
        // Update the active controller with final result
        if (mounted) {
          setState(() {
            controllerToUpdate.text = result;
            _isListening = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice recognition error: $error')),
          );
          setState(() => _isListening = false);
        }
      },
    );
  }

  Future<bool> _onWillPop() async {
    // Don't show dialog if form is being submitted
    if (_isSubmitting) {
      return false;
    }
    
    // Check if form has unsaved changes
    bool hasUnsavedChanges = false;
    if (_form != null) {
      // Check if any field values have changed
      for (var entry in _fieldControllers.entries) {
        final fieldKey = entry.key;
        final currentValue = entry.value.text.trim();
        final savedValue = _form!.formData[fieldKey]?.toString().trim() ?? '';
        if (currentValue != savedValue) {
          hasUnsavedChanges = true;
          break;
        }
      }
    }
    
    if (hasUnsavedChanges) {
      // Show dialog
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Exit Form?'),
          content: const Text('You have unsaved changes. What would you like to do?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Save & Exit
                await _saveFormData();
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save & Exit'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Exit without saving'),
            ),
          ],
        ),
      );
      
      if (result == true && mounted) {
        // User chose to exit
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      }
      return false; // Prevent default back action
    }
    
    // No unsaved changes, allow navigation
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Stack(
        children: [
          Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () async {
                          await _onWillPop();
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formTitle ?? 'Form Filling',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Page $_currentPage/$_totalPages • ${_calculateProgress(_getCurrentFormData()).toInt()}% Complete',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.save_outlined),
                        onPressed: () async {
                          await _saveFormData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Form saved successfully!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.help_outline),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Help'),
                              content: const Text(
                                'Fill out the form fields as prompted. The AI assistant will guide you through each step. Use the chat interface at the bottom to ask questions or get help.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Form Fields
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display form description/instructions if available
                        if (_form?.description != null && _form!.description!.isNotEmpty)
                          Builder(
                            builder: (context) {
                              // Extract description (excluding metadata)
                              String description = _form!.description!;
                              // Remove metadata if present
                              if (description.contains('__METADATA__:')) {
                                description = description.substring(0, description.indexOf('__METADATA__:')).trim();
                              }
                              // Only show if there's actual description text (not just metadata)
                              if (description.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.dividerColor.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 20,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Form Instructions',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      description,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        // Render fields for current page only
                        if (_getCurrentPageFields().isNotEmpty)
                          ...(_getCurrentPageFields().map((fieldKey) {
                            // Only render if field exists in metadata (to exclude leftover fields)
                            if (_fieldMetadata.isNotEmpty && !_fieldMetadata.containsKey(fieldKey)) {
                              return const SizedBox.shrink();
                            }
                            final fieldMeta = _fieldMetadata[fieldKey] as Map<String, dynamic>?;
                            final fieldType = fieldMeta?['type'] as String? ?? 'text';
                            // Skip static fields (they're handled separately if needed)
                            if (fieldType == 'static') {
                              return const SizedBox.shrink();
                            }
                            return _buildFormField(fieldKey, theme);
                          }).toList())
                        else if (_fieldMetadata.isNotEmpty)
                          // Fallback: render all non-static fields from metadata if pagination failed
                          ...(_fieldMetadata.keys.where((fieldKey) {
                            final fieldMeta = _fieldMetadata[fieldKey] as Map<String, dynamic>?;
                            final fieldType = fieldMeta?['type'] as String? ?? 'text';
                            return fieldType != 'static';
                          }).map((fieldKey) {
                            return _buildFormField(fieldKey, theme);
                          }).toList())
                        else if (_form?.formData != null && _form!.formData!.isNotEmpty)
                          // Fallback: render all fields from formData (only if no metadata)
                          ...(_form!.formData!.keys.map((fieldKey) {
                            return _buildFormField(fieldKey, theme);
                          }).toList())
                        else
                          // Fallback: show empty state message
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    size: 64,
                                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No form fields found',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Please check the form configuration',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        // Navigation Buttons - Show if there are fields or multiple pages
                        if ((_form?.formData != null && _form!.formData!.isNotEmpty) || 
                            _getCurrentPageFields().isNotEmpty ||
                            _totalPages > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              FilledButton.icon(
                                onPressed: _currentPage > 1
                                    ? () {
                                        AppLoggerService().logPageTransition(
                                          'Page $_currentPage', 
                                          'Page ${_currentPage - 1}',
                                          pageNumber: _currentPage - 1,
                                          totalPages: _totalPages,
                                        );
                                        setState(() {
                                          _currentPage--;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Previous'),
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) {
                                      if (states.contains(MaterialState.disabled)) {
                                        return theme.colorScheme.surface.withOpacity(0.12);
                                      }
                                      // Use lighter grey for dark theme, primary color for other themes
                                      return theme.brightness == Brightness.dark
                                          ? const Color(0xFF333333) // Grey (20% white, 80% black) as requested
                                          : theme.colorScheme.primary;
                                    },
                                  ),
                                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) {
                                      if (states.contains(MaterialState.disabled)) {
                                        return theme.colorScheme.onSurface.withOpacity(0.38);
                                      }
                                      return Colors.white;
                                    },
                                  ),
                                  padding: MaterialStateProperty.all(
                                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () async {
                                  if (_currentPage < _totalPages) {
                                    // Save current form data first to ensure we're validating latest values
                                    await _saveFormData();
                                    
                                    // Validate current page before moving to next
                                    final emptyRequiredFields = _validateCurrentPageRequiredFields();
                                    
                                    if (emptyRequiredFields.isNotEmpty) {
                                      // Show error message
                                      final fieldNames = emptyRequiredFields
                                          .map((name) => _formatFieldLabel(name))
                                          .join(', ');
                                      
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Please fill in all required fields: $fieldNames'),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                        
                                        // Scroll to first empty required field
                                        final firstEmptyField = emptyRequiredFields.first;
                                        final fieldFocusNode = _getFieldFocusNode(firstEmptyField);
                                        if (fieldFocusNode.canRequestFocus) {
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            if (mounted) {
                                              fieldFocusNode.requestFocus();
                                            }
                                          });
                                        }
                                      }
                                      return;
                                    }
                                    
                                    // All required fields filled, move to next page
                                    if (mounted) {
                                      AppLoggerService().logPageTransition(
                                        'Page $_currentPage', 
                                        'Page ${_currentPage + 1}',
                                        pageNumber: _currentPage + 1,
                                        totalPages: _totalPages,
                                      );
                                      setState(() {
                                        _currentPage++;
                                      });
                                    }
                                  } else {
                                    // Submit form (this already has validation)
                                    AppLoggerService().logFormAction('Submitting form', 
                                      formId: widget.formId,
                                      formTitle: _formTitle);
                                    _submitForm();
                                  }
                                },
                                icon: Icon(
                                  _currentPage == _totalPages ? Icons.check : Icons.arrow_forward,
                                ),
                                label: Text(
                                  _currentPage == _totalPages ? 'Submit' : 'Next',
                                ),
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
                                  foregroundColor: MaterialStateProperty.all(
                                    Colors.white,
                                  ),
                                  padding: MaterialStateProperty.all(
                                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // AI Assistant Button
                        FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _isChatOpen = true;
                            });
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('AI Assistant'),
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.disabled)) {
                                  return theme.colorScheme.surface.withOpacity(0.3);
                                }
                                // Use lighter grey for dark theme, primary color for other themes
                                return theme.brightness == Brightness.dark
                                    ? const Color(0xFF9E9E9E) // Light grey for better visibility in dark theme
                                    : theme.colorScheme.primary;
                              },
                            ),
                            foregroundColor: MaterialStateProperty.all(
                              Colors.white,
                            ),
                            padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // AI Chat Interface Overlay
        if (_isChatOpen)
          _buildChatInterface(context, theme),
      ],
    ),
    );
  }
  
  Widget _buildChatInterface(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Chat Header with Back Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isChatOpen = false;
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Close Chat',
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chat_bubble_outline),
                  const SizedBox(width: 12),
                  Text(
                    'AI Assistant',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            // Chat Messages
            Expanded(
              child: Container(
                color: theme.scaffoldBackgroundColor,
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start a conversation with AI Assistant',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _chatScrollController,
                        padding: const EdgeInsets.all(16),
                        reverse: false,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ChatBubble(
                              text: message['text'] as String,
                              isAI: message['isAI'] as bool,
                            ),
                          );
                        },
                      ),
              ),
            ),
            // Input Area
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      style: TextStyle(
                        color: isDark 
                            ? Colors.white 
                            : theme.colorScheme.onSurface, // Text color matches theme
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(
                          color: isDark 
                              ? Colors.white.withOpacity(0.6) 
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.2) : theme.dividerColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.2) : theme.dividerColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark 
                            ? const Color(0xFF333333) // 20% white, 80% black
                            : theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: _isListening && _activeController == _messageController
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Icon(Icons.mic, color: Colors.red, size: 20),
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                      onTap: () {
                        setState(() {
                          _activeController = _messageController;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _startListening,
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return theme.colorScheme.surface.withOpacity(0.3);
                          }
                          // Red when listening, otherwise use lighter grey for dark theme
                          if (_isListening) {
                            return Colors.red;
                          }
                          // Use lighter grey for dark theme, primary color for other themes
                          return theme.brightness == Brightness.dark
                              ? const Color(0xFF333333) // Grey (20% white, 80% black) as requested
                              : theme.colorScheme.primary;
                        },
                      ),
                      foregroundColor: MaterialStateProperty.all(
                        Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
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
                      foregroundColor: MaterialStateProperty.all(
                        Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFormField(String fieldKey, ThemeData theme) {
    final fieldMeta = _fieldMetadata[fieldKey] as Map<String, dynamic>?;
    final fieldType = fieldMeta?['type'] as String? ?? 'text';
    final isRequired = fieldMeta?['required'] == true;
    // Use the field name as-is from metadata, or format it if needed
    final fieldLabel = _formatFieldLabel(fieldKey);
    final description = fieldMeta?['description'] as String?;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field Label with required asterisk
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white, // White color for visibility
                    ),
                    children: [
                      TextSpan(text: fieldLabel),
                      if (isRequired)
                        TextSpan(
                          text: ' *',
                          style: GoogleFonts.poppins(
                            color: AppColors.primaryOrange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (description != null && fieldType == 'static')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 8),
          // Field Widget based on type
          _buildFieldWidget(fieldKey, fieldType, fieldMeta, theme),
        ],
      ),
    );
  }
  
  /// Build a clear button widget for form fields
  Widget? _buildClearButton(String fieldKey, String fieldType) {
    // Check if field has a value
    bool hasValue = false;
    
    if (fieldType == 'dropdown' || fieldType == 'select' || fieldType == 'radio') {
      // For dropdown/select/radio, check formData
      hasValue = _form?.formData?[fieldKey] != null;
    } else if (fieldType == 'date') {
      // For date, check both controller and formData
      hasValue = _form?.formData?[fieldKey] != null;
    } else {
      // For text fields, check controller
      final controller = _getFieldController(fieldKey);
      hasValue = controller.text.isNotEmpty;
    }
    
    // Don't show clear button if field is empty
    if (!hasValue) return null;
    
    return IconButton(
      icon: const Icon(Icons.clear, size: 20),
      onPressed: () {
        setState(() {
          final controller = _getFieldController(fieldKey);
          controller.clear();
          if (_form?.formData != null) {
            // Clear the field based on type
            switch (fieldType) {
              case 'checkbox':
                _form!.formData![fieldKey] = <String>[];
                break;
              case 'number':
              case 'date':
              case 'radio':
              case 'dropdown':
              case 'select':
                _form!.formData![fieldKey] = null;
                break;
              default:
                _form!.formData![fieldKey] = null;
            }
          }
        });
        _saveFormData();
      },
      tooltip: 'Clear',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildFieldWidget(
    String fieldKey,
    String fieldType,
    Map<String, dynamic>? fieldMeta,
    ThemeData theme,
  ) {
    switch (fieldType) {
      case 'static':
        return const SizedBox.shrink(); // Static content is already shown above
      
      case 'radio':
        final options = (fieldMeta?['options'] as List<dynamic>?) ?? [];
        final currentValue = _form?.formData?[fieldKey];
        final hasSelection = currentValue != null;
        
        return Column(
          children: [
            ...options.map<Widget>((option) {
              final optionText = option.toString();
              final isSelected = currentValue == optionText;
              
              return RadioListTile<String>(
                title: Text(
                  optionText,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                value: optionText,
                groupValue: isSelected ? optionText : null,
                activeColor: AppColors.primaryOrange,
                onChanged: (value) {
                  setState(() {
                    if (_form?.formData != null) {
                      _form!.formData![fieldKey] = value;
                    }
                  });
                  _saveFormData();
                },
                contentPadding: EdgeInsets.zero,
                tileColor: AppColors.darkSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
            if (hasSelection)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_form?.formData != null) {
                        _form!.formData![fieldKey] = null;
                      }
                    });
                    _saveFormData();
                  },
                  icon: const Icon(Icons.clear, size: 16, color: Colors.white70),
                  label: Text(
                    'Clear selection',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
        );
      
      case 'checkbox':
        final options = (fieldMeta?['options'] as List<dynamic>?) ?? [];
        final currentValues = (_form?.formData?[fieldKey] as List<dynamic>?) ?? [];
        final selectedValues = currentValues.map((e) => e.toString()).toSet();
        final hasSelection = selectedValues.isNotEmpty;
        
        return Column(
          children: [
            ...options.map<Widget>((option) {
              final optionText = option.toString();
              final isSelected = selectedValues.contains(optionText);
              
              return CheckboxListTile(
                title: Text(
                  optionText,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                value: isSelected,
                activeColor: AppColors.primaryOrange,
                checkColor: Colors.white,
                onChanged: (value) {
                  setState(() {
                    if (_form?.formData != null) {
                      final currentList = List<String>.from(selectedValues);
                      if (value == true) {
                        if (!currentList.contains(optionText)) {
                          currentList.add(optionText);
                        }
                      } else {
                        currentList.remove(optionText);
                      }
                      _form!.formData![fieldKey] = currentList;
                    }
                  });
                  _saveFormData();
                },
                contentPadding: EdgeInsets.zero,
                tileColor: AppColors.darkSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
            if (hasSelection)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_form?.formData != null) {
                        _form!.formData![fieldKey] = <String>[];
                      }
                    });
                    _saveFormData();
                  },
                  icon: const Icon(Icons.clear, size: 16, color: Colors.white70),
                  label: Text(
                    'Clear all',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
        );
      
      case 'dropdown':
      case 'select':
        final isRequired = fieldMeta?['required'] == true;
        final isEmpty = _form?.formData?[fieldKey] == null;
        final showError = isRequired && isEmpty;
        final options = (fieldMeta?['options'] as List<dynamic>?) ?? [];
        final currentValue = _form?.formData?[fieldKey]?.toString();
        final clearButton = _buildClearButton(fieldKey, fieldType);
        
        return DropdownButtonFormField<String>(
          value: currentValue,
          isExpanded: true, // Prevent overflow by allowing dropdown to expand
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: showError 
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: showError 
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: showError ? Colors.red : AppColors.primaryOrange,
                width: 2,
              ),
            ),
            errorText: showError ? 'This field is required' : null,
            errorStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.red,
            ),
            filled: true,
            fillColor: AppColors.darkSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: clearButton != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(child: clearButton),
                      ),
                      const SizedBox(width: 4),
                      const Padding(
                        padding: EdgeInsets.only(right: 12.0),
                        child: Icon(Icons.arrow_drop_down, size: 24, color: Colors.white70),
                      ),
                    ],
                  )
                : const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: Icon(Icons.arrow_drop_down, size: 24, color: Colors.white70),
                  ),
          ),
          dropdownColor: AppColors.darkSurface,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.white,
          ),
          items: options.map<DropdownMenuItem<String>>((option) {
            final optionText = option.toString();
            return DropdownMenuItem<String>(
              value: optionText,
              child: Text(
                optionText,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                softWrap: true,
              ),
            );
          }).toList(),
          selectedItemBuilder: (context) {
            // Custom builder for selected item to handle long text
            return options.map<Widget>((option) {
              final optionText = option.toString();
              return Text(
                optionText,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              );
            }).toList();
          },
          onChanged: (value) {
            setState(() {
              if (_form?.formData != null) {
                _form!.formData![fieldKey] = value;
                // Update controller text for clear button visibility
                _getFieldController(fieldKey).text = value ?? '';
              }
            });
            _saveFormData();
          },
        );
      
      case 'textarea':
        final isRequired = fieldMeta?['required'] == true;
        final isEmpty = _form?.formData?[fieldKey] == null || 
                       _form!.formData![fieldKey].toString().trim().isEmpty;
        final showError = isRequired && isEmpty;
        final controller = _getFieldController(fieldKey);
        final isListeningToThisField = _isListening && _activeController == controller;
        final clearButton = _buildClearButton(fieldKey, fieldType);
        
        return TextField(
          controller: controller,
          focusNode: _getFieldFocusNode(fieldKey),
          maxLines: 5,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'Enter ${fieldKey}',
            hintStyle: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.white60,
            ),
            filled: true,
            fillColor: AppColors.darkSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: showError 
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: showError 
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: showError ? Colors.red : AppColors.primaryOrange,
                width: 2,
              ),
            ),
            errorText: showError ? 'This field is required' : null,
            errorStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.red,
            ),
            suffixIcon: isListeningToThisField
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(Icons.mic, color: Colors.red),
                  )
                : clearButton,
          ),
          onChanged: (value) {
            if (_form?.formData != null) {
              final trimmedValue = value.trim();
              _form!.formData![fieldKey] = trimmedValue.isEmpty ? null : trimmedValue;
            }
            _saveFormData();
            // Trigger rebuild to update error state and clear button visibility
            setState(() {});
          },
        );
      
      case 'number':
        final isRequired = fieldMeta?['required'] == true;
        final isEmpty = _form?.formData?[fieldKey] == null;
        final showError = isRequired && isEmpty;
        final controller = _getFieldController(fieldKey);
        final isListeningToThisField = _isListening && _activeController == controller;
        final clearButton = _buildClearButton(fieldKey, fieldType);
        
        return TextField(
          controller: controller,
          focusNode: _getFieldFocusNode(fieldKey),
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'Enter ${fieldKey}',
            hintStyle: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.white60,
            ),
            filled: true,
            fillColor: AppColors.darkSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: showError 
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: showError 
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: showError ? Colors.red : AppColors.primaryOrange,
                width: 2,
              ),
            ),
            errorText: showError ? 'This field is required' : null,
            errorStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.red,
            ),
            suffixIcon: isListeningToThisField
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(Icons.mic, color: Colors.red),
                  )
                : clearButton,
          ),
          onChanged: (value) {
            if (_form?.formData != null) {
              _form!.formData![fieldKey] = value.isEmpty ? null : num.tryParse(value);
            }
            _saveFormData();
            // Trigger rebuild to update error state and clear button visibility
            setState(() {});
          },
        );
      
      case 'date':
        final isRequired = fieldMeta?['required'] == true;
        final isEmpty = _form?.formData?[fieldKey] == null;
        final showError = isRequired && isEmpty;
        final controller = _getFieldController(fieldKey);
        final clearButton = _buildClearButton(fieldKey, fieldType);
        
        return TextField(
          controller: controller,
          focusNode: _getFieldFocusNode(fieldKey),
          readOnly: true,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'Select ${fieldKey}',
            hintStyle: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.white60,
            ),
            filled: true,
            fillColor: AppColors.darkSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: showError 
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: showError 
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: showError ? Colors.red : AppColors.primaryOrange,
                width: 2,
              ),
            ),
            errorText: showError ? 'This field is required' : null,
            suffixIcon: clearButton != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                controller.clear();
                                if (_form?.formData != null) {
                                  _form!.formData![fieldKey] = null;
                                }
                              });
                              _saveFormData();
                            },
                            tooltip: 'Clear',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Padding(
                        padding: EdgeInsets.only(right: 12.0),
                        child: Icon(Icons.calendar_today, size: 24),
                      ),
                    ],
                  )
                : const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: Icon(Icons.calendar_today, size: 24),
                  ),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() {
                controller.text = 
                    '${date.day}/${date.month}/${date.year}';
                if (_form?.formData != null) {
                  _form!.formData![fieldKey] = date.toIso8601String();
                }
              });
              _saveFormData();
            }
          },
        );
      
      case 'email':
        final isRequired = fieldMeta?['required'] == true;
        final isEmpty = _form?.formData?[fieldKey] == null || 
                       _form!.formData![fieldKey].toString().trim().isEmpty;
        final showError = isRequired && isEmpty;
        final controller = _getFieldController(fieldKey);
        final isListeningToThisField = _isListening && _activeController == controller;
        final clearButton = _buildClearButton(fieldKey, fieldType);
        
        return TextField(
          controller: controller,
          focusNode: _getFieldFocusNode(fieldKey),
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'Enter ${fieldKey}',
            hintStyle: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.white60,
            ),
            filled: true,
            fillColor: AppColors.darkSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: showError 
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: showError 
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: showError ? Colors.red : AppColors.primaryOrange,
                width: 2,
              ),
            ),
            errorText: showError ? 'This field is required' : null,
            suffixIcon: isListeningToThisField
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(Icons.mic, color: Colors.red),
                  )
                : clearButton,
          ),
          onChanged: (value) {
            if (_form?.formData != null) {
              final trimmedValue = value.trim();
              _form!.formData![fieldKey] = trimmedValue.isEmpty ? null : trimmedValue;
            }
            _saveFormData();
            // Trigger rebuild to update error state and clear button visibility
            setState(() {});
          },
        );
      
      case 'phone':
        final isRequired = fieldMeta?['required'] == true;
        final isEmpty = _form?.formData?[fieldKey] == null || 
                       _form!.formData![fieldKey].toString().trim().isEmpty;
        final showError = isRequired && isEmpty;
        final controller = _getFieldController(fieldKey);
        final isListeningToThisField = _isListening && _activeController == controller;
        final clearButton = _buildClearButton(fieldKey, fieldType);
        
        return TextField(
          controller: controller,
          focusNode: _getFieldFocusNode(fieldKey),
          keyboardType: TextInputType.phone,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'Enter ${fieldKey}',
            hintStyle: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.white60,
            ),
            filled: true,
            fillColor: AppColors.darkSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: showError 
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: showError 
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: showError ? Colors.red : AppColors.primaryOrange,
                width: 2,
              ),
            ),
            errorText: showError ? 'This field is required' : null,
            errorStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.red,
            ),
            suffixIcon: isListeningToThisField
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(Icons.mic, color: Colors.red),
                  )
                : clearButton,
          ),
          onChanged: (value) {
            if (_form?.formData != null) {
              final trimmedValue = value.trim();
              _form!.formData![fieldKey] = trimmedValue.isEmpty ? null : trimmedValue;
            }
            _saveFormData();
            // Trigger rebuild to update error state and clear button visibility
            setState(() {});
          },
        );
      
      case 'file':
        final isRequired = fieldMeta?['required'] == true;
        final filePath = _form?.formData?[fieldKey] as String?;
        final isEmpty = filePath == null || filePath.isEmpty;
        final showError = isRequired && isEmpty;
        
        return InkWell(
          onTap: () async {
            try {
              final filePicker = FilePicker.platform;
              final result = await filePicker.pickFiles(
                type: FileType.any,
                allowMultiple: false,
              );
              
              if (result != null && result.files.single.path != null) {
                setState(() {
                  if (_form?.formData != null) {
                    _form!.formData![fieldKey] = result.files.single.path;
                  }
                });
                _saveFormData();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error picking file: $e')),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              border: Border.all(
                color: showError ? Colors.red : Colors.white30,
                width: showError ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  color: showError ? Colors.red : AppColors.primaryOrange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filePath != null 
                            ? filePath.split('/').last 
                            : 'Tap to upload file',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: filePath != null 
                              ? Colors.white 
                              : Colors.white60,
                          fontWeight: filePath != null ? FontWeight.w500 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (showError)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'This field is required',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                    ],
                  ),
                ),
                if (filePath != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        if (_form?.formData != null) {
                          _form!.formData![fieldKey] = null;
                        }
                      });
                      _saveFormData();
                    },
                    tooltip: 'Remove file',
                  ),
              ],
            ),
          ),
        );
      
      default: // text
        final isRequired = fieldMeta?['required'] == true;
        final isEmpty = _form?.formData?[fieldKey] == null || 
                       _form!.formData![fieldKey].toString().trim().isEmpty;
        final showError = isRequired && isEmpty;
        final controller = _getFieldController(fieldKey);
        final isListeningToThisField = _isListening && _activeController == controller;
        final clearButton = _buildClearButton(fieldKey, fieldType);
        
        return TextField(
          controller: controller,
          focusNode: _getFieldFocusNode(fieldKey),
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'Enter ${fieldKey}',
            hintStyle: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.white60,
            ),
            filled: true,
            fillColor: AppColors.darkSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: showError 
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: showError 
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: showError ? Colors.red : AppColors.primaryOrange,
                width: 2,
              ),
            ),
            errorText: showError ? 'This field is required' : null,
            errorStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.red,
            ),
            suffixIcon: isListeningToThisField
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(Icons.mic, color: Colors.red),
                  )
                : clearButton,
          ),
          onChanged: (value) {
            if (_form?.formData != null) {
              final trimmedValue = value.trim();
              _form!.formData![fieldKey] = trimmedValue.isEmpty ? null : trimmedValue;
            }
            _saveFormData();
            // Trigger rebuild to update error state and clear button visibility
            setState(() {});
          },
        );
    }
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
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isAI;

  const _ChatBubble({
    required this.text,
    required this.isAI,
  });

  // Helper function to convert markdown links to plain URLs
  // Converts [text](url) to just the URL so Linkify can detect it properly
  String _convertMarkdownLinks(String text) {
    // Pattern to match markdown links: [text](url)
    final markdownLinkPattern = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
    
    String processedText = text;
    
    // Replace all markdown links with just the clean URL
    // Linkify will automatically detect and make it clickable
    processedText = processedText.replaceAllMapped(markdownLinkPattern, (match) {
      final linkText = match.group(1) ?? '';
      final url = match.group(2) ?? '';
      // Clean the URL - remove any trailing characters that might cause issues
      String cleanUrl = url.trim();
      // Remove any trailing markdown characters, brackets, or punctuation
      cleanUrl = cleanUrl.replaceAll(RegExp(r'[)\]}\s]+$'), '');
      // Return format: linkText: cleanUrl
      // This ensures the URL is clearly separated and Linkify can detect it
      if (cleanUrl.isNotEmpty) {
        return '$linkText: $cleanUrl';
      }
      return linkText;
    });
    
    return processedText;
  }

  // Parse markdown and create TextSpans with formatting
  List<TextSpan> _parseMarkdown(String text, TextStyle baseStyle, TextStyle linkStyle, BuildContext context) {
    List<TextSpan> spans = [];
    
    // First, extract all markdown patterns and URLs with their positions
    List<_MarkdownElement> elements = [];
    
    // Find bold text: **text** or __text__
    final boldPattern = RegExp(r'\*\*([^*]+)\*\*|__([^_]+)__');
    for (final match in boldPattern.allMatches(text)) {
      final boldText = match.group(1) ?? match.group(2) ?? '';
      elements.add(_MarkdownElement(
        start: match.start,
        end: match.end,
        type: _MarkdownType.bold,
        content: boldText,
      ));
    }
    
    // Find URLs: http:// or https://
    final urlPattern = RegExp(r'https?://[^\s\)\]\}]+');
    for (final match in urlPattern.allMatches(text)) {
      final url = match.group(0)!;
      elements.add(_MarkdownElement(
        start: match.start,
        end: match.end,
        type: _MarkdownType.url,
        content: url,
      ));
    }
    
    // Sort elements by position
    elements.sort((a, b) => a.start.compareTo(b.start));
    
    // Remove overlapping elements (prioritize URLs, then bold)
    List<_MarkdownElement> filteredElements = [];
    for (final element in elements) {
      bool shouldAdd = true;
      
      // Check if this element overlaps with any existing element
      for (int i = filteredElements.length - 1; i >= 0; i--) {
        final existing = filteredElements[i];
        
        // Check for overlap
        if (!(element.end <= existing.start || element.start >= existing.end)) {
          // They overlap
          // Prioritize URLs over bold
          if (element.type == _MarkdownType.url && existing.type == _MarkdownType.bold) {
            // Replace bold with URL
            filteredElements.removeAt(i);
          } else if (element.type == _MarkdownType.bold && existing.type == _MarkdownType.url) {
            // Don't add bold if URL already exists
            shouldAdd = false;
            break;
          } else {
            // Same type or both are bold/url - keep the first one
            shouldAdd = false;
            break;
          }
        }
      }
      
      if (shouldAdd) {
        filteredElements.add(element);
      }
    }
    
    // Re-sort after filtering (in case we removed elements)
    filteredElements.sort((a, b) => a.start.compareTo(b.start));
    
    // Build TextSpans
    int currentIndex = 0;
    for (final element in filteredElements) {
      // Add text before this element
      if (element.start > currentIndex) {
        final beforeText = text.substring(currentIndex, element.start);
        spans.add(TextSpan(text: beforeText, style: baseStyle));
      }
      
      // Add the formatted element
      if (element.type == _MarkdownType.bold) {
        spans.add(TextSpan(
          text: element.content,
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (element.type == _MarkdownType.url) {
        spans.add(TextSpan(
          text: element.content,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => _openUrl(context, element.content),
        ));
      }
      
      currentIndex = element.end;
    }
    
    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex), style: baseStyle));
    }
    
    return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
  }

  // Helper to open URLs
  void _openUrl(BuildContext context, String url) async {
    // Clean the URL thoroughly
    String cleanUrl = url.trim();
    
    // Remove any trailing markdown characters or malformed parts
    cleanUrl = cleanUrl.replaceAll(RegExp(r'\]\([^)]*\)\s*$'), '');
    cleanUrl = cleanUrl.replaceAll(RegExp(r'[)\]}\s]+$'), '');
    cleanUrl = cleanUrl.replaceAll(RegExp(r'^\s*[(\[]+'), '');
    
    // Extract URL from malformed strings
    final urlPattern = RegExp(r'https?://[^\s\)\]\}]+');
    final urlMatch = urlPattern.firstMatch(cleanUrl);
    if (urlMatch != null) {
      cleanUrl = urlMatch.group(0)!;
    }
    
    cleanUrl = cleanUrl.trim();
    
    // Validate URL format
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid URL format: $cleanUrl'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    try {
      final uri = Uri.parse(cleanUrl);
      debugPrint('Attempting to launch URL: $cleanUrl');
      
      // Try to launch the URL with externalApplication mode (opens in browser)
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (!launched) {
          debugPrint('launchUrl returned false');
          // Try alternative modes as fallback
          try {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
          } catch (e2) {
            debugPrint('platformDefault also failed: $e2');
            throw Exception('Could not launch URL');
          }
        }
      } catch (e) {
        debugPrint('externalApplication failed: $e');
        // Try platformDefault as fallback
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e2) {
          debugPrint('All launch modes failed: $e2');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not open $cleanUrl. Please make sure you have a browser installed.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error parsing or launching URL: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening URL: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine colors based on theme
    // AI messages: lighter background that's more visible
    // User messages: 20% white and 80% black (Color(0xFF333333)) as requested
    final aiMessageColor = isDark
        ? theme.colorScheme.primary.withOpacity(0.25) // Lighter for dark theme - more visible
        : theme.colorScheme.primary.withOpacity(0.1);
    final aiMessageTextColor = theme.colorScheme.onSurface;
    
    // User messages: 20% white and 80% black (Color(0xFF333333))
    final userMessageColor = isDark
        ? const Color(0xFF333333) // 20% white, 80% black
        : theme.colorScheme.primary;
    
    final userMessageTextColor = Colors.white; // White text for good contrast on dark background

    // Text style for the message
    final textStyle = TextStyle(
      color: isAI ? aiMessageTextColor : userMessageTextColor,
    );

    // Link style
    final linkStyle = textStyle.copyWith(
      color: isAI 
          ? theme.colorScheme.primary 
          : Colors.lightBlueAccent,
      decoration: TextDecoration.underline,
    );

    // Pre-process text to convert markdown links to plain URLs
    final processedText = _convertMarkdownLinks(text);

    // Parse markdown and create TextSpans
    final textSpans = _parseMarkdown(processedText, textStyle, linkStyle, context);

    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAI ? aiMessageColor : userMessageColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: RichText(
          text: TextSpan(children: textSpans),
        ),
      ),
    );
  }
}

// Helper classes for markdown parsing
enum _MarkdownType { bold, url }

class _MarkdownElement {
  final int start;
  final int end;
  final _MarkdownType type;
  final String content;
  
  _MarkdownElement({
    required this.start,
    required this.end,
    required this.type,
    required this.content,
  });
}

