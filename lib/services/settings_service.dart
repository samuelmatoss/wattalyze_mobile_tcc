import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/auth_response.dart';

class SettingsService {
  static const String baseUrl = 'http://192.168.0.101:8000/api';

  // MÃ©todo auxiliar para fazer requisiÃ§Ãµes autenticadas com token
  static Future<http.Response> _authenticatedRequest(
    String endpoint, {
    required String token,
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    switch (method) {
      case 'GET':
        return await http.get(url, headers: headers);
      case 'POST':
        return await http.post(
          url,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'PUT':
        return await http.put(
          url,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'DELETE':
        return await http.delete(url, headers: headers);
      default:
        throw Exception('Método HTTP nÃ£o suportado: $method');
    }
  }

  // Buscar informaÃ§Ãµes do usuÃ¡rio
  static Future<User> getUserProfile(String token) async {
    try {
      final response = await _authenticatedRequest(
        'user', // Usando o endpoint correto do AuthService
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['user']);
      } else {
        throw Exception('Erro ao buscar perfil: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na comunicação com o servidor: $e');
    }
  }

  // Atualizar perfil do usuÃ¡rio
  static Future<User> updateProfile(String token, UpdateProfileRequest request) async {
    try {
      final response = await _authenticatedRequest(
        'user', // Usando o endpoint correto do AuthService
        token: token,
        method: 'PUT',
        body: request.toJson(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['user']);
      } else {
        final error = json.decode(response.body);
        if (response.statusCode == 422) {
          // Validation errors
          final errors = error['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first as List;
          throw Exception(firstError.first);
        }
        throw Exception('Erro ao atualizar perfil: ${error['message'] ?? response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro na comunicação com o servidor: $e');
    }
  }

  // Alterar senha do usuÃ¡rio
  static Future<void> changePassword(String token, ChangePasswordRequest request) async {
    try {
      final response = await _authenticatedRequest(
        'user', // Usando o mesmo endpoint, mas com dados de senha
        token: token,
        method: 'PUT',
        body: request.toJson(),
      );

      if (response.statusCode == 200) {
        // Success
        return;
      } else {
        final error = json.decode(response.body);
        if (response.statusCode == 422) {
          // Validation errors
          final errors = error['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first as List;
          throw Exception(firstError.first);
        }
        throw Exception('Erro ao alterar senha: ${error['message'] ?? response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro na comunicação com o servidor: $e');
    }
  }

  // ValidaÃ§Ãµes locais
  static String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email obrigatório';
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Email inválido';
    }

    return null;
  }

  static String? validateName(String name) {
    if (name.isEmpty) {
      return 'Nome obrigatório';
    }

    if (name.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }

    if (name.trim().length > 255) {
      return 'Nome deve ter no máximo 255 caracteres';
    }

    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Senha obrigatória';
    }

    if (password.length < 8) {
      return 'Senha deve ter pelo menos 8 caracteres';
    }

    return null;
  }

  static String? validatePasswordConfirmation(String password, String confirmation) {
    if (confirmation.isEmpty) {
      return 'Confirmação de senha  obrigatória';
    }

    if (password != confirmation) {
      return 'Senhas não coincidem';
    }

    return null;
  }

  static String? validateCurrentPassword(String currentPassword) {
    if (currentPassword.isEmpty) {
      return 'Senha atual  obrigatória';
    }

    return null;
  }

  // Helper para formatar datas
  static String formatAccountAge(DateTime? createdAt) {
    if (createdAt == null) return 'Data não disponível';

    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'ano' : 'anos'}';
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'mês' : 'meses'}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'dia' : 'dias'}';
    } else {
      return 'Hoje';
    }
  }

  // Verificar forÃ§a da senha
  static int getPasswordStrength(String password) {
    int strength = 0;

    // Comprimento
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // Caracteres
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    return strength;
  }

  static String getPasswordStrengthText(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Muito fraca';
      case 2:
      case 3:
        return 'Fraca';
      case 4:
        return 'Média';
      case 5:
        return 'Forte';
      case 6:
        return 'Muito forte';
      default:
        return 'Fraca';
    }
  }

  static Color getPasswordStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return const Color(0xFFE74C3C);
      case 2:
      case 3:
        return const Color(0xFFF39C12);
      case 4:
        return const Color(0xFFE67E22);
      case 5:
      case 6:
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFFE74C3C);
    }
  }
}

// Classes para requests
class UpdateProfileRequest {
  final String name;
  final String email;

  UpdateProfileRequest({
    required this.name,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
    };
  }
}

class ChangePasswordRequest {
  final String currentPassword;
  final String password;
  final String passwordConfirmation;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.password,
    required this.passwordConfirmation,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
  }
}