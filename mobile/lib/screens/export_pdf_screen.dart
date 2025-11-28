import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/motor.dart';
import '../providers/motor_provider.dart';
import '../providers/auth_provider.dart';
import '../services/pdf_export_service.dart';
import '../theme/app_theme.dart';

class ExportPdfScreen extends StatefulWidget {
  const ExportPdfScreen({super.key});

  @override
  State<ExportPdfScreen> createState() => _ExportPdfScreenState();
}

class _ExportPdfScreenState extends State<ExportPdfScreen> {
  final Set<int> _selectedMotorIds = {};
  final PdfExportService _pdfExportService = PdfExportService();
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 7));
  }

  Future<void> _pickDate({
    required bool isStart,
  }) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = DateTime.now().subtract(const Duration(days: 365));
    final lastDate = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate == null) return;

    setState(() {
      if (isStart) {
        _startDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          0,
          0,
        );
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      } else {
        _endDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          23,
          59,
        );
        if (_endDate.isBefore(_startDate)) {
          _startDate = _endDate.subtract(const Duration(days: 1));
        }
      }
    });
  }

  Future<void> _generateReport(List<Motor> motors) async {
    if (_selectedMotorIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une machine.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    // Afficher un dialog de progression
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Génération du PDF en cours...'),
                const SizedBox(height: 8),
                Text(
                  'Cela peut prendre quelques instants',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      final selectedMotors = motors
          .where((motor) =>
              motor.id != null && _selectedMotorIds.contains(motor.id))
          .toList();

      final result = await _pdfExportService.generateMotorReport(
        motors: selectedMotors,
        startDate: _startDate,
        endDate: _endDate,
      );

      // Fermer le dialog de progression
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Aucune donnée disponible pour la période sélectionnée.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await Printing.sharePdf(
        bytes: result.bytes,
        filename: result.fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Rapport généré avec succès (${result.totalEntries} entrées)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Fermer le dialog en cas d'erreur
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la génération du PDF : $e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exporter en PDF'),
      ),
      body: Consumer2<MotorProvider, AuthProvider>(
        builder: (context, motorProvider, authProvider, _) {
          // Vérifier que l'utilisateur est administrateur
          if (!authProvider.isAdmin) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Accès réservé aux administrateurs'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final motors = motorProvider.motors;

          if (motors.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.precision_manufacturing_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text('Aucune machine disponible pour l\'export.'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.baseSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateSelector(
                  startDate: _startDate,
                  endDate: _endDate,
                  onPickStart: () => _pickDate(isStart: true),
                  onPickEnd: () => _pickDate(isStart: false),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sélectionnez les machines',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedMotorIds
                                ..clear()
                                ..addAll(
                                  motors
                                      .where((m) => m.id != null)
                                      .map((m) => m.id!),
                                );
                            });
                          },
                          child: const Text('Tout sélectionner'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedMotorIds.clear());
                          },
                          child: const Text('Tout désélectionner'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: motors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final motor = motors[index];
                    final motorId = motor.id;
                    if (motorId == null) return const SizedBox.shrink();

                    final isSelected = _selectedMotorIds.contains(motorId);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedMotorIds.add(motorId);
                          } else {
                            _selectedMotorIds.remove(motorId);
                          }
                        });
                      },
                      title: Text(
                        motor.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        'Code: ${motor.code} • '
                        'Lieu: ${motor.location ?? 'N/A'}',
                      ),
                      secondary: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppTheme.accentGreen : Colors.grey,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        _isGenerating ? null : () => _generateReport(motors),
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf),
                    label: Text(
                      _isGenerating
                          ? 'Génération en cours...'
                          : 'Générer le rapport PDF',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Le rapport inclura :\n'
                  '• Informations machines (nom, code, localisation)\n'
                  '• Historique de télémétrie (température, vibration, courant, RPM)\n'
                  '• Graphiques temporels par métrique\n'
                  '• Statistiques (min, max, moyennes, temps de fonctionnement)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  const _DateSelector({
    required this.startDate,
    required this.endDate,
    required this.onPickStart,
    required this.onPickEnd,
  });

  String _format(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Période du rapport',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickStart,
                icon: const Icon(Icons.calendar_month),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date de début'),
                    Text(
                      _format(startDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickEnd,
                icon: const Icon(Icons.event),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date de fin'),
                    Text(
                      _format(endDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
