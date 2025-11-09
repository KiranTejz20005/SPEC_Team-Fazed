import '../models/form_model.dart';

class SearchService {
  static List<FormModel> searchForms(List<FormModel> forms, String query) {
    if (query.isEmpty) return forms;

    final lowerQuery = query.toLowerCase();
    return forms.where((form) {
      return form.title.toLowerCase().contains(lowerQuery) ||
          (form.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          (form.formType?.toLowerCase().contains(lowerQuery) ?? false) ||
          (form.tags?.any((tag) => tag.toLowerCase().contains(lowerQuery)) ?? false) ||
          form.formData.values.any((value) => 
            value.toString().toLowerCase().contains(lowerQuery)
          );
    }).toList();
  }

  static List<FormModel> filterForms(
    List<FormModel> forms, {
    String? status,
    String? formType,
    DateTime? startDate,
    DateTime? endDate,
    double? minProgress,
    double? maxProgress,
  }) {
    return forms.where((form) {
      if (status != null && form.status != status) return false;
      if (formType != null && form.formType != formType) return false;
      if (startDate != null && form.createdAt.isBefore(startDate)) return false;
      if (endDate != null && form.createdAt.isAfter(endDate)) return false;
      if (minProgress != null && form.progress < minProgress) return false;
      if (maxProgress != null && form.progress > maxProgress) return false;
      return true;
    }).toList();
  }

  static List<FormModel> sortForms(
    List<FormModel> forms, {
    required String sortBy,
    bool ascending = true,
  }) {
    final sorted = List<FormModel>.from(forms);
    
    sorted.sort((a, b) {
      int comparison;
      switch (sortBy) {
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'date':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'progress':
          comparison = a.progress.compareTo(b.progress);
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
        default:
          comparison = 0;
      }
      return ascending ? comparison : -comparison;
    });
    
    return sorted;
  }
}

