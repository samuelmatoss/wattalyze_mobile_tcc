import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.0.101:8000/api';
  static const String _tokenKey = 'auth_token';

  // Salvar token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Recuperar token
  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> isTokenValid() async {
    try {
      final token = await getSavedToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Remover token
  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getSavedToken();
    return token != null;
  }

  // Login
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(json.decode(response.body));
      await _saveToken(authResponse.accessToken);
      return authResponse;
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Erro no login');
    }
  }

  // Registro
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode == 201) {
      final authResponse = AuthResponse.fromJson(json.decode(response.body));
      await _saveToken(authResponse.accessToken);
      return authResponse;
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Erro no registro');
    }
  }

  // Logout
  Future<MessageResponse> logout() async {
    final token = await getSavedToken();
    if (token == null) throw Exception('Token não encontrado');

    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      await _removeToken();
      return MessageResponse.fromJson(json.decode(response.body));
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Erro no logout');
    }
  }

  // Obter perfil do usuário
  Future<UserResponse> getProfile() async {
    final token = await getSavedToken();
    if (token == null) throw Exception('Token não encontrado');

    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return UserResponse.fromJson(json.decode(response.body));
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Erro ao buscar perfil');
    }
  }

  // Atualizar perfil do usuário
  Future<ProfileUpdateResponse> updateProfile({
    String? name,
    String? email,
    String? password,
    String? passwordConfirmation,
  }) async {
    final token = await getSavedToken();
    if (token == null) throw Exception('Token não encontrado');

    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (password != null) {
      body['password'] = password;
      body['password_confirmation'] = passwordConfirmation;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return ProfileUpdateResponse.fromJson(json.decode(response.body));
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Erro ao atualizar perfil');
    }
  }

  // Enviar email de recuperação de senha
  Future<MessageResponse> sendPasswordResetEmail({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password/email'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      return MessageResponse.fromJson(json.decode(response.body));
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Erro ao enviar email');
    }
  }

  // Resetar senha com token
  Future<MessageResponse> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password/reset'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'token': token,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode == 200) {
      return MessageResponse.fromJson(json.decode(response.body));
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Erro ao resetar senha');
    }
  }

  // Verificar email
  Future<MessageResponse> verifyEmail({
    required String id,
    required String hash,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/email/verify/$id/$hash'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return MessageResponse.fromJson(json.decode(response.body));
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Erro na verificação');
    }
  }

  // Reenviar email de verificação
  Future<MessageResponse> resendVerificationEmail() async {
    final token = await getSavedToken();
    if (token == null) throw Exception('Token não encontrado');

    final response = await http.post(
      Uri.parse('$baseUrl/email/verification-notification'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return MessageResponse.fromJson(json.decode(response.body));
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Erro ao reenviar email');
    }
  }

  // Renovar token
  Future<RefreshTokenResponse> refreshToken() async {
    final token = await getSavedToken();
    if (token == null) throw Exception('Token não encontrado');

    final response = await http.post(
      Uri.parse('$baseUrl/refresh'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final refreshResponse =
          RefreshTokenResponse.fromJson(json.decode(response.body));
      await _saveToken(refreshResponse.accessToken);
      return refreshResponse;
    } else {
      await _removeToken();
      throw Exception('Token expirado');
    }
  }

  // Verificar se o email do usuário atual foi verificado
  Future<bool> checkEmailVerified() async {
    try {
      final userResponse = await getProfile();
      return userResponse.user.emailVerifiedAt != null;
    } catch (e) {
      return false;
    }
  }
}
