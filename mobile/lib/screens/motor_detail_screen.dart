import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/motor_provider.dart';
import '../providers/config_provider.dart';
import '../providers/auth_provider.dart';
import '../models/motor.dart';
import '../theme/app_theme.dart';
import '../widgets/rpm_gauge.dart';
import '../widgets/metric_card.dart';
import 'motor_form_screen.dart';
import 'motor_start_confirm_screen.dart';
import 'motor_statistics_screen.dart';
import 'motor_safety_screen.dart';

class MotorDetailScreen extends StatefulWidget {
  final int motorId;

  const MotorDetailScreen({super.key, required this.motorId});

  @override
  State<MotorDetailScreen> createState() => _MotorDetailScreenState();
}

class _MotorDetailScreenState extends State<MotorDetailScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<MotorProvider>(
      builder: (context, motorProvider, _) {
        final motor =
            motorProvider.motors.firstWhere((m) => m.id == widget.motorId);

        return Scaffold(
          appBar: _CustomAppBar(motor: motor),
          body: Column(
            children: [
              // Tabs horizontales en chips
              _TabChips(
                selectedIndex: _selectedTab,
                onTabSelected: (index) {
                  setState(() => _selectedTab = index);
                },
              ),
              // Contenu selon le tab sélectionné
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    _ControlTab(motorId: widget.motorId),
                    _HistoryTab(motorId: widget.motorId),
                    MotorStatisticsScreen(motorId: widget.motorId),
                    MotorSafetyScreen(motorId: widget.motorId),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Motor motor;

  const _CustomAppBar({required this.motor});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigProvider>(
      builder: (context, configProvider, _) {
        return AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Centre de contrôle'),
              Text(
                motor.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            Icon(
              configProvider.isEsp32Connected ? Icons.wifi : Icons.wifi_off,
              color: configProvider.isEsp32Connected
                  ? AppTheme.accentGreen
                  : Colors.grey,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MotorFormScreen(motor: motor),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TabChips extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const _TabChips({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = ['Historique', 'Statistiques', 'Sécurité'];

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.baseSpacing, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected =
                selectedIndex == index + 1; // +1 car index 0 = Contrôle
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(tabs[index]),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) onTabSelected(index + 1);
                },
                selectedColor: AppTheme.primaryBlue.withOpacity(0.1),
                labelStyle: TextStyle(
                  color:
                      isSelected ? AppTheme.primaryBlue : AppTheme.neutralText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ControlTab extends StatelessWidget {
  final int motorId;

  const _ControlTab({required this.motorId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MotorProvider, ConfigProvider>(
      builder: (context, motorProvider, configProvider, _) {
        // Récupérer le moteur mis à jour depuis le provider
        final motor = motorProvider.motors.firstWhere(
          (m) => m.id == motorId,
          orElse: () => throw Exception('Motor not found'),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.baseSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Statut WiFi
              Card(
                color: configProvider.isEsp32Connected
                    ? AppTheme.accentGreen.withOpacity(0.1)
                    : AppTheme.dangerRed.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        configProvider.isEsp32Connected
                            ? Icons.wifi
                            : Icons.wifi_off,
                        color: configProvider.isEsp32Connected
                            ? AppTheme.accentGreen
                            : AppTheme.dangerRed,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        configProvider.isEsp32Connected
                            ? 'WiFi Connecté'
                            : 'WiFi Déconnecté',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: configProvider.isEsp32Connected
                              ? AppTheme.accentGreen
                              : AppTheme.dangerRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Carte Surveillance en temps réel avec jauge
              Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.baseSpacing),
                      child: Text(
                        'Surveillance en temps réel',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    RpmGauge(
                      currentRpm: motor.lastSpeedRpm ?? 0,
                      targetRpm: 1500, // TODO: Récupérer depuis la config
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mini-cards métriques
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Température',
                      value: motor.lastTemperature?.toStringAsFixed(1) ?? '--',
                      unit: '°C',
                      icon: Icons.thermostat,
                      color: (motor.lastTemperature ?? 0) >
                              configProvider.maxTemperature
                          ? AppTheme.dangerRed
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: 'Vibration',
                      value: motor.lastVibration?.toStringAsFixed(2) ?? '--',
                      unit: 'mm/s',
                      icon: Icons.vibration,
                      color: (motor.lastVibration ?? 0) >
                              configProvider.maxVibration
                          ? AppTheme.warningYellow
                          : AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: 'Courant',
                      value: motor.lastCurrent?.toStringAsFixed(1) ?? '--',
                      unit: 'A',
                      icon: Icons.electric_bolt,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Panneau de contrôle (fond sombre)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Bleu très foncé
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(AppTheme.baseSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panneau de contrôle',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Boutons Start/Stop
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: motor.isRunning
                                ? null
                                : () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MotorStartConfirmScreen(
                                          motorId: motor.id!,
                                        ),
                                      ),
                                    );
                                    if (result == true && context.mounted) {
                                      final authProvider =
                                          Provider.of<AuthProvider>(context,
                                              listen: false);
                                      motorProvider.loadMotors(
                                          configProvider: configProvider,
                                          authProvider: authProvider);
                                    }
                                  },
                            icon: const Icon(Icons.power_settings_new),
                            label: const Text('DÉMARRER'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.grey.shade700,
                              foregroundColor: Colors.white70,
                              disabledBackgroundColor: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: motor.isRunning
                                ? () async {
                                    final authProvider =
                                        Provider.of<AuthProvider>(context,
                                            listen: false);
                                    final success =
                                        await motorProvider.sendMotorCommand(
                                      motor.id!,
                                      'STOP',
                                      configProvider: configProvider,
                                      authProvider: authProvider,
                                    );
                                    if (success && context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Moteur arrêté'),
                                          backgroundColor: AppTheme.accentGreen,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('ARRÊT'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.dangerRed,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Slider Vitesse cible
                    Text(
                      'Vitesse cible (RPM)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: 1500.0,
                      min: 540,
                      max: 1800,
                      divisions: 126,
                      label: '1500 RPM',
                      onChanged: (value) {
                        // TODO: Mettre à jour la vitesse cible
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '540 RPM',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white54,
                                  ),
                        ),
                        Text(
                          '1500 RPM',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          '1800 RPM',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white54,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Statut système
                    Row(
                      children: [
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
                          'Système Prêt',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          'WiFi Connecté',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.accentGreen,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final int motorId;

  const _HistoryTab({required this.motorId});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Historique de télémétrie'),
    );
  }
}
