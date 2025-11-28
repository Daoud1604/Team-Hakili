import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/motor_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/motor_card.dart';
import '../theme/app_theme.dart';
import 'motor_detail_screen.dart';
import 'motor_form_screen.dart';
import 'export_pdf_screen.dart';

class MotorsListScreen extends StatelessWidget {
  const MotorsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<MotorProvider, AuthProvider>(
        builder: (context, motorProvider, authProvider, _) {
          final motors = motorProvider.motors;

          if (motors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.precision_manufacturing_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune machine enregistrée',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Appuyez sur + pour en ajouter une',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.baseSpacing),
            itemCount: motors.length,
            itemBuilder: (context, index) {
              final motor = motors[index];
              return MotorCard(
                motor: motor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MotorDetailScreen(motorId: motor.id!),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final isAdmin = authProvider.isAdmin;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAdmin) ...[
                FloatingActionButton.extended(
                  heroTag: 'export_pdf',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExportPdfScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Exporter PDF'),
                  backgroundColor: AppTheme.dangerRed,
                ),
                const SizedBox(height: 12),
              ],
              FloatingActionButton.extended(
                heroTag: 'add_motor',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MotorFormScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle machine'),
                backgroundColor: AppTheme.primaryBlue,
              ),
            ],
          );
        },
      ),
    );
  }
}
