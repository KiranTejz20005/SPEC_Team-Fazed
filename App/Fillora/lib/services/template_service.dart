import 'dart:convert';
import 'database_service.dart';

class TemplateService {
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();

  final DatabaseService _db = DatabaseService();

  // Predefined templates
  final List<Map<String, dynamic>> _defaultTemplates = [
    // Education Category
    {
      'id': 'scholarship',
      'name': 'Scholarship Application',
      'description': 'Complete scholarship forms quickly',
      'category': 'Education',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Email', 'type': 'email', 'required': true},
          {'name': 'Phone', 'type': 'phone', 'required': true},
          {'name': 'Date of Birth', 'type': 'date', 'required': true},
          {'name': 'Degree', 'type': 'text', 'required': true},
          {'name': 'University', 'type': 'text', 'required': true},
          {'name': 'GPA', 'type': 'number', 'required': true},
          {'name': 'Annual Income', 'type': 'number', 'required': false},
        ],
      }),
      'icon': 'school',
    },
    {
      'id': 'admission',
      'name': 'University Admission',
      'description': 'Apply for university admission',
      'category': 'Education',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Email', 'type': 'email', 'required': true},
          {'name': 'Phone', 'type': 'phone', 'required': true},
          {'name': 'Date of Birth', 'type': 'date', 'required': true},
          {'name': 'Previous Education', 'type': 'textarea', 'required': true},
          {'name': 'Marks/Percentage', 'type': 'number', 'required': true},
          {'name': 'Course Applied', 'type': 'text', 'required': true},
        ],
      }),
      'icon': 'cast_for_education',
    },
    {
      'id': 'loan_education',
      'name': 'Education Loan',
      'description': 'Apply for education loan',
      'category': 'Education',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Course', 'type': 'text', 'required': true},
          {'name': 'Loan Amount', 'type': 'number', 'required': true},
          {'name': 'Annual Income', 'type': 'number', 'required': true},
          {'name': 'Co-applicant Name', 'type': 'text', 'required': false},
        ],
      }),
      'icon': 'account_balance',
    },
    // Travel Category
    {
      'id': 'passport',
      'name': 'Passport Renewal',
      'description': 'Renew your passport application',
      'category': 'Travel',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Passport Number', 'type': 'text', 'required': true},
          {'name': 'Date of Birth', 'type': 'date', 'required': true},
          {'name': 'Expiry Date', 'type': 'date', 'required': true},
          {'name': 'Address', 'type': 'textarea', 'required': true},
          {'name': 'Phone', 'type': 'phone', 'required': true},
        ],
      }),
      'icon': 'flight',
    },
    {
      'id': 'visa',
      'name': 'Visa Application',
      'description': 'Apply for visa',
      'category': 'Travel',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Country', 'type': 'text', 'required': true},
          {'name': 'Purpose of Visit', 'type': 'textarea', 'required': true},
          {'name': 'Duration', 'type': 'text', 'required': true},
          {'name': 'Passport Number', 'type': 'text', 'required': true},
        ],
      }),
      'icon': 'card_membership',
    },
    {
      'id': 'driving_license',
      'name': 'Driving License',
      'description': 'Apply or renew driving license',
      'category': 'Travel',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Date of Birth', 'type': 'date', 'required': true},
          {'name': 'Address', 'type': 'textarea', 'required': true},
          {'name': 'License Number', 'type': 'text', 'required': false},
          {'name': 'Vehicle Type', 'type': 'text', 'required': true},
        ],
      }),
      'icon': 'directions_car',
    },
    // Employment Category
    {
      'id': 'job',
      'name': 'Job Application',
      'description': 'Apply for jobs',
      'category': 'Employment',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Email', 'type': 'email', 'required': true},
          {'name': 'Phone', 'type': 'phone', 'required': true},
          {'name': 'Previous Experience', 'type': 'textarea', 'required': false},
          {'name': 'Education', 'type': 'textarea', 'required': true},
          {'name': 'Skills', 'type': 'text', 'required': true},
        ],
      }),
      'icon': 'work',
    },
    {
      'id': 'resume',
      'name': 'Resume Builder',
      'description': 'Create professional resume',
      'category': 'Employment',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Email', 'type': 'email', 'required': true},
          {'name': 'Phone', 'type': 'phone', 'required': true},
          {'name': 'Professional Summary', 'type': 'textarea', 'required': true},
          {'name': 'Work Experience', 'type': 'textarea', 'required': true},
          {'name': 'Education', 'type': 'textarea', 'required': true},
          {'name': 'Skills', 'type': 'text', 'required': true},
        ],
      }),
      'icon': 'description',
    },
    {
      'id': 'tax_return',
      'name': 'Income Tax Return',
      'description': 'File your income tax return',
      'category': 'Employment',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'PAN Number', 'type': 'text', 'required': true},
          {'name': 'Annual Income', 'type': 'number', 'required': true},
          {'name': 'TDS Deducted', 'type': 'number', 'required': false},
          {'name': 'Tax Exemptions', 'type': 'textarea', 'required': false},
        ],
      }),
      'icon': 'receipt_long',
    },
    // Finance Category
    {
      'id': 'insurance',
      'name': 'Insurance Form',
      'description': 'Insurance application',
      'category': 'Finance',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Date of Birth', 'type': 'date', 'required': true},
          {'name': 'Annual Income', 'type': 'number', 'required': true},
          {'name': 'Coverage Amount', 'type': 'number', 'required': true},
          {'name': 'Medical History', 'type': 'textarea', 'required': false},
        ],
      }),
      'icon': 'health_and_safety',
    },
    {
      'id': 'loan_home',
      'name': 'Home Loan',
      'description': 'Apply for home loan',
      'category': 'Finance',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Annual Income', 'type': 'number', 'required': true},
          {'name': 'Loan Amount', 'type': 'number', 'required': true},
          {'name': 'Property Value', 'type': 'number', 'required': true},
          {'name': 'Employment Type', 'type': 'text', 'required': true},
        ],
      }),
      'icon': 'home',
    },
    {
      'id': 'loan_personal',
      'name': 'Personal Loan',
      'description': 'Apply for personal loan',
      'category': 'Finance',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Annual Income', 'type': 'number', 'required': true},
          {'name': 'Loan Amount', 'type': 'number', 'required': true},
          {'name': 'Loan Purpose', 'type': 'textarea', 'required': true},
          {'name': 'Employment Status', 'type': 'text', 'required': true},
        ],
      }),
      'icon': 'credit_card',
    },
    {
      'id': 'bank_account',
      'name': 'Bank Account Opening',
      'description': 'Open new bank account',
      'category': 'Finance',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Date of Birth', 'type': 'date', 'required': true},
          {'name': 'Address', 'type': 'textarea', 'required': true},
          {'name': 'Account Type', 'type': 'text', 'required': true},
          {'name': 'Initial Deposit', 'type': 'number', 'required': false},
        ],
      }),
      'icon': 'account_balance_wallet',
    },
    // Healthcare Category
    {
      'id': 'medical_appointment',
      'name': 'Medical Appointment',
      'description': 'Book medical appointment',
      'category': 'Healthcare',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Phone', 'type': 'phone', 'required': true},
          {'name': 'Date of Birth', 'type': 'date', 'required': true},
          {'name': 'Preferred Date', 'type': 'date', 'required': true},
          {'name': 'Medical Issue', 'type': 'textarea', 'required': true},
          {'name': 'Doctor/Department', 'type': 'text', 'required': true},
        ],
      }),
      'icon': 'medical_services',
    },
    {
      'id': 'health_insurance',
      'name': 'Health Insurance',
      'description': 'Apply for health insurance',
      'category': 'Healthcare',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Date of Birth', 'type': 'date', 'required': true},
          {'name': 'Family Members', 'type': 'number', 'required': true},
          {'name': 'Coverage Amount', 'type': 'number', 'required': true},
          {'name': 'Medical History', 'type': 'textarea', 'required': false},
        ],
      }),
      'icon': 'healing',
    },
    // Government Category
    {
      'id': 'aadhar',
      'name': 'Aadhar Card',
      'description': 'Apply or update Aadhar card',
      'category': 'Government',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Date of Birth', 'type': 'date', 'required': true},
          {'name': 'Address', 'type': 'textarea', 'required': true},
          {'name': 'Aadhar Number', 'type': 'text', 'required': false},
          {'name': 'Update Type', 'type': 'text', 'required': true},
        ],
      }),
      'icon': 'badge',
    },
    {
      'id': 'voter_id',
      'name': 'Voter ID Card',
      'description': 'Apply for voter ID card',
      'category': 'Government',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Date of Birth', 'type': 'date', 'required': true},
          {'name': 'Address', 'type': 'textarea', 'required': true},
          {'name': 'Constituency', 'type': 'text', 'required': true},
        ],
      }),
      'icon': 'how_to_vote',
    },
    {
      'id': 'ration_card',
      'name': 'Ration Card',
      'description': 'Apply for ration card',
      'category': 'Government',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Date of Birth', 'type': 'date', 'required': true},
          {'name': 'Address', 'type': 'textarea', 'required': true},
          {'name': 'Family Members', 'type': 'number', 'required': true},
          {'name': 'Annual Income', 'type': 'number', 'required': true},
        ],
      }),
      'icon': 'shopping_bag',
    },
    // Legal Category
    {
      'id': 'legal_document',
      'name': 'Legal Document',
      'description': 'Draft legal documents',
      'category': 'Legal',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Document Type', 'type': 'text', 'required': true},
          {'name': 'Purpose', 'type': 'textarea', 'required': true},
          {'name': 'Parties Involved', 'type': 'textarea', 'required': true},
        ],
      }),
      'icon': 'gavel',
    },
    {
      'id': 'complaint',
      'name': 'Complaint Form',
      'description': 'File a complaint',
      'category': 'Legal',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Email', 'type': 'email', 'required': true},
          {'name': 'Phone', 'type': 'phone', 'required': true},
          {'name': 'Complaint Details', 'type': 'textarea', 'required': true},
          {'name': 'Date of Incident', 'type': 'date', 'required': false},
        ],
      }),
      'icon': 'report_problem',
    },
    // Utilities Category
    {
      'id': 'electricity',
      'name': 'Electricity Connection',
      'description': 'Apply for electricity connection',
      'category': 'Utilities',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Address', 'type': 'textarea', 'required': true},
          {'name': 'Phone', 'type': 'phone', 'required': true},
          {'name': 'Connection Type', 'type': 'text', 'required': true},
          {'name': 'Load Required', 'type': 'text', 'required': true},
        ],
      }),
      'icon': 'bolt',
    },
    {
      'id': 'water',
      'name': 'Water Connection',
      'description': 'Apply for water connection',
      'category': 'Utilities',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Address', 'type': 'textarea', 'required': true},
          {'name': 'Phone', 'type': 'phone', 'required': true},
          {'name': 'Connection Type', 'type': 'text', 'required': true},
        ],
      }),
      'icon': 'water_drop',
    },
    {
      'id': 'gas',
      'name': 'Gas Connection',
      'description': 'Apply for LPG/CNG connection',
      'category': 'Utilities',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Full Name', 'type': 'text', 'required': true},
          {'name': 'Address', 'type': 'textarea', 'required': true},
          {'name': 'Phone', 'type': 'phone', 'required': true},
          {'name': 'Connection Type', 'type': 'text', 'required': true},
          {'name': 'Aadhar Number', 'type': 'text', 'required': true},
        ],
      }),
      'icon': 'local_gas_station',
    },
    // Real Estate Category
    {
      'id': 'rental_agreement',
      'name': 'Rental Agreement',
      'description': 'Create rental agreement',
      'category': 'Real Estate',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Landlord Name', 'type': 'text', 'required': true},
          {'name': 'Tenant Name', 'type': 'text', 'required': true},
          {'name': 'Property Address', 'type': 'textarea', 'required': true},
          {'name': 'Rent Amount', 'type': 'number', 'required': true},
          {'name': 'Lease Duration', 'type': 'text', 'required': true},
          {'name': 'Start Date', 'type': 'date', 'required': true},
        ],
      }),
      'icon': 'apartment',
    },
    {
      'id': 'property_registration',
      'name': 'Property Registration',
      'description': 'Register property documents',
      'category': 'Real Estate',
      'formStructure': jsonEncode({
        'fields': [
          {'name': 'Buyer Name', 'type': 'text', 'required': true},
          {'name': 'Seller Name', 'type': 'text', 'required': true},
          {'name': 'Property Address', 'type': 'textarea', 'required': true},
          {'name': 'Property Value', 'type': 'number', 'required': true},
          {'name': 'Property Type', 'type': 'text', 'required': true},
        ],
      }),
      'icon': 'home_work',
    },
  ];

  Future<void> initializeTemplates() async {
    try {
      final existingTemplates = await _db.getAllTemplates();
      if (existingTemplates.isEmpty) {
        for (var template in _defaultTemplates) {
          template['createdAt'] = DateTime.now().toIso8601String();
          template['usageCount'] = 0;
          await _db.insertTemplate(template);
        }
      }
    } catch (e) {
      print('Error initializing templates: $e');
      // Continue even if initialization fails
    }
  }

  Future<List<Map<String, dynamic>>> getAllTemplates() async {
    try {
      await initializeTemplates();
      final templates = await _db.getAllTemplates();
      // If database is empty, return default templates directly
      if (templates.isEmpty) {
        return _defaultTemplates.map((t) => {
          ...t,
          'createdAt': DateTime.now().toIso8601String(),
          'usageCount': 0,
        }).toList();
      }
      return templates;
    } catch (e) {
      print('Error getting templates: $e');
      // Return default templates if database fails
      return _defaultTemplates.map((t) => {
        ...t,
        'createdAt': DateTime.now().toIso8601String(),
        'usageCount': 0,
      }).toList();
    }
  }

  Future<List<Map<String, dynamic>>> getTemplatesByCategory(String category) async {
    final allTemplates = await getAllTemplates();
    return allTemplates.where((t) => t['category'] == category).toList();
  }

  Future<Map<String, dynamic>?> getTemplateById(String id) async {
    final allTemplates = await getAllTemplates();
    try {
      return allTemplates.firstWhere((t) => t['id'] == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> incrementUsageCount(String templateId) async {
    try {
      final template = await getTemplateById(templateId);
      if (template != null) {
        // Create a new mutable map from the template to avoid read-only issues
        final updatedTemplate = Map<String, dynamic>.from(template);
        updatedTemplate['usageCount'] = (updatedTemplate['usageCount'] ?? 0) + 1;
        await _db.insertTemplate(updatedTemplate);
      }
    } catch (e) {
      // Silently fail - usage count increment is not critical
      print('Error incrementing usage count: $e');
    }
  }

  Future<List<String>> getCategories() async {
    final templates = await getAllTemplates();
    final categories = templates.map((t) => t['category'] as String).toSet();
    return categories.toList();
  }

  Future<List<Map<String, dynamic>>> searchTemplates(String query) async {
    final allTemplates = await getAllTemplates();
    if (query.isEmpty) return allTemplates;

    final lowerQuery = query.toLowerCase();
    return allTemplates.where((template) {
      return (template['name'] as String).toLowerCase().contains(lowerQuery) ||
          (template['description'] as String? ?? '').toLowerCase().contains(lowerQuery) ||
          (template['category'] as String).toLowerCase().contains(lowerQuery);
    }).toList();
  }
}

