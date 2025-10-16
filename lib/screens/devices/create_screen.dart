import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/device_model.dart';
import '../../services/device_service.dart';


class DeviceCreateScreen extends StatefulWidget {
 final String authToken;


 const DeviceCreateScreen({Key? key, required this.authToken})
: super(key: key);


 @override
State<DeviceCreateScreen> createState() => _DeviceCreateScreenState();
}


class _DeviceCreateScreenState extends State<DeviceCreateScreen>
 with TickerProviderStateMixin {
late DeviceService _deviceService;
 late TabController _tabController;
 late AnimationController _animationController;


 final _formKey = GlobalKey<FormState>();
final _basicFormKey = GlobalKey<FormState>();
final _technicalFormKey = GlobalKey<FormState>();

// Controllers
final _nameController = TextEditingController();
 final _macAddressController = TextEditingController();
 final _locationController = TextEditingController();
final _serialNumberController = TextEditingController();
 final _modelController = TextEditingController();
 final _manufacturerController = TextEditingController();
 final _firmwareVersionController = TextEditingController();
 final _ratedPowerController = TextEditingController();
 final _ratedVoltageController = TextEditingController();


 // Dados do formulário
 List<DeviceEnvironment> _environments = [];
 List<DeviceType> _deviceTypes = [];


 String _selectedStatus = 'offline';
 int? _selectedEnvironmentId;
int? _selectedDeviceTypeId;
 DateTime? _installationDate;


 bool _isLoading = false;
 bool _isLoadingFormData = true;
 String? _error;
 Map<String, String> _fieldErrors = {};


 // Cores
 static const primaryGreen = Color(0xFF00D9A3);
 static const primaryDark = Color(0xFF00B386);
 static const bgColor = Color(0xFFF8FAFC);
 static const cardBg = Color(0xFFFFFFFF);
 static const textPrimary = Color(0xFF1E293B);
 static const textSecondary = Color(0xFF64748B);


@override
void initState() {
super.initState();
 _deviceService = DeviceService(widget.authToken);
 _tabController = TabController(length: 2, vsync: this);
_animationController = AnimationController(
duration: const Duration(milliseconds: 600),
vsync: this,
 );
 _loadFormData();
 }

@override void dispose() { 
  _tabController.dispose();
   _animationController.dispose();
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

 Future<void> _loadFormData() async {
 try {
setState(() {
 _isLoadingFormData = true;
 _error = null;
 });


 final response = await _deviceService.getFormData();


if (!mounted) return;


setState(() {
 _environments = response.environments;
 _deviceTypes = response.deviceTypes;
 _isLoadingFormData = false;
 });


_animationController.forward();
} catch (e) {
 if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingFormData = false;
      });
    }
  }


  Future<void> _submitForm() async {
    _fieldErrors.clear();


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


      final device = Device(
        id: 0,
        name: _nameController.text.trim(),
        macAddress: _macAddressController.text.trim(),
        status: _selectedStatus,
        userId: 0,
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


      final validationErrors = DeviceService.validateDevice(device);
      if (validationErrors.isNotEmpty) {
        setState(() => _fieldErrors = validationErrors);


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro: ${validationErrors.values.first}')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }


      await _deviceService.storeDevice(device);


      if (!mounted) return;


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Dispositivo cadastrado com sucesso!',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;


      setState(() {
        _error = e.toString();


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


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erro ao cadastrar: $e')),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Adicionar Dispositivo',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: cardBg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _isLoading ? null : _submitForm,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: primaryGreen),
                    )
                  : const Icon(Icons.check_rounded, size: 20),
              label: const Text('Salvar',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                foregroundColor: primaryGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: _isLoadingFormData ? _buildLoadingState() : _buildForm(),
    );
  }


  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryGreen.withOpacity(0.1),
                  primaryDark.withOpacity(0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
                color: primaryGreen, strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          const Text(
            'Carregando formulário...',
            style: TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 15),
          ),
        ],
      ),
    );
  }


  Widget _buildForm() {
    if (_error != null) return _buildErrorState();


    return Column(
      children: [
        Container(
          color: cardBg,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryGreen.withOpacity(0.15),
                                primaryDark.withOpacity(0.15)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.info_outline_rounded,
                              color: primaryGreen, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Adicione um novo dispositivo IoT',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Preencha os dados para começar o monitoramento de energia. Os campos com * são obrigatórios.',
                      style: TextStyle(
                          fontSize: 13, color: textSecondary, height: 1.5),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Colors.grey[200]!, width: 1)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: primaryGreen,
                  unselectedLabelColor: textSecondary,
                  indicatorColor: primaryGreen,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Informações Básicas'),
                    Tab(text: 'Detalhes Técnicos'),
                  ],
                ),
              ),
            ],
          ),
        ),
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


  Widget _buildBasicForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: FadeTransition(
        opacity: _animationController,
        child: Form(
          key: _basicFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                title: 'Identificação',
                icon: Icons.badge_rounded,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nome do Dispositivo *',
                    hint: 'Ex: Sensor Sala Principal',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nome é obrigatório';
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
                    hint: 'Ex: Sala de Reuniões 1, Corredor A',
                    icon: Icons.location_on_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Configuração',
                icon: Icons.settings_rounded,
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
      ),
    );
  }


  Widget _buildTechnicalForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: FadeTransition(
        opacity: _animationController,
        child: Form(
          key: _technicalFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                title: 'Especificações Técnicas',
                icon: Icons.memory_rounded,
                children: [
                  _buildTextField(
                    controller: _serialNumberController,
                    label: 'Número de Série',
                    hint: 'Ex: SN123456789',
                    icon: Icons.qr_code_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _modelController,
                    label: 'Modelo',
                    hint: 'Ex: ESP32-DevKit',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _manufacturerController,
                    label: 'Fabricante',
                    hint: 'Ex: Espressif',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _firmwareVersionController,
                    label: 'Versão do Firmware',
                    hint: 'Ex: v1.2.3',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Especificações Elétricas',
                icon: Icons.electrical_services_rounded,
                children: [
                  _buildNumberField(
                    controller: _ratedPowerController,
                    label: 'Potência Nominal (W)',
                    hint: 'Ex: 150',
                    suffix: 'W',
                  ),
                  const SizedBox(height: 8),
                  _buildHelpText('Potência de consumo do dispositivo em Watts'),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    controller: _ratedVoltageController,
                    label: 'Tensão Nominal (V)',
                    hint: 'Ex: 220',
                    suffix: 'V',
                  ),
                  const SizedBox(height: 8),
                  _buildHelpText('Tensão de alimentação (110V, 220V, etc.)'),
                ],
              ),
            ],
          ),
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
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryGreen.withOpacity(0.15),
                        primaryDark.withOpacity(0.15)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary),
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
    String? hint,
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
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon:
            icon != null ? Icon(icon, color: primaryGreen, size: 20) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorText: hasError ? _fieldErrors[_getFieldKey(label)] : null,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }


  Widget _buildMacAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _macAddressController,
          label: 'Endereço MAC *',
          hint: '00:1A:2B:3C:4D:5E',
          icon: Icons.network_check_rounded,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f:]')),
            LengthLimitingTextInputFormatter(17),
            _MacAddressFormatter(),
          ],
          keyboardType: TextInputType.text,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Endereço MAC é obrigatório';
            }
            if (!DeviceService.isValidMacAddress(value)) {
              return 'Formato inválido (XX:XX:XX:XX:XX:XX)';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildHelpCard(
          title: 'Onde encontrar o MAC:',
          items: [
            'Na etiqueta física do dispositivo',
            'No manual do fabricante',
            'Na configuração de rede',
          ],
        ),
      ],
    );
  }


  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary),
      decoration: InputDecoration(
        labelText: 'Status Inicial *',
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        prefixIcon: Icon(_getStatusIcon(_selectedStatus),
            color: primaryGreen, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: DeviceService.getAvailableStatuses().map((status) {
        return DropdownMenuItem(
          value: status,
          child: Row(
            children: [
              Icon(_getStatusIcon(status),
                  size: 18, color: _getStatusColor(status)),
              const SizedBox(width: 10),
              Text(_getStatusText(status)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedStatus = value!),
    );
  }


  Widget _buildEnvironmentDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedEnvironmentId,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary),
      decoration: InputDecoration(
        labelText: 'Ambiente',
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        prefixIcon:
            const Icon(Icons.home_rounded, color: primaryGreen, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      hint: const Text('Selecione um ambiente'),
      items: _environments.map((env) {
        return DropdownMenuItem(value: env.id, child: Text(env.name));
      }).toList(),
      onChanged: (value) => setState(() => _selectedEnvironmentId = value),
    );
  }


  Widget _buildDeviceTypeDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedDeviceTypeId,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary),
      decoration: InputDecoration(
        labelText: 'Tipo de Dispositivo',
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        prefixIcon:
            const Icon(Icons.category_rounded, color: primaryGreen, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      hint: const Text('Selecione o tipo'),
      items: _deviceTypes.map((type) {
        return DropdownMenuItem(value: type.id, child: Text(type.name));
      }).toList(),
      onChanged: (value) => setState(() => _selectedDeviceTypeId = value),
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
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: primaryGreen),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() => _installationDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Data de Instalação',
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          prefixIcon: const Icon(Icons.calendar_today_rounded,
              color: primaryGreen, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        child: Text(
          _installationDate != null
              ? '${_installationDate!.day.toString().padLeft(2, '0')}/${_installationDate!.month.toString().padLeft(2, '0')}/${_installationDate!.year}'
              : 'Selecione a data',
          style: TextStyle(
            color: _installationDate != null ? textPrimary : textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }


  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? suffix,
  }) {
    return _buildTextField(
      controller: controller,
      label: label,
      hint: hint,
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


  Widget _buildHelpCard({required String title, required List<String> items}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGreen.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: primaryDark, fontSize: 12),
          ),
          const SizedBox(height: 6),
          ...items
              .map((item) => Padding(
                    padding: const EdgeInsets.only(left: 4, top: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.w700)),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                                color: primaryDark, fontSize: 11, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }


  Widget _buildHelpText(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
    );
  }


  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.red[400]!, Colors.red[600]!]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Erro ao carregar formulário',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadFormData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar Novamente',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }


  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Icons.check_circle_rounded;
      case 'offline':
        return Icons.cancel_rounded;
      case 'maintenance':
        return Icons.build_rounded;
      default:
        return Icons.help_rounded;
    }
  }


  Color _getStatusColor(String status) {
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


  String _getStatusText(String status) {
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
    return label
        .toLowerCase()
        .replaceAll(' *', '')
        .replaceAll(' ', '_')
        .replaceAll('ç', 'c')
        .replaceAll('ã', 'a')
        .replaceAll('ê', 'e');
  }
}


// Formatter para endereço MAC
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
