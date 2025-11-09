import 'dart:convert';

class FormModel {
  final String id;
  final String title;
  final String? description;
  final Map<String, dynamic> formData;
  final String status; // 'draft', 'in_progress', 'completed', 'submitted'
  final double progress;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;
  final String? formType;
  final List<String>? tags;
  final String? templateId;

  FormModel({
    required this.id,
    required this.title,
    this.description,
    required this.formData,
    required this.status,
    required this.progress,
    required this.createdAt,
    this.updatedAt,
    this.submittedAt,
    this.formType,
    this.tags,
    this.templateId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'formData': jsonEncode(formData),
      'status': status,
      'progress': progress,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'formType': formType,
      'tags': tags?.join(','),
      'templateId': templateId,
    };
  }

  factory FormModel.fromMap(Map<String, dynamic> map) {
    return FormModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      formData: map['formData'] != null 
          ? jsonDecode(map['formData'] as String) as Map<String, dynamic>
          : {},
      status: map['status'] as String,
      progress: (map['progress'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      submittedAt: map['submittedAt'] != null ? DateTime.parse(map['submittedAt'] as String) : null,
      formType: map['formType'] as String?,
      tags: map['tags'] != null ? (map['tags'] as String).split(',') : null,
      templateId: map['templateId'] as String?,
    );
  }

  FormModel copyWith({
    String? id,
    String? title,
    String? description,
    Map<String, dynamic>? formData,
    String? status,
    double? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    String? formType,
    List<String>? tags,
    String? templateId,
  }) {
    return FormModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      formData: formData ?? this.formData,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      formType: formType ?? this.formType,
      tags: tags ?? this.tags,
      templateId: templateId ?? this.templateId,
    );
  }
}

