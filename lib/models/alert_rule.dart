import 'device_model.dart';
import 'environment_model.dart';
class AlertRule {
  final int id;
  final int userId;
  final int? deviceId;
  final int? environmentId;
  final String name;
  final String type;
  final double? thresholdValue;
  final String? condition;
  final String? notificationChannels;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Device? device;
  final Environment? environment;

  AlertRule({
    required this.id,
    required this.userId,
    this.deviceId,
    this.environmentId,
    required this.name,
    required this.type,
    this.thresholdValue,
    this.condition,
    this.notificationChannels,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.device,
    this.environment,
  });

  factory AlertRule.fromJson(Map<String, dynamic> json) {
    return AlertRule(
      id: json['id'],
      userId: json['user_id'],
      deviceId: json['device_id'],
      environmentId: json['environment_id'],
      name: json['name'],
      type: json['type'],
      thresholdValue: json['threshold_value'] != null ? double.tryParse(json['threshold_value'].toString()) : null,
      condition: json['condition'],
      notificationChannels: json['notification_channels'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      device: json['device'] != null ? Device.fromJson(json['device']) : null,
      environment: json['environment'] != null ? Environment.fromJson(json['environment']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'environment_id': environmentId,
      'name': name,
      'type': type,
      'threshold_value': thresholdValue,
      'condition': condition,
      'notification_channels': notificationChannels,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'device': device?.toJson(),
      'environment': environment?.toJson(),
    };
  }
}