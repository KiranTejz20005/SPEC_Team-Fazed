import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/debug_console_widget.dart';
import 'debug_log_service.dart';

class DebugConsoleService {
  static final DebugConsoleService _instance = DebugConsoleService._internal();
  factory DebugConsoleService() => _instance;
  DebugConsoleService._internal();

  bool _isConsoleVisible = false;
  final DebugLogService _logService = DebugLogService();
  
  bool get isConsoleVisible => _isConsoleVisible;
  
  int get logCount => _logService.logs.length;
  
  // Stream to notify listeners when console visibility changes
  final _visibilityController = StreamController<bool>.broadcast();
  Stream<bool> get visibilityStream => _visibilityController.stream;
  
  void _notifyVisibilityChanged() {
    _visibilityController.add(_isConsoleVisible);
  }
  
  void showDebugConsole(BuildContext context) {
    if (_isConsoleVisible) {
      return; // Already showing
    }
    
    try {
      _isConsoleVisible = true;
      _notifyVisibilityChanged();
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bug_report,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Debug Console',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      // Log count badge
                      if (logCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$logCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _isConsoleVisible = false;
                          _notifyVisibilityChanged();
                        },
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Debug console content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DebugConsoleWidget(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).whenComplete(() {
        _isConsoleVisible = false;
        _notifyVisibilityChanged();
      }).catchError((error) {
        _isConsoleVisible = false;
        _notifyVisibilityChanged();
        print('Error showing debug console: $error');
      });
    } catch (e) {
      _isConsoleVisible = false;
      _notifyVisibilityChanged();
      print('Error in showDebugConsole: $e');
    }
  }
  
  void dispose() {
    _visibilityController.close();
  }
}

