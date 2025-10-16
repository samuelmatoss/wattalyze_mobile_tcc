import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/device_model.dart';
import '../../services/device_service.dart';

class DeviceEditScreen extends StatefulWidget {
  final Device device;
  final String authToken;

  const DeviceEditScreen({
    Key? key,
    required this.device,
    required this.authToken,
  }) : super(key: key);

  @override
  State<DeviceEditScreen> createState() => _DeviceEditScreenState();
}

class _DeviceEditScreenState extends State<DeviceEditScreen>
    with SingleTickerProviderStateMixin {
  late DeviceService _deviceService;
  late TabController _tabController;
  
  final _formKey = GlobalKey<FormState>();
  final _basicFormKey = GlobalKey<FormState>();
  final _technicalFormKey = GlobalKey<FormState>();
  
  // Controllers para campos bÃ¡sicos
  final _nameController = TextEditingController();
  final _macAddressController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Controllers para campos tÃ©cnicos
  final _serialNumberController = TextEditingController();
  final _modelController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _firmwareVersionController = TextEditingController();
  final _ratedPowerController = TextEditingController();
  final _ratedVoltageController = TextEditingController();
  
  // Dados do formulÃ¡rio
  List<DeviceEnvironment> _environments = [];
  List<DeviceType> _deviceTypes = [];
  
  // Valores selecionados
  String _selectedStatus = 'offline';
  int? _selectedEnvironmentId;
  int? _selectedDeviceTypeId;
  DateTime? _installationDate;
  
  bool _isLoading = false;
  bool _isLoadingFormData = true;
  String? _error;
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _deviceService = DeviceService(widget.authToken);
    _tabController = TabController(length: 2, vsync: this);
    _populateFormWithDeviceData();
    _loadFormData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _macAddressController.dispose();
    _locationController.dispose();
    _serialNumberController.dispose();
    _modelController.dispose();
    _manufacturerController.dispose();
    _firmwareVersionController.dispose();
    _ratedPowerController.dispose();
    _ratedVoltageController.dispose();
    super.dispose();
  }

  void _populateFormWithDeviceData() {
    final device = widget.device;
    
    _nameController.text = device.name;
    _macAddressController.text = device.macAddress;
    _locationController.text = device.location ?? '';
    _serialNumberController.text = device.serialNumber ?? '';
    _modelController.text = device.model ?? '';
    _manufacturerController.text = device.manufacturer ?? '';
    _firmwareVersionController.text = device.firmwareVersion ?? '';
    _ratedPowerController.text = device.ratedPower?.toString() ?? '';
    _ratedVoltageController.text = device.ratedVoltage?.toString() ?? '';
    
    _selectedStatus = device.status;
    _selectedEnvironmentId = device.environmentId;
    _selectedDeviceTypeId = device.deviceTypeId;
    
    if (device.installationDate != null) {
      _installationDate = DateTime.tryParse(device.installationDate!);
    }
  }

  Future<void> _loadFormData() async {
    try {
      setState(() {
        _isLoadingFormData = true;
        _error = null;
      });

      final response = await _deviceService.getEditData(widget.device.id);
      
      setState(() {
        _environments = response.environments;
        _deviceTypes = response.deviceTypes;
        _isLoadingFormData = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingFormData = false;
      });
    }
  }

  Future<void> _submitForm() async {
    _fieldErrors.clear();
    
    // Validar ambas as abas
    final basicValid = _basicFormKey.currentState?.validate() ?? false;
    final technicalValid = _technicalFormKey.currentState?.validate() ?? false;
    
    if (!basicValid) {
      _tabController.animateTo(0);
      return;
    }
    
    if (!technicalValid) {
      _tabController.animateTo(1);
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final updatedDevice = widget.device.copyWith(
        name: _nameController.text.trim(),
        macAddress: _macAddressController.text.trim(),
        status: _selectedStatus,
        serialNumber: _serialNumberController.text.trim().isEmpty 
            ? null 
            : _serialNumberController.text.trim(),
        model: _modelController.text.trim().isEmpty 
            ? null 
            : _modelController.text.trim(),
        manufacturer: _manufacturerController.text.trim().isEmpty 
            ? null 
            : _manufacturerController.text.trim(),
        firmwareVersion: _firmwareVersionController.text.trim().isEmpty 
            ? null 
            : _firmwareVersionController.text.trim(),
        location: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
        installationDate: _installationDate?.toIso8601String().split('T').first,
        ratedPower: _ratedPowerController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_ratedPowerController.text.trim()),
        ratedVoltage: _ratedVoltageController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_ratedVoltageController.text.trim()),
        deviceTypeId: _selectedDeviceTypeId,
        environmentId: _selectedEnvironmentId,
      );

      // ValidaÃ§Ã£o adicional
      final validationErrors = DeviceService.validateDevice(updatedDevice);
      if (validationErrors.isNotEmpty) {
        setState(() {
          _fieldErrors = validationErrors;
        });
        
        // Mostrar primeiro erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de validação: ${validationErrors.values.first}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _deviceService.updateDevice(widget.device.id, updatedDevice);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dispositivo atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna true para indicar que foi atualizado
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        
        // Verificar se Ã© erro de validaÃ§Ã£o
        if (e.toString().contains('validação')) {
          final errorMsg = e.toString();
          if (errorMsg.contains('mac_address')) {
            _fieldErrors['mac_address'] = 'Endereço MAC inválido ou já existe';
          }
          if (errorMsg.contains('serial_number')) {
            _fieldErrors['serial_number'] = 'Número de série já existe';
          }
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Editar ${widget.device.name}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: _isLoadingFormData ? _buildLoadingState() : _buildForm(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando dados do dispositivo...'),
        ],
      ),
    );
  }

  Widget _buildForm() {
    if (_error != null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        // Device info header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getDeviceTypeIcon(),
                  color: _getStatusColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.device.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.device.macAddress,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              _buildCurrentStatusBadge(),
            ],
          ),
        ),
        
        // Tab bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue[600],
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue[600],
            tabs: const [
              Tab(text: 'Informações Básicas'),
              Tab(text: 'Detalhes Técnicos'),
            ],
          ),
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBasicForm(),
              _buildTechnicalForm(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStatusBadge() {
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
            widget.device.status.toUpperCase(),
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

  Widget _buildBasicForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _basicFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: 'Identificação',
              icon: Icons.badge,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Nome do Dispositivo *',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome Ã© obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildMacAddressField(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _locationController,
                  label: 'Localização',
                  icon: Icons.location_on,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Configuração',
              icon: Icons.settings,
              children: [
                _buildStatusDropdown(),
                const SizedBox(height: 16),
                _buildEnvironmentDropdown(),
                const SizedBox(height: 16),
                _buildDeviceTypeDropdown(),
                const SizedBox(height: 16),
                _buildInstallationDatePicker(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _technicalFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: 'Especificações Técnicas',
              icon: Icons.memory,
              children: [
                _buildTextField(
                  controller: _serialNumberController,
                  label: 'Número de Série',
                  icon: Icons.qr_code,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _modelController,
                  label: 'Modelo',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _manufacturerController,
                  label: 'Fabricante',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _firmwareVersionController,
                  label: 'Versão do Firmware',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Especificações Elétricas',
              icon: Icons.electrical_services,
              children: [
                _buildNumberField(
                  controller: _ratedPowerController,
                  label: 'Potência Nominal (W)',
                  suffix: 'W',
                ),
                const SizedBox(height: 16),
                _buildNumberField(
                  controller: _ratedVoltageController,
                  label: 'Tensão Nominal (V)',
                  suffix: 'V',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    final hasError = _fieldErrors.containsKey(_getFieldKey(label));
    
    return TextFormField(
      controller: controller,
      validator: validator,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        errorText: hasError ? _fieldErrors[_getFieldKey(label)] : null,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildMacAddressField() {
    return _buildTextField(
      controller: _macAddressController,
      label: 'Endereço MAC *',
      icon: Icons.network_check,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f:]')),
        LengthLimitingTextInputFormatter(17),
        _MacAddressFormatter(),
      ],
      keyboardType: TextInputType.text,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Endereço MAC obrigatório';
        }
        if (!DeviceService.isValidMacAddress(value)) {
          return 'Formato de MAC inválido (XX:XX:XX:XX:XX:XX)';
        }
        return null;
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status *',
        prefixIcon: Icon(_getStatusIconByValue(_selectedStatus)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: DeviceService.getAvailableStatuses().map((status) {
        return DropdownMenuItem(
          value: status,
          child: Row(
            children: [
              Icon(_getStatusIconByValue(status), size: 16),
              const SizedBox(width: 8),
              Text(_getStatusTextByValue(status)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedStatus = value!;
        });
      },
    );
  }

  Widget _buildEnvironmentDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedEnvironmentId,
      decoration: InputDecoration(
        labelText: 'Ambiente',
        prefixIcon: const Icon(Icons.home),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      hint: const Text('Selecione um ambiente'),
      items: _environments.map((env) {
        return DropdownMenuItem(
          value: env.id,
          child: Text(env.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedEnvironmentId = value;
        });
      },
    );
  }

  Widget _buildDeviceTypeDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedDeviceTypeId,
      decoration: InputDecoration(
        labelText: 'Tipo de Dispositivo',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      hint: const Text('Selecione o tipo'),
      items: _deviceTypes.map((type) {
        return DropdownMenuItem(
          value: type.id,
          child: Text(type.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDeviceTypeId = value;
        });
      },
    );
  }

  Widget _buildInstallationDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _installationDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            _installationDate = date;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Data de Instalação',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          _installationDate != null
              ? '${_installationDate!.day.toString().padLeft(2, '0')}/${_installationDate!.month.toString().padLeft(2, '0')}/${_installationDate!.year}'
              : 'Selecione a data',
          style: TextStyle(
            color: _installationDate != null ? Colors.black87 : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    String? suffix,
  }) {
    return _buildTextField(
      controller: controller,
      label: label,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          final number = double.tryParse(value.trim());
          if (number == null || number < 0) {
            return 'Digite um número válido';
          }
        }
        return null;
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar dados',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFormData,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.device.status.toLowerCase()) {
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
    switch (widget.device.status.toLowerCase()) {
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

  IconData _getDeviceTypeIcon() {
    final typeName = widget.device.deviceType?.name.toLowerCase() ?? '';
    if (typeName.contains('temperature')) {
      return Icons.thermostat;
    } else if (typeName.contains('humidity')) {
      return Icons.water_drop;
    } else {
      return Icons.electrical_services;
    }
  }

  IconData _getStatusIconByValue(String status) {
    switch (status.toLowerCase()) {
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

  String _getStatusTextByValue(String status) {
    switch (status.toLowerCase()) {
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

  String _getFieldKey(String label) {
    return label.toLowerCase()
        .replaceAll(' *', '')
        .replaceAll(' ', '_')
        .replaceAll('Ã§', 'c')
        .replaceAll('Ã£', 'a')
        .replaceAll('Ãª', 'e');
  }
}

// Formatter para endereÃ§o MAC (reutilizado do create screen)
class _MacAddressFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(':', '').toUpperCase();
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length && i < 12; i++) {
      if (i > 0 && i % 2 == 0) {
        buffer.write(':');
      }
      buffer.write(text[i]);
    }
    
    final formatted = buffer.toString();
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}