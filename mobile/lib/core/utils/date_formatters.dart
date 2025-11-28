import 'package:intl/intl.dart';

/// Utilitaires de formatage de dates
class DateFormatters {
  DateFormatters._();

  /// Format date/heure complet
  static final DateFormat dateTime = DateFormat('dd/MM/yyyy HH:mm');

  /// Format date seulement
  static final DateFormat date = DateFormat('dd/MM/yyyy');

  /// Format heure seulement
  static final DateFormat time = DateFormat('HH:mm');

  /// Format pour les noms de fichiers
  static final DateFormat fileName = DateFormat('yyyyMMdd_HHmmss');

  /// Format ISO 8601
  static final DateFormat iso8601 = DateFormat('yyyy-MM-ddTHH:mm:ssZ');

  /// Formate une durée en texte lisible
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Formate une date relative (ex: "il y a 2 heures")
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    }
    return 'À l\'instant';
  }
}
