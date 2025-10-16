

class DashboardResponse {
  final bool success;
  final DashboardData data;
  final DashboardMeta? meta;

  DashboardResponse({
    required this.success,
    required this.data,
    this.meta,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    // Verificar se a resposta tem estrutura aninhada ou direta
    if (json.containsKey('data') && json.containsKey('success')) {
      // Nova estrutura da API melhorada
      return DashboardResponse(
        success: json['success'] ?? true,
        data: DashboardData.fromJson(json['data']),
        meta: json['meta'] != null ? DashboardMeta.fromJson(json['meta']) : null,
      );
    } else {
      // Estrutura atual (compatibilidade reversa)
      return DashboardResponse(
        success: true,
        data: DashboardData.fromJson(json),
        meta: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.toJson(),
      'meta': meta?.toJson(),
    };
  }

  // Getters de conveniência (compatibilidade com código existente)
  List<Device> get devices => data.devices;
  List<Alert> get alerts => data.alerts;
  Map<String, dynamic> get dailyConsumption => data.dailyConsumption;
  double get totalConsumption => data.totalConsumption;
}

class DashboardData {
  final List<Device> devices;
  final List<Alert> alerts;
  final Map<String, dynamic> dailyConsumption;
  final double totalConsumption;
  final DashboardStats? stats;

  DashboardData({
    required this.devices,
    required this.alerts,
    required this.dailyConsumption,
    required this.totalConsumption,
    this.stats,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    // Processar daily_consumption com tratamento especial
    Map<String, dynamic> parsedDailyConsumption = {};
    final rawDailyConsumption = json['daily_consumption'];
    
    if (rawDailyConsumption != null) {
      if (rawDailyConsumption is Map<String, dynamic>) {
        // Se já é um Map, usa diretamente
        parsedDailyConsumption = Map<String, dynamic>.from(rawDailyConsumption);
      } else if (rawDailyConsumption is List) {
        // Se é uma lista (mesmo vazia), converte para Map vazio
        parsedDailyConsumption = {};
      } else {

        parsedDailyConsumption = {};
      }
    }

    return DashboardData(
      devices: List<Device>.from(
        (json['devices'] as List).map((x) => Device.fromJson(x))
      ),
      alerts: List<Alert>.from(
        (json['alerts'] as List).map((x) => Alert.fromJson(x))
      ),
      dailyConsumption: parsedDailyConsumption,
      totalConsumption: (json['total_consumption'] as num?)?.toDouble() ?? 0.0,
      stats: json['stats'] != null ? DashboardStats.fromJson(json['stats']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'devices': devices.map((x) => x.toJson()).toList(),
      'alerts': alerts.map((x) => x.toJson()).toList(),
      'daily_consumption': dailyConsumption,
      'total_consumption': totalConsumption,
      'stats': stats?.toJson(),
    };
  }
}

class DashboardMeta {
  final DateTime timestamp;
  final String timezone;
  final String version;

  DashboardMeta({
    required this.timestamp,
    required this.timezone,
    required this.version,
  });

  factory DashboardMeta.fromJson(Map<String, dynamic> json) {
    return DashboardMeta(
      timestamp: DateTime.parse(json['timestamp']),
      timezone: json['timezone'],
      version: json['version'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'timezone': timezone,
      'version': version,
    };
  }
}

class DashboardStats {
  final int totalDevices;
  final int activeDevices;
  final int offlineDevices;
  final int maintenanceDevices;
  final int totalAlerts;
  final int highSeverityAlerts;

  DashboardStats({
    required this.totalDevices,
    required this.activeDevices,
    required this.offlineDevices,
    required this.maintenanceDevices,
    required this.totalAlerts,
    required this.highSeverityAlerts,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalDevices: json['total_devices'] ?? 0,
      activeDevices: json['active_devices'] ?? 0,
      offlineDevices: json['offline_devices'] ?? 0,
      maintenanceDevices: json['maintenance_devices'] ?? 0,
      totalAlerts: json['total_alerts'] ?? 0,
      highSeverityAlerts: json['high_severity_alerts'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_devices': totalDevices,
      'active_devices': activeDevices,
      'offline_devices': offlineDevices,
      'maintenance_devices': maintenanceDevices,
      'total_alerts': totalAlerts,
      'high_severity_alerts': highSeverityAlerts,
    };
  }
}

class Device {
  final int id;
  final String name;
  final String macAddress;
  final DeviceType deviceType;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Device({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.deviceType,
    this.status = 'offline',
    this.createdAt,
    this.updatedAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      macAddress: json['mac_address'],
      deviceType: DeviceType.fromJson(json['device_type']),
      status: json['status'] ?? 'offline',
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
      'name': name,
      'mac_address': macAddress,
      'device_type': deviceType.toJson(),
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isOnline => status == 'online';
  bool get isOffline => status == 'offline';
  bool get isMaintenance => status == 'maintenance';
}

class DeviceType {
  final int id;
  final String name;
  final String? description;
  final String? unit;
  final String? iconName;

  DeviceType({
    required this.id,
    required this.name,
    this.description,
    this.unit,
    this.iconName,
  });

  factory DeviceType.fromJson(Map<String, dynamic> json) {
    return DeviceType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      unit: json['unit'],
      iconName: json['icon_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'unit': unit,
      'icon_name': iconName,
    };
  }

  bool get isTemperatureSensor => name.toLowerCase().contains('temperature');
  bool get isHumiditySensor => name.toLowerCase().contains('humidity');
  bool get isEnergyDevice => !isTemperatureSensor && !isHumiditySensor;
}

class Alert {
  final int id;
  final String message;
  final String severity;
  final bool isResolved;
  final Device device;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  Alert({
    required this.id,
    required this.message,
    required this.severity,
    required this.isResolved,
    required this.device,
    required this.createdAt,
    this.resolvedAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      message: json['message'],
      severity: json['severity'] ?? 'medium',
      isResolved: json['is_resolved'] ?? false,
      device: Device.fromJson(json['device']),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.parse(json['resolved_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'severity': severity,
      'is_resolved': isResolved,
      'device': device.toJson(),
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  bool get isHighSeverity => severity == 'high';
  bool get isMediumSeverity => severity == 'medium';
  bool get isLowSeverity => severity == 'low';

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d atrás';
    } else {
      return '${(difference.inDays / 30).floor()}m atrás';
    }
  }
}

