import 'device_model.dart';
import 'shared_models.dart'; 

class Environment {
  final int id;
  final String name;
  final String type;
  final String? description;
  final double? sizeSqm;
  final int? occupancy;
  final String? voltageStandard;
  final String? tariffType;
  final String? energyProvider;
  final String? installationDate;
  final bool isDefault;
  final int userId;
  final List<Device>? devices;

  Environment({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.sizeSqm,
    this.occupancy,
    this.voltageStandard,
    this.tariffType,
    this.energyProvider,
    this.installationDate,
    required this.isDefault,
    required this.userId,
    this.devices,
  });

  factory Environment.fromJson(Map<String, dynamic> json) {
    return Environment(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      description: json['description'],
      sizeSqm: json['size_sqm'] != null ? double.tryParse(json['size_sqm'].toString()) : null,
      occupancy: json['occupancy'],
      voltageStandard: json['voltage_standard'],
      tariffType: json['tariff_type'],
      energyProvider: json['energy_provider'],
      installationDate: json['installation_date'],
      isDefault: json['is_default'] ?? false,
      userId: json['user_id'] ?? 0,
      devices: json['devices'] != null 
          ? List<Device>.from(json['devices'].map((x) => Device.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'type': type,
      'is_default': isDefault,
    };

    if (id > 0) data['id'] = id;
    if (description != null) data['description'] = description;
    if (sizeSqm != null) data['size_sqm'] = sizeSqm;
    if (occupancy != null) data['occupancy'] = occupancy;
    if (voltageStandard != null) data['voltage_standard'] = voltageStandard;
    if (tariffType != null) data['tariff_type'] = tariffType;
    if (energyProvider != null) data['energy_provider'] = energyProvider;
    if (installationDate != null) data['installation_date'] = installationDate;
    if (userId > 0) data['user_id'] = userId;

    return data;
  }

  Environment copyWith({
    int? id,
    String? name,
    String? type,
    String? description,
    double? sizeSqm,
    int? occupancy,
    String? voltageStandard,
    String? tariffType,
    String? energyProvider,
    String? installationDate,
    bool? isDefault,
    int? userId,
    List<Device>? devices,
  }) {
    return Environment(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      sizeSqm: sizeSqm ?? this.sizeSqm,
      occupancy: occupancy ?? this.occupancy,
      voltageStandard: voltageStandard ?? this.voltageStandard,
      tariffType: tariffType ?? this.tariffType,
      energyProvider: energyProvider ?? this.energyProvider,
      installationDate: installationDate ?? this.installationDate,
      isDefault: isDefault ?? this.isDefault,
      userId: userId ?? this.userId,
      devices: devices ?? this.devices,
    );
  }
}

// Modelo para a resposta da listagem de ambientes
class EnvironmentIndexResponse {
  final List<Environment> environments;
  final Map<String, ConsumptionData> environmentDailyConsumption;

  EnvironmentIndexResponse({
    required this.environments,
    required this.environmentDailyConsumption,
  });

  factory EnvironmentIndexResponse.fromJson(Map<String, dynamic> json) {
    final consumptionMap = <String, ConsumptionData>{};
    
    if (json['environment_daily_consumption'] != null) {
      final rawConsumption = json['environment_daily_consumption'];
      
      if (rawConsumption is Map<String, dynamic>) {
        rawConsumption.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            // Tentar formato novo primeiro
            try {
              consumptionMap[key] = ConsumptionData.fromJson(value);
            } catch (e) {
              // Se falhar, tentar formato antigo
              try {
                consumptionMap[key] = ConsumptionData.fromEnvironmentFormat(value);
              } catch (e2) {
                print('Erro ao processar consumption para environment $key: $e2');
              }
            }
          }
        });
      }
    }

    return EnvironmentIndexResponse(
      environments: json['environments'] != null
          ? List<Environment>.from(json['environments'].map((x) => Environment.fromJson(x)))
          : [],
      environmentDailyConsumption: consumptionMap,
    );
  }
}

// Modelo para a resposta de um único ambiente
class EnvironmentShowResponse {
  final Environment environment;

  EnvironmentShowResponse({required this.environment});

  factory EnvironmentShowResponse.fromJson(Map<String, dynamic> json) {
    return EnvironmentShowResponse(
      environment: Environment.fromJson(json['environment']),
    );
  }
}

// Modelo para a resposta de consumo de um ambiente
class EnvironmentConsumptionResponse {
  final Environment environment;
  final ConsumptionData consumptionData;

  EnvironmentConsumptionResponse({
    required this.environment,
    required this.consumptionData,
  });

  factory EnvironmentConsumptionResponse.fromJson(Map<String, dynamic> json) {
    ConsumptionData consumption;
    
    // Tentar formato novo
    try {
      consumption = ConsumptionData.fromJson(json['consumption_data']);
    } catch (e) {
      // Fallback para formato antigo
      try {
        consumption = ConsumptionData.fromEnvironmentFormat(json['consumption_data']);
      } catch (e2) {
        print('Erro ao processar consumption data: $e2');
        consumption = ConsumptionData(measurements: {});
      }
    }

    return EnvironmentConsumptionResponse(
      environment: Environment.fromJson(json['environment']),
      consumptionData: consumption,
    );
  }
}

// Modelo para resposta básica de sucesso
class EnvironmentSuccessResponse {
  final String message;
  final Environment environment;

  EnvironmentSuccessResponse({
    required this.message,
    required this.environment,
  });

  factory EnvironmentSuccessResponse.fromJson(Map<String, dynamic> json) {
    return EnvironmentSuccessResponse(
      message: json['message'] ?? 'Sucesso',
      environment: Environment.fromJson(json['environment']),
    );
  }
}