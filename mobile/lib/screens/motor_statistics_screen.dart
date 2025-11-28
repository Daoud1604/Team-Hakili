import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MotorStatisticsScreen extends StatelessWidget {
  final int motorId;

  const MotorStatisticsScreen({super.key, required this.motorId});

  @override
  Widget build(BuildContext context) {
    // TODO: Récupérer les vraies statistiques depuis le provider
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.baseSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte principale Disponibilité
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(AppTheme.baseSpacing * 2),
            child: Column(
              children: [
                Text(
                  'Disponibilité du moteur',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  '85%',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Score d\'efficacité',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Donuts de temps de marche / arrêt
          Row(
            children: [
              Expanded(
                child: _DonutCard(
                  title: 'Temps de marche',
                  percentage: 85,
                  value: '12h 40m',
                  color: AppTheme.accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DonutCard(
                  title: 'Temps d\'arrêt',
                  percentage: 15,
                  value: '2h 15m',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chronologie 24h
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.baseSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chronologie des 24 dernières heures',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _TimelineBar(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendItem(
                        color: AppTheme.accentGreen,
                        label: 'En marche',
                      ),
                      const SizedBox(width: 16),
                      _LegendItem(
                        color: AppTheme.dangerRed,
                        label: 'Arrêté',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['0h', '6h', '12h', '18h', '24h']
                        .map((time) => Text(
                              time,
                              style: Theme.of(context).textTheme.bodySmall,
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Métriques de production
          Text(
            'Métriques de production',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _ProductionMetricCard(
            icon: Icons.trending_up,
            title: 'Démarrages aujourd\'hui',
            value: '12 fois',
          ),
          const SizedBox(height: 8),
          _ProductionMetricCard(
            icon: Icons.access_time,
            title: 'Temps moyen de marche',
            value: '63 minutes',
          ),
          const SizedBox(height: 8),
          _ProductionMetricCard(
            icon: Icons.build,
            title: 'Dernière maintenance',
            value: 'Il y a 5 jours',
            isGood: true,
          ),
        ],
      ),
    );
  }
}

class _DonutCard extends StatelessWidget {
  final String title;
  final int percentage;
  final String value;
  final Color color;

  const _DonutCard({
    required this.title,
    required this.percentage,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.baseSpacing),
        child: Column(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 12,
                    color: color,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  Text(
                    '$percentage%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Simulation d'une chronologie (vert = marche, rouge = arrêt)
    final segments = [
      true,
      true,
      true,
      false,
      true,
      true,
      true,
      true,
      false,
      true,
      true,
      true,
      true,
      true,
      false,
      true,
    ];

    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: segments.map((isRunning) {
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isRunning ? AppTheme.accentGreen : AppTheme.dangerRed,
                borderRadius: segments.indexOf(isRunning) == 0
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      )
                    : segments.indexOf(isRunning) == segments.length - 1
                        ? const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          )
                        : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ProductionMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isGood;

  const _ProductionMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    this.isGood = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryBlue),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGood)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
