import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../repositories/backend_auth_repository.dart';
import 'config_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  BackendAuthRepository? _backendAuthRepository;
  User? _currentUser;
  bool _isAuthenticated = false;
  String? _token;
  DateTime? _tokenExpiry;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _currentUser?.role == 'ADMIN';
  bool get isTechnician => _currentUser?.role == 'TECHNICIAN';
  String? get token => _token;

  AuthProvider() {
    _loadUserFromStorage();
  }

  void setConfigProvider(ConfigProvider configProvider) {
    if (configProvider.operationMode == 'server') {
      _backendAuthRepository = BackendAuthRepository(
        baseUrl: configProvider.backendBaseUrl,
      );
    }
  }

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('current_user_id');
    final token = prefs.getString('auth_token');
    final operationMode = prefs.getString('operation_mode') ?? 'autonomous';

    if (operationMode == 'server' && token != null) {
      // Mode serveur : vérifier si le token est valide
      _token = token;
      _tokenExpiry = _getTokenExpiry(token);
      if (_isTokenValid) {
        // Charger l'utilisateur depuis le backend
        // Note: nécessite ConfigProvider, sera fait après l'initialisation
      } else {
        // Token expiré, déconnecter
        await logout();
      }
    } else if (userId != null) {
      // Mode autonome : charger depuis SQLite local
      final user = await _userRepository.getUserById(userId);
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        notifyListeners();
      }
    }
  }

  bool get _isTokenValid {
    if (_token == null || _tokenExpiry == null) return false;
    return DateTime.now().isBefore(_tokenExpiry!);
  }

  DateTime? _getTokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final data = json.decode(decoded) as Map<String, dynamic>;

      final exp = data['exp'] as int?;
      if (exp != null) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<String?> getValidToken() async {
    if (_isTokenValid) return _token;
    // Token expiré, déconnecter
    await logout();
    return null;
  }

  Future<bool> login(String email, String password,
      {ConfigProvider? configProvider}) async {
    // Détecter le mode d'opération
    final prefs = await SharedPreferences.getInstance();
    final operationMode = configProvider?.operationMode ??
        prefs.getString('operation_mode') ??
        'autonomous';

    if (operationMode == 'server') {
      // Login via backend FastAPI avec JWT
      if (_backendAuthRepository == null && configProvider != null) {
        _backendAuthRepository = BackendAuthRepository(
          baseUrl: configProvider.backendBaseUrl,
        );
      }

      if (_backendAuthRepository == null) {
        return false;
      }

      final result = await _backendAuthRepository!.login(email, password);
      if (result != null) {
        _token = result['access_token'];
        _tokenExpiry = _getTokenExpiry(_token!);

        // Récupérer les informations de l'utilisateur
        final user = await _backendAuthRepository!.getCurrentUser(_token!);
        if (user != null) {
          _currentUser = user;
          _isAuthenticated = true;

          // Sauvegarder le token et le mode
          await prefs.setString('auth_token', _token!);
          await prefs.setString('operation_mode', 'server');

          notifyListeners();
          return true;
        }
      }
      return false;
    } else {
      // Login local (SQLite)
      final user = await _userRepository.getUserByEmail(email);
      if (user != null && user.password == password && user.isActive) {
        _currentUser = user;
        _isAuthenticated = true;

        await prefs.setInt('current_user_id', user.id!);
        await prefs.setString('operation_mode', 'autonomous');

        notifyListeners();
        return true;
      }
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    _token = null;
    _tokenExpiry = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    await prefs.remove('auth_token');

    notifyListeners();
  }

  Future<bool> createUser(User user) async {
    try {
      await _userRepository.createUser(user);
      return true;
    } catch (e) {
      return false;
    }
  }
}
