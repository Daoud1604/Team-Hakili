/// Utilitaires de validation
class Validators {
  Validators._();

  /// Valide une adresse email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  /// Valide un mot de passe
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  /// Valide un champ requis
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    return null;
  }

  /// Valide une adresse IP
  static String? ipAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'adresse IP est requise';
    }
    final ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    if (!ipRegex.hasMatch(value)) {
      return 'Format d\'adresse IP invalide';
    }
    return null;
  }

  /// Valide un port
  static String? port(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le port est requis';
    }
    final port = int.tryParse(value);
    if (port == null || port < 1 || port > 65535) {
      return 'Le port doit être entre 1 et 65535';
    }
    return null;
  }
}
