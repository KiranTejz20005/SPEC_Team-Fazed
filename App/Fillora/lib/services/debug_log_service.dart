import 'dart:async';
import 'package:flutter/foundation.dart';

class DebugLogService {
  static final DebugLogService _instance = DebugLogService._internal();
  factory DebugLogService() => _instance;
  DebugLogService._internal();

  final List<LogEntry> _logs = [];
  final _logController = StreamController<LogEntry>.broadcast();
  
  Stream<LogEntry> get logStream => _logController.stream;
  List<LogEntry> get logs => List.unmodifiable(_logs);
  
  void clear() {
    _logs.clear();
    _logController.add(LogEntry('', LogType.info, DateTime.now()));
  }
  
  void addLog(String message, LogType type) {
    final entry = LogEntry(message, type, DateTime.now());
    _logs.add(entry);
    _logController.add(entry);
    
    // Also print to console for immediate visibility
    final prefix = type == LogType.error ? '❌ [ERROR]' 
        : type == LogType.warning ? '⚠️ [WARNING]'
        : type == LogType.success ? '✅ [SUCCESS]'
        : 'ℹ️ [INFO]';
    print('$prefix $message');
    debugPrint('$prefix $message');
    
    // Keep only last 500 logs to prevent memory issues
    if (_logs.length > 500) {
      _logs.removeRange(0, _logs.length - 500);
    }
  }
  
  void info(String message) => addLog(message, LogType.info);
  void warning(String message) => addLog(message, LogType.warning);
  void error(String message) => addLog(message, LogType.error);
  void success(String message) => addLog(message, LogType.success);
  
  void dispose() {
    _logController.close();
  }
}

class LogEntry {
  final String message;
  final LogType type;
  final DateTime timestamp;
  
  LogEntry(this.message, this.type, this.timestamp);
  
  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    final millisecond = timestamp.millisecond.toString().padLeft(3, '0');
    return '$hour:$minute:$second.$millisecond';
  }
  
  String get formattedDateTime {
    final year = timestamp.year;
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }
  
  String get formattedDate {
    final year = timestamp.year;
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

enum LogType {
  info,
  warning,
  error,
  success,
}

