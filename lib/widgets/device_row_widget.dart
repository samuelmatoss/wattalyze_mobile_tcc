
import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../models/shared_models.dart';


class DeviceRowWidget extends StatelessWidget {
  final Device device;
  final InfluxData? influxData;
  final List<DailyMeasurement> dailyConsumption;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const DeviceRowWidget({
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
    final todayConsumption = _getTodayConsumption();
    final instantaneousPower = influxData?.value;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone do dispositivo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: deviceType.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  deviceType.icon,
                  color: deviceType.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Informações principais
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.macAddress,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (device.environment != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              device.environment!.name,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Status
              // Valor atual/instantâneo
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      deviceType.instantLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      instantaneousPower != null 
                          ? '${instantaneousPower.toStringAsFixed(deviceType.decimals)} ${deviceType.unit}'
                          : 'Sem dados',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: instantaneousPower != null ? Colors.black87 : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Consumo diário (apenas para energia)
              if (deviceType.isEnergy)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Hoje',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${todayConsumption.toStringAsFixed(3)} kWh',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              
              // Ações
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'diagnostics':
                      // Implementar navegação para diagnósticos
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'diagnostics',
                    child: Row(
                      children: [
                        Icon(Icons.analytics, size: 18),
                        SizedBox(width: 8),
                        Text('Diagnósticos'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red[400]),
                        const SizedBox(width: 8),
                        Text('Excluir', style: TextStyle(color: Colors.red[400])),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _getStatusText(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  DeviceTypeInfo _getDeviceTypeInfo() {
    final typeName = device.deviceType?.name.toLowerCase() ?? '';
    
    if (typeName.contains('temperature')) {
      return DeviceTypeInfo(
        unit: '°C',
        instantLabel: 'Temperatura',
        color: Colors.orange,
        icon: Icons.thermostat,
        isEnergy: false,
        decimals: 1,
      );
    } else if (typeName.contains('humidity')) {
      return DeviceTypeInfo(
        unit: '%',
        instantLabel: 'Umidade',
        color: Colors.blue,
        icon: Icons.water_drop,
        isEnergy: false,
        decimals: 1,
      );
    } else {
      return DeviceTypeInfo(
        unit: 'W',
        instantLabel: 'Potência',
        color: Colors.green,
        icon: Icons.electrical_services,
        isEnergy: true,
        decimals: 2,
      );
    }
  }

  double _getTodayConsumption() {
    if (dailyConsumption.isEmpty) return 0.0;
    
    final lastRecord = dailyConsumption.last;
    return lastRecord.value;
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

  String _getStatusText() {
    switch (device.status.toLowerCase()) {
      case 'online':
        return 'Online';
      case 'offline':
        return 'Offline';
      case 'maintenance':
        return 'Manutenção';
      default:
        return 'Desconhecido';
    }
  }
}

class DeviceTypeInfo {
  final String unit;
  final String instantLabel;
  final Color color;
  final IconData icon;
  final bool isEnergy;
  final int decimals;

  DeviceTypeInfo({
    required this.unit,
    required this.instantLabel,
    required this.color,
    required this.icon,
    required this.isEnergy,
    required this.decimals,
  });
}
