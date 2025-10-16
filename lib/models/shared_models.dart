// shared_models.dart
// Modelo unificado para medições diárias

class DailyMeasurement {
  final String date;
  final double value;
  final String type;  // 'energy', 'temperature', 'humidity'
  final String unit;  // 'kWh', '°C', '%'

  DailyMeasurement({
    required this.date,
    required this.value,
    required this.type,
    required this.unit,
  });

  factory DailyMeasurement.fromJson(Map<String, dynamic> json) {
    return DailyMeasurement(
      date: json['date'] as String,
      value: (json['value'] as num).toDouble(),
      type: json['type'] ?? 'energy',
      unit: json['unit'] ?? _getDefaultUnit(json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'value': value,
      'type': type,
      'unit': unit,
    };
  }

  static String _getDefaultUnit(String? type) {
    switch (type) {
      case 'temperature':
        return '°C';
      case 'humidity':
        return '%';
      case 'energy':
      default:
        return 'kWh';
    }
  }

  String get formattedDate {
    try {
      final dateParts = date.split('-');
      return '${dateParts[2]}/${dateParts[1]}';
    } catch (e) {
      return date;
    }
  }

  String get formattedValue {
    final decimals = type == 'energy' ? 3 : 2;
    return '${value.toStringAsFixed(decimals)} $unit';
  }

  // Conversores para compatibilidade
  static DailyMeasurement fromEnergy(String date, double energy) {
    return DailyMeasurement(
      date: date,
      value: energy,
      type: 'energy',
      unit: 'kWh',
    );
  }

  static DailyMeasurement fromTemperature(String date, double temperature) {
    return DailyMeasurement(
      date: date,
      value: temperature,
      type: 'temperature',
      unit: '°C',
    );
  }

  static DailyMeasurement fromHumidity(String date, double humidity) {
    return DailyMeasurement(
      date: date,
      value: humidity,
      type: 'humidity',
      unit: '%',
    );
  }
}

// Agrupa medições por tipo
class ConsumptionData {
  final Map<String, List<DailyMeasurement>> measurements;

  ConsumptionData({required this.measurements});

  // Getters de conveniência
  List<DailyMeasurement> get energy => measurements['energy'] ?? [];
  List<DailyMeasurement> get temperature => measurements['temperature'] ?? [];
  List<DailyMeasurement> get humidity => measurements['humidity'] ?? [];

  bool get isEmpty => measurements.isEmpty || 
      measurements.values.every((list) => list.isEmpty);

  bool hasType(String type) => measurements.containsKey(type) && 
      measurements[type]!.isNotEmpty;

  factory ConsumptionData.fromJson(Map<String, dynamic> json) {
    final result = <String, List<DailyMeasurement>>{};
    
    json.forEach((type, data) {
      if (data is List) {
        result[type] = data
            .map((item) => DailyMeasurement.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    });

    return ConsumptionData(measurements: result);
  }

  // Compatibilidade com formato antigo de Environment
  factory ConsumptionData.fromEnvironmentFormat(Map<String, dynamic> json) {
    final measurements = <String, List<DailyMeasurement>>{};

    // Converter formato antigo: {energy: [], temperature: [], humidity: []}
    ['energy', 'temperature', 'humidity'].forEach((type) {
      if (json[type] != null && json[type] is List) {
        measurements[type] = (json[type] as List).map((item) {
          return DailyMeasurement(
            date: item['date'],
            value: (item[type] as num).toDouble(),
            type: type,
            unit: DailyMeasurement._getDefaultUnit(type),
          );
        }).toList();
      }
    });

    return ConsumptionData(measurements: measurements);
  }

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};
    measurements.forEach((type, list) {
      result[type] = list.map((m) => m.toJson()).toList();
    });
    return result;
  }

  // Agregar todos os valores de um tipo específico
  double getTotalForType(String type) {
    if (!hasType(type)) return 0.0;
    return measurements[type]!.fold(0.0, (sum, m) => sum + m.value);
  }

  // Obter média de um tipo específico
  double getAverageForType(String type) {
    if (!hasType(type)) return 0.0;
    final list = measurements[type]!;
    if (list.isEmpty) return 0.0;
    return getTotalForType(type) / list.length;
  }
}

// Helper para processar dados raw da API
class ConsumptionDataProcessor {
  /// Processa dados de consumo que podem vir como lista vazia ou Map
  static Map<String, ConsumptionData> processRawConsumption(dynamic rawData) {
    final result = <String, ConsumptionData>{};

    if (rawData == null || rawData is List) {
      return result; // Retorna vazio para null ou lista
    }

    if (rawData is! Map<String, dynamic>) {
      return result; // Retorna vazio para tipos inesperados
    }

    try {
      rawData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          result[key] = ConsumptionData.fromJson(value);
        }
      });
    } catch (e) {
      print('Erro ao processar consumption data: $e');
      return <String, ConsumptionData>{};
    }

    return result;
  }
}