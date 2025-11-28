import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class BackendAuthRepository {
  final String baseUrl;

  BackendAuthRepository({required this.baseUrl});

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/login-json');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return {
          'access_token': data['access_token'],
          'token_type': data['token_type'] ?? 'bearer',
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<User?> getCurrentUser(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/users/me');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return User(
          id: data['id'],
          fullName: data['full_name'],
          email: data['email'],
          password: '', // Ne pas stocker le mot de passe
          role: data['role'],
          isActive: data['is_active'] ?? true,
          createdAt: DateTime.parse(data['created_at']),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
