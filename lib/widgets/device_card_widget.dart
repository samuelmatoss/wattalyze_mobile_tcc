import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/device_model.dart';
import '../models/shared_models.dart';

class DeviceCardWidget extends StatelessWidget {
  final Device device;
  final InfluxData? influxData;
  final List<DailyMeasurement> dailyConsumption; // ✅ ajustado
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const DeviceCardWidget({
    Key? key,
    required this.device,
    this.influxData,
    required this.dailyConsumption,
    this.onTap,
    this.onDelete,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceType = _getDeviceTypeInfo();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              border: Border.all(
                color: _getStatusColor().withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, deviceType),
                const SizedBox(height: 16),
                _buildCurrentValue(context, deviceType),
                const SizedBox(height: 20),
                _buildChart(context, deviceType),
                const SizedBox(height: 16),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DeviceTypeInfo deviceType) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                device.macAddress,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
              ),
              if (device.environment != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      device.environment!.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Column(
          children: [
            _buildStatusBadge(),
            const SizedBox(height: 8),
            Icon(
              deviceType.icon,
              size: 24,
              color: Colors.grey[600],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor();
    final icon = _getStatusIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            device.status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentValue(BuildContext context, DeviceTypeInfo deviceType) {
    final value = influxData?.value;
    final unit = deviceType.unit;
    final time = influxData?.time;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deviceType.title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    value != null
                        ? '${value.toStringAsFixed(deviceType.decimals)}'
                        : 'Sem dados',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: value != null ? Colors.black87 : Colors.grey,
                        ),
                  ),
                  if (value != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (time != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Última atualização',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatLastUpdate(time),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, DeviceTypeInfo deviceType) {
    if (dailyConsumption.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Text(
            'Sem dados de histórico disponíveis',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Criar spots para o gráfico
    final spots = dailyConsumption.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

// Garantir minY e maxY válidos
    double minY =
        dailyConsumption.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    double maxY =
        dailyConsumption.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    if (minY == maxY) {
      // Evitar minY == maxY (necessário para fl_chart)
      minY = minY * 0.9;
      maxY = maxY * 1.1;
      if (minY == maxY) maxY = minY + 1;
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                deviceType.chartLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '7 dias',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[200]!, strokeWidth: 0.5);
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(deviceType.isEnergy ? 1 : 0),
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < dailyConsumption.length) {
                          final date =
                              DateTime.parse(dailyConsumption[index].date);
                          return Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: deviceType.chartColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: deviceType.chartColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: deviceType.chartColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Editar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete),
          color: Colors.red[400],
        ),
      ],
    );
  }

  DeviceTypeInfo _getDeviceTypeInfo() {
    final typeName = device.deviceType?.name.toLowerCase() ?? '';

    if (typeName.contains('temperature')) {
      return DeviceTypeInfo(
        title: 'Temperatura Atual',
        unit: '°C',
        chartLabel: 'Temperatura (°C) - 7 dias',
        chartColor: Colors.orange,
        icon: Icons.thermostat,
        isEnergy: false,
        decimals: 1,
      );
    } else if (typeName.contains('humidity')) {
      return DeviceTypeInfo(
        title: 'Umidade Atual',
        unit: '%',
        chartLabel: 'Umidade (%) - 7 dias',
        chartColor: Colors.blue,
        icon: Icons.water_drop,
        isEnergy: false,
        decimals: 1,
      );
    } else {
      return DeviceTypeInfo(
        title: 'Consumo Hoje',
        unit: 'kWh',
        chartLabel: 'Consumo Diário (7 dias)',
        chartColor: Colors.green,
        icon: Icons.electrical_services,
        isEnergy: true,
        decimals: 3,
      );
    }
  }

  Color _getStatusColor() {
    switch (device.status.toLowerCase()) {
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

  IconData _getStatusIcon() {
    switch (device.status.toLowerCase()) {
      case 'online':
        return Icons.check_circle;
      case 'offline':
        return Icons.cancel;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.help;
    }
  }

  String _formatLastUpdate(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Agora';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}min atrás';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h atrás';
      } else {
        return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  double _getChartInterval() {
    if (dailyConsumption.isEmpty) return 1;

    final maxValue =
        dailyConsumption.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return maxValue / 4;
  }

  double _getMinY() {
    if (dailyConsumption.isEmpty) return 0;

    final minValue =
        dailyConsumption.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    return minValue * 0.9;
  }

  double _getMaxY() {
    if (dailyConsumption.isEmpty) return 10;

    final maxValue =
        dailyConsumption.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return maxValue * 1.1;
  }
}

class DeviceTypeInfo {
  final String title;
  final String unit;
  final String chartLabel;
  final Color chartColor;
  final IconData icon;
  final bool isEnergy;
  final int decimals;

  DeviceTypeInfo({
    required this.title,
    required this.unit,
    required this.chartLabel,
    required this.chartColor,
    required this.icon,
    required this.isEnergy,
    required this.decimals,
  });
}
