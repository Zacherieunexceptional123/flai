import 'package:flutter/material.dart';
import '../flai/flai.dart';

class ThemeSwitcher extends StatelessWidget {
  final String currentTheme;
  final ValueChanged<String> onThemeChanged;

  const ThemeSwitcher({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  static const _themes = [
    ('light', 'Light', Icons.light_mode),
    ('dark', 'Dark', Icons.dark_mode),
    ('ios', 'iOS', Icons.apple),
    ('premium', 'Premium', Icons.auto_awesome),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.sm,
        vertical: theme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(theme.radius.lg),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _themes.map((t) {
          final (name, label, icon) = t;
          final isSelected = name == currentTheme;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.spacing.xs / 2),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(theme.radius.md),
                onTap: () => onThemeChanged(name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.sm,
                    vertical: theme.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(theme.radius.md),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isSelected
                            ? theme.colors.primaryForeground
                            : theme.colors.mutedForeground,
                      ),
                      if (isSelected) ...[
                        SizedBox(width: theme.spacing.xs),
                        Text(
                          label,
                          style: theme.typography.bodySmall(
                            color: theme.colors.primaryForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
