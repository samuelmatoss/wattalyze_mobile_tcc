import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report_model.dart';
import '../../models/device_model.dart';
import '../../services/report_service.dart';

class GenerateReportScreen extends StatefulWidget {
  final String token;

  const GenerateReportScreen({Key? key, required this.token}) : super(key: key);

  @override
  _GenerateReportScreenState createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedType;
  String? _selectedPeriodType;
  String? _selectedFormat;
  DateTime? _startDate;
  DateTime? _endDate;
  List<Device> _devices = [];
  List<int> _selectedDeviceIds = [];
  bool _isLoading = false;
  bool _devicesLoaded = false;

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final devices = await ReportService.getDevicesForReport(widget.token);
      setState(() {
        _devices = devices;
        _devicesLoaded = true;
      });
    } catch (e) {
      setState(() => _devicesLoaded = true);
      _showErrorMessage('Erro ao carregar dispositivos: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE74C3C),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF27AE60),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now().subtract(const Duration(days: 30)))
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF27AE60),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2C3E50),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Ajustar data de fim se necessÃ¡rio
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar perÃ­odo
    final periodError = ReportService.validatePeriod(_startDate, _endDate);
    if (periodError != null) {
      _showErrorMessage(periodError);
      return;
    }

    // Validar dispositivos selecionados
    if (_selectedDeviceIds.isEmpty) {
      _showErrorMessage('Selecione pelo menos um dispositivo');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = CreateReportRequest(
        name: _nameController.text,
        type: _selectedType!,
        periodType: _selectedPeriodType!,
        periodStart: _startDate!,
        periodEnd: _endDate!,
        format: _selectedFormat!,
        deviceIds: _selectedDeviceIds,
      );

      final report = await ReportService.createReport(widget.token, request);

      _showSuccessMessage(
          'Relatório criado! Será processado em segundo plano.');

      // Navegar de volta e indicar sucesso
      Navigator.of(context).pop(true);
    } catch (e) {
      _showErrorMessage('Erro ao criar relatório: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildFormSection(
      title: 'Informações Básicas',
      icon: Icons.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormLabel('Nome do Relatório'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Nome obrigatório';
              }
              return null;
            },
            decoration: _buildInputDecoration('Digite o nome do relatório'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Tipo de RelatÃ³rio'),
                    const SizedBox(height: 8),
                    _buildDropdown<String>(
                      value: _selectedType,
                      items: ReportService.getReportTypes()
                          .map<DropdownMenuItem<String>>((type) =>
                              DropdownMenuItem<String>(
                                value: type['value'] as String,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(type['label']),
                                    Text(
                                      type['description'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6C757D),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedType = value),
                      hint: 'Selecione o tipo',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Formato'),
                    const SizedBox(height: 8),
                    _buildDropdown<String>(
                      value: _selectedFormat,
                      items: ReportService.getReportTypes()
                          .map<DropdownMenuItem<String>>(
                              (type) => DropdownMenuItem<String>(
                                    value: type['value'] as String,
                                    child: Column(
                                      children: [
                                        Icon(
                                          _getIconData(type['icon']),
                                          size: 16,
                                          color: const Color(0xFF27AE60),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(type['label']),
                                      ],
                                    ),
                                  ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedFormat = value),
                      hint: 'Formato do arquivo',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSection() {
    return _buildFormSection(
      title: 'Período do Relatório',
      icon: Icons.date_range,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormLabel('Agrupamento'),
          const SizedBox(height: 8),
          _buildDropdown<String>(
            value: _selectedPeriodType,
            items: ReportService.getFormats()
                .map<DropdownMenuItem<String>>(
                    (format) => DropdownMenuItem<String>(
                          value: format['value'] as String,
                          child: Row(
                            children: [
                              Icon(
                                _getIconData(format['icon'] as String),
                                size: 16,
                                color: const Color(0xFF27AE60),
                              ),
                              const SizedBox(width: 8),
                              Text(format['label'] as String),
                            ],
                          ),
                        ))
                .toList(),
            onChanged: (value) => setState(() => _selectedPeriodType = value),
            hint: 'Como agrupar os dados',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Data Inicial'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(true),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFE9ECEF),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF27AE60),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _startDate != null
                                  ? _dateFormatter.format(_startDate!)
                                  : 'Selecionar data',
                              style: TextStyle(
                                color: _startDate != null
                                    ? const Color(0xFF2C3E50)
                                    : const Color(0xFF6C757D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Data Final'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(false),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFE9ECEF),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF27AE60),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _endDate != null
                                  ? _dateFormatter.format(_endDate!)
                                  : 'Selecionar data',
                              style: TextStyle(
                                color: _endDate != null
                                    ? const Color(0xFF2C3E50)
                                    : const Color(0xFF6C757D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_startDate != null && _endDate != null) ...[
            const SizedBox(height: 12),
            _buildPeriodInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodInfo() {
    final days = _endDate!.difference(_startDate!).inDays + 1;
    final estimatedSize = ReportService.estimateReportSize(
      CreateReportRequest(
        name: _nameController.text,
        type: _selectedType ?? 'consumption',
        periodType: _selectedPeriodType ?? 'daily',
        periodStart: _startDate!,
        periodEnd: _endDate!,
        format: _selectedFormat ?? 'pdf',
        deviceIds: _selectedDeviceIds,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF27AE60).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(
            width: 4,
            color: Color(0xFF27AE60),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações do Período:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$days dias de dados',
            style: const TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 13,
            ),
          ),
          Text(
            'Tamanho estimado: $estimatedSize',
            style: const TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesSection() {
    return _buildFormSection(
      title: 'Dispositivos',
      icon: Icons.devices,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildFormLabel('Selecionar Dispositivos'),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedDeviceIds.length == _devices.length) {
                      _selectedDeviceIds.clear();
                    } else {
                      _selectedDeviceIds = _devices.map((d) => d.id).toList();
                    }
                  });
                },
                child: Text(
                  _selectedDeviceIds.length == _devices.length
                      ? 'Desmarcar todos'
                      : 'Selecionar todos',
                  style: const TextStyle(
                    color: Color(0xFF27AE60),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_devicesLoaded)
            const Center(child: CircularProgressIndicator())
          else if (_devices.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: const Text(
                'Nenhum dispositivo encontrado. Cadastre dispositivos primeiro.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6C757D),
                ),
              ),
            )
          else
            ...(_devices.map((device) => _buildDeviceCheckbox(device))),
        ],
      ),
    );
  }

  Widget _buildDeviceCheckbox(Device device) {
    final isSelected = _selectedDeviceIds.contains(device.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedDeviceIds.remove(device.id);
            } else {
              _selectedDeviceIds.add(device.id);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF27AE60).withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF27AE60)
                  : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                color: isSelected
                    ? const Color(0xFF27AE60)
                    : const Color(0xFF6C757D),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    if (device.environment != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        device.environment!.name,
                        style: const TextStyle(
                          color: Color(0xFF6C757D),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF27AE60),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE9ECEF), width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF27AE60), width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.8),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String hint,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: _buildInputDecoration(hint),
      validator: (value) {
        if (value == null) {
          return 'Campo obrigatório';
        }
        return null;
      },
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'picture_as_pdf':
        return Icons.picture_as_pdf;
      case 'table_chart':
        return Icons.table_chart;
      case 'grid_on':
        return Icons.grid_on;
      case 'code':
        return Icons.code;
      default:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerar Relatório'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2C3E50),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFC3CFE2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildBasicInfoSection(),
                _buildPeriodSection(),
                _buildDevicesSection(),
                const SizedBox(height: 32),

                // BotÃ£o gerar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _generateReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Gerando...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.insert_drive_file,
                                  color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Gerar Relatório',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}