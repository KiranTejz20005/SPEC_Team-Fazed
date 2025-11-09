import '../models/form_model.dart';
import 'database_service.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final DatabaseService _db = DatabaseService();

  Future<Map<String, dynamic>> getDashboardStats() async {
    final allForms = await _db.getAllForms();
    
    final completed = allForms.where((f) => f.status == 'completed' || f.status == 'submitted').length;
    final inProgress = allForms.where((f) => f.status == 'in_progress').length;
    final drafts = allForms.where((f) => f.status == 'draft').length;
    
    final totalTimeSaved = completed * 15; // Assume 15 minutes per form
    final averageProgress = allForms.isEmpty 
        ? 0.0 
        : allForms.map((f) => f.progress).reduce((a, b) => a + b) / allForms.length;
    
    final formsThisMonth = allForms.where((f) {
      final now = DateTime.now();
      return f.createdAt.month == now.month && f.createdAt.year == now.year;
    }).length;

    return {
      'totalForms': allForms.length,
      'completed': completed,
      'inProgress': inProgress,
      'drafts': drafts,
      'totalTimeSaved': totalTimeSaved,
      'averageProgress': averageProgress,
      'formsThisMonth': formsThisMonth,
    };
  }

  Future<List<Map<String, dynamic>>> getFormTypeStats() async {
    final allForms = await _db.getAllForms();
    final Map<String, int> typeCounts = {};
    
    for (var form in allForms) {
      final type = form.formType ?? 'Other';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }
    
    return typeCounts.entries.map((e) => {
      'type': e.key,
      'count': e.value,
    }).toList();
  }

  Future<Map<String, int>> getMonthlyStats() async {
    final allForms = await _db.getAllForms();
    final Map<String, int> monthlyStats = {};
    
    for (var form in allForms) {
      final monthKey = '${form.createdAt.year}-${form.createdAt.month.toString().padLeft(2, '0')}';
      monthlyStats[monthKey] = (monthlyStats[monthKey] ?? 0) + 1;
    }
    
    return monthlyStats;
  }

  Future<double> getCompletionRate() async {
    final allForms = await _db.getAllForms();
    if (allForms.isEmpty) return 0.0;
    
    final completed = allForms.where((f) => 
      f.status == 'completed' || f.status == 'submitted'
    ).length;
    
    return completed / allForms.length;
  }
}

