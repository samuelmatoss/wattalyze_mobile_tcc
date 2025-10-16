import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alert.dart';
import '../models/alert_rule.dart';
import '../models/device_model.dart';
import '../models/environment_model.dart';

class AlertService {
  static const String baseUrl = 'http://192.168.0.101:8000/api';

  // Método auxiliar para obter o token de autenticação
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Método auxiliar para fazer requisições autenticadas
  static Future<http.Response> _authenticatedRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    final url = Uri.parse('$baseUrl/$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    switch (method) {
      case 'GET':
        return await http.get(url, headers: headers);
      case 'POST':
        return await http.post(url, headers: headers, body: json.encode(body));
      case 'PUT':
        return await http.put(url, headers: headers, body: json.encode(body));
      case 'DELETE':
        return await http.delete(url, headers: headers);
      default:
        throw Exception('Método HTTP não suportado');
    }
  }

  // Obter regras de alerta
  static Future<Map<String, dynamic>> getRules() async {
    final response = await _authenticatedRequest('alert-rules');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'rules': (data['rules'] as List).map((rule) => AlertRule.fromJson(rule)).toList(),
        'devices': (data['devices'] as List).map((device) => Device.fromJson(device)).toList(),
        'environments': (data['environments'] as List).map((env) => Environment.fromJson(env)).toList(),
      };
    } else {
      throw Exception('Falha ao carregar regras: ${response.statusCode}');
    }
  }

  // Criar uma nova regra
  static Future<AlertRule> createRule(Map<String, dynamic> ruleData) async {
    final response = await _authenticatedRequest(
      'alert-rules',
      method: 'POST',
      body: ruleData,
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return AlertRule.fromJson(data['rule']);
    } else {
      throw Exception('Falha ao criar regra: ${response.statusCode}');
    }
  }

  // Obter alertas ativos
  static Future<List<Alert>> getActiveAlerts() async {
    final response = await _authenticatedRequest('alerts/active');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['alerts']['data'] as List).map((alert) => Alert.fromJson(alert)).toList();
    } else {
      throw Exception('Falha ao carregar alertas ativos: ${response.statusCode}');
    }
  }

  // Obter histórico de alertas
  static Future<List<Alert>> getAlertHistory() async {
    final response = await _authenticatedRequest('alerts/history');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['alerts']['data'] as List).map((alert) => Alert.fromJson(alert)).toList();
    } else {
      throw Exception('Falha ao carregar histórico de alertas: ${response.statusCode}');
    }
  }

  // Marcar alerta como resolvido
  static Future<void> markAlertAsResolved(int alertId) async {
    final response = await _authenticatedRequest('alerts/$alertId/resolved', method: 'PUT');
    if (response.statusCode != 200) {
      throw Exception('Falha ao marcar alerta como resolvido: ${response.statusCode}');
    }
  }

  // Obter uma regra para edição
  static Future<Map<String, dynamic>> getRuleForEdit(int ruleId) async {
    final response = await _authenticatedRequest('alert-rules/$ruleId/edit');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'rule': AlertRule.fromJson(data['rule']),
        'devices': (data['devices'] as List).map((device) => Device.fromJson(device)).toList(),
        'environments': (data['environments'] as List).map((env) => Environment.fromJson(env)).toList(),
      };
    } else {
      throw Exception('Falha ao carregar regra: ${response.statusCode}');
    }
  }

  // Atualizar uma regra
  static Future<void> updateRule(int ruleId, Map<String, dynamic> ruleData) async {
    final response = await _authenticatedRequest(
      'alert-rules/$ruleId',
      method: 'PUT',
      body: ruleData,
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao atualizar regra: ${response.statusCode}');
    }
  }

  // Excluir uma regra
  static Future<void> deleteRule(int ruleId) async {
    final response = await _authenticatedRequest('alert-rules/$ruleId', method: 'DELETE');
    if (response.statusCode != 200) {
      throw Exception('Falha ao excluir regra: ${response.statusCode}');
    }
  }

  // Alternar status da regra
  static Future<bool> toggleRule(int ruleId) async {
    final response = await _authenticatedRequest('alert-rules/$ruleId/toggle', method: 'PUT');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['is_active'];
    } else {
      throw Exception('Falha ao alternar regra: ${response.statusCode}');
    }
  }

  // Marcar alerta como lido
  static Future<void> acknowledgeAlert(int alertId) async {
    final response = await _authenticatedRequest('alerts/$alertId/acknowledge', method: 'PUT');
    if (response.statusCode != 200) {
      throw Exception('Falha ao marcar alerta como lido: ${response.statusCode}');
    }
  }

  // Resolver alertas em massa
  static Future<void> bulkResolveAlerts(List<int> alertIds) async {
    final response = await _authenticatedRequest(
      'alerts/bulk-resolve',
      method: 'POST',
      body: {'alert_ids': alertIds},
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao resolver alertas em massa: ${response.statusCode}');
    }
  }
}
