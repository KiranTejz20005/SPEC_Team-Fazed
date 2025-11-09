import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/debug_log_service.dart';

class DebugConsoleWidget extends StatefulWidget {
  const DebugConsoleWidget({super.key});

  @override
  State<DebugConsoleWidget> createState() => _DebugConsoleWidgetState();
}

class LogHistoryDialog extends StatelessWidget {
  final DebugLogService logService;
  
  const LogHistoryDialog({super.key, required this.logService});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final logs = logService.logs;
    
    // Group logs by date
    final Map<String, List<LogEntry>> logsByDate = {};
    for (final log in logs) {
      final dateKey = log.formattedDate;
      if (!logsByDate.containsKey(dateKey)) {
        logsByDate[dateKey] = [];
      }
      logsByDate[dateKey]!.add(log);
    }
    
    final sortedDates = logsByDate.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return Dialog(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                ),
                const SizedBox(width: 8),
                Text(
                  'Log History',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Logs grouped by date
            Expanded(
              child: logs.isEmpty
                  ? Center(
                      child: Text(
                        'No logs yet...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: sortedDates.length,
                      itemBuilder: (context, dateIndex) {
                        final date = sortedDates[dateIndex];
                        final dateLogs = logsByDate[date]!;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date header
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                date,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                ),
                              ),
                            ),
                            // Logs for this date
                            ...dateLogs.map((log) {
                              final color = _getLogColor(log.type);
                              final icon = _getLogIcon(log.type);
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4, left: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 14,
                                      color: color,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '[${log.formattedDateTime}]',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        log.message,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (dateIndex < sortedDates.length - 1) const Divider(height: 24),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getLogColor(LogType type) {
    switch (type) {
      case LogType.error:
        return Colors.red.shade400;
      case LogType.warning:
        return Colors.orange.shade400;
      case LogType.success:
        return Colors.green.shade400;
      case LogType.info:
      default:
        return Colors.grey.shade300;
    }
  }
  
  IconData _getLogIcon(LogType type) {
    switch (type) {
      case LogType.error:
        return Icons.error_outline;
      case LogType.warning:
        return Icons.warning_amber_rounded;
      case LogType.success:
        return Icons.check_circle_outline;
      case LogType.info:
      default:
        return Icons.info_outline;
    }
  }
}

class _DebugConsoleWidgetState extends State<DebugConsoleWidget> {
  final DebugLogService _logService = DebugLogService();
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _logService.logStream.listen((_) {
      if (mounted && _autoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _getLogColor(LogType type) {
    switch (type) {
      case LogType.error:
        return Colors.red.shade400;
      case LogType.warning:
        return Colors.orange.shade400;
      case LogType.success:
        return Colors.green.shade400;
      case LogType.info:
      default:
        return Colors.grey.shade300;
    }
  }

  IconData _getLogIcon(LogType type) {
    switch (type) {
      case LogType.error:
        return Icons.error_outline;
      case LogType.warning:
        return Icons.warning_amber_rounded;
      case LogType.success:
        return Icons.check_circle_outline;
      case LogType.info:
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bug_report,
                  size: 18,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Debug Console',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center,
                        size: 18,
                      ),
                      tooltip: _autoScroll ? 'Disable auto-scroll' : 'Enable auto-scroll',
                      onPressed: () {
                        setState(() {
                          _autoScroll = !_autoScroll;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy all logs',
                      onPressed: () {
                        final allLogs = _logService.logs
                            .map((log) => '[${log.formattedDateTime}] [${log.type.name.toUpperCase()}] ${log.message}')
                            .join('\n');
                        Clipboard.setData(ClipboardData(text: allLogs));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logs copied to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.history, size: 18),
                      tooltip: 'View log history',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => LogHistoryDialog(logService: _logService),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Logs
          Expanded(
            child: ClipRect(
              child: StreamBuilder<LogEntry>(
                stream: _logService.logStream,
                initialData: null,
                builder: (context, snapshot) {
                  final logs = _logService.logs;
                  if (logs.isEmpty) {
                    return Center(
                      child: Text(
                        'No logs yet...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final color = _getLogColor(log.type);
                      final icon = _getLogIcon(log.type);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              icon,
                              size: 14,
                              color: color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '[${log.formattedTime}]',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                fontFamily: 'monospace',
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                log.message,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.clip,
                                softWrap: true,
                                maxLines: null,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

