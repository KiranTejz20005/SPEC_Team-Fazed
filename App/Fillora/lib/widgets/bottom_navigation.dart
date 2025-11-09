import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/app_logger_service.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavigation extends StatelessWidget {
  final String currentRoute;

  const BottomNavigation({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: bottomPadding > 0 ? bottomPadding + 8 : 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentRoute == '/dashboard',
                onTap: () {
                  AppLoggerService().logUserInteraction('Bottom navigation', details: 'Home');
                  context.go('/dashboard');
                },
              ),
              _NavItem(
                icon: Icons.description_rounded,
                label: 'Templates',
                isActive: currentRoute == '/templates',
                onTap: () {
                  AppLoggerService().logUserInteraction('Bottom navigation', details: 'Templates');
                  context.go('/templates');
                },
              ),
              _NavItem(
                icon: Icons.upload_rounded,
                label: 'Upload',
                isActive: currentRoute == '/form-selection' || currentRoute == '/document-upload',
                onTap: () {
                  AppLoggerService().logUserInteraction('Bottom navigation', details: 'Upload');
                  context.push('/form-selection');
                },
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                isActive: currentRoute == '/settings',
                onTap: () {
                  AppLoggerService().logUserInteraction('Bottom navigation', details: 'Settings');
                  context.go('/settings');
                },
              ),
            ],
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryOrange.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(
                  color: AppColors.primaryOrange,
                  width: 1.5,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? AppColors.primaryOrange
                  : Colors.white70,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? AppColors.primaryOrange
                    : Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
