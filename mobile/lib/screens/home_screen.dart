import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/motor_provider.dart';
import '../providers/config_provider.dart';
import '../theme/app_theme.dart';
import '../models/motor.dart';
import 'motors_list_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'motor_detail_screen.dart';
import 'users_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    // Construire les écrans et items de navigation selon le rôle
    final List<Widget> _screens = isAdmin
        ? [
            DashboardScreen(onNotificationTap: () {
              setState(() => _selectedIndex = 2);
            }),
            const MotorsListScreen(),
            const NotificationsScreen(),
            const UsersManagementScreen(),
            const SettingsScreen(),
          ]
        : [
            DashboardScreen(onNotificationTap: () {
              setState(() => _selectedIndex = 2);
            }),
            const MotorsListScreen(),
            const NotificationsScreen(),
          ];

    final List<BottomNavigationBarItem> _navItems = isAdmin
        ? [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Accueil',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.precision_manufacturing),
              label: 'Machines',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Alertes',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Utilisateurs',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Config',
            ),
          ]
        : [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Accueil',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.precision_manufacturing),
              label: 'Machines',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Alertes',
            ),
          ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.neutralText,
        items: _navItems,
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNotificationTap;

  const DashboardScreen({super.key, this.onNotificationTap});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les moteurs et initialiser le polling après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() {
    final motorProvider = Provider.of<MotorProvider>(context, listen: false);
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Charger les moteurs
    motorProvider.loadMotors(
        configProvider: configProvider, authProvider: authProvider);

    // Démarrer le polling de télémétrie
    motorProvider.startPollingTelemetry(configProvider,
        authProvider: authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MotorProvider, AuthProvider>(
      builder: (context, motorProvider, authProvider, _) {
        final motors = motorProvider.motors;
        final runningMotors = motors.where((m) => m.isRunning).length;
        final totalMotors = motors.length;
        final healthyMotors = motors.where((m) {
          if (!m.isRunning) return false;
          final temp = m.lastTemperature ?? 0;
          final vib = m.lastVibration ?? 0;
          return temp < 80 && vib < 5;
        }).length;
        final criticalMotors = runningMotors - healthyMotors;

        final user = authProvider.currentUser;
        final initials = user?.fullName
                .split(' ')
                .map((n) => n[0])
                .take(2)
                .join()
                .toUpperCase() ??
            'A';
        final userRole =
            user?.role == 'ADMIN' ? 'Administrateur' : 'Technicien';

        return SafeArea(
          child: Scaffold(
            backgroundColor: AppTheme.screenBackground,
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.baseSpacing,
                vertical: AppTheme.baseSpacing,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header custom
                  _DashboardHeader(
                    initials: initials,
                    userRole: userRole,
                    notificationCount: 5,
                    onNotificationTap: widget.onNotificationTap,
                    onLogout: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Déconnexion'),
                          content: const Text(
                            'Êtes-vous sûr de vouloir vous déconnecter ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Annuler'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Déconnexion'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        await authProvider.logout();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Déconnexion réussie'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Carte Vue d'ensemble
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.baseSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vue d\'ensemble',
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                          const SizedBox(height: 16),
                          // Ligne de 3 indicateurs
                          Row(
                            children: [
                              Expanded(
                                child: _OverviewIndicator(
                                  value: totalMotors.toString(),
                                  label: 'Total',
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.shade300,
                              ),
                              Expanded(
                                child: _OverviewIndicator(
                                  value: healthyMotors.toString(),
                                  label: 'Sains',
                                  color: AppTheme.accentGreen,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.shade300,
                              ),
                              Expanded(
                                child: _OverviewIndicator(
                                  value: criticalMotors.toString(),
                                  label: 'Critiques',
                                  color: AppTheme.dangerRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Titre section Machines
                  Text(
                    'Machines',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Liste des machines
                  if (motors.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'Aucune machine enregistrée',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    )
                  else
                    ...motors.map((motor) => _DashboardMotorCard(
                          motor: motor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MotorDetailScreen(
                                  motorId: motor.id!,
                                ),
                              ),
                            );
                          },
                        )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String initials;
  final String userRole;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onLogout;

  const _DashboardHeader({
    required this.initials,
    required this.userRole,
    required this.notificationCount,
    this.onNotificationTap,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.baseSpacing,
        vertical: 12,
      ),
      child: Row(
        children: [
          // À gauche : Avatar avec menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout' && onLogout != null) {
                onLogout!();
              }
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryBlue,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Déconnexion',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MotorGuard',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                Text(
                  userRole,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.neutralText,
                      ),
                ),
              ],
            ),
          ),
          // À droite : Notifications avec badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: onNotificationTap,
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.dangerRed,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardMotorCard extends StatelessWidget {
  final Motor motor;
  final VoidCallback onTap;

  const _DashboardMotorCard({
    required this.motor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = motor.isRunning;
    final rpm = motor.lastSpeedRpm ?? 0.0;
    final temp = motor.lastTemperature ?? 0.0;
    final vib = motor.lastVibration ?? 0.0;
    final current = motor.lastCurrent ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
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
              // Ligne 1 - En-tête : Nom + Point + Chevron
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          motor.name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(width: 6),
                        // Point de connexion : vert si connecté/surveillé, bleu sinon
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: (motor.lastUpdate != null &&
                                    DateTime.now()
                                            .difference(motor.lastUpdate!)
                                            .inSeconds <
                                        30)
                                ? AppTheme.accentGreen
                                : AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Ligne 2 - État + RPM
              Row(
                children: [
                  // Badge état
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                  const SizedBox(width: 8),
                  // RPM
                  Row(
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        size: 16,
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
                ],
              ),
              const SizedBox(height: 12),

              // Ligne 3 - Métriques (Temp, Vibr, Courant)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Température
                  _MiniMetric(
                    icon: Icons.thermostat,
                    label: 'Temp',
                    value: '${temp.toStringAsFixed(0)}°C',
                    iconColor: Colors.orange,
                  ),
                  // Vibration
                  _MiniMetric(
                    icon: Icons.graphic_eq,
                    label: 'Vibr',
                    value: '${vib.toStringAsFixed(1)} mm/s',
                    iconColor: AppTheme.primaryBlue,
                  ),
                  // Courant
                  _MiniMetric(
                    icon: Icons.bolt_rounded,
                    label: 'Courant',
                    value: '${current.toStringAsFixed(1)} A',
                    iconColor: Colors.amber,
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

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _MiniMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewIndicator extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _OverviewIndicator({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
