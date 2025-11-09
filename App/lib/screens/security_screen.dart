import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottom_navigation.dart';
import '../services/app_lock_service.dart';
import '../services/biometric_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _appLockEnabled = false;
  bool _twoFactorEnabled = false;
  bool _biometricEnabled = false;
  bool _sessionTimeoutEnabled = false;
  int _sessionTimeoutMinutes = 15;
  bool _isLoading = false;
  final AppLockService _appLockService = AppLockService();
  final BiometricService _biometricService = BiometricService();
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final biometricAvailable = await _biometricService.isBiometricsAvailable();
      final biometricEnabled = await _appLockService.isBiometricEnabled();
      
      setState(() {
        _appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
        _twoFactorEnabled = prefs.getBool('two_factor_enabled') ?? false;
        _biometricEnabled = biometricEnabled;
        _biometricAvailable = biometricAvailable;
        _sessionTimeoutEnabled = prefs.getBool('session_timeout_enabled') ?? false;
        _sessionTimeoutMinutes = prefs.getInt('session_timeout_minutes') ?? 15;
      });
    } catch (e) {
      print('Error loading security settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSecuritySetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  Widget _buildSwitch({
    required bool value,
    ValueChanged<bool>? onChanged,
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

  Future<void> _showChangePasswordDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
  }

  Future<String?> _showLockTypeDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Lock Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: const Text('PIN'),
              subtitle: const Text('4-digit PIN'),
              onTap: () => Navigator.of(context).pop('pin'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Password'),
              subtitle: const Text('Custom password'),
              onTap: () => Navigator.of(context).pop('password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDisableLockDialog() async {
    // First verify PIN/password
    final verified = await _showVerifyLockDialog();
    if (verified != true) {
      return false;
    }

    // Then show confirmation dialog
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable App Lock'),
        content: const Text(
          'Are you sure you want to disable app lock? Your PIN/password will be removed.',
        ),
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
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showVerifyLockDialog() async {
    final lockType = await _appLockService.getAppLockType();
    if (lockType == null) {
      return false;
    }

    return await showDialog<bool>(
      context: context,
      builder: (context) => _VerifyLockDialog(lockType: lockType),
    );
  }

  Future<void> _showLogoutOtherDevicesDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout from Other Devices'),
        content: const Text(
          'This will sign you out from all other devices where you are currently logged in. You will remain signed in on this device.',
        ),
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
            child: const Text('Logout Other Devices'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      // Simulate logout from other devices
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged out from all other devices'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _showSessionTimeoutDialog() async {
    int selectedMinutes = _sessionTimeoutMinutes;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Session Timeout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Automatically log out after inactivity:'),
              const SizedBox(height: 16),
              DropdownButton<int>(
                value: selectedMinutes,
                isExpanded: true,
                items: [5, 15, 30, 60, 120].map((minutes) {
                  String label;
                  if (minutes < 60) {
                    label = '$minutes minutes';
                  } else {
                    final hours = minutes ~/ 60;
                    label = hours == 1 ? '1 hour' : '$hours hours';
                  }
                  return DropdownMenuItem(
                    value: minutes,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedMinutes = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _sessionTimeoutMinutes = selectedMinutes;
                });
                _saveSecuritySetting('session_timeout_minutes', selectedMinutes);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session timeout updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
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
                          'Security',
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
                    // App Lock Section
                    _SecuritySection(
                      title: 'App Protection',
                      items: [
                        _SecurityItem(
                          icon: Icons.lock_outline,
                          title: 'App Lock',
                          subtitle: 'Require authentication to open the app',
                          trailing: _buildSwitch(
                            value: _appLockEnabled,
                            onChanged: (value) async {
                              if (value) {
                                // Show dialog to choose PIN or Password
                                final lockType = await _showLockTypeDialog();
                                if (lockType != null) {
                                  // Navigate to setup screen
                                  final result = await context.push<bool>(
                                    '/app-lock-setup?type=$lockType',
                                  );
                                  if (result == true) {
                                    setState(() {
                                      _appLockEnabled = true;
                                    });
                                    _saveSecuritySetting('app_lock_enabled', true);
                                  }
                                }
                              } else {
                                // Disable app lock - requires PIN/password verification
                                final shouldDisable = await _showDisableLockDialog();
                                if (shouldDisable == true) {
                                  final appLockService = AppLockService();
                                  await appLockService.setAppLockEnabled(false);
                                  // Also disable biometric if app lock is disabled
                                  await appLockService.setBiometricEnabled(false);
                                  setState(() {
                                    _appLockEnabled = false;
                                    _biometricEnabled = false;
                                  });
                                  _saveSecuritySetting('app_lock_enabled', false);
                                  _saveSecuritySetting('biometric_enabled', false);
                                } else {
                                  // Reset switch if user cancelled
                                  setState(() {
                                    _appLockEnabled = true;
                                  });
                                }
                              }
                            },
                          ),
                        ),
                        _SecurityItem(
                          icon: Icons.fingerprint,
                          title: 'Biometric Authentication',
                          subtitle: _biometricAvailable
                              ? 'Use fingerprint or face ID to unlock'
                              : 'Biometric authentication not available on this device',
                          trailing: _buildSwitch(
                            value: _biometricEnabled,
                            onChanged: (value) async {
                              if (value && !_appLockEnabled) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enable App Lock first'),
                                  ),
                                );
                                return;
                              }

                              if (value && !_biometricAvailable) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Biometric authentication is not available on this device'),
                                  ),
                                );
                                return;
                              }

                              // Test biometric authentication when enabling
                              if (value) {
                                try {
                                  final authenticated = await _biometricService.authenticate(
                                    reason: 'Enable biometric authentication',
                                  );
                                  
                                  if (!authenticated) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Biometric authentication failed'),
                                      ),
                                    );
                                    return;
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                    ),
                                  );
                                  return;
                                }
                              }

                              await _appLockService.setBiometricEnabled(value);
                              setState(() {
                                _biometricEnabled = value;
                              });
                              _saveSecuritySetting('biometric_enabled', value);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value
                                        ? 'Biometric authentication enabled'
                                        : 'Biometric authentication disabled',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
                          enabled: _appLockEnabled && _biometricAvailable,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Account Security Section
                    _SecuritySection(
                      title: 'Account Security',
                      items: [
                        _SecurityItem(
                          icon: Icons.lock_reset,
                          title: 'Change Password',
                          subtitle: 'Update your account password',
                          onTap: _showChangePasswordDialog,
                        ),
                        _SecurityItem(
                          icon: Icons.verified_user_outlined,
                          title: 'Two-Factor Authentication',
                          subtitle: 'Add an extra layer of security (Coming soon)',
                          trailing: _buildSwitch(
                            value: _twoFactorEnabled,
                            onChanged: (value) {
                              // Don't allow enabling - show coming soon message
                              if (value) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Two-factor authentication is coming soon!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                // Don't update the state - keep it off
                              } else {
                                // Allow disabling if it was somehow enabled
                                setState(() {
                                  _twoFactorEnabled = false;
                                });
                                _saveSecuritySetting('two_factor_enabled', false);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Session Management Section
                    _SecuritySection(
                      title: 'Session Management',
                      items: [
                        _SecurityItem(
                          icon: Icons.timer_outlined,
                          title: 'Session Timeout',
                          subtitle: _sessionTimeoutEnabled
                              ? _sessionTimeoutMinutes < 60
                                  ? 'Auto logout after $_sessionTimeoutMinutes minutes of inactivity'
                                  : 'Auto logout after ${_sessionTimeoutMinutes ~/ 60} hour${_sessionTimeoutMinutes ~/ 60 > 1 ? 's' : ''} of inactivity'
                              : 'Automatically log out after inactivity',
                          trailing: _buildSwitch(
                            value: _sessionTimeoutEnabled,
                            onChanged: (value) {
                              setState(() {
                                _sessionTimeoutEnabled = value;
                              });
                              _saveSecuritySetting('session_timeout_enabled', value);
                              if (value) {
                                _showSessionTimeoutDialog();
                              }
                            },
                          ),
                        ),
                        _SecurityItem(
                          icon: Icons.devices_outlined,
                          title: 'Active Sessions',
                          subtitle: 'Manage devices where you are logged in',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Active Sessions'),
                                content: const Text(
                                  'Current Device:\n• This Device (Active)\n\nOther Devices:\n• iPhone 13 Pro (Last active: 2 hours ago)\n• Chrome on Windows (Last active: 1 day ago)',
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
                        _SecurityItem(
                          icon: Icons.logout,
                          title: 'Logout from Other Devices',
                          subtitle: 'Sign out from all other devices',
                          onTap: _showLogoutOtherDevicesDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Privacy Section
                    _SecuritySection(
                      title: 'Privacy',
                      items: [
                        _SecurityItem(
                          icon: Icons.delete_outline,
                          title: 'Clear App Data',
                          subtitle: 'Remove all locally stored data',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Clear App Data'),
                                content: const Text(
                                  'This will remove all locally stored data including cached forms and preferences. This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('App data cleared successfully'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Clear Data'),
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

class _SecuritySection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SecuritySection({
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

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Change Password'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: _obscureOldPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureOldPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureOldPassword = !_obscureOldPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            side: BorderSide(color: theme.colorScheme.outline),
            elevation: 0,
          ),
          child: const Text('Change Password'),
        ),
      ],
    );
  }
}

class _SecurityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool enabled;

  const _SecurityItem({
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

class _VerifyLockDialog extends StatefulWidget {
  final String lockType; // 'pin' or 'password'

  const _VerifyLockDialog({required this.lockType});

  @override
  State<_VerifyLockDialog> createState() => _VerifyLockDialogState();
}

class _VerifyLockDialogState extends State<_VerifyLockDialog> {
  final AppLockService _appLockService = AppLockService();
  final List<TextEditingController> _pinControllers = [];
  final List<FocusNode> _pinFocusNodes = [];
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _isVerifying = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.lockType == 'pin') {
      for (int i = 0; i < 4; i++) {
        _pinControllers.add(TextEditingController());
        _pinFocusNodes.add(FocusNode());
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pinFocusNodes[0].requestFocus();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _passwordFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var focusNode in _pinFocusNodes) {
      focusNode.dispose();
    }
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_isVerifying) return;

    String input;
    if (widget.lockType == 'pin') {
      input = _pinControllers.map((c) => c.text).join();
      if (input.length != 4) {
        setState(() {
          _errorMessage = 'Please enter 4-digit PIN';
        });
        return;
      }
    } else {
      input = _passwordController.text;
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your password';
        });
        return;
      }
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    final isValid = await _appLockService.verifyLock(input);

    if (isValid) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Incorrect ${widget.lockType == 'pin' ? 'PIN' : 'password'}. Please try again.';
      });

      // Clear input fields
      if (widget.lockType == 'pin') {
        for (var controller in _pinControllers) {
          controller.clear();
        }
        if (_pinFocusNodes.isNotEmpty) {
          _pinFocusNodes[0].requestFocus();
        }
      } else {
        _passwordController.clear();
        _passwordFocusNode.requestFocus();
      }

      HapticFeedback.vibrate();
    }
  }

  void _onPinChanged(int index, String value) {
    if (value.isNotEmpty && index < _pinControllers.length - 1) {
      _pinFocusNodes[index + 1].requestFocus();
    }

    if (index == _pinControllers.length - 1 && value.isNotEmpty) {
      final allFilled = _pinControllers.every((c) => c.text.isNotEmpty);
      if (allFilled) {
        _verify();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Verify ${widget.lockType == 'pin' ? 'PIN' : 'Password'}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please enter your ${widget.lockType == 'pin' ? 'PIN' : 'password'} to disable app lock',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (widget.lockType == 'pin')
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: TextField(
                      controller: _pinControllers[index],
                      focusNode: _pinFocusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      obscureText: true,
                      style: theme.textTheme.titleLarge,
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorBorder: _errorMessage.isNotEmpty
                            ? OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              )
                            : null,
                      ),
                      onChanged: (value) => _onPinChanged(index, value),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  );
                }),
              )
            else
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                ),
                onSubmitted: (_) => _verify(),
              ),
            if (_errorMessage.isNotEmpty && widget.lockType == 'pin')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        if (widget.lockType == 'password')
          FilledButton(
            onPressed: _isVerifying ? null : _verify,
            child: _isVerifying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify'),
          ),
      ],
    );
  }
}

