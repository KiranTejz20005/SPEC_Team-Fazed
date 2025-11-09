import '../services/auth_service.dart';

/// Service to automatically fill form fields with user profile data
class ProfileAutofillService {
  static final ProfileAutofillService _instance = ProfileAutofillService._internal();
  factory ProfileAutofillService() => _instance;
  ProfileAutofillService._internal();

  final AuthService _authService = AuthService();

  /// Get user profile data
  Future<Map<String, dynamic>?> _getProfileData() async {
    try {
      return await _authService.getCurrentUser();
    } catch (e) {
      print('Error getting profile data: $e');
      return null;
    }
  }

  /// Normalize field name for matching (lowercase, remove special chars, etc.)
  String _normalizeFieldName(String fieldName) {
    return fieldName
        .toLowerCase()
        .replaceAll(RegExp(r'[_\s\-]'), '')
        .trim();
  }

  /// Check if a field name matches profile field patterns
  String? _getProfileFieldForFormField(String formFieldName) {
    final normalized = _normalizeFieldName(formFieldName);
    
    // Mapping of normalized form field names to profile field keys
    final fieldMappings = {
      // Name fields
      'name': 'name',
      'fullname': 'name',
      'full_name': 'name',
      'firstname': 'name',
      'first_name': 'name',
      'lastname': 'name',
      'last_name': 'name',
      'fullnam': 'name', // typo tolerance
      
      // Nickname
      'nickname': 'nickname',
      'nick_name': 'nickname',
      'nick': 'nickname',
      'preferredname': 'nickname',
      'preferred_name': 'nickname',
      
      // Email fields
      'email': 'email',
      'emailaddress': 'email',
      'email_address': 'email',
      'e-mail': 'email',
      'mail': 'email',
      
      // Phone fields
      'phone': 'phone',
      'phonenumber': 'phone',
      'phone_number': 'phone',
      'mobile': 'phone',
      'mobilenumber': 'phone',
      'mobile_number': 'phone',
      'contactnumber': 'phone',
      'contact_number': 'phone',
      'tel': 'phone',
      'telephone': 'phone',
      
      // Date of Birth fields
      'dateofbirth': 'dateOfBirth',
      'date_of_birth': 'dateOfBirth',
      'dob': 'dateOfBirth',
      'birthdate': 'dateOfBirth',
      'birth_date': 'dateOfBirth',
      'birthday': 'dateOfBirth',
      'age': 'dateOfBirth', // Could calculate from DOB
      
      // Gender fields
      'gender': 'gender',
      'sex': 'gender',
      
      // Address fields
      'address': 'address',
      'street': 'address',
      'streetaddress': 'address',
      'street_address': 'address',
      'location': 'address',
      'residence': 'address',
      'homeaddress': 'address',
      'home_address': 'address',
      
      // Nationality/Country fields
      'nationality': 'nationality',
      'country': 'nationality',
      'countryoforigin': 'nationality',
      'country_of_origin': 'nationality',
      'citizenship': 'nationality',
      
      // Occupation fields
      'occupation': 'occupation',
      'jobtitle': 'occupation',
      'job_title': 'occupation',
      'position': 'occupation',
      'profession': 'occupation',
      'work': 'occupation',
      'employment': 'occupation',
      'designation': 'occupation',
    };

    // Direct match
    if (fieldMappings.containsKey(normalized)) {
      return fieldMappings[normalized];
    }

    // Partial match (field name contains a key)
    for (var entry in fieldMappings.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Format date of birth for form fields
  String? _formatDateOfBirth(dynamic dob) {
    if (dob == null) return null;
    
    try {
      if (dob is String) {
        final date = DateTime.parse(dob);
        // Format as YYYY-MM-DD (common form format)
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      print('Error formatting date of birth: $e');
    }
    
    return dob.toString();
  }

  /// Format gender value for form fields
  String? _formatGender(dynamic gender) {
    if (gender == null) return null;
    
    final genderStr = gender.toString().toLowerCase();
    
    // Map common gender values
    if (genderStr == 'male' || genderStr == 'm') {
      return 'Male';
    } else if (genderStr == 'female' || genderStr == 'f') {
      return 'Female';
    } else if (genderStr == 'other' || genderStr == 'o') {
      return 'Other';
    } else if (genderStr == 'prefer_not_to_say') {
      return 'Prefer not to say';
    }
    
    // Return capitalized if it's a valid value
    return genderStr.isNotEmpty ? genderStr[0].toUpperCase() + genderStr.substring(1) : null;
  }

  /// Auto-fill form data with profile information
  /// Returns the form data with profile values filled in for matching fields
  Future<Map<String, dynamic>> autofillFormData(
    Map<String, dynamic> formData,
    Map<String, dynamic>? fieldMetadata,
  ) async {
    // Get profile data
    final profileData = await _getProfileData();
    if (profileData == null || profileData.isEmpty) {
      return formData;
    }

    // Create a copy of form data to modify
    final filledFormData = Map<String, dynamic>.from(formData);

    // Iterate through form fields and try to match with profile data
    for (var fieldName in formData.keys) {
      // Skip if field already has a value (don't overwrite existing data)
      if (filledFormData[fieldName] != null && 
          filledFormData[fieldName] != '' && 
          filledFormData[fieldName] is! List ||
          (filledFormData[fieldName] is List && (filledFormData[fieldName] as List).isNotEmpty)) {
        continue;
      }

      // Get the corresponding profile field
      final profileField = _getProfileFieldForFormField(fieldName);
      if (profileField == null || !profileData.containsKey(profileField)) {
        continue;
      }

      final profileValue = profileData[profileField];
      if (profileValue == null || profileValue == '') {
        continue;
      }

      // Get field type from metadata if available
      String? fieldType;
      if (fieldMetadata != null && fieldMetadata.containsKey(fieldName)) {
        final fieldMeta = fieldMetadata[fieldName];
        if (fieldMeta is Map<String, dynamic>) {
          fieldType = fieldMeta['type'] as String?;
        }
      }

      // Format value based on field type
      dynamic valueToFill;
      if (fieldType == 'date' && profileField == 'dateOfBirth') {
        valueToFill = _formatDateOfBirth(profileValue);
      } else if ((fieldType == 'dropdown' || fieldType == 'radio' || fieldType == 'select') && 
                 profileField == 'gender') {
        valueToFill = _formatGender(profileValue);
      } else {
        valueToFill = profileValue.toString();
      }

      // Fill the field
      filledFormData[fieldName] = valueToFill;
    }

    return filledFormData;
  }

  /// Auto-fill a single field value based on profile data
  Future<dynamic> getFieldValue(String fieldName, String? fieldType) async {
    final profileData = await _getProfileData();
    if (profileData == null || profileData.isEmpty) {
      return null;
    }

    final profileField = _getProfileFieldForFormField(fieldName);
    if (profileField == null || !profileData.containsKey(profileField)) {
      return null;
    }

    final profileValue = profileData[profileField];
    if (profileValue == null || profileValue == '') {
      return null;
    }

    // Format value based on field type
    if (fieldType == 'date' && profileField == 'dateOfBirth') {
      return _formatDateOfBirth(profileValue);
    } else if ((fieldType == 'dropdown' || fieldType == 'radio' || fieldType == 'select') && 
               profileField == 'gender') {
      return _formatGender(profileValue);
    }

    return profileValue.toString();
  }
}
