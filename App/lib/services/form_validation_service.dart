class FormValidationService {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', '').replaceAll('-', ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (double.tryParse(value) == null) {
      return '$fieldName must be a number';
    }
    return null;
  }

  static String? validateDate(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  static Map<String, String?> validateForm(Map<String, dynamic> formData, Map<String, Map<String, dynamic>> validationRules) {
    Map<String, String?> errors = {};
    
    validationRules.forEach((field, rules) {
      final value = formData[field];
      
      if (rules['required'] == true) {
        final error = validateRequired(value?.toString(), field);
        if (error != null) {
          errors[field] = error;
          return;
        }
      }
      
      if (rules['type'] == 'email') {
        final error = validateEmail(value?.toString());
        if (error != null) {
          errors[field] = error;
          return;
        }
      }
      
      if (rules['type'] == 'phone') {
        final error = validatePhone(value?.toString());
        if (error != null) {
          errors[field] = error;
          return;
        }
      }
      
      if (rules['minLength'] != null) {
        final error = validateMinLength(value?.toString(), rules['minLength'] as int, field);
        if (error != null) {
          errors[field] = error;
          return;
        }
      }
      
      if (rules['maxLength'] != null) {
        final error = validateMaxLength(value?.toString(), rules['maxLength'] as int, field);
        if (error != null) {
          errors[field] = error;
          return;
        }
      }
    });
    
    return errors;
  }
}

