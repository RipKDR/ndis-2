import 'package:flutter/material.dart';

/// Reusable FeatureCard used on dashboards.
enum FeatureCardSize { small, medium, large }

class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? subtitle;
  final FeatureCardSize size;

  const FeatureCard._internal({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.size = FeatureCardSize.large,
  });

  factory FeatureCard.large({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return FeatureCard._internal(
      title: title,
      icon: icon,
      onTap: onTap,
      subtitle: subtitle,
      size: FeatureCardSize.large,
    );
  }

  factory FeatureCard.medium({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return FeatureCard._internal(
      title: title,
      icon: icon,
      onTap: onTap,
      subtitle: subtitle,
      size: FeatureCardSize.medium,
    );
  }

  factory FeatureCard.small({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return FeatureCard._internal(
      title: title,
      icon: icon,
      onTap: onTap,
      subtitle: subtitle,
      size: FeatureCardSize.small,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    // Slightly stronger gradient and subtle secondary tint for depth
    final bg = LinearGradient(
      colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 1.0],
    );

    final iconSize = switch (size) {
      FeatureCardSize.large => 40.0,
      FeatureCardSize.medium => 32.0,
      FeatureCardSize.small => 24.0,
    };

    final padding = switch (size) {
      FeatureCardSize.large => 20.0,
      FeatureCardSize.medium => 16.0,
      FeatureCardSize.small => 12.0,
    };

    return Card(
      elevation: 6,
      shadowColor: color.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: bg,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FocusableActionDetector(
                mouseCursor: SystemMouseCursors.click,
                child: Semantics(
                  label: title,
                  button: true,
                  enabled: true,
                  child: Tooltip(
                    message: subtitle ?? title,
                    child: Icon(icon, size: iconSize, color: color),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
