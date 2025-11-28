import 'package:flutter/material.dart';
import '../models/motor.dart';
import '../theme/app_theme.dart';

class MotorCard extends StatelessWidget {
  final Motor motor;
  final VoidCallback onTap;

  const MotorCard({
    super.key,
    required this.motor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = motor.isRunning;
    final rpm = motor.lastSpeedRpm ?? 0;
    final temperature = motor.lastTemperature ?? 0;
    final vibration = motor.lastVibration ?? 0;
    final current = motor.lastCurrent ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.baseSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne 1 : nom + point + chevron
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          motor.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isRunning
                                ? AppTheme.primaryBlue
                                : Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.neutralText,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Ligne 2 : badge état + RPM
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isRunning
                          ? AppTheme.accentGreen.withOpacity(0.1)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isRunning ? 'En marche' : 'Arrêté',
                      style: TextStyle(
                        color: isRunning
                            ? AppTheme.accentGreen
                            : AppTheme.neutralText,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.speed_rounded,
                    size: 18,
                    color: AppTheme.neutralText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${rpm.toStringAsFixed(0)} RPM',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Ligne 3 : métriques
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MetricInfo(
                    icon: Icons.thermostat_rounded,
                    label: 'Temp',
                    value: '${temperature.toStringAsFixed(0)}°C',
                    color: Colors.orange,
                  ),
                  _MetricInfo(
                    icon: Icons.timeline_rounded,
                    label: 'Vibr.',
                    value: '${vibration.toStringAsFixed(1)} mm/s',
                    color: AppTheme.primaryBlue,
                  ),
                  _MetricInfo(
                    icon: Icons.bolt_rounded,
                    label: 'Courant',
                    value: '${current.toStringAsFixed(1)} A',
                    color: Colors.amber.shade700,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.neutralText,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
