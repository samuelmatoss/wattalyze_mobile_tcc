
import 'package:flutter/material.dart';
import '../models/device_model.dart';

class FilterBottomSheet extends StatefulWidget {
  final List<DeviceEnvironment> environments;
  final List<DeviceType> deviceTypes;
  final String currentStatus;
  final int? currentEnvironment;
  final int? currentDeviceType;
  final Function(String status, int? environmentId, int? deviceTypeId) onFiltersChanged;

  const FilterBottomSheet({
    Key? key,
    required this.environments,
    required this.deviceTypes,
    required this.currentStatus,
    required this.currentEnvironment,
    required this.currentDeviceType,
    required this.onFiltersChanged,
  }) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _selectedStatus;
  int? _selectedEnvironment;
  int? _selectedDeviceType;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
    _selectedEnvironment = widget.currentEnvironment;
    _selectedDeviceType = widget.currentDeviceType;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle indicator
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.filter_list),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Filtrar Dispositivos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Limpar'),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Filter content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusFilter(),
                  const SizedBox(height: 24),
                  _buildEnvironmentFilter(),
                  const SizedBox(height: 24),
                  _buildDeviceTypeFilter(),
                ],
              ),
            ),
          ),
          
          // Action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Aplicar Filtros'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatusChip('all', 'Todos'),
            _buildStatusChip('online', 'Online'),
            _buildStatusChip('offline', 'Offline'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String value, String label) {
    final isSelected = _selectedStatus == value;
    
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != 'all')
            Icon(
              _getStatusIcon(value),
              size: 16,
              color: isSelected ? Colors.white : _getStatusColor(value),
            ),
          if (value != 'all') const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
      },
      selectedColor: value == 'all' ? Colors.blue : _getStatusColor(value),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildEnvironmentFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ambiente',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.environments.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Nenhum ambiente cadastrado',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                selected: _selectedEnvironment == null,
                label: const Text('Todos'),
                onSelected: (selected) {
                  setState(() {
                    _selectedEnvironment = null;
                  });
                },
                selectedColor: Colors.blue,
                checkmarkColor: Colors.white,
              ),
              ...widget.environments.map((env) => FilterChip(
                selected: _selectedEnvironment == env.id,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Text(env.name),
                  ],
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedEnvironment = selected ? env.id : null;
                  });
                },
                selectedColor: Colors.green,
                checkmarkColor: Colors.white,
              )).toList(),
            ],
          ),
      ],
    );
  }

  Widget _buildDeviceTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Dispositivo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.deviceTypes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Nenhum tipo cadastrado',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                selected: _selectedDeviceType == null,
                label: const Text('Todos'),
                onSelected: (selected) {
                  setState(() {
                    _selectedDeviceType = null;
                  });
                },
                selectedColor: Colors.blue,
                checkmarkColor: Colors.white,
              ),
              ...widget.deviceTypes.map((type) => FilterChip(
                selected: _selectedDeviceType == type.id,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getDeviceTypeIcon(type.name), size: 16),
                    const SizedBox(width: 4),
                    Text(type.name),
                  ],
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedDeviceType = selected ? type.id : null;
                  });
                },
                selectedColor: Colors.purple,
                checkmarkColor: Colors.white,
              )).toList(),
            ],
          ),
      ],
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStatus = 'all';
      _selectedEnvironment = null;
      _selectedDeviceType = null;
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_selectedStatus, _selectedEnvironment, _selectedDeviceType);
    Navigator.pop(context);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Colors.green;
      case 'offline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Icons.check_circle;
      case 'offline':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  IconData _getDeviceTypeIcon(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('temperature')) {
      return Icons.thermostat;
    } else if (lowerType.contains('humidity')) {
      return Icons.water_drop;
    } else if (lowerType.contains('energy') || lowerType.contains('power')) {
      return Icons.electrical_services;
    } else if (lowerType.contains('sensor')) {
      return Icons.sensors;
    } else {
      return Icons.device_unknown;
    }
  }
}
