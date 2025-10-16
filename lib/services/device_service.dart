import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device_model.dart';

class DeviceService {
  static const String baseUrl =
      'http://192.168.0.101:8000/api'; // Sua URL da API
  final String token;

  DeviceService(this.token);

  // Cabeçalhos comuns
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  // Index: Listar todos os dispositivos com dados em tempo real
  Future<DeviceIndexResponse> getDevices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final dynamic rawData = json.decode(response.body);

        // Conversão segura com verificação de tipo
        Map<String, dynamic> data;

        if (rawData is List<dynamic>) {
          // Caso o retorno seja uma lista, converte para o formato esperado
          data = {
            'devices': rawData.cast<Map<String, dynamic>>(),
            'environments': <Map<String, dynamic>>[],
            'device_types': <Map<String, dynamic>>[],
            'influx_data': <String, dynamic>{},
            'daily_consumption': <String, dynamic>{},
          };
        } else if (rawData is Map<String, dynamic>) {
          data = rawData;
        } else {
          throw Exception(
              'Formato de resposta inválido: esperado Map ou List, recebido ${rawData.runtimeType}');
        }

        return DeviceIndexResponse.fromJson(data);
      } else {
        throw Exception(
            'Falha ao carregar dispositivos: ${response.statusCode}');
      }
    } catch (e) {
      print('Detalhes do erro: $e');
      throw Exception('Erro de conexão: $e');
    }
  }

  // Create: Obter dados para formulário de criação
  Future<DeviceFormResponse> getFormData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices/create'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeviceFormResponse.fromJson(data);
      } else {
        throw Exception(
            'Falha ao carregar dados do formulário: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar dados do formulário: $e');
    }
  }

  // Store: Criar um novo dispositivo
  Future<DeviceSuccessResponse> storeDevice(Device device) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/devices'),
        headers: _headers,
        body: json.encode(device.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return DeviceSuccessResponse.fromJson(data);
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        final errors = data['errors'];
        throw Exception('Erro de validação: $errors');
      } else {
        throw Exception('Falha ao criar dispositivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao criar dispositivo: $e');
    }
  }

  // Show: Obter um dispositivo específico com histórico de consumo
  Future<DeviceShowResponse> getDevice(int deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices/$deviceId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeviceShowResponse.fromJson(data);
      } else if (response.statusCode == 403) {
        throw Exception('Acesso não autorizado');
      } else {
        throw Exception(
            'Falha ao carregar dispositivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar dispositivo: $e');
    }
  }

  // Edit: Obter dados para formulário de edição
  Future<DeviceFormResponse> getEditData(int deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices/$deviceId/edit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeviceFormResponse.fromJson(data);
      } else if (response.statusCode == 403) {
        throw Exception('Acesso não autorizado');
      } else {
        throw Exception(
            'Falha ao carregar dados de edição: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar dados de edição: $e');
    }
  }

  // Update: Atualizar um dispositivo
  Future<DeviceSuccessResponse> updateDevice(
      int deviceId, Device device) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/devices/$deviceId'),
        headers: _headers,
        body: json.encode(device.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeviceSuccessResponse.fromJson(data);
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        final errors = data['errors'];
        throw Exception('Erro de validação: $errors');
      } else if (response.statusCode == 403) {
        throw Exception('Acesso não autorizado');
      } else {
        throw Exception(
            'Falha ao atualizar dispositivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar dispositivo: $e');
    }
  }

  // Diagnostics: Obter dados de diagnóstico do dispositivo
  Future<DeviceDiagnosticsResponse> getDiagnostics(int deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices/$deviceId/diagnostics'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeviceDiagnosticsResponse.fromJson(data);
      } else if (response.statusCode == 403) {
        throw Exception('Acesso não autorizado');
      } else {
        throw Exception(
            'Falha ao carregar diagnósticos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar diagnósticos: $e');
    }
  }

  // Debug: Obter dados de depuração do InfluxDB
  Future<DeviceDebugResponse> getDebugData(int deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices/$deviceId/debug'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeviceDebugResponse.fromJson(data);
      } else if (response.statusCode == 403) {
        throw Exception('Acesso não autorizado');
      } else {
        throw Exception(
            'Falha ao carregar dados de depuração: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar dados de depuração: $e');
    }
  }

  // Destroy: Excluir um dispositivo
  Future<void> deleteDevice(int deviceId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/devices/$deviceId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 403) {
        throw Exception('Acesso não autorizado');
      } else {
        throw Exception('Falha ao excluir dispositivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao excluir dispositivo: $e');
    }
  }

  // Método auxiliar para criar um dispositivo com dados mínimos
  static Device createMinimal({
    required String name,
    required String macAddress,
    required String status,
    int? id,
    int? deviceTypeId,
    int? environmentId,
    int userId = 0,
  }) {
    return Device(
      id: id ?? 0,
      name: name,
      macAddress: macAddress,
      status: status,
      deviceTypeId: deviceTypeId,
      environmentId: environmentId,
      userId: userId,
    );
  }

  // Método auxiliar para verificar se o MAC Address é válido
  static bool isValidMacAddress(String macAddress) {
    // Formato esperado: XX:XX:XX:XX:XX:XX
    final macRegex = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    return macRegex.hasMatch(macAddress);
  }

  // Método auxiliar para formatar o MAC Address
  static String formatMacAddress(String macAddress) {
    // Remove caracteres especiais e converte para maiúsculas
    final cleaned =
        macAddress.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();

    if (cleaned.length != 12) {
      throw ArgumentError('O MAC Address deve ter 12 caracteres hexadecimais');
    }

    // Adiciona os dois pontos
    return cleaned
        .replaceAllMapped(
          RegExp(r'(.{2})'),
          (match) => '${match.group(1)}:',
        )
        .substring(0, 17); // Remove o último ':'
  }

  // Método auxiliar para obter status disponíveis
  static List<String> getAvailableStatuses() {
    return ['online', 'offline', 'maintenance'];
  }

  // Método auxiliar para validar campos obrigatórios
  static Map<String, String> validateDevice(Device device) {
    final Map<String, String> errors = {};

    if (device.name.trim().isEmpty) {
      errors['name'] = 'Nome é obrigatório';
    }

    if (device.macAddress.trim().isEmpty) {
      errors['mac_address'] = 'Endereço MAC é obrigatório';
    } else if (!isValidMacAddress(device.macAddress)) {
      errors['mac_address'] =
          'Formato do endereço MAC inválido (XX:XX:XX:XX:XX:XX)';
    }

    if (!getAvailableStatuses().contains(device.status)) {
      errors['status'] = 'Status deve ser: online, offline ou maintenance';
    }

    if (device.ratedPower != null && device.ratedPower! < 0) {
      errors['rated_power'] = 'Potência nominal não pode ser negativa';
    }

    if (device.ratedVoltage != null && device.ratedVoltage! < 0) {
      errors['rated_voltage'] = 'Tensão nominal não pode ser negativa';
    }

    return errors;
  }

  // Método para obter dispositivos por ambiente
  Future<DeviceIndexResponse> getDevicesByEnvironment(int environmentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices?environment_id=$environmentId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeviceIndexResponse.fromJson(data);
      } else {
        throw Exception(
            'Falha ao carregar dispositivos do ambiente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar dispositivos do ambiente: $e');
    }
  }

  // Método para obter dispositivos por tipo
  Future<DeviceIndexResponse> getDevicesByType(int deviceTypeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices?device_type_id=$deviceTypeId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeviceIndexResponse.fromJson(data);
      } else {
        throw Exception(
            'Falha ao carregar dispositivos por tipo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar dispositivos por tipo: $e');
    }
  }

  // Método para obter dispositivos por status
  Future<DeviceIndexResponse> getDevicesByStatus(String status) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices?status=$status'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeviceIndexResponse.fromJson(data);
      } else {
        throw Exception(
            'Falha ao carregar dispositivos por status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar dispositivos por status: $e');
    }
  }
}
