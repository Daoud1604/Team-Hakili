import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Récupérer les notifications depuis le provider
    final notifications = <_NotificationItem>[
      _NotificationItem(
        type: NotificationType.critical,
        title: 'Connexion perdue',
        subtitle: 'Convoyeur Est',
        time: 'Il y a 2 heures',
      ),
      _NotificationItem(
        type: NotificationType.warning,
        title: 'Vibration au-dessus de la normale',
        subtitle: 'Broyeur Principal',
        time: 'Il y a 5 heures',
      ),
      _NotificationItem(
        type: NotificationType.warning,
        title: 'Maintenance programmée',
        subtitle: 'Pompe station 4',
        time: 'Il y a 1 jour',
      ),
      _NotificationItem(
        type: NotificationType.info,
        title: 'Mise à jour firmware disponible',
        subtitle: 'ESP32_001',
        time: 'Il y a 2 jours',
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune notification',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.baseSpacing),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _NotificationCard(notification: notification);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.baseSpacing),
            child: Text(
              'Appuyez sur une alerte pour afficher les actions',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

enum NotificationType { critical, warning, info }

class _NotificationItem {
  final NotificationType type;
  final String title;
  final String subtitle;
  final String time;

  _NotificationItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem notification;

  const _NotificationCard({required this.notification});

  Color get _borderColor {
    switch (notification.type) {
      case NotificationType.critical:
        return AppTheme.dangerRed;
      case NotificationType.warning:
        return AppTheme.warningYellow;
      case NotificationType.info:
        return AppTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Afficher les actions
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: _borderColor, width: 4),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.baseSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  notification.time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.neutralText,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
