import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/debug_console_service.dart';
import '../services/debug_log_service.dart';

class FloatingDebugButton extends StatefulWidget {
  final GlobalKey<NavigatorState>? navigatorKey;
  
  const FloatingDebugButton({super.key, this.navigatorKey});

  @override
  State<FloatingDebugButton> createState() => _FloatingDebugButtonState();
}

class _FloatingDebugButtonState extends State<FloatingDebugButton> {
  final DebugConsoleService _consoleService = DebugConsoleService();
  final DebugLogService _logService = DebugLogService();
  int _logCount = 0;
  bool _isConsoleVisible = false;
  
  // Position state
  Offset _position = const Offset(0, 0);
  bool _isDragging = false;
  bool _hasInitialPosition = false;
  bool _wasDragged = false;
  Offset _panStartPosition = const Offset(0, 0);
  DateTime? _panStartTime;

  // Screens where we should hide the debug button
  final List<String> _hiddenRoutes = [
    '/onboarding',
    '/signin',
    '/signup',
    '/app-lock',
    '/app-lock-setup',
  ];

  @override
  void initState() {
    super.initState();
    _loadPosition();
    // Listen to log stream to update badge count
    _logService.logStream.listen((_) {
      if (mounted) {
        setState(() {
          _logCount = _logService.logs.length;
        });
      }
    });
    // Listen to console visibility changes
    _consoleService.visibilityStream.listen((isVisible) {
      if (mounted) {
        setState(() {
          _isConsoleVisible = isVisible;
        });
      }
    });
    // Get initial log count
    _logCount = _logService.logs.length;
    _isConsoleVisible = _consoleService.isConsoleVisible;
  }

  Future<void> _loadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedX = prefs.getDouble('debug_button_x');
      final savedY = prefs.getDouble('debug_button_y');
      
      if (savedX != null && savedY != null) {
        setState(() {
          _position = Offset(savedX, savedY);
          _hasInitialPosition = true;
        });
      } else {
        // Default position (bottom right)
        setState(() {
          _hasInitialPosition = true;
        });
      }
    } catch (e) {
      setState(() {
        _hasInitialPosition = true;
      });
    }
  }

  Future<void> _savePosition(double x, double y) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('debug_button_x', x);
      await prefs.setDouble('debug_button_y', y);
    } catch (e) {
      // Ignore save errors
    }
  }

  bool _shouldShowButton(BuildContext context) {
    try {
      final location = GoRouterState.of(context).uri.path;
      // Check if current path matches any hidden route
      for (final hiddenRoute in _hiddenRoutes) {
        if (location == hiddenRoute || location.startsWith(hiddenRoute)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      // If we can't get the route, show the button by default
      return true;
    }
  }

  void _showDebugConsole(BuildContext context) {
    // Get Navigator context from the navigator key
    BuildContext? modalContext;
    
    if (widget.navigatorKey?.currentContext != null) {
      modalContext = widget.navigatorKey!.currentContext;
    } else {
      // Fallback: try to find Navigator in build context
      modalContext = Navigator.maybeOf(context)?.context ?? context;
    }
    
    if (modalContext != null) {
      _consoleService.showDebugConsole(modalContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show button on hidden routes or when console is visible
    if (!_shouldShowButton(context) || !_hasInitialPosition || _isConsoleVisible) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final buttonSize = 56.0;
    
    // Calculate default position if not set
    if (_position == const Offset(0, 0) && !_isDragging) {
      _position = Offset(
        screenSize.width - buttonSize - 16,
        screenSize.height - buttonSize - 100, // Above bottom navigation
      );
    }
    
    // Ensure button stays within screen bounds
    final clampedX = _position.dx.clamp(0.0, screenSize.width - buttonSize);
    final clampedY = _position.dy.clamp(0.0, screenSize.height - buttonSize);

    return Positioned(
      left: clampedX,
      top: clampedY,
      child: GestureDetector(
        onPanStart: (details) {
          _panStartPosition = details.globalPosition;
          _panStartTime = DateTime.now();
          setState(() {
            _isDragging = true;
            _wasDragged = false;
          });
        },
        onPanUpdate: (details) {
          // Calculate total distance moved from start
          final distanceMoved = (details.globalPosition - _panStartPosition).distance;
          
          // If moved more than 15 pixels, consider it a drag (higher threshold for better tap detection)
          if (distanceMoved > 15) {
            if (!_wasDragged) {
              setState(() {
                _wasDragged = true;
              });
            }
            // Update position during drag
            setState(() {
              // Use actual position + delta to update
              final currentPos = _position.dx == 0 && _position.dy == 0 
                  ? Offset(clampedX, clampedY) 
                  : _position;
              final newX = (currentPos.dx + details.delta.dx).clamp(0.0, screenSize.width - buttonSize);
              final newY = (currentPos.dy + details.delta.dy).clamp(0.0, screenSize.height - buttonSize);
              _position = Offset(newX, newY);
            });
          }
        },
        onPanEnd: (details) {
          final wasDragged = _wasDragged;
          final finalDistance = _panStartPosition != const Offset(0, 0)
              ? (details.globalPosition - _panStartPosition).distance
              : 0.0;
          
          setState(() {
            _isDragging = false;
          });
          
          // Handle tap or drag - if moved less than 20 pixels, it's a tap
          if (wasDragged || finalDistance > 20) {
            // Snap to nearest edge
            final currentPos = _position.dx == 0 && _position.dy == 0 
                ? Offset(clampedX, clampedY) 
                : _position;
            final centerX = screenSize.width / 2;
            final snappedX = currentPos.dx < centerX ? 0.0 : screenSize.width - buttonSize;
            
            setState(() {
              _position = Offset(snappedX, currentPos.dy.clamp(0.0, screenSize.height - buttonSize));
            });
            
            // Save snapped position
            _savePosition(_position.dx, _position.dy);
            _logService.info('Debug button snapped to ${snappedX == 0 ? "left" : "right"} edge');
          } else {
            // No significant drag detected - treat as tap and open console
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                _showDebugConsole(context);
              }
            });
          }
          
          _panStartTime = null;
          _wasDragged = false;
        },
        onPanCancel: () {
          setState(() {
            _isDragging = false;
          });
          
          // If cancelled and wasn't dragged, might be a tap
          if (!_wasDragged) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showDebugConsole(context);
              }
            });
          }
          
          _wasDragged = false;
          _panStartTime = null;
        },
        behavior: HitTestBehavior.opaque,
        child: Material(
          elevation: _isDragging ? 16 : 8,
          shadowColor: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(28),
          color: Colors.orange.shade700,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.bug_report,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                // Badge to show log count
                if (_logCount > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        _logCount > 99 ? '99+' : '$_logCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
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

