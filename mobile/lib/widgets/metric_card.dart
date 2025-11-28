import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? unit;
  final IconData icon;
  final Color? color;
  final Color? valueColor;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    required this.icon,
    this.color,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? AppTheme.primaryBlue;
    final textColor = valueColor ?? displayColor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.baseSpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: displayColor, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                children: [
                  TextSpan(text: value),
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textColor,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
