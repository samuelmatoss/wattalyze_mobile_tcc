import 'alert_rule.dart';
import 'device_model.dart';
import 'environment_model.dart';
class Alert {
  final int id;
  final int userId;
  final int? deviceId;
  final int? environmentId;
  final int? alertRuleId;
  final String message;
  final bool isResolved;
  final bool isRead;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Device? device;
  final Environment? environment;
  final AlertRule? alertRule;

  Alert({
    required this.id,
    required this.userId,
    this.deviceId,
    this.environmentId,
    this.alertRuleId,
    required this.message,
    required this.isResolved,
    required this.isRead,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
    this.device,
    this.environment,
    this.alertRule,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      userId: json['user_id'],
      deviceId: json['device_id'],
      environmentId: json['environment_id'],
      alertRuleId: json['alert_rule_id'],
      message: json['message'],
      isResolved: json['is_resolved'] == 1 || json['is_resolved'] == true,
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      device: json['device'] != null ? Device.fromJson(json['device']) : null,
      environment: json['environment'] != null ? Environment.fromJson(json['environment']) : null,
      alertRule: json['alert_rule'] != null ? AlertRule.fromJson(json['alert_rule']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'environment_id': environmentId,
      'alert_rule_id': alertRuleId,
      'message': message,
      'is_resolved': isResolved,
      'is_read': isRead,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'device': device?.toJson(),
      'environment': environment?.toJson(),
      'alert_rule': alertRule?.toJson(),
    };
  }
}