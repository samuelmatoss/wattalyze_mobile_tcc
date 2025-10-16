import 'package:flutter/material.dart';
import '../../models/alert_rule.dart';
import '../../models/device_model.dart';
import '../../models/environment_model.dart';
import '../../services/alert_service.dart';

class AlertRulesScreen extends StatefulWidget {
  const AlertRulesScreen({Key? key}) : super(key: key);

  @override
  _AlertRulesScreenState createState() => _AlertRulesScreenState();
}

class _AlertRulesScreenState extends State<AlertRulesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _thresholdValueController = TextEditingController();

  String? _selectedType;
  int? _selectedDeviceId;
  int? _selectedEnvironmentId;

  List<AlertRule> _rules = [];
  List<Device> _devices = [];
  List<Environment> _environments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await AlertService.getRules();
      setState(() {
        _rules = data['rules'] as List<AlertRule>;
        _devices = data['devices'] as List<Device>;
        _environments = data['environments'] as List<Environment>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Erro ao carregar dados: $e');
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

  Future<void> _createRule() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final ruleData = {
        'name': _nameController.text,
        'type': _selectedType,
        'threshold_value': _thresholdValueController.text.isNotEmpty
            ? double.parse(_thresholdValueController.text)
            : null,
        'device_id': _selectedDeviceId,
        'environment_id': _selectedEnvironmentId,
      };

      await AlertService.createRule(ruleData);
      _clearForm();
      await _loadData();
      _showSuccessMessage('Regra criada com sucesso!');
    } catch (e) {
      _showErrorMessage('Erro ao criar regra: $e');
    }
  }

  Future<void> _toggleRule(AlertRule rule) async {
    try {
      await AlertService.toggleRule(rule.id);
      await _loadData();
      _showSuccessMessage('Status da regra alterado com sucesso!');
    } catch (e) {
      _showErrorMessage('Erro ao alterar status da regra: $e');
    }
  }

  Future<void> _deleteRule(AlertRule rule) async {
    final confirmed =
        await _showConfirmDialog('Tem certeza que deseja excluir esta regra?');

    if (confirmed) {
      try {
        await AlertService.deleteRule(rule.id);
        await _loadData();
        _showSuccessMessage('Regra excluí­da com sucesso!');
      } catch (e) {
        _showErrorMessage('Erro ao excluir regra: $e');
      }
    }
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmação'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE74C3C),
                ),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _clearForm() {
    _nameController.clear();
    _thresholdValueController.clear();
    setState(() {
      _selectedType = null;
      _selectedDeviceId = null;
      _selectedEnvironmentId = null;
    });
  }

  Widget _buildCreateRuleCard() {
    return Container(
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
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
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
              child: const Row(
                children: [
                  Icon(Icons.add_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Nova Regra',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFormLabel('Nome'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameController,
                      hintText: 'Digite o nome da regra',
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Nome obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFormLabel('Tipo'),
                    const SizedBox(height: 8),
                    _buildDropdown<String>(
                      value: _selectedType,
                      items: [
                        DropdownMenuItem(
                          value: 'consumption_threshold',
                          child: Text('Limite de Consumo'),
                        ),
                        DropdownMenuItem(
                          value: 'cost_threshold',
                          child: Text('Limite de Custo'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedType = value),
                      hint: 'Selecione o tipo',
                    ),
                    const SizedBox(height: 16),
                    _buildFormLabel('Valor do Limite'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _thresholdValueController,
                      hintText: '0.00',
                      keyboardType: TextInputType.number,
                      helperText: 'Opcional - deixe vazio se não aplicável',
                    ),
                    const SizedBox(height: 16),
                    _buildFormLabel('Dispositivo'),
                    const SizedBox(height: 8),
                    _buildDropdown<int>(
                      value: _selectedDeviceId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos os dispositivos'),
                        ),
                        ..._devices.map((device) => DropdownMenuItem(
                              value: device.id,
                              child: Text(device.name),
                            )),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedDeviceId = value),
                      hint: 'Selecione dispositivo',
                    ),
                    const SizedBox(height: 16),
                    _buildFormLabel('Ambiente'),
                    const SizedBox(height: 8),
                    _buildDropdown<int>(
                      value: _selectedEnvironmentId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos os ambientes'),
                        ),
                        ..._environments.map((env) => DropdownMenuItem(
                              value: env.id,
                              child: Text(env.name),
                            )),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedEnvironmentId = value),
                      hint: 'Selecione ambiente',
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildModernButton(
                        onPressed: _createRule,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add, size: 18),
                            SizedBox(width: 8),
                            Text('Criar Regra'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF27AE60),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  Widget _buildRulesListCard() {
    return Container(
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
            child: const Row(
              children: [
                Icon(Icons.list, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Regras Existentes',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (_rules.isEmpty) _buildEmptyState() else _buildRulesTable(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 60,
            color: Color(0xFF27AE60),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma regra cadastrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie sua primeira regra de alerta usando o formulário acima.',
            style: TextStyle(
              color: Color(0xFF6C757D),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRulesTable() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Icon(Icons.tag, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Nome',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Tipo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Icon(Icons.toggle_on, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Ações',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rules.length,
            itemBuilder: (context, index) {
              final rule = _rules[index];
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      width: 4,
                      color: rule.isActive
                          ? const Color(0xFF27AE60)
                          : Colors.transparent,
                    ),
                  ),
                ),
                child: InkWell(
                  onTap: () {},
                  hoverColor: const Color(0xFF27AE60).withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                color: Color(0xFF27AE60),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  rule.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatRuleType(rule.type),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () => _toggleRule(rule),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: rule.isActive
                                      ? [Color(0xFF27AE60), Color(0xFF2ECC71)]
                                      : [Color(0xFF95A5A6), Color(0xFF7F8C8D)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    rule.isActive
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rule.isActive ? 'Ativa' : 'Inativa',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildActionButton(
                                icon: Icons.edit,
                                color: const Color(0xFFE67E22),
                                onPressed: () => _editRule(rule),
                              ),
                              const SizedBox(width: 8),
                              _buildActionButton(
                                icon: Icons.delete,
                                color: const Color(0xFFE74C3C),
                                onPressed: () => _deleteRule(rule),
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
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  String _formatRuleType(String type) {
    switch (type) {
      case 'consumption_threshold':
        return 'Limite de Consumo';
      case 'cost_threshold':
        return 'Limite de Custo';
      default:
        return type;
    }
  }

  void _editRule(AlertRule rule) {
    // Implementar navegaÃ§Ã£o para tela de ediÃ§Ã£o
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          decoration: InputDecoration(
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
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: const TextStyle(
              color: Color(0xFF6C757D),
              fontSize: 12,
            ),
          ),
        ],
      ],
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
      decoration: InputDecoration(
        hintText: hint,
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
      ),
    );
  }

  Widget _buildModernButton({
    required VoidCallback onPressed,
    required Widget child,
    Color? backgroundColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? const Color(0xFF27AE60),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: child,
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFC3CFE2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF27AE60),
                                        Color(0xFF2ECC71)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Regras de Alerta',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            _buildCreateRuleCard(),
                            
                            _buildRulesListCard(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}