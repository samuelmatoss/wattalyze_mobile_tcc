import 'shared_models.dart'; // Importar o modelo unificado

// Modelo para DeviceType
class DeviceType {
  final int id;
  final String name;

  DeviceType({
    required this.id,
    required this.name,
  });

  factory DeviceType.fromJson(Map<String, dynamic> json) {
    return DeviceType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

// Modelo para Environment (simplificado para relacionamento)
class DeviceEnvironment {
  final int id;
  final String name;

  DeviceEnvironment({
    required this.id,
    required this.name,
  });

  factory DeviceEnvironment.fromJson(Map<String, dynamic> json) {
    return DeviceEnvironment(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

// Modelo principal do Device
class Device {
  final int id;
  final String name;
  final String macAddress;
  final String? serialNumber;
  final String? model;
  final String? manufacturer;
  final String? firmwareVersion;
  final String status; // online, offline, maintenance
  final String? location;
  final String? installationDate;
  final double? ratedPower;
  final double? ratedVoltage;
  final int? deviceTypeId;
  final int? environmentId;
  final int userId;
  final DeviceType? deviceType;
  final DeviceEnvironment? environment;

  Device({
    required this.id,
    required this.name,
    required this.macAddress,
    this.serialNumber,
    this.model,
    this.manufacturer,
    this.firmwareVersion,
    required this.status,
    this.location,
    this.installationDate,
    this.ratedPower,
    this.ratedVoltage,
    this.deviceTypeId,
    this.environmentId,
    required this.userId,
    this.deviceType,
    this.environment,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      macAddress: json['mac_address'] ?? '',
      serialNumber: json['serial_number'],
      model: json['model'],
      manufacturer: json['manufacturer'],
      firmwareVersion: json['firmware_version'],
      status: json['status'] ?? 'offline',
      location: json['location'],
      installationDate: json['installation_date'],
      ratedPower: json['rated_power'] != null
          ? double.tryParse(json['rated_power'].toString())
          : null,
      ratedVoltage: json['rated_voltage'] != null
          ? double.tryParse(json['rated_voltage'].toString())
          : null,
      deviceTypeId: json['device_type_id'],
      environmentId: json['environment_id'],
      userId: json['user_id'] ?? 0,
      deviceType: json['device_type'] != null
          ? DeviceType.fromJson(json['device_type'])
          : null,
      environment: json['environment'] != null
          ? DeviceEnvironment.fromJson(json['environment'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'mac_address': macAddress,
      'status': status,
    };

    if (id > 0) data['id'] = id;
    if (serialNumber != null) data['serial_number'] = serialNumber;
    if (model != null) data['model'] = model;
    if (manufacturer != null) data['manufacturer'] = manufacturer;
    if (firmwareVersion != null) data['firmware_version'] = firmwareVersion;
    if (location != null) data['location'] = location;
    if (installationDate != null) data['installation_date'] = installationDate;
    if (ratedPower != null) data['rated_power'] = ratedPower;
    if (ratedVoltage != null) data['rated_voltage'] = ratedVoltage;
    if (deviceTypeId != null) data['device_type_id'] = deviceTypeId;
    if (environmentId != null) data['environment_id'] = environmentId;
    if (userId > 0) data['user_id'] = userId;

    return data;
  }

  Device copyWith({
    int? id,
    String? name,
    String? macAddress,
    String? serialNumber,
    String? model,
    String? manufacturer,
    String? firmwareVersion,
    String? status,
    String? location,
    String? installationDate,
    double? ratedPower,
    double? ratedVoltage,
    int? deviceTypeId,
    int? environmentId,
    int? userId,
    DeviceType? deviceType,
    DeviceEnvironment? environment,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      macAddress: macAddress ?? this.macAddress,
      serialNumber: serialNumber ?? this.serialNumber,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      status: status ?? this.status,
      location: location ?? this.location,
      installationDate: installationDate ?? this.installationDate,
      ratedPower: ratedPower ?? this.ratedPower,
      ratedVoltage: ratedVoltage ?? this.ratedVoltage,
      deviceTypeId: deviceTypeId ?? this.deviceTypeId,
      environmentId: environmentId ?? this.environmentId,
      userId: userId ?? this.userId,
      deviceType: deviceType ?? this.deviceType,
      environment: environment ?? this.environment,
    );
  }
}

// Modelo para dados em tempo real do InfluxDB
class InfluxData {
  final double? value;
  final String? unit;
  final String? time;

  InfluxData({
    this.value,
    this.unit,
    this.time,
  });

  factory InfluxData.fromJson(Map<String, dynamic> json) {
    return InfluxData(
      value: json['value'] != null
          ? double.tryParse(json['value'].toString())
          : null,
      unit: json['unit'],
      time: json['time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'unit': unit,
      'time': time,
    };
  }
}

// Modelo para consumo de energia (histórico)
class EnergyConsumption {
  final String timestamp;
  final double? consumptionKwh;
  final double? instantaneousPower;
  final double? voltage;
  final double? current;

  EnergyConsumption({
    required this.timestamp,
    this.consumptionKwh,
    this.instantaneousPower,
    this.voltage,
    this.current,
  });

  factory EnergyConsumption.fromJson(Map<String, dynamic> json) {
    return EnergyConsumption(
      timestamp: json['timestamp'] ?? '',
      consumptionKwh: json['consumption_kwh'] != null
          ? double.tryParse(json['consumption_kwh'].toString())
          : null,
      instantaneousPower: json['instantaneous_power'] != null
          ? double.tryParse(json['instantaneous_power'].toString())
          : null,
      voltage: json['voltage'] != null
          ? double.tryParse(json['voltage'].toString())
          : null,
      current: json['current'] != null
          ? double.tryParse(json['current'].toString())
          : null,
    );
  }
}

// Modelo para resposta do index (listagem) - ATUALIZADO para usar DailyMeasurement
class DeviceIndexResponse {
  final List<Device> devices;
  final List<DeviceEnvironment> environments;
  final List<DeviceType> deviceTypes;
  final Map<String, InfluxData> influxData;
  final Map<String, List<DailyMeasurement>> dailyConsumption;

  DeviceIndexResponse({
    required this.devices,
    required this.environments,
    required this.deviceTypes,
    required this.influxData,
    required this.dailyConsumption,
  });

  factory DeviceIndexResponse.fromJson(Map<String, dynamic> json) {
    // Handle influx_data - can be array or object
    Map<String, InfluxData> influxMap = {};
    final influxRaw = json['influx_data'];
    if (influxRaw is Map<String, dynamic>) {
      influxRaw.forEach((key, value) {
        influxMap[key] = InfluxData.fromJson(value);
      });
    }
    // If it's a List (empty array), influxMap stays empty

    // Handle daily_consumption - can be array or object
    Map<String, List<DailyMeasurement>> consumptionMap = {};
    final consumptionRaw = json['daily_consumption'];
    if (consumptionRaw is Map<String, dynamic>) {
      consumptionRaw.forEach((key, value) {
        if (value is List) {
          consumptionMap[key] = value.map((item) {
            if (item is Map<String, dynamic> && item.containsKey('type')) {
              return DailyMeasurement.fromJson(item);
            }
            return DailyMeasurement(
              date: item['date'] ?? '',
              value: double.tryParse(item['value'].toString()) ?? 0.0,
              type: 'energy',
              unit: 'kWh',
            );
          }).toList();
        }
      });
    }
    // If it's a List (empty array), consumptionMap stays empty

    return DeviceIndexResponse(
      devices: json['devices'] != null
          ? List<Device>.from(json['devices'].map((x) => Device.fromJson(x)))
          : [],
      environments: json['environments'] != null
          ? List<DeviceEnvironment>.from(
              json['environments'].map((x) => DeviceEnvironment.fromJson(x)))
          : [],
      deviceTypes: json['device_types'] != null
          ? List<DeviceType>.from(
              json['device_types'].map((x) => DeviceType.fromJson(x)))
          : [],
      influxData: influxMap,
      dailyConsumption: consumptionMap,
    );
  }
}

// Modelo para resposta de formulário (create/edit)
class DeviceFormResponse {
  final List<DeviceEnvironment> environments;
  final List<DeviceType> deviceTypes;
  final Device? device;

  DeviceFormResponse({
    required this.environments,
    required this.deviceTypes,
    this.device,
  });

  factory DeviceFormResponse.fromJson(Map<String, dynamic> json) {
    return DeviceFormResponse(
      environments: json['environments'] != null
          ? List<DeviceEnvironment>.from(
              json['environments'].map((x) => DeviceEnvironment.fromJson(x)))
          : [],
      deviceTypes: json['device_types'] != null
          ? List<DeviceType>.from(
              json['device_types'].map((x) => DeviceType.fromJson(x)))
          : [],
      device: json['device'] != null ? Device.fromJson(json['device']) : null,
    );
  }
}

// Modelo para resposta de show
class DeviceShowResponse {
  final Device device;
  final List<EnergyConsumption> consumption;

  DeviceShowResponse({
    required this.device,
    required this.consumption,
  });

  factory DeviceShowResponse.fromJson(Map<String, dynamic> json) {
    return DeviceShowResponse(
      device: Device.fromJson(json['device']),
      consumption: json['consumption'] != null
          ? List<EnergyConsumption>.from(
              json['consumption'].map((x) => EnergyConsumption.fromJson(x)))
          : [],
    );
  }
}

// Modelo para resposta de diagnósticos
class DeviceDiagnosticsResponse {
  final Device device;
  final String? lastSeen;
  final String status;
  final List<EnergyConsumption> consumptionData;

  DeviceDiagnosticsResponse({
    required this.device,
    this.lastSeen,
    required this.status,
    required this.consumptionData,
  });

  factory DeviceDiagnosticsResponse.fromJson(Map<String, dynamic> json) {
    return DeviceDiagnosticsResponse(
      device: Device.fromJson(json['device']),
      lastSeen: json['last_seen'],
      status: json['status'] ?? 'offline',
      consumptionData: json['consumption_data'] != null
          ? List<EnergyConsumption>.from(json['consumption_data']
              .map((x) => EnergyConsumption.fromJson(x)))
          : [],
    );
  }
}

// Modelo para resposta de debug
class DeviceDebugResponse {
  final int deviceId;
  final Map<String, dynamic> measurementInfo;
  final int rawDataCount;
  final List<dynamic> sampleData;

  DeviceDebugResponse({
    required this.deviceId,
    required this.measurementInfo,
    required this.rawDataCount,
    required this.sampleData,
  });

  factory DeviceDebugResponse.fromJson(Map<String, dynamic> json) {
    return DeviceDebugResponse(
      deviceId: json['device_id'] ?? 0,
      measurementInfo: json['measurement_info'] ?? {},
      rawDataCount: json['raw_data_count'] ?? 0,
      sampleData: json['sample_data'] ?? [],
    );
  }
}

// Modelo para resposta de sucesso
class DeviceSuccessResponse {
  final String message;
  final Device? device;

  DeviceSuccessResponse({
    required this.message,
    this.device,
  });

  factory DeviceSuccessResponse.fromJson(Map<String, dynamic> json) {
    return DeviceSuccessResponse(
      message: json['message'] ?? 'Sucesso',
      device: json['device'] != null ? Device.fromJson(json['device']) : null,
    );
  }
}
