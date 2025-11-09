import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';
import '../models/form_model.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final DatabaseService _db = DatabaseService();
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  final List<FormModel> _pendingSync = [];

  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      if (_isOnline) {
        _syncPendingForms();
      }
    });
  }

  Future<void> saveForm(FormModel form, {bool sync = true}) async {
    // Always save locally
    await _db.insertForm(form);

    // If online and sync is enabled, sync immediately
    if (_isOnline && sync) {
      await _syncForm(form);
    } else {
      // Queue for later sync
      _pendingSync.add(form);
    }
  }

  Future<void> _syncForm(FormModel form) async {
    try {
      // In production, this would call your backend API
      // For now, we'll just mark it as synced
      await Future.delayed(const Duration(milliseconds: 500));
      // Simulate API call
      print('Synced form: ${form.id}');
    } catch (e) {
      // If sync fails, add to pending
      _pendingSync.add(form);
    }
  }

  Future<void> _syncPendingForms() async {
    if (_pendingSync.isEmpty) return;

    final formsToSync = List<FormModel>.from(_pendingSync);
    _pendingSync.clear();

    for (final form in formsToSync) {
      await _syncForm(form);
    }
  }

  Future<List<FormModel>> getForms({bool onlineOnly = false}) async {
    if (onlineOnly && !_isOnline) {
      return [];
    }
    return await _db.getAllForms();
  }

  Future<void> syncAllPending() async {
    if (_isOnline) {
      await _syncPendingForms();
    }
  }

  int get pendingSyncCount => _pendingSync.length;
}

