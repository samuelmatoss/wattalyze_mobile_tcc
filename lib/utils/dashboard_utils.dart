import 'package:flutter/material.dart';

class DashboardUtils {
  // Cores
  static const Color primaryGreen = Color(0xFF27ae60);
  static const Color primaryDark = Color(0xFF2c3e50);
  static const Color primaryOrange = Color(0xFFf39c12);
  static const Color primaryRed = Color(0xFFe74c3c);
  static const Color textMuted = Color(0xFF6c757d);

  static const double borderRadius = 16.0;

  // Cores por tipo de dispositivo
  static Color getDeviceTypeColor(String deviceType) {
    final type = deviceType.toLowerCase();
    if (type.contains('temperature')) {
      return primaryOrange;
    } else if (type.contains('humidity')) {
      return const Color(0xFF3498DB);
    } else {
      return primaryGreen;
    }
  }

  // Ícones por tipo de dispositivo (Material Icons)
  static IconData getDeviceTypeIcon(String deviceType) {
    final type = deviceType.toLowerCase();
    if (type.contains('temperature')) {
      return Icons.thermostat;
    } else if (type.contains('humidity')) {
      return Icons.water_drop;
    } else {
      return Icons.flash_on;
    }
  }

  // Unidades
  static String getDeviceUnit(String deviceType) {
    final type = deviceType.toLowerCase();
    if (type.contains('temperature')) {
      return '°C';
    } else if (type.contains('humidity')) {
      return '%';
    } else {
      return 'kWh';
    }
  }

  // Cor por status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Colors.green;
      case 'offline':
        return Colors.red;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Formatação de números
  static String formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    } else if (value >= 1) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  // Formatação de data
  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}';
    } catch (e) {
      return dateString;
    }
  }

  // Decoração de cards
  static BoxDecoration createCardDecoration({
    List<Color>? gradientColors,
    BoxShadow? shadow,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: gradientColors != null
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            )
          : null,
      color: gradientColors == null ? Colors.white : null,
      boxShadow: shadow != null ? [shadow] : [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}