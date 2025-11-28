import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/network_scanner_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ConfigProvider, AuthProvider>(
      builder: (context, configProvider, authProvider, _) {
        // Vérifier que l'utilisateur est administrateur
        if (!authProvider.isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
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

        return Scaffold(
          backgroundColor: AppTheme.screenBackground,
          body: CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 100,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.primaryBlue,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Configuration',
                    style: TextStyle(color: Colors.white),
                  ),
                  centerTitle: false,
                ),
              ),
              // Contenu
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.baseSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mode de fonctionnement
                      _ConfigSection(
                        icon: Icons.sync,
                        title: 'Mode de fonctionnement',
                        children: [
                          _RadioOption(
                            title: 'Local autonome (ESP32 uniquement)',
                            subtitle:
                                'Communication directe avec l\'ESP32 via Wi-Fi',
                            value: 'autonomous',
                            groupValue: configProvider.operationMode,
                            onChanged: (value) {
                              if (value != null) {
                                configProvider.updateOperationMode(value);
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          _RadioOption(
                            title: 'Serveur FastAPI',
                            subtitle: 'Connexion via backend centralisé',
                            value: 'server',
                            groupValue: configProvider.operationMode,
                            onChanged: (value) {
                              if (value != null) {
                                configProvider.updateOperationMode(value);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Configuration réseau ESP32 (visible seulement en mode autonome)
                      if (configProvider.operationMode == 'autonomous') ...[
                        _ConfigSection(
                          icon: Icons.wifi,
                          title: 'Configuration réseau ESP32',
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info,
                                      color: Colors.blue.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'L\'ESP32 et le téléphone doivent être sur le même réseau Wi-Fi',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ConfigItem(
                              title: 'Adresse IP de l\'ESP32',
                              subtitle: configProvider.esp32Ip,
                              onTap: () => _showEditDialog(
                                context,
                                'Adresse IP de l\'ESP32',
                                configProvider.esp32Ip,
                                (value) => configProvider.updateEsp32Ip(value),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            _ConfigItem(
                              title: 'Port ESP32',
                              subtitle: configProvider.esp32Port.toString(),
                              onTap: () =>
                                  _showPortDialog(context, configProvider),
                            ),
                            _ConfigItem(
                              title: 'URL complète',
                              subtitle: configProvider.esp32BaseUrl,
                              onTap: () => _showEditDialog(
                                context,
                                'URL base ESP32',
                                configProvider.esp32BaseUrl,
                                (value) =>
                                    configProvider.updateEsp32BaseUrl(value),
                              ),
                            ),
                            const Divider(height: 24),
                            _TestConnectionItem(
                              title: 'Test de connexion ESP32',
                              isConnected: configProvider.isEsp32Connected,
                              onTest: () async {
                                final success =
                                    await configProvider.testEsp32Connection();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Connexion réussie'
                                            : 'Échec de la connexion',
                                      ),
                                      backgroundColor:
                                          success ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _showDiscoverDialog(context, configProvider);
                                },
                                icon: const Icon(Icons.search),
                                label: const Text(
                                    'Découvrir l\'ESP32 sur le réseau'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Configuration Backend (visible seulement en mode serveur)
                      if (configProvider.operationMode == 'server') ...[
                        _ConfigSection(
                          icon: Icons.cloud,
                          title: 'Configuration Backend',
                          children: [
                            _ConfigItem(
                              title: 'URL base Backend',
                              subtitle: configProvider.backendBaseUrl,
                              onTap: () => _showEditDialog(
                                context,
                                'URL base Backend',
                                configProvider.backendBaseUrl,
                                (value) =>
                                    configProvider.updateBackendBaseUrl(value),
                              ),
                            ),
                            _SwitchItem(
                              title: 'Certificats auto-signés',
                              subtitle:
                                  'Autoriser les certificats non vérifiés',
                              value: configProvider.allowSelfSignedCert,
                              onChanged: (value) => configProvider
                                  .updateAllowSelfSignedCert(value),
                            ),
                            const Divider(height: 24),
                            _TestConnectionItem(
                              title: 'Test de connexion Backend',
                              isConnected: configProvider.isBackendConnected,
                              onTest: () async {
                                final success = await configProvider
                                    .testBackendConnection();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Connexion réussie'
                                            : 'Échec de la connexion',
                                      ),
                                      backgroundColor:
                                          success ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Paramètres de télémétrie
                      _ConfigSection(
                        icon: Icons.analytics,
                        title: 'Paramètres de télémétrie',
                        children: [
                          _ConfigItem(
                            title: 'Intervalle de rafraîchissement',
                            subtitle:
                                '${(configProvider.refreshIntervalMs / 1000).toStringAsFixed(1)} secondes',
                            onTap: () =>
                                _showIntervalDialog(context, configProvider),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Alertes et notifications
                      _ConfigSection(
                        icon: Icons.notifications,
                        title: 'Alertes et notifications',
                        children: [
                          _ConfigItem(
                            title: 'Température maximale',
                            subtitle:
                                '${configProvider.maxTemperature.toStringAsFixed(1)}°C',
                            onTap: () => _showNumberDialog(
                              context,
                              'Température maximale (°C)',
                              configProvider.maxTemperature,
                              (value) =>
                                  configProvider.updateMaxTemperature(value),
                              min: 0,
                              max: 150,
                            ),
                          ),
                          _ConfigItem(
                            title: 'Vibration maximale',
                            subtitle:
                                '${configProvider.maxVibration.toStringAsFixed(1)} mm/s',
                            onTap: () => _showNumberDialog(
                              context,
                              'Vibration maximale (mm/s)',
                              configProvider.maxVibration,
                              (value) =>
                                  configProvider.updateMaxVibration(value),
                              min: 0,
                              max: 20,
                            ),
                          ),
                          _ConfigItem(
                            title: 'Niveau de batterie minimal',
                            subtitle:
                                '${configProvider.minBatteryPercent.toStringAsFixed(0)}%',
                            onTap: () => _showNumberDialog(
                              context,
                              'Niveau de batterie minimal (%)',
                              configProvider.minBatteryPercent,
                              (value) =>
                                  configProvider.updateMinBatteryPercent(value),
                              min: 0,
                              max: 100,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Configuration de sécurité
                      _ConfigSection(
                        icon: Icons.shield,
                        title: 'Sécurité',
                        children: [
                          _ConfigItem(
                            title: 'Délai d\'arrêt d\'urgence',
                            subtitle:
                                '${configProvider.emergencyStopDelaySeconds} secondes',
                            onTap: () => _showNumberDialog(
                              context,
                              'Délai d\'arrêt d\'urgence (secondes)',
                              configProvider.emergencyStopDelaySeconds
                                  .toDouble(),
                              (value) => configProvider
                                  .updateEmergencyStopDelay(value.toInt()),
                              min: 1,
                              max: 30,
                              isInt: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Informations système
                      _ConfigSection(
                        icon: Icons.info,
                        title: 'Informations',
                        children: [
                          _InfoItem(
                            title: 'Version',
                            value: '1.0.0',
                          ),
                          _InfoItem(
                            title: 'Utilisateur',
                            value:
                                '${authProvider.currentUser?.email ?? 'N/A'}',
                          ),
                          _InfoItem(
                            title: 'Rôle',
                            value: authProvider.currentUser?.role ?? 'N/A',
                          ),
                          const Divider(height: 24),
                          _ConfigItem(
                            title: 'Déconnexion',
                            subtitle: 'Se déconnecter de l\'application',
                            titleColor: Colors.red,
                            leading:
                                const Icon(Icons.logout, color: Colors.red),
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Déconnexion'),
                                  content: const Text(
                                    'Êtes-vous sûr de vouloir vous déconnecter ?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Annuler'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
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
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Dialogs
  void _showEditDialog(
    BuildContext context,
    String title,
    String initialValue,
    Function(String) onSave, {
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showPortDialog(BuildContext context, ConfigProvider configProvider) {
    final controller =
        TextEditingController(text: configProvider.esp32Port.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Port ESP32'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Port',
            border: OutlineInputBorder(),
            hintText: '80',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final port = int.tryParse(controller.text);
              if (port != null && port > 0 && port <= 65535) {
                configProvider.updateEsp32Port(port);
              }
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showIntervalDialog(
      BuildContext context, ConfigProvider configProvider) {
    final controller = TextEditingController(
      text: (configProvider.refreshIntervalMs / 1000).toStringAsFixed(1),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Intervalle de rafraîchissement'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Secondes',
            border: OutlineInputBorder(),
            hintText: '2.0',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final seconds = double.tryParse(controller.text);
              if (seconds != null && seconds > 0) {
                configProvider.updateRefreshInterval((seconds * 1000).toInt());
              }
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showNumberDialog(
    BuildContext context,
    String title,
    double initialValue,
    Function(double) onSave, {
    required double min,
    required double max,
    bool isInt = false,
  }) {
    final controller = TextEditingController(
      text: isInt
          ? initialValue.toInt().toString()
          : initialValue.toStringAsFixed(1),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
            helperText: 'Min: $min, Max: $max',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = isInt
                  ? int.tryParse(controller.text)?.toDouble()
                  : double.tryParse(controller.text);
              if (value != null && value >= min && value <= max) {
                onSave(value);
              }
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showDiscoverDialog(
      BuildContext context, ConfigProvider configProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DiscoverDialog(
        configProvider: configProvider,
      ),
    );
  }
}

// Dialog de découverte ESP32
class _DiscoverDialog extends StatefulWidget {
  final ConfigProvider configProvider;

  const _DiscoverDialog({required this.configProvider});

  @override
  State<_DiscoverDialog> createState() => _DiscoverDialogState();
}

class _DiscoverDialogState extends State<_DiscoverDialog> {
  bool _isScanning = true;
  double _progress = 0.0;
  List<Esp32Device> _foundDevices = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _progress = 0.0;
      _foundDevices = [];
      _errorMessage = null;
    });

    try {
      final devices = await NetworkScannerService.scanNetworkAuto(
        startRange: 1,
        endRange: 254,
        port: widget.configProvider.esp32Port,
        timeout: const Duration(milliseconds: 800),
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isScanning = false;
          _foundDevices = devices;
          if (devices.isEmpty) {
            _errorMessage = 'Aucun ESP32 trouvé sur le réseau.\n'
                'Assurez-vous que l\'ESP32 est allumé et connecté au même réseau Wi-Fi.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'Erreur lors du scan : $e';
        });
      }
    }
  }

  void _selectDevice(Esp32Device device) {
    // Extraire l'IP de l'URL
    try {
      final uri = Uri.parse(device.url);
      widget.configProvider.updateEsp32Ip(uri.host);
      if (uri.port != 80) {
        widget.configProvider.updateEsp32Port(uri.port);
      }
    } catch (e) {
      // Utiliser l'IP directement
      widget.configProvider.updateEsp32Ip(device.ip);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ESP32 configuré : ${device.ip}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Découvrir l\'ESP32'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isScanning
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(value: _progress),
                  const SizedBox(height: 16),
                  Text(
                    'Scan du réseau en cours...',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recherche des ESP32 sur le réseau local...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : _errorMessage != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : _foundDevices.isEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off,
                              color: Colors.grey, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun ESP32 trouvé',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Assurez-vous que l\'ESP32 est allumé et connecté au même réseau Wi-Fi.',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESP32 trouvé${_foundDevices.length > 1 ? 's' : ''} :',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _foundDevices.length,
                              itemBuilder: (context, index) {
                                final device = _foundDevices[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.router,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    title: Text(
                                      'ESP32 - ${device.ip}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(device.url),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => _selectDevice(device),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
      actions: [
        if (_isScanning)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          )
        else ...[
          TextButton(
            onPressed: _startScan,
            child: const Text('Nouveau scan'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ],
    );
  }
}

// Widgets réutilisables
class _ConfigSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _ConfigSection({
    required this.icon,
    required this.title,
    required this.children,
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
                Icon(icon, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ConfigItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final Widget? leading;

  const _ConfigItem({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Theme.of(context).textTheme.titleMedium?.color,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String title;
  final String value;

  const _InfoItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }
}

class _SwitchItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _SwitchItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String? groupValue;
  final Function(String?) onChanged;

  const _RadioOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = groupValue == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
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

class _TestConnectionItem extends StatelessWidget {
  final String title;
  final bool isConnected;
  final VoidCallback onTest;

  const _TestConnectionItem({
    required this.title,
    required this.isConnected,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isConnected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? 'Connecté' : 'Non connecté',
                    style: TextStyle(
                      color: isConnected ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onTest,
          tooltip: 'Tester la connexion',
        ),
      ],
    );
  }
}
