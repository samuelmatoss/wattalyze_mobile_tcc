import "user_model.dart";

// models/auth_response.dart

class AuthResponse {
  final String message;
  final User user;
  final String accessToken;
  final String tokenType;
  final bool? emailVerified;

  AuthResponse({
    required this.message,
    required this.user,
    required this.accessToken,
    required this.tokenType,
    this.emailVerified,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'],
      user: User.fromJson(json['user']),
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      emailVerified: json['email_verified'],
    );
  }
}

class UserResponse {
  final User user;

  UserResponse({required this.user});

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(user: User.fromJson(json['user']));
  }
}

class MessageResponse {
  final String message;

  MessageResponse({required this.message});

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(message: json['message']);
  }
}

class ValidationErrorResponse {
  final String message;
  final Map<String, dynamic> errors;

  ValidationErrorResponse({
    required this.message,
    required this.errors,
  });

  factory ValidationErrorResponse.fromJson(Map<String, dynamic> json) {
    return ValidationErrorResponse(
      message: json['message'],
      errors: json['errors'] ?? {},
    );
  }

  // Helper para obter primeira mensagem de erro de um campo
  String? getFirstError(String field) {
    if (errors.containsKey(field) && errors[field] is List && errors[field].isNotEmpty) {
      return errors[field][0];
    }
    return null;
  }

  // Helper para obter todas as mensagens de erro como string
  String getAllErrors() {
    final List<String> allErrors = [];
    errors.forEach((field, fieldErrors) {
      if (fieldErrors is List) {
        for (var error in fieldErrors) {
          allErrors.add(error.toString());
        }
      }
    });
    return allErrors.join('\n');
  }
}

// Response para atualização de perfil
class ProfileUpdateResponse {
  final String message;
  final User user;

  ProfileUpdateResponse({
    required this.message,
    required this.user,
  });

  factory ProfileUpdateResponse.fromJson(Map<String, dynamic> json) {
    return ProfileUpdateResponse(
      message: json['message'],
      user: User.fromJson(json['user']),
    );
  }
}

// Response para refresh token
class RefreshTokenResponse {
  final String message;
  final String accessToken;
  final String tokenType;
  final User? user;

  RefreshTokenResponse({
    required this.message,
    required this.accessToken,
    required this.tokenType,
    this.user,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      message: json['message'],
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

// Response para reset de senha
class PasswordResetResponse {
  final String message;

  PasswordResetResponse({required this.message});

  factory PasswordResetResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetResponse(message: json['message']);
  }
}

// Response genérico para operações que só retornam mensagem
class ApiResponse {
  final String message;
  final bool success;
  final dynamic data;

  ApiResponse({
    required this.message,
    required this.success,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      message: json['message'] ?? '',
      success: json['success'] ?? true,
      data: json['data'],
    );
  }

  factory ApiResponse.success(String message, {dynamic data}) {
    return ApiResponse(
      message: message,
      success: true,
      data: data,
    );
  }

  factory ApiResponse.error(String message, {dynamic data}) {
    return ApiResponse(
      message: message,
      success: false,
      data: data,
    );
  }
}