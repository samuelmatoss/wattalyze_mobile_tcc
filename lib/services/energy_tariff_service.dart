// services/energy_tariff_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/energy_tariff_model.dart';

class EnergyTariffService {
  static const String baseUrl = 'http://sua-api.com/api'; // Altere para sua URL

  final String token;

  EnergyTariffService(this.token);

  // Headers comuns
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // Index: Listar todas as tarifas (com paginação)
  Future<TariffPaginationResponse> getTariffs({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/energy-tariffs?page=$page'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return TariffPaginationResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Falha ao carregar tarifas: ${response.statusCode}');
    }
  }

  // Store: Criar uma nova tarifa
  Future<TariffSuccessResponse> storeTariff(EnergyTariff tariff) async {
    final response = await http.post(
      Uri.parse('$baseUrl/energy-tariffs'),
      headers: _headers,
      body: json.encode(tariff.toJson()),
    );

    if (response.statusCode == 201) {
      return TariffSuccessResponse.fromJson(json.decode(response.body));
    } else if (response.statusCode == 422) {
      final errorResponse =
          ValidationErrorResponse.fromJson(json.decode(response.body));
      throw Exception('Erro de validação: ${errorResponse.errors}');
    } else {
      throw Exception('Falha ao criar tarifa: ${response.statusCode}');
    }
  }

  // Show: Obter uma tarifa específica
  Future<EnergyTariff> getTariff(int tariffId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/energy-tariffs/$tariffId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return EnergyTariff.fromJson(data['tariff']);
    } else if (response.statusCode == 403) {
      throw Exception('Acesso não autorizado');
    } else {
      throw Exception('Falha ao carregar tarifa: ${response.statusCode}');
    }
  }

  // Update: Atualizar uma tarifa
  Future<TariffSuccessResponse> updateTariff(
      int tariffId, EnergyTariff tariff) async {
    final response = await http.put(
      Uri.parse('$baseUrl/energy-tariffs/$tariffId'),
      headers: _headers,
      body: json.encode(tariff.toJson()),
    );

    if (response.statusCode == 200) {
      return TariffSuccessResponse.fromJson(json.decode(response.body));
    } else if (response.statusCode == 422) {
      final errorResponse =
          ValidationErrorResponse.fromJson(json.decode(response.body));
      throw Exception('Erro de validação: ${errorResponse.errors}');
    } else if (response.statusCode == 403) {
      throw Exception('Acesso não autorizado');
    } else {
      throw Exception('Falha ao atualizar tarifa: ${response.statusCode}');
    }
  }

  // Destroy: Excluir uma tarifa
  Future<void> deleteTariff(int tariffId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/energy-tariffs/$tariffId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 403) {
      throw Exception('Acesso não autorizado');
    } else {
      throw Exception('Falha ao excluir tarifa: ${response.statusCode}');
    }
  }

  // Método auxiliar para criar uma tarifa com dados mínimos
  static EnergyTariff createMinimal({
    required String name,
    required double bracket1Min,
    required double bracket1Rate,
    int? id,
    bool isActive = true,
    int userId = 0,
  }) {
    return EnergyTariff(
      id: id ?? 0,
      name: name,
      bracket1Min: bracket1Min,
      bracket1Rate: bracket1Rate,
      isActive: isActive,
      userId: userId,
    );
  }

  // Método para obter tarifas ativas
  Future<List<EnergyTariff>> getActiveTariffs() async {
    final response = await getTariffs();
    return response.tariffs
        .where((tariff) => tariff.isActive && tariff.isValid)
        .toList();
  }

  // Método para calcular custo usando uma tarifa específica
  Future<double> calculateCostWithTariff(int tariffId, double consumption) async {
    try {
      final tariff = await getTariff(tariffId);
      return tariff.calculateCost(consumption);
    } catch (e) {
      throw Exception('Erro ao calcular custo: $e');
    }
  }
}
