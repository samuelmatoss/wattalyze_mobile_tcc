
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';


class Report {
  final int id;
  final int userId;
  final String name;
  final String type;
  final String periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String format;
  final String status;
  final String? filePath;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? filters;
  final bool isScheduled;
  final String? scheduleFrequency;
  final DateTime? nextGeneration;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Report({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.format,
    required this.status,
    this.filePath,
    this.data,
    this.filters,
    this.isScheduled = false,
    this.scheduleFrequency,
    this.nextGeneration,
    this.createdAt,
    this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      type: json['type'],
      periodType: json['period_type'],
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: DateTime.parse(json['period_end']),
      format: json['format'],
      status: json['status'],
      filePath: json['file_path'],
      data: json['data'] != null 
          ? (json['data'] is String 
              ? Map<String, dynamic>.from(jsonDecode(json['data']))
              : Map<String, dynamic>.from(json['data']))
          : null,
      filters: json['filters'] != null
          ? (json['filters'] is String 
              ? Map<String, dynamic>.from(jsonDecode(json['filters']))
              : Map<String, dynamic>.from(json['filters']))
          : null,
      isScheduled: json['is_scheduled'] ?? false,
      scheduleFrequency: json['schedule_frequency'],
      nextGeneration: json['next_generation'] != null 
          ? DateTime.parse(json['next_generation'])
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'period_type': periodType,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'format': format,
      'status': status,
      'file_path': filePath,
      'data': data,
      'filters': filters,
      'is_scheduled': isScheduled,
      'schedule_frequency': scheduleFrequency,
      'next_generation': nextGeneration?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper getters
  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'processing':
        return 'Processando';
      case 'completed':
        return 'Concluído';
      case 'failed':
        return 'Falhou';
      default:
        return status;
    }
  }

  String get typeDisplayName {
    switch (type) {
      case 'consumption':
        return 'Consumo';
      case 'cost':
        return 'Custo';
      case 'efficiency':
        return 'Eficiência';
      case 'comparative':
        return 'Comparativo';
      case 'custom':
        return 'Personalizado';
      default:
        return type;
    }
  }

  String get formatDisplayName {
    switch (format) {
      case 'pdf':
        return 'PDF';
      case 'excel':
        return 'Excel';
      case 'csv':
        return 'CSV';
      case 'json':
        return 'JSON';
      default:
        return format.toUpperCase();
    }
  }

  String get periodTypeDisplayName {
    switch (periodType) {
      case 'daily':
        return 'Diário';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensal';
      case 'yearly':
        return 'Anual';
      case 'custom':
        return 'Personalizado';
      default:
        return periodType;
    }
  }

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isFailed => status == 'failed';
  bool get hasFile => filePath != null && filePath!.isNotEmpty;
  
  String get periodDisplay {
    final startFormat = '${periodStart.day.toString().padLeft(2, '0')}/'
                      '${periodStart.month.toString().padLeft(2, '0')}/'
                      '${periodStart.year}';
    final endFormat = '${periodEnd.day.toString().padLeft(2, '0')}/'
                    '${periodEnd.month.toString().padLeft(2, '0')}/'
                    '${periodEnd.year}';
    return '$startFormat - $endFormat';
  }

  Color get statusColor {
    switch (status) {
      case 'completed':
        return const Color(0xFF27AE60);
      case 'processing':
        return const Color(0xFFF39C12);
      case 'failed':
        return const Color(0xFFE74C3C);
      case 'pending':
      default:
        return const Color(0xFF95A5A6);
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'processing':
        return Icons.hourglass_empty;
      case 'failed':
        return Icons.error;
      case 'pending':
      default:
        return Icons.schedule;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'consumption':
        return Icons.flash_on;
      case 'cost':
        return Icons.attach_money;
      case 'efficiency':
        return Icons.trending_up;
      case 'comparative':
        return Icons.compare_arrows;
      case 'custom':
        return Icons.tune;
      default:
        return Icons.description;
    }
  }

  // Summary data helpers
  ReportSummary? get summary {
    if (data != null && data!['summary'] != null) {
      return ReportSummary.fromJson(data!['summary']);
    }
    return null;
  }

  List<String> get deviceNames {
    if (data != null && data!['devices'] != null) {
      final devices = data!['devices'] as Map<String, dynamic>;
      return devices.keys.toList();
    }
    return [];
  }
}

class ReportSummary {
  final double totalConsumption;
  final double totalCost;
  final double avgConsumption;
  final double avgCost;
  final double maxConsumption;
  final double minConsumption;
  final int totalDevices;

  ReportSummary({
    required this.totalConsumption,
    required this.totalCost,
    required this.avgConsumption,
    required this.avgCost,
    required this.maxConsumption,
    required this.minConsumption,
    required this.totalDevices,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    // Handle both direct summary and device-based summary
    if (json.containsKey('total_devices')) {
      return ReportSummary(
        totalConsumption: (json['total_consumption'] ?? 0.0).toDouble(),
        totalCost: (json['total_cost'] ?? 0.0).toDouble(),
        avgConsumption: (json['avg_consumption'] ?? 0.0).toDouble(),
        avgCost: (json['avg_cost'] ?? 0.0).toDouble(),
        maxConsumption: (json['max_consumption'] ?? 0.0).toDouble(),
        minConsumption: (json['min_consumption'] ?? 0.0).toDouble(),
        totalDevices: (json['total_devices'] ?? 0).toInt(),
      );
    } else {
      // Calculate summary from device data
      double totalConsumption = 0;
      double totalCost = 0;
      double maxConsumption = 0;
      double minConsumption = double.infinity;
      int deviceCount = 0;

      json.forEach((deviceName, deviceData) {
        if (deviceData is Map<String, dynamic>) {
          totalConsumption += (deviceData['total_consumption'] ?? 0.0).toDouble();
          totalCost += (deviceData['total_cost'] ?? 0.0).toDouble();
          maxConsumption = math.max(maxConsumption, (deviceData['max_consumption'] ?? 0.0).toDouble());
          minConsumption = math.min(minConsumption, (deviceData['min_consumption'] ?? 0.0).toDouble());
          deviceCount++;
        }
      });

      return ReportSummary(
        totalConsumption: totalConsumption,
        totalCost: totalCost,
        avgConsumption: deviceCount > 0 ? totalConsumption / deviceCount : 0,
        avgCost: deviceCount > 0 ? totalCost / deviceCount : 0,
        maxConsumption: maxConsumption == 0 ? 0 : maxConsumption,
        minConsumption: minConsumption == double.infinity ? 0 : minConsumption,
        totalDevices: deviceCount,
      );
    }
  }
}

// Report creation request model
class CreateReportRequest {
  final String name;
  final String type;
  final String periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String format;
  final List<int>? deviceIds;
  final Map<String, dynamic>? additionalFilters;

  CreateReportRequest({
    required this.name,
    required this.type,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.format,
    this.deviceIds,
    this.additionalFilters,
  });

  Map<String, dynamic> toJson() {
    final filters = <String, dynamic>{};
    if (deviceIds != null && deviceIds!.isNotEmpty) {
      filters['devices'] = deviceIds;
    }
    if (additionalFilters != null) {
      filters.addAll(additionalFilters!);
    }

    return {
      'name': name,
      'type': type,
      'period_type': periodType,
      'period_start': periodStart.toIso8601String().split('T')[0],
      'period_end': periodEnd.toIso8601String().split('T')[0],
      'format': format,
      if (filters.isNotEmpty) 'filters': filters,
    };
  }
}
