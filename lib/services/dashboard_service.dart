import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_response.dart';
import '../models/shared_models.dart';

class DashboardService {
  static const String baseUrl = 'http://192.168.0.101:8000/api';

  final String token;

  DashboardService(this.token);

  /// Busca dados completos do dashboard
  Future<DashboardResponse> getDashboardData() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/dashboard'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Log para debug (remover em produção)
        print('Dashboard API Response: ${jsonData.toString()}');

        return DashboardResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido ou expirado. Faça login novamente.');
      } else if (response.statusCode == 403) {
        throw Exception('Acesso negado. Verifique suas permissões.');
      } else if (response.statusCode >= 500) {
        throw Exception('Erro interno do servidor. Tente novamente mais tarde.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Erro ao carregar dados do dashboard');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Timeout da requisição. Verifique sua conexão.');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Erro de conexão. Verifique sua internet.');
      } else {
        rethrow; // Re-throw para manter a mensagem original
      }
    }
  }

  /// Busca apenas dispositivos do usuário
  Future<List<Device>> getUserDevices() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/devices'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final devices = (jsonData['data'] as List)
            .map((device) => Device.fromJson(device))
            .toList();
        return devices;
      } else {
        throw Exception('Erro ao carregar dispositivos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Falha ao buscar dispositivos: $e');
    }
  }

  /// Busca apenas alertas do usuário
  Future<List<Alert>> getUserAlerts() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/alerts'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final alerts = (jsonData['data'] as List)
            .map((alert) => Alert.fromJson(alert))
            .toList();
        return alerts;
      } else {
        throw Exception('Erro ao carregar alertas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Falha ao buscar alertas: $e');
    }
  }

  /// Processa dados de consumo diário da API
  /// Agora lida corretamente com lista vazia ou Map
  Map<String, Map<String, List<DailyMeasurement>>> parseDailyConsumption(
      dynamic rawData) {
    final result = <String, Map<String, List<DailyMeasurement>>>{};

    // Se for lista (vazia ou não), retorna mapa vazio
    if (rawData is! Map<String, dynamic>) {
      print('Daily consumption não é um Map, retornando vazio');
      return result;
    }

    // Se for Map, processa normalmente
    rawData.forEach((deviceId, deviceData) {
      final measurements = <String, List<DailyMeasurement>>{};

      if (deviceData is Map<String, dynamic>) {
        deviceData.forEach((type, data) {
          if (data is List) {
            measurements[type] = data
                .map(
                    (item) => DailyMeasurement.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        });
      }

      result[deviceId] = measurements;
    });

    return result;
  }

  /// Agrega dados por tipo (energy, temperature, humidity)
  Map<String, double> aggregateDataByType(
    Map<String, dynamic> dailyConsumption,
    String type,
    List<Device> devices,
  ) {
    final aggregated = <String, double>{};

    // Verificação adicional se dailyConsumption está vazio
    if (dailyConsumption.isEmpty) {
      print('Daily consumption vazio para tipo: $type');
      return aggregated;
    }

    dailyConsumption.forEach((deviceId, deviceData) {
      if (deviceData is Map<String, dynamic> && deviceData.containsKey(type)) {
        final data = deviceData[type] as List;

        for (var measurement in data) {
          final date = measurement['date'] as String;
          final value = (measurement['value'] as num).toDouble();

          // Para energy, soma os valores. Para temperature/humidity, faz média
          if (type == 'energy') {
            aggregated[date] = (aggregated[date] ?? 0) + value;
          } else {
            // Para temperatura e umidade, pegamos o último valor (mais recente)
            aggregated[date] = value;
          }
        }
      }
    });

    return aggregated;
  }

  /// Formata dados para o gráfico
  List<ChartDataPoint> formatChartData(Map<String, double> aggregatedData) {
    final sortedEntries = aggregatedData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sortedEntries.map((entry) {
      final dateParts = entry.key.split('-');
      final formattedDate = '${dateParts[2]}/${dateParts[1]}';

      return ChartDataPoint(
        label: formattedDate,
        value: entry.value,
        date: entry.key,
      );
    }).toList();
  }

  /// Verifica conectividade com a API
  Future<bool> checkApiConnectivity() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Classe auxiliar para dados do gráfico
class ChartDataPoint {
  final String label;
  final double value;
  final String date;

  ChartDataPoint({
    required this.label,
    required this.value,
    required this.date,
  });
}
