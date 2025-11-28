import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class RpmGauge extends StatelessWidget {
  final double currentRpm;
  final double? targetRpm;
  final double maxRpm;

  const RpmGauge({
    super.key,
    required this.currentRpm,
    this.targetRpm,
    this.maxRpm = 1800,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (currentRpm / maxRpm).clamp(0.0, 1.0);
    final targetPercentage =
        targetRpm != null ? (targetRpm! / maxRpm).clamp(0.0, 1.0) : null;

    return Container(
      padding: const EdgeInsets.all(AppTheme.baseSpacing),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: CustomPaint(
              size: const Size(double.infinity, 150),
              painter: _GaugePainter(
                percentage: percentage,
                targetPercentage: targetPercentage,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Actuel ${currentRpm.toStringAsFixed(0)} RPM',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (targetRpm != null) ...[
            const SizedBox(height: 4),
            Text(
              'Cible ${targetRpm!.toStringAsFixed(0)} RPM',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.warningYellow,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final double? targetPercentage;

  _GaugePainter({
    required this.percentage,
    this.targetPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width * 0.4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Arc de fond (gris)
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      math.pi, // 180 degrés (demi-cercle)
      math.pi, // 180 degrés
      false,
      backgroundPaint,
    );

    // Arc actuel (bleu)
    final currentPaint = Paint()
      ..color = AppTheme.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      math.pi,
      math.pi * percentage,
      false,
      currentPaint,
    );

    // Point cible (jaune)
    if (targetPercentage != null) {
      final targetAngle = math.pi + (math.pi * targetPercentage!);
      final targetX = center.dx + radius * math.cos(targetAngle);
      final targetY = center.dy + radius * math.sin(targetAngle);

      final targetPaint = Paint()
        ..color = AppTheme.warningYellow
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(targetX, targetY),
        8,
        targetPaint,
      );
    }

    // Aiguille (rouge)
    final needleAngle = math.pi + (math.pi * percentage);
    final needleLength = radius * 0.8;
    final needleEndX = center.dx + needleLength * math.cos(needleAngle);
    final needleEndY = center.dy + needleLength * math.sin(needleAngle);

    final needlePaint = Paint()
      ..color = AppTheme.dangerRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(needleEndX, needleEndY), needlePaint);

    // Point central
    final centerPaint = Paint()
      ..color = AppTheme.dangerRed
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 6, centerPaint);
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.targetPercentage != targetPercentage;
  }
}
