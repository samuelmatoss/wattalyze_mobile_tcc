// models/energy_tariff_model.dart
class EnergyTariff {
  final int id;
  final String name;
  final String? provider;
  final String? region;
  final String? tariffType;
  final double bracket1Min;
  final double? bracket1Max;
  final double bracket1Rate;
  final double? bracket2Min;
  final double? bracket2Max;
  final double? bracket2Rate;
  final double? bracket3Min;
  final double? bracket3Max;
  final double? bracket3Rate;
  final double? taxRate;
  final String? validFrom;
  final String? validUntil;
  final bool isActive;
  final int userId;
  final String? createdAt;
  final String? updatedAt;

  EnergyTariff({
    required this.id,
    required this.name,
    this.provider,
    this.region,
    this.tariffType,
    required this.bracket1Min,
    this.bracket1Max,
    required this.bracket1Rate,
    this.bracket2Min,
    this.bracket2Max,
    this.bracket2Rate,
    this.bracket3Min,
    this.bracket3Max,
    this.bracket3Rate,
    this.taxRate,
    this.validFrom,
    this.validUntil,
    required this.isActive,
    required this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory EnergyTariff.fromJson(Map<String, dynamic> json) {
    return EnergyTariff(
      id: json['id'],
      name: json['name'],
      provider: json['provider'],
      region: json['region'],
      tariffType: json['tariff_type'],
      bracket1Min: double.tryParse(json['bracket1_min'].toString()) ?? 0.0,
      bracket1Max: json['bracket1_max'] != null ? double.tryParse(json['bracket1_max'].toString()) : null,
      bracket1Rate: double.tryParse(json['bracket1_rate'].toString()) ?? 0.0,
      bracket2Min: json['bracket2_min'] != null ? double.tryParse(json['bracket2_min'].toString()) : null,
      bracket2Max: json['bracket2_max'] != null ? double.tryParse(json['bracket2_max'].toString()) : null,
      bracket2Rate: json['bracket2_rate'] != null ? double.tryParse(json['bracket2_rate'].toString()) : null,
      bracket3Min: json['bracket3_min'] != null ? double.tryParse(json['bracket3_min'].toString()) : null,
      bracket3Max: json['bracket3_max'] != null ? double.tryParse(json['bracket3_max'].toString()) : null,
      bracket3Rate: json['bracket3_rate'] != null ? double.tryParse(json['bracket3_rate'].toString()) : null,
      taxRate: json['tax_rate'] != null ? double.tryParse(json['tax_rate'].toString()) : null,
      validFrom: json['valid_from'],
      validUntil: json['valid_until'],
      isActive: json['is_active'] ?? false,
      userId: json['user_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider,
      'region': region,
      'tariff_type': tariffType,
      'bracket1_min': bracket1Min,
      'bracket1_max': bracket1Max,
      'bracket1_rate': bracket1Rate,
      'bracket2_min': bracket2Min,
      'bracket2_max': bracket2Max,
      'bracket2_rate': bracket2Rate,
      'bracket3_min': bracket3Min,
      'bracket3_max': bracket3Max,
      'bracket3_rate': bracket3Rate,
      'tax_rate': taxRate,
      'valid_from': validFrom,
      'valid_until': validUntil,
      'is_active': isActive,
      'user_id': userId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Método para calcular o custo baseado no consumo
  double calculateCost(double consumption) {
    double cost = 0.0;

    // Faixa 1
    if (consumption > bracket1Min) {
      double upper = bracket1Max ?? consumption;
      double bracket1Consumption = consumption.clamp(bracket1Min, upper) - bracket1Min;
      cost += bracket1Consumption * bracket1Rate;
    }

    // Faixa 2
    if (bracket2Rate != null && bracket2Min != null && consumption > bracket2Min!) {
      double upper = bracket2Max ?? consumption;
      double bracket2Consumption = consumption.clamp(bracket2Min!, upper) - bracket2Min!;
      cost += bracket2Consumption * bracket2Rate!;
    }

    // Faixa 3
    if (bracket3Rate != null && bracket3Min != null && consumption > bracket3Min!) {
      double upper = bracket3Max ?? consumption;
      double bracket3Consumption = consumption.clamp(bracket3Min!, upper) - bracket3Min!;
      cost += bracket3Consumption * bracket3Rate!;
    }

    // Adicionar taxa
    if (taxRate != null) {
      cost += cost * (taxRate! / 100);
    }

    return cost;
  }

  /// Verifica se a tarifa está válida na data atual
  bool get isValid {
    final now = DateTime.now();

    if (validFrom != null) {
      final from = DateTime.parse(validFrom!);
      if (now.isBefore(from)) return false;
    }

    if (validUntil != null) {
      final until = DateTime.parse(validUntil!);
      if (now.isAfter(until)) return false;
    }

    return isActive;
  }
}

// Modelo para resposta paginada
class TariffPaginationResponse {
  final List<EnergyTariff> tariffs;
  final PaginationData pagination;

  TariffPaginationResponse({
    required this.tariffs,
    required this.pagination,
  });

  factory TariffPaginationResponse.fromJson(Map<String, dynamic> json) {
    return TariffPaginationResponse(
      tariffs: List<EnergyTariff>.from(
          json['tariffs']['data'].map((x) => EnergyTariff.fromJson(x))),
      pagination: PaginationData.fromJson(json['tariffs']),
    );
  }
}

// Modelo para dados de paginação
class PaginationData {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationData({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationData.fromJson(Map<String, dynamic> json) {
    return PaginationData(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
      total: json['total'] ?? 0,
    );
  }
}

// Modelo para resposta de sucesso
class TariffSuccessResponse {
  final String message;
  final EnergyTariff tariff;

  TariffSuccessResponse({
    required this.message,
    required this.tariff,
  });

  factory TariffSuccessResponse.fromJson(Map<String, dynamic> json) {
    return TariffSuccessResponse(
      message: json['message'],
      tariff: EnergyTariff.fromJson(json['tariff']),
    );
  }
}

// Modelo para resposta de validação de erro
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
      errors: Map<String, dynamic>.from(json['errors']),
    );
  }
}
