import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const ActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = iconColor ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withOpacity(0.2),
                        primaryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
