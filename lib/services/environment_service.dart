import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/environment_model.dart';

class EnvironmentService {
  static const String baseUrl = 'http://192.168.0.101:8000/api'; // Sua URL da API
  final String token;

  EnvironmentService(this.token);

  // Headers comuns
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  // Index: Listar todos os ambientes com dados de consumo
  Future<EnvironmentIndexResponse> getEnvironments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/environments'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EnvironmentIndexResponse.fromJson(data);
      } else {
        throw Exception('Falha ao carregar ambientes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Store: Criar um novo ambiente
  Future<EnvironmentSuccessResponse> storeEnvironment(Environment environment) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/environments'),
        headers: _headers,
        body: json.encode(environment.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return EnvironmentSuccessResponse.fromJson(data);
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        final errors = data['errors'];
        throw Exception('Erro de validação: $errors');
      } else {
        throw Exception('Falha ao criar ambiente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao criar ambiente: $e');
    }
  }

  // Show: Obter um ambiente específico
  Future<EnvironmentShowResponse> getEnvironment(int environmentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/environments/$environmentId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EnvironmentShowResponse.fromJson(data);
      } else if (response.statusCode == 403) {
        throw Exception('Acesso não autorizado');
      } else {
        throw Exception('Falha ao carregar ambiente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar ambiente: $e');
    }
  }

  // Update: Atualizar um ambiente
  Future<EnvironmentSuccessResponse> updateEnvironment(int environmentId, Environment environment) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/environments/$environmentId'),
        headers: _headers,
        body: json.encode(environment.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EnvironmentSuccessResponse.fromJson(data);
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        final errors = data['errors'];
        throw Exception('Erro de validação: $errors');
      } else if (response.statusCode == 403) {
        throw Exception('Acesso não autorizado');
      } else {
        throw Exception('Falha ao atualizar ambiente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar ambiente: $e');
    }
  }

  // Consumption: Obter dados de consumo de um ambiente
  Future<EnvironmentConsumptionResponse> getConsumption(int environmentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/environments/$environmentId/consumption'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EnvironmentConsumptionResponse.fromJson(data);
      } else if (response.statusCode == 403) {
        throw Exception('Acesso não autorizado');
      } else {
        throw Exception('Falha ao carregar consumo do ambiente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar consumo: $e');
    }
  }

  // Destroy: Excluir um ambiente
  Future<void> deleteEnvironment(int environmentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/environments/$environmentId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 403) {
        throw Exception('Acesso não autorizado');
      } else {
        throw Exception('Falha ao excluir ambiente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao excluir ambiente: $e');
    }
  }

  // Helper method para criar um ambiente com dados mínimos
  static Environment createMinimal({
    required String name,
    required String type,
    int? id,
    bool isDefault = false,
    int userId = 0,
  }) {
    return Environment(
      id: id ?? 0,
      name: name,
      type: type,
      isDefault: isDefault,
      userId: userId,
    );
  }
}
