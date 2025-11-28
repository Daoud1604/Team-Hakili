import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MotorSafetyScreen extends StatefulWidget {
  final int motorId;

  const MotorSafetyScreen({super.key, required this.motorId});

  @override
  State<MotorSafetyScreen> createState() => _MotorSafetyScreenState();
}

class _MotorSafetyScreenState extends State<MotorSafetyScreen> {
  bool _tempStopEnabled = true;
  bool _vibStopEnabled = true;
  bool _batteryAlertEnabled = true;
  bool _smsAlertsEnabled = false;
  String _stopDelay = '5s';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.baseSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bloc d'explication
          Card(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.baseSpacing),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppTheme.warningYellow),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Arrêts automatiques de sécurité. Lorsqu\'activé, MotorGuard déclenche le contacteur pour arrêter immédiatement le moteur lors de la détection de ces conditions.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Carte Système de sécurité actif
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.baseSpacing),
              child: Column(
                children: [
                  Icon(
                    Icons.shield,
                    size: 48,
                    color: AppTheme.accentGreen,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Système de sécurité actif',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '4 déclencheurs activés sur 5',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Déclencheurs automatiques
          Text(
            'Déclencheurs automatiques',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _SafetyTriggerCard(
            title: 'Arrêt si Température > 90°C',
            description:
                'Déclenche un arrêt automatique si la température dépasse le seuil critique.',
            threshold: '90°C',
            enabled: _tempStopEnabled,
            onChanged: (value) {
              setState(() => _tempStopEnabled = value);
            },
          ),
          const SizedBox(height: 12),
          _SafetyTriggerCard(
            title: 'Arrêt si Vibration > 5 mm/s',
            description:
                'Déclenche un arrêt automatique si la vibration dépasse le seuil.',
            threshold: '5 mm/s',
            enabled: _vibStopEnabled,
            onChanged: (value) {
              setState(() => _vibStopEnabled = value);
            },
          ),
          const SizedBox(height: 12),
          _SafetyTriggerCard(
            title: 'Alerte si Batterie < 20%',
            description: 'Avertissement de batterie faible du capteur IoT.',
            threshold: '20%',
            enabled: _batteryAlertEnabled,
            onChanged: (value) {
              setState(() => _batteryAlertEnabled = value);
            },
          ),
          const SizedBox(height: 24),

          // Options avancées
          Text(
            'Options avancées',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.baseSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Délai avant arrêt',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Attendre avant de déclencher l\'arrêt',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _stopDelay,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: ['Immédiat', '5s', '10s', '30s']
                        .map((delay) => DropdownMenuItem(
                              value: delay == 'Immédiat' ? '0s' : delay,
                              child: Text(delay),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _stopDelay = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: const Text('Notifications SMS'),
              subtitle: const Text('Alertes par message texte'),
              value: _smsAlertsEnabled,
              onChanged: (value) {
                setState(() => _smsAlertsEnabled = value);
              },
            ),
          ),
          const SizedBox(height: 24),

          // Bouton de sauvegarde
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Sauvegarder la configuration
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuration sauvegardée'),
                    backgroundColor: AppTheme.accentGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Sauvegarder la configuration'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyTriggerCard extends StatelessWidget {
  final String title;
  final String description;
  final String threshold;
  final bool enabled;
  final Function(bool) onChanged;

  const _SafetyTriggerCard({
    required this.title,
    required this.description,
    required this.threshold,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.baseSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onChanged,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.screenBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Seuil : $threshold',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
