import 'package:flutter/material.dart';
import '../utils/dashboard_utils.dart';
import '../models/dashboard_response.dart';

class StatCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DashboardStats? stats; // Adicionar stats opcionais

  const StatCardWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DashboardUtils.createCardDecoration(
        gradientColors: [color, _getDarkerColor(color)],
        shadow: BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ),
      child: Stack(
        children: [
          // Efeito de brilho
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DashboardUtils.borderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      _getSubtitleIcon(),
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                // Adicionar detalhes extras se stats estão disponíveis
                if (stats != null && _shouldShowExtraInfo())
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _getExtraInfo(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDarkerColor(Color color) {
    return Color.fromRGBO(
      (color.red * 0.8).round(),
      (color.green * 0.8).round(),
      (color.blue * 0.8).round(),
      1.0,
    );
  }

  IconData _getSubtitleIcon() {
    if (title.contains('Consumo')) {
      return Icons.flash_on;
    } else if (title.contains('Dispositivos')) {
      return Icons.devices;
    } else if (title.contains('Alertas')) {
      return Icons.warning_amber;
    }
    return Icons.access_time;
  }

  bool _shouldShowExtraInfo() {
    return stats != null && (
      title.contains('Dispositivos') || title.contains('Alertas')
    );
  }

  String _getExtraInfo() {
    if (stats == null) return '';

    if (title.contains('Dispositivos')) {
      final offline = stats!.offlineDevices;
      final maintenance = stats!.maintenanceDevices;
      if (offline > 0 || maintenance > 0) {
        return '$offline offline, $maintenance manutenção';
      }
    } else if (title.contains('Alertas')) {
      final high = stats!.highSeverityAlerts;
      if (high > 0) {
        return '$high críticos';
      }
    }

    return '';
  }
}