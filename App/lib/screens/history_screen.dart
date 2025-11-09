import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/bottom_navigation.dart';
import '../services/database_service.dart';
import '../services/search_service.dart';
import '../models/form_model.dart';
import '../services/app_logger_service.dart';

class HistoryScreen extends StatefulWidget {
  final String? initialStatus;
  
  const HistoryScreen({super.key, this.initialStatus});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _activeTab = 'All';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _db = DatabaseService();
  List<FormModel> _allForms = [];
  List<FormModel> _filteredForms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AppLoggerService().logScreenEvent('HistoryScreen', 'Initialized', 
      details: {'initialStatus': widget.initialStatus ?? 'All'});
    // Set initial tab based on query parameter
    if (widget.initialStatus != null) {
      if (widget.initialStatus == 'completed') {
        _activeTab = 'Completed';
      } else if (widget.initialStatus == 'in_progress') {
        _activeTab = 'In Progress';
      }
    }
    _loadForms();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload forms when screen becomes visible
    _loadForms();
  }

  @override
  void dispose() {
    AppLoggerService().logScreenEvent('HistoryScreen', 'Disposed');
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadForms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final forms = await _db.getAllForms();
      if (mounted) {
        // Sort forms by latest submission/update time
        forms.sort((a, b) {
          // For completed forms (status completed/submitted OR 100% progress), use submittedAt; for others, use updatedAt or createdAt
          DateTime? aDate;
          DateTime? bDate;
          
          final aIsCompleted = a.status == 'completed' || a.status == 'submitted' || a.progress >= 100.0;
          final bIsCompleted = b.status == 'completed' || b.status == 'submitted' || b.progress >= 100.0;
          
          if (aIsCompleted) {
            aDate = a.submittedAt ?? a.updatedAt ?? a.createdAt;
          } else {
            aDate = a.updatedAt ?? a.createdAt;
          }
          
          if (bIsCompleted) {
            bDate = b.submittedAt ?? b.updatedAt ?? b.createdAt;
          } else {
            bDate = b.updatedAt ?? b.createdAt;
          }
          
          // Sort in descending order (most recent first)
          return bDate.compareTo(aDate);
        });
        
        setState(() {
          _allForms = forms;
          _isLoading = false;
        });
        // Filter forms after loading
        _filterForms();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading forms: $e')),
          );
        }
      }
    }
  }

  void _onSearchChanged() {
    _filterForms();
  }

  int _getFormCount(String tab) {
    if (tab == 'All') {
      return _allForms.length;
    } else if (tab == 'In Progress') {
      return _allForms.where((form) {
        return (form.status == 'in_progress' || form.status == 'draft') && form.progress < 100.0;
      }).length;
    } else if (tab == 'Completed') {
      return _allForms.where((form) {
        return form.status == 'completed' || 
               form.status == 'submitted' || 
               form.progress >= 100.0;
      }).length;
    }
    return 0;
  }

  void _filterForms() {
    if (!mounted) return;
    
    List<FormModel> filtered = _allForms;

    // Filter by tab/status
    if (_activeTab == 'In Progress') {
      // Show only forms that are in progress and not completed (progress < 100%)
      filtered = filtered.where((form) {
        return (form.status == 'in_progress' || form.status == 'draft') && form.progress < 100.0;
      }).toList();
    } else if (_activeTab == 'Completed') {
      // Include forms with 'completed' or 'submitted' status, or 100% progress
      filtered = filtered.where((form) {
        return form.status == 'completed' || 
               form.status == 'submitted' || 
               form.progress >= 100.0;
      }).toList();
    }

    // Search filter
    if (_searchController.text.isNotEmpty) {
      filtered = SearchService.searchForms(filtered, _searchController.text);
    }

    setState(() {
      _filteredForms = filtered;
    });
  }

  String _formatTime(DateTime date) {
    int hour = date.hour;
    int minute = date.minute;
    int second = date.second;
    String period = hour >= 12 ? 'PM' : 'AM';
    
    // Convert to 12-hour format
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour = hour - 12;
    }
    
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')} $period';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    // Normalize dates to midnight for accurate day comparison
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly);

    String dateText;
    if (difference.inDays == 0) {
      dateText = 'Today';
    } else if (difference.inDays == 1) {
      dateText = 'Yesterday';
    } else if (difference.inDays < 7) {
      dateText = '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      dateText = '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }
    
    // Add time with dot separator
    return '$dateText • ${_formatTime(date)}';
  }

  Future<void> _showDeleteConfirmation(BuildContext context, FormModel form) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Form'),
        content: Text('Are you sure you want to delete "${form.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Save current scroll position before deletion
      final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
      final deletedIndex = _filteredForms.indexWhere((f) => f.id == form.id);
      
      try {
        // Optimistically remove from local lists immediately
        setState(() {
          _allForms.removeWhere((f) => f.id == form.id);
          _filteredForms.removeWhere((f) => f.id == form.id);
        });
        
        // Delete from database
        AppLoggerService().logFormAction('Deleting form', 
          formId: form.id,
          formTitle: form.title);
        await _db.deleteForm(form.id);
        AppLoggerService().logFormAction('Form deleted successfully', 
          formId: form.id,
          formTitle: form.title);
        
        // Maintain scroll position after the list rebuilds
        if (mounted && _scrollController.hasClients) {
          // Wait for the layout to update, then restore scroll position
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Wait one more frame to ensure layout is stable
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _scrollController.hasClients) {
                final maxScroll = _scrollController.position.maxScrollExtent;
                
                // Approximate height of one list item (card + padding)
                const itemHeight = 112.0;
                
                // Calculate target scroll offset
                // If deleted item was above current scroll, adjust down by item height
                // Otherwise maintain the same scroll position
                double targetOffset = scrollOffset;
                
                if (deletedIndex >= 0) {
                  // Estimate if deleted item was above the current viewport
                  final estimatedDeletedItemTop = deletedIndex * itemHeight;
                  
                  // If we were scrolled past the deleted item, we need to adjust
                  if (scrollOffset >= estimatedDeletedItemTop) {
                    // Item was at or above current viewport - adjust scroll
                    targetOffset = (scrollOffset - itemHeight).clamp(0.0, maxScroll);
                  } else {
                    // Item was below viewport - maintain scroll position
                    targetOffset = scrollOffset.clamp(0.0, maxScroll);
                  }
                }
                
                // Only adjust if there's a meaningful difference
                if ((_scrollController.offset - targetOffset).abs() > 0.5) {
                  _scrollController.jumpTo(targetOffset);
                }
              }
            });
          });
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Form deleted successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // If deletion fails, reload from database
        await _loadForms();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting form: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/dashboard');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Form History',
                          style: theme.textTheme.displaySmall,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Search Forms'),
                              content: TextField(
                                controller: _searchController,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: 'Search forms...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Clear'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'All',
                          count: _getFormCount('All'),
                          isActive: _activeTab == 'All',
                          onTap: () {
                            AppLoggerService().logUserInteraction('Tab selected', details: 'All');
                            setState(() {
                              _activeTab = 'All';
                            });
                            _filterForms();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TabButton(
                          label: 'In Progress',
                          count: _getFormCount('In Progress'),
                          isActive: _activeTab == 'In Progress',
                          onTap: () {
                            AppLoggerService().logUserInteraction('Tab selected', details: 'In Progress');
                            setState(() {
                              _activeTab = 'In Progress';
                            });
                            _filterForms();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TabButton(
                          label: 'Completed',
                          count: _getFormCount('Completed'),
                          isActive: _activeTab == 'Completed',
                          onTap: () {
                            AppLoggerService().logUserInteraction('Tab selected', details: 'Completed');
                            setState(() {
                              _activeTab = 'Completed';
                            });
                            _filterForms();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // History List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredForms.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history_outlined,
                                      size: 64,
                                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _allForms.isEmpty
                                          ? 'No forms yet'
                                          : 'No ${_activeTab.toLowerCase()} forms found',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _allForms.isEmpty
                                          ? 'Start filling out forms to see them here'
                                          : 'Try selecting a different tab or clear your search',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              children: [
                                ..._filteredForms.map((form) {
                                      // For completed/submitted forms, use submittedAt if available
                                      // Otherwise use updatedAt or createdAt
                                      // Also treat forms with 100% progress as completed
                                      final isCompleted = form.status == 'completed' || 
                                                          form.status == 'submitted' || 
                                                          form.progress >= 100.0;
                                      final dateToShow = isCompleted && form.submittedAt != null
                                          ? form.submittedAt!
                                          : (form.updatedAt ?? form.createdAt);
                                      
                                      return Padding(
                                        key: ValueKey('form_${form.id}'),
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _HistoryItem(
                                          title: form.title,
                                          date: _formatDate(dateToShow),
                                          status: isCompleted
                                              ? 'Completed'
                                              : form.status == 'in_progress'
                                                  ? '${form.progress.toInt()}%'
                                                  : form.status,
                                          isCompleted: isCompleted,
                                          progress: form.progress < 100.0 ? (form.progress / 100.0) : null,
                                          showDelete: _activeTab == 'In Progress',
                                          onTap: () {
                                            if (isCompleted) {
                                              AppLoggerService().logFormAction('Opening form for review', 
                                                formId: form.id,
                                                formTitle: form.title);
                                              context.go('/review?formId=${form.id}&from=history');
                                            } else {
                                              AppLoggerService().logFormAction('Opening form to fill', 
                                                formId: form.id,
                                                formTitle: form.title);
                                              context.go('/conversational-form?formId=${form.id}&from=history');
                                            }
                                          },
                                          onDelete: () => _showDeleteConfirmation(context, form),
                                        ),
                                      );
                                    }),
                                const SizedBox(height: 100),
                              ],
                            ),
                ),
              ],
            ),
            // Bottom Navigation
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavigation(currentRoute: '/history'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($count)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String title;
  final String date;
  final String status;
  final bool isCompleted;
  final double? progress;
  final bool showDelete;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _HistoryItem({
    required this.title,
    required this.date,
    required this.status,
    this.isCompleted = false,
    this.progress,
    this.showDelete = false,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                top: 16,
                bottom: 16,
                right: showDelete && onDelete != null ? 60 : 16,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withOpacity(0.1)
                          : theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_outline
                          : Icons.description_outlined,
                      color: isCompleted
                          ? Colors.green
                          : theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (progress != null && !isCompleted) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress!.clamp(0.0, 1.0),
                              backgroundColor: theme.dividerColor,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withOpacity(0.1)
                          : theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: isCompleted
                            ? Colors.green
                            : theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showDelete && onDelete != null)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
