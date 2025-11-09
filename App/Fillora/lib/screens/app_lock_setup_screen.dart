import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/app_lock_service.dart';

class AppLockSetupScreen extends StatefulWidget {
  final String lockType; // 'pin' or 'password'
  final bool isChanging; // true if changing existing lock

  const AppLockSetupScreen({
    super.key,
    required this.lockType,
    this.isChanging = false,
  });

  @override
  State<AppLockSetupScreen> createState() => _AppLockSetupScreenState();
}

class _AppLockSetupScreenState extends State<AppLockSetupScreen> {
  final AppLockService _appLockService = AppLockService();
  final List<TextEditingController> _pinControllers = [];
  final List<FocusNode> _pinFocusNodes = [];
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _oldPasswordFocusNode = FocusNode();

  String _step = 'new'; // 'old', 'new', 'confirm'
  bool _isSettingUp = false;
  String _errorMessage = '';
  String _newPin = '';
  String _newPassword = '';

  @override
  void initState() {
    super.initState();
    if (widget.lockType == 'pin') {
      for (int i = 0; i < 4; i++) {
        _pinControllers.add(TextEditingController());
        _pinFocusNodes.add(FocusNode());
      }
    }

    if (widget.isChanging) {
      _step = 'old';
    } else {
      _step = 'new';
    }

    // Focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.lockType == 'pin' && _pinFocusNodes.isNotEmpty) {
        _pinFocusNodes[0].requestFocus();
      } else if (widget.lockType == 'password') {
        if (_step == 'old') {
          _oldPasswordFocusNode.requestFocus();
        } else {
          _passwordFocusNode.requestFocus();
        }
      }
    });
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
    _confirmPasswordController.dispose();
    _oldPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _oldPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOldLock() async {
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
      input = _oldPasswordController.text;
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your current password';
        });
        return;
      }
    }

    setState(() {
      _isSettingUp = true;
      _errorMessage = '';
    });

    final isValid = await _appLockService.verifyLock(input);

    if (isValid) {
      setState(() {
        _step = 'new';
        _isSettingUp = false;
        _errorMessage = '';
      });

      // Clear old input
      if (widget.lockType == 'pin') {
        for (var controller in _pinControllers) {
          controller.clear();
        }
        _pinFocusNodes[0].requestFocus();
      } else {
        _oldPasswordController.clear();
        _passwordFocusNode.requestFocus();
      }
    } else {
      setState(() {
        _isSettingUp = false;
        _errorMessage = 'Incorrect ${widget.lockType == 'pin' ? 'PIN' : 'password'}. Please try again.';
      });

      // Clear input
      if (widget.lockType == 'pin') {
        for (var controller in _pinControllers) {
          controller.clear();
        }
        _pinFocusNodes[0].requestFocus();
      } else {
        _oldPasswordController.clear();
        _oldPasswordFocusNode.requestFocus();
      }

      HapticFeedback.vibrate();
    }
  }

  void _onNewPinChanged(int index, String value) {
    if (value.isNotEmpty && index < _pinControllers.length - 1) {
      _pinFocusNodes[index + 1].requestFocus();
    }

    if (index == _pinControllers.length - 1 && value.isNotEmpty) {
      final allFilled = _pinControllers.every((c) => c.text.isNotEmpty);
      if (allFilled) {
        final pin = _pinControllers.map((c) => c.text).join();
        if (pin.length == 4) {
          setState(() {
            _newPin = pin;
            _step = 'confirm';
            _errorMessage = '';
          });
          // Clear and focus first field for confirmation
          for (var controller in _pinControllers) {
            controller.clear();
          }
          // Use a small delay to ensure the UI has updated before focusing
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _pinFocusNodes.isNotEmpty) {
              _pinFocusNodes[0].requestFocus();
            }
          });
        }
      }
    }
  }

  Future<void> _confirmPin() async {
    final confirmPin = _pinControllers.map((c) => c.text).join();
    if (confirmPin.length != 4) {
      setState(() {
        _errorMessage = 'Please enter 4-digit PIN';
      });
      return;
    }

    if (confirmPin != _newPin) {
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
      });
      for (var controller in _pinControllers) {
        controller.clear();
      }
      _pinFocusNodes[0].requestFocus();
      HapticFeedback.vibrate();
      return;
    }

    await _savePin();
  }

  Future<void> _savePin() async {
    setState(() {
      _isSettingUp = true;
      _errorMessage = '';
    });

    bool success;
    if (widget.isChanging) {
      // Need to verify old PIN first
      final oldPin = await _getOldPinForChange();
      if (oldPin == null) {
        setState(() {
          _isSettingUp = false;
          _errorMessage = 'Please verify your old PIN first';
        });
        return;
      }
      success = await _appLockService.changePin(oldPin, _newPin);
    } else {
      success = await _appLockService.setupPin(_newPin);
    }

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN set successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } else {
      setState(() {
        _isSettingUp = false;
        _errorMessage = 'Failed to set PIN. Please try again.';
      });
    }
  }

  Future<String?> _getOldPinForChange() async {
    // This would need to be stored temporarily or verified again
    // For simplicity, we'll require re-verification
    return null;
  }

  Future<void> _savePassword() async {
    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      _confirmPasswordController.clear();
      _confirmPasswordFocusNode.requestFocus();
      HapticFeedback.vibrate();
      return;
    }

    setState(() {
      _isSettingUp = true;
      _errorMessage = '';
    });

    bool success;
    if (widget.isChanging) {
      success = await _appLockService.changePassword(
        _oldPasswordController.text,
        _passwordController.text,
      );
    } else {
      success = await _appLockService.setupPassword(_passwordController.text);
    }

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password set successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } else {
      setState(() {
        _isSettingUp = false;
        _errorMessage = widget.isChanging
            ? 'Failed to change password. Please check your current password.'
            : 'Failed to set password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isChanging ? 'Change ${widget.lockType == 'pin' ? 'PIN' : 'Password'}' : 'Set ${widget.lockType == 'pin' ? 'PIN' : 'Password'}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_step == 'old') ...[
                Text(
                  'Enter Current ${widget.lockType == 'pin' ? 'PIN' : 'Password'}',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please verify your current ${widget.lockType == 'pin' ? 'PIN' : 'password'} to continue',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),
                if (widget.lockType == 'pin')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextField(
                          controller: _pinControllers[index],
                          focusNode: _pinFocusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          obscureText: true,
                          style: theme.textTheme.headlineSmall,
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 3) {
                              _pinFocusNodes[index + 1].requestFocus();
                            }
                            if (index == 3 && value.isNotEmpty) {
                              final allFilled = _pinControllers.every((c) => c.text.isNotEmpty);
                              if (allFilled) {
                                _verifyOldLock();
                              }
                            }
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      );
                    }),
                  )
                else
                  TextField(
                    controller: _oldPasswordController,
                    focusNode: _oldPasswordFocusNode,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _verifyOldLock(),
                  ),
                const SizedBox(height: 16),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSettingUp ? null : _verifyOldLock,
                    child: _isSettingUp
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
                  ),
                ),
              ] else if (_step == 'new') ...[
                Text(
                  widget.isChanging
                      ? 'Enter New ${widget.lockType == 'pin' ? 'PIN' : 'Password'}'
                      : 'Create ${widget.lockType == 'pin' ? 'PIN' : 'Password'}',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.lockType == 'pin'
                      ? 'Enter a 4-digit PIN to secure your app'
                      : 'Enter a password (at least 6 characters) to secure your app',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),
                if (widget.lockType == 'pin')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextField(
                          controller: _pinControllers[index],
                          focusNode: _pinFocusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          obscureText: true,
                          style: theme.textTheme.headlineSmall,
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) => _onNewPinChanged(index, value),
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
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                      helperText: 'At least 6 characters',
                    ),
                    onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
                  ),
                if (widget.lockType == 'password') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _savePassword(),
                  ),
                ],
                const SizedBox(height: 16),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                if (widget.lockType == 'password') ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSettingUp ? null : _savePassword,
                      child: _isSettingUp
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Set Password'),
                    ),
                  ),
                ],
              ] else if (_step == 'confirm') ...[
                Text(
                  'Confirm PIN',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Re-enter your PIN to confirm',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: _pinControllers[index],
                        focusNode: _pinFocusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        obscureText: true,
                        style: theme.textTheme.headlineSmall,
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 3) {
                            _pinFocusNodes[index + 1].requestFocus();
                          }
                          if (index == 3 && value.isNotEmpty) {
                            final allFilled = _pinControllers.every((c) => c.text.isNotEmpty);
                            if (allFilled) {
                              _confirmPin();
                            }
                          }
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

