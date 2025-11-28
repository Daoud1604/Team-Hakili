import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/motor_provider.dart';
import '../providers/config_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class MotorStartConfirmScreen extends StatefulWidget {
  final int motorId;

  const MotorStartConfirmScreen({super.key, required this.motorId});

  @override
  State<MotorStartConfirmScreen> createState() =>
      _MotorStartConfirmScreenState();
}

class _MotorStartConfirmScreenState extends State<MotorStartConfirmScreen> {
  double _sliderValue = 1500.0;
  bool _isConfirming = false;
  double _confirmSliderValue = 0.0;

  Future<void> _handleConfirm() async {
    setState(() => _isConfirming = true);

    final motorProvider = Provider.of<MotorProvider>(context, listen: false);
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await motorProvider.sendMotorCommand(
      widget.motorId,
      'START',
      targetSpeedRpm: _sliderValue,
      configProvider: configProvider,
      authProvider: authProvider,
    );

    setState(() => _isConfirming = false);

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moteur démarré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du démarrage'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MotorProvider>(
      builder: (context, motorProvider, _) {
        final motor =
            motorProvider.motors.firstWhere((m) => m.id == widget.motorId);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Confirmation de sécurité'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.baseSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bandeau supérieur (type chantier)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.warningYellow,
                    border: Border.all(color: AppTheme.neutralDark, width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, color: AppTheme.neutralDark),
                      const SizedBox(width: 8),
                      Text(
                        'ZONE DE SÉCURITÉ',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.neutralDark,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Icône warning au centre
                Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 64,
                    color: AppTheme.warningYellow,
                  ),
                ),
                const SizedBox(height: 24),

                // Titre
                Text(
                  'Confirmation de sécurité',
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Bloc d'information jaune
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.warningYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(AppTheme.baseSpacing),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.warningYellow,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vous êtes sur le point de démarrer ${motor.name} (ID: ${motor.code}) à distance.\n'
                          'Assurez-vous que la zone est dégagée et sécurisée.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Slider pour vitesse cible
                Text(
                  'Vitesse cible (RPM)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  _sliderValue.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _sliderValue,
                  min: 540,
                  max: 1800,
                  divisions: 126,
                  label: _sliderValue.toStringAsFixed(0),
                  onChanged: (value) {
                    setState(() => _sliderValue = value);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('540 RPM',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text('1800 RPM',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 32),

                // Zone d'action : Slider "Glissez pour confirmer"
                Text(
                  'Glissez pour confirmer',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          'Glisser pour confirmer',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 60,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 25,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 30,
                          ),
                        ),
                        child: Slider(
                          value: _confirmSliderValue,
                          min: 0,
                          max: 100,
                          onChanged: (value) {
                            setState(() => _confirmSliderValue = value);
                            if (value >= 100) {
                              _handleConfirm();
                            }
                          },
                          activeColor: Colors.transparent,
                          inactiveColor: Colors.transparent,
                          thumbColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _isConfirming
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
