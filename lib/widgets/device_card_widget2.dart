import 'package:flutter/material.dart';
import '../models/dashboard_response.dart';
import '../utils/dashboard_utils.dart';

class DeviceCardWidget extends StatelessWidget {
  final Device device;
  final Map<String, dynamic> dailyConsumption;
  final double animationDelay;
  final AnimationController animationController;

  const DeviceCardWidget({
    Key? key,
    required this.device,
    required this.dailyConsumption,
    required this.animationDelay,
    required this.animationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceType = device.deviceType.name.toLowerCase();
    final color = DashboardUtils.getDeviceTypeColor(deviceType);
    final icon = DashboardUtils.getDeviceTypeIcon(deviceType);
    final unit = DashboardUtils.getDeviceUnit(deviceType);

    // USAR DADOS REAIS: Status vem da API
    final status = _getStatusFromApi();
    final statusColor = DashboardUtils.getStatusColor(status);

    // USAR DADOS REAIS: Valor atual dos dados de consumo
    final currentValue = _getCurrentValueFromApi();

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(
          (animationController.value - animationDelay).clamp(0.0, 1.0) / (1.0 - animationDelay),
        );

        return Transform.translate(
          offset: Offset(0, 50 * (1 - progress)),
          child: Opacity(
            opacity: progress,
            child: Container(
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
                          end: Alignment.center,
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
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _capitalizeFirst(status),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              icon,
                              color: Colors.white.withOpacity(0.8),
                              size: 28,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Badge do tipo
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            device.deviceType.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Footer com leitura atual e status
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Leitura atual',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatCurrentValue(currentValue, unit),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getStatusIndicatorColor(status),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _getStatusIndicatorColor(status).withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

  /// DADOS REAIS: Obter status do device da API
  String _getStatusFromApi() {
    // Usar o status que vem da API (deve ter sido adicionado no controller)
    return device.status;
  }

  /// DADOS REAIS: Obter valor atual dos dados de consumo
  double _getCurrentValueFromApi() {
    final deviceId = device.id.toString();

    // Verificar se há dados de consumo para este dispositivo
    if (!dailyConsumption.containsKey(deviceId)) {
      return 0.0;
    }

    final deviceData = dailyConsumption[deviceId] as Map<String, dynamic>?;
    if (deviceData == null) return 0.0;

    // Determinar que tipo de dado buscar baseado no tipo do dispositivo
    String dataType;
    final deviceTypeName = device.deviceType.name.toLowerCase();

    if (deviceTypeName.contains('temperature')) {
      dataType = 'temperature';
    } else if (deviceTypeName.contains('humidity')) {
      dataType = 'humidity';
    } else {
      dataType = 'energy';
    }

    // Buscar o dado mais recente deste tipo
    if (deviceData.containsKey(dataType)) {
      final measurements = deviceData[dataType] as List?;
      if (measurements != null && measurements.isNotEmpty) {
        // Pegar a última medição (mais recente)
        final lastMeasurement = measurements.last;
        return (lastMeasurement['value'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return 0.0;
  }

  /// Formatar valor atual com tratamento adequado
  String _formatCurrentValue(double value, String unit) {
    if (value == 0.0) {
      return 'N/A';
    }

    return '${DashboardUtils.formatNumber(value)} $unit';
  }

  /// Capitalizar primeira letra
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Cor do indicador de status baseado no status real
  Color _getStatusIndicatorColor(String status) {
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
}