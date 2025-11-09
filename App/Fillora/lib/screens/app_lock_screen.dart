import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../services/app_lock_service.dart';
import '../services/biometric_service.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final AppLockService _appLockService = AppLockService();
  final BiometricService _biometricService = BiometricService();
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  String? _lockType;
  bool _isLoading = true;
  bool _isVerifying = false;
  String _errorMessage = '';
  int _failedAttempts = 0;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  String _biometricTypeName = 'Biometric';
  final List<String> _previousValues = ['', '', '', '']; // Track previous values to detect backspace
  final List<FocusNode> _keyboardListenerFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _initializeLock();
  }

  Future<void> _initializeLock() async {
    final lockType = await _appLockService.getAppLockType();
    final isEnabled = await _appLockService.isAppLockEnabled();
    
    if (!isEnabled || lockType == null) {
      // If app lock is not enabled, navigate to dashboard
      if (mounted) {
        context.go('/dashboard');
      }
      return;
    }

    // Check biometric availability
    final biometricEnabled = await _appLockService.isBiometricEnabled();
    final biometricAvailable = await _biometricService.isBiometricsAvailable();
    String biometricTypeName = 'Biometric';
    
    if (biometricAvailable) {
      biometricTypeName = await _biometricService.getPrimaryBiometricTypeName();
    }

    setState(() {
      _lockType = lockType;
      _biometricEnabled = biometricEnabled;
      _biometricAvailable = biometricAvailable;
      _biometricTypeName = biometricTypeName;
      _isLoading = false;
    });

    // Initialize controllers and focus nodes based on lock type
    if (lockType == 'pin') {
      for (int i = 0; i < 4; i++) {
        final controller = _PinTextEditingController(
          onBackspaceOnEmpty: i > 0 ? () {
            if (mounted) {
              _handleBackspaceOnEmptyField(i);
            }
          } : null,
        );
        _controllers.add(controller);
        _focusNodes.add(FocusNode());
      }
    } else {
      // For password, we'll use a single field
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }

    // Try biometric authentication if enabled and available
    if (_biometricEnabled && _biometricAvailable) {
      // Small delay to let the UI render first
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _authenticateWithBiometric();
        }
      });
    } else {
      // Focus first field if biometric is not available
      if (_focusNodes.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNodes[0].requestFocus();
        });
      }
    }
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to unlock ${_biometricTypeName}',
      );

      if (authenticated && mounted) {
        // Success - unlock and navigate
        await _appLockService.unlockApp();
        if (mounted) {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      print('Biometric authentication error: $e');
      // If biometric fails, focus on the input field
      if (mounted && _focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyInput() async {
    if (_isVerifying) return;

    String input;
    if (_lockType == 'pin') {
      input = _controllers.map((c) => c.text).join();
      if (input.length != 4) {
        setState(() {
          _errorMessage = 'Please enter 4-digit PIN';
        });
        return;
      }
    } else {
      input = _controllers[0].text;
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
      // Success - unlock and navigate
      await _appLockService.unlockApp();
      if (mounted) {
        context.go('/dashboard');
      }
    } else {
      // Failed attempt
      setState(() {
        _failedAttempts++;
        _isVerifying = false;
        _errorMessage = 'Incorrect ${_lockType == 'pin' ? 'PIN' : 'password'}. Please try again.';
      });

      // Clear input fields
      for (var controller in _controllers) {
        controller.clear();
      }
      if (_focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }

      // Haptic feedback
      HapticFeedback.vibrate();
    }
  }

  void _onPinChanged(int index, String value) {
    final previousValue = _previousValues[index];
    _previousValues[index] = value;

    if (value.isNotEmpty) {
      // If a digit is entered, move to next field
      if (index < _controllers.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
      
      // Auto-verify when all PIN digits are entered
      if (index == _controllers.length - 1) {
        final allFilled = _controllers.every((c) => c.text.isNotEmpty);
        if (allFilled) {
          _verifyInput();
        }
      }
    } else if (previousValue.isNotEmpty && value.isEmpty) {
      // Field was cleared (backspace pressed on a field with content)
      // Move to previous field if not on first field
      if (index > 0) {
        Future.microtask(() {
          if (mounted) {
            _controllers[index - 1].clear();
            _previousValues[index - 1] = '';
            _focusNodes[index - 1].requestFocus();
          }
        });
      }
    }
  }

  void _handleBackspaceOnEmptyField(int currentIndex) {
    if (currentIndex > 0 && mounted) {
      _controllers[currentIndex - 1].clear();
      _previousValues[currentIndex - 1] = '';
      _focusNodes[currentIndex - 1].requestFocus();
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return PopScope(
      canPop: false, // Prevent back navigation when locked
      child: Scaffold(
        body: SafeArea(
          child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock Icon
              Icon(
                Icons.lock_outline,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                'App Locked',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                _lockType == 'pin'
                    ? 'Enter your 4-digit PIN to unlock'
                    : 'Enter your password to unlock',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Input Fields
              if (_lockType == 'pin')
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
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
                        onTap: () {
                          // Store current value when field is tapped
                          _previousValues[index] = _controllers[index].text;
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
                  controller: _controllers[0],
                  focusNode: _focusNodes[0],
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                  ),
                  onSubmitted: (_) => _verifyInput(),
                ),

              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 32),

              // Biometric Button
              if (_biometricEnabled && _biometricAvailable) ...[
                OutlinedButton.icon(
                  onPressed: _isVerifying ? null : _authenticateWithBiometric,
                  icon: Icon(
                    _biometricTypeName.toLowerCase().contains('face')
                        ? Icons.face_outlined
                        : Icons.fingerprint_outlined,
                  ),
                  label: Text('Use $_biometricTypeName'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Verify Button (for password)
              if (_lockType == 'password')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isVerifying ? null : _verifyInput,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Unlock'),
                  ),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _PinTextEditingController extends TextEditingController {
  VoidCallback? onBackspaceOnEmpty;
  TextSelection _lastSelection = const TextSelection.collapsed(offset: 0);

  _PinTextEditingController({this.onBackspaceOnEmpty}) {
    addListener(_onTextOrSelectionChanged);
  }

  void _onTextOrSelectionChanged() {
    final currentSelection = selection;
    
    // Detect backspace on empty field
    // When backspace is pressed on an empty field, the selection might change
    // even though the text stays empty
    if (text.isEmpty && 
        _lastSelection.baseOffset > 0 && 
        currentSelection.baseOffset == 0 &&
        onBackspaceOnEmpty != null) {
      // Selection moved to start on empty field - likely backspace
      Future.microtask(() => onBackspaceOnEmpty?.call());
    }
    
    _lastSelection = currentSelection;
  }

  @override
  void dispose() {
    removeListener(_onTextOrSelectionChanged);
    super.dispose();
  }
}


