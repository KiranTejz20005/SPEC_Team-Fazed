import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottom_navigation.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _formRemindersEnabled = true;
  bool _submissionConfirmationsEnabled = true;
  bool _weeklySummaryEnabled = false;
  bool _promotionalNotificationsEnabled = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _pushNotificationsEnabled = prefs.getBool('push_notifications_enabled') ?? true;
        _emailNotificationsEnabled = prefs.getBool('email_notifications_enabled') ?? true;
        _formRemindersEnabled = prefs.getBool('form_reminders_enabled') ?? true;
        _submissionConfirmationsEnabled = prefs.getBool('submission_confirmations_enabled') ?? true;
        _weeklySummaryEnabled = prefs.getBool('weekly_summary_enabled') ?? false;
        _promotionalNotificationsEnabled = prefs.getBool('promotional_notifications_enabled') ?? false;
        _soundEnabled = prefs.getBool('notification_sound_enabled') ?? true;
        _vibrationEnabled = prefs.getBool('notification_vibration_enabled') ?? true;
      });
    } catch (e) {
      print('Error loading notification settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Widget _buildSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: theme.colorScheme.primary,
      activeTrackColor: theme.colorScheme.primary.withOpacity(0.5),
      inactiveThumbColor: theme.colorScheme.onSurface.withOpacity(0.5),
      inactiveTrackColor: theme.colorScheme.surface,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: 100.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/settings');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Notifications',
                          style: theme.textTheme.displaySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    // General Notifications Section
                    _NotificationSection(
                      title: 'General',
                      items: [
                        _NotificationItem(
                          icon: Icons.notifications_active_outlined,
                          title: 'Push Notifications',
                          subtitle: 'Receive notifications on your device',
                          trailing: _buildSwitch(
                            value: _pushNotificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _pushNotificationsEnabled = value;
                              });
                              _saveNotificationSetting('push_notifications_enabled', value);
                            },
                          ),
                        ),
                        _NotificationItem(
                          icon: Icons.email_outlined,
                          title: 'Email Notifications',
                          subtitle: 'Receive notifications via email',
                          trailing: _buildSwitch(
                            value: _emailNotificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _emailNotificationsEnabled = value;
                              });
                              _saveNotificationSetting('email_notifications_enabled', value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Form Notifications Section
                    _NotificationSection(
                      title: 'Form Notifications',
                      items: [
                        _NotificationItem(
                          icon: Icons.alarm_outlined,
                          title: 'Form Reminders',
                          subtitle: 'Get reminded about incomplete forms',
                          trailing: _buildSwitch(
                            value: _formRemindersEnabled,
                            onChanged: (value) {
                              setState(() {
                                _formRemindersEnabled = value;
                              });
                              _saveNotificationSetting('form_reminders_enabled', value);
                            },
                          ),
                          enabled: _pushNotificationsEnabled || _emailNotificationsEnabled,
                        ),
                        _NotificationItem(
                          icon: Icons.check_circle_outline,
                          title: 'Submission Confirmations',
                          subtitle: 'Get notified when forms are submitted',
                          trailing: _buildSwitch(
                            value: _submissionConfirmationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _submissionConfirmationsEnabled = value;
                              });
                              _saveNotificationSetting('submission_confirmations_enabled', value);
                            },
                          ),
                          enabled: _pushNotificationsEnabled || _emailNotificationsEnabled,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Summary & Reports Section
                    _NotificationSection(
                      title: 'Summary & Reports',
                      items: [
                        _NotificationItem(
                          icon: Icons.summarize_outlined,
                          title: 'Weekly Summary',
                          subtitle: 'Receive a weekly summary of your activity',
                          trailing: _buildSwitch(
                            value: _weeklySummaryEnabled,
                            onChanged: (value) {
                              setState(() {
                                _weeklySummaryEnabled = value;
                              });
                              _saveNotificationSetting('weekly_summary_enabled', value);
                            },
                          ),
                          enabled: _emailNotificationsEnabled,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Promotional Section
                    _NotificationSection(
                      title: 'Promotional',
                      items: [
                        _NotificationItem(
                          icon: Icons.local_offer_outlined,
                          title: 'Promotional Notifications',
                          subtitle: 'Receive updates about new features and offers',
                          trailing: _buildSwitch(
                            value: _promotionalNotificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _promotionalNotificationsEnabled = value;
                              });
                              _saveNotificationSetting('promotional_notifications_enabled', value);
                            },
                          ),
                          enabled: _pushNotificationsEnabled || _emailNotificationsEnabled,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Notification Preferences Section
                    _NotificationSection(
                      title: 'Notification Preferences',
                      items: [
                        _NotificationItem(
                          icon: Icons.volume_up_outlined,
                          title: 'Sound',
                          subtitle: 'Play sound for notifications',
                          trailing: _buildSwitch(
                            value: _soundEnabled,
                            onChanged: (value) {
                              setState(() {
                                _soundEnabled = value;
                              });
                              _saveNotificationSetting('notification_sound_enabled', value);
                            },
                          ),
                          enabled: _pushNotificationsEnabled,
                        ),
                        _NotificationItem(
                          icon: Icons.vibration,
                          title: 'Vibration',
                          subtitle: 'Vibrate for notifications',
                          trailing: _buildSwitch(
                            value: _vibrationEnabled,
                            onChanged: (value) {
                              setState(() {
                                _vibrationEnabled = value;
                              });
                              _saveNotificationSetting('notification_vibration_enabled', value);
                            },
                          ),
                          enabled: _pushNotificationsEnabled,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Notification History
                    _NotificationSection(
                      title: 'History',
                      items: [
                        _NotificationItem(
                          icon: Icons.history_outlined,
                          title: 'View Notification History',
                          subtitle: 'See all your past notifications',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Notification History'),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: [
                                      _NotificationHistoryItem(
                                        title: 'Form Submitted',
                                        message: 'Your Passport Renewal form was submitted successfully',
                                        time: '2 hours ago',
                                      ),
                                      _NotificationHistoryItem(
                                        title: 'Form Reminder',
                                        message: 'You have 2 incomplete forms',
                                        time: '1 day ago',
                                      ),
                                      _NotificationHistoryItem(
                                        title: 'Weekly Summary',
                                        message: 'You completed 5 forms this week',
                                        time: '3 days ago',
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
            // Bottom Navigation
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavigation(currentRoute: '/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _NotificationSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool enabled;

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        color: enabled
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withOpacity(0.38),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled
              ? null
              : theme.colorScheme.onSurface.withOpacity(0.38),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled
              ? theme.colorScheme.onSurface.withOpacity(0.6)
              : theme.colorScheme.onSurface.withOpacity(0.38),
        ),
      ),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: enabled ? onTap : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

class _NotificationHistoryItem extends StatelessWidget {
  final String title;
  final String message;
  final String time;

  const _NotificationHistoryItem({
    required this.title,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                time,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

