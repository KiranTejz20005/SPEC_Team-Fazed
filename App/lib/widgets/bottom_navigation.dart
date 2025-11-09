import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/app_logger_service.dart';

class BottomNavigation extends StatelessWidget {
  final String currentRoute;

  const BottomNavigation({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: bottomPadding > 0 ? bottomPadding + 12 : 12, // Add safe area padding
          top: 12,
        ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isActive: currentRoute == '/dashboard',
              onTap: () {
                AppLoggerService().logUserInteraction('Bottom navigation', details: 'Home');
                context.go('/dashboard');
              },
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.description_rounded,
              label: 'Templates',
              isActive: currentRoute == '/templates',
              onTap: () {
                AppLoggerService().logUserInteraction('Bottom navigation', details: 'Templates');
                context.go('/templates');
              },
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.history_rounded,
              label: 'History',
              isActive: currentRoute == '/history',
              onTap: () {
                AppLoggerService().logUserInteraction('Bottom navigation', details: 'History');
                context.go('/history');
              },
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              isActive: currentRoute == '/settings',
              onTap: () {
                AppLoggerService().logUserInteraction('Bottom navigation', details: 'Settings');
                context.go('/settings');
              },
            ),
          ),
          const SizedBox(width: 8),
          _FAB(
            onTap: () {
              AppLoggerService().logUserInteraction('FAB', details: 'New form');
              context.push('/form-selection');
            },
            primaryColor: theme.colorScheme.primary,
            brightness: theme.brightness,
          ),
        ],
      ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: isActive
              ? Border.all(
                  color: primaryColor,
                  width: 2,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? primaryColor : theme.colorScheme.onSurface.withOpacity(0.6),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? primaryColor : theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _FAB extends StatelessWidget {
  final VoidCallback onTap;
  final Color primaryColor;
  final Brightness brightness;

  const _FAB({
    required this.onTap,
    required this.primaryColor,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    // Use grey (20% white, 80% black) for dark theme, primary color for other themes
    final buttonColor = brightness == Brightness.dark
        ? const Color(0xFF333333) // Grey (20% white, 80% black) as requested
        : primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: buttonColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: buttonColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

