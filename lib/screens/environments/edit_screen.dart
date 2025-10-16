import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../services/environment_service.dart';
import '../../models/environment_model.dart';
import '../../theme/wattalyze_colors.dart';

class EnvironmentEditScreen extends StatefulWidget {
  final String token;
  final Environment environment;

  const EnvironmentEditScreen({
    Key? key,
    required this.token,
    required this.environment,
  }) : super(key: key);

  @override
  State<EnvironmentEditScreen> createState() => _EnvironmentEditScreenState();
}

class _EnvironmentEditScreenState extends State<EnvironmentEditScreen>
    with TickerProviderStateMixin {
  late EnvironmentService _environmentService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sizeSqmController = TextEditingController();
  final _occupancyController = TextEditingController();
  final _voltageStandardController = TextEditingController();
  final _tariffTypeController = TextEditingController();
  final _energyProviderController = TextEditingController();
  final _installationDateController = TextEditingController();

  String? _selectedType;
  bool _isDefault = false;
  bool _isLoading = false;
  Map<String, String?> _errors = {};

  final List<Map<String, String>> _environmentTypes = [
    {'value': 'residential', 'label': 'Residencial', 'icon': '🏠'},
    {'value': 'commercial', 'label': 'Comercial', 'icon': '🏢'},
    {'value': 'industrial', 'label': 'Industrial', 'icon': '🏭'},
    {'value': 'public', 'label': 'Público', 'icon': '🏛️'},
  ];

  @override
  void initState() {
    super.initState();
    _environmentService = EnvironmentService(widget.token);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeFields();
    _animationController.forward();
  }

  void _initializeFields() {
    final env = widget.environment;

    _nameController.text = env.name;
    _descriptionController.text = env.description ?? '';
    _sizeSqmController.text = env.sizeSqm?.toString() ?? '';
    _occupancyController.text = env.occupancy?.toString() ?? '';
    _voltageStandardController.text = env.voltageStandard ?? '';
    _tariffTypeController.text = env.tariffType ?? '';
    _energyProviderController.text = env.energyProvider ?? '';
    _installationDateController.text = env.installationDate ?? '';

    _selectedType = env.type;
    _isDefault = env.isDefault;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _sizeSqmController.dispose();
    _occupancyController.dispose();
    _voltageStandardController.dispose();
    _tariffTypeController.dispose();
    _energyProviderController.dispose();
    _installationDateController.dispose();
    super.dispose();
  }

  Future<void> _selectInstallationDate() async {
    HapticFeedback.lightImpact();

    DateTime? initialDate = DateTime.now();
    if (_installationDateController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_installationDateController.text);
      } catch (e) {
        initialDate = DateTime.now();
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: WattalyzeColors.primaryGreen,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _installationDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _updateEnvironment() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) {
      if (_selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Por favor, selecione o tipo de ambiente'),
            backgroundColor: WattalyzeColors.primaryRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errors.clear();
    });

    try {
      final updatedEnvironment = widget.environment.copyWith(
        name: _nameController.text.trim(),
        type: _selectedType!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        sizeSqm: _sizeSqmController.text.trim().isEmpty
            ? null
            : double.tryParse(_sizeSqmController.text.trim()),
        occupancy: _occupancyController.text.trim().isEmpty
            ? null
            : int.tryParse(_occupancyController.text.trim()),
        voltageStandard: _voltageStandardController.text.trim().isEmpty
            ? null
            : _voltageStandardController.text.trim(),
        tariffType: _tariffTypeController.text.trim().isEmpty
            ? null
            : _tariffTypeController.text.trim(),
        energyProvider: _energyProviderController.text.trim().isEmpty
            ? null
            : _energyProviderController.text.trim(),
        installationDate: _installationDateController.text.trim().isEmpty
            ? null
            : _installationDateController.text.trim(),
        isDefault: _isDefault,
      );

      await _environmentService.updateEnvironment(
          widget.environment.id, updatedEnvironment);

      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Ambiente ""${updatedEnvironment.name}"" atualizado com sucesso!'),
          backgroundColor: WattalyzeColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar ambiente: $e'),
          backgroundColor: WattalyzeColors.primaryRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Container(
       
        child: _isLoading ? _buildLoadingOverlay() : _buildContent(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.95),
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: WattalyzeColors.primaryDark,
            size: 20,
          ),
        ),
      ),
      title: Text(
        'Editar Ambiente',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: WattalyzeColors.primaryDark,
          fontSize: 20,
        ),
      ),
      flexibleSpace: ClipRRect(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: WattalyzeColors.primaryGreen,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Atualizando ambiente...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: WattalyzeColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - _fadeAnimation.value)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: WattalyzeColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: WattalyzeColors.primaryGreen
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Editar Ambiente',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: WattalyzeColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Atualize as informações do ambiente ""${widget.environment.name}""',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: WattalyzeColors.primaryGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Formulário (mesmo conteúdo da tela de criação, mas com dados preenchidos)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Campos obrigatórios
                          Text(
                            'Informações Básicas',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: WattalyzeColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Nome
                          _buildTextField(
                            controller: _nameController,
                            label: 'Nome do Ambiente',
                            hint: 'Ex: Sala de estar, Escritório principal...',
                            icon: Icons.business_rounded,
                            required: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor, informe o nome do ambiente';
                              }
                              if (value.trim().length < 2) {
                                return 'Nome deve ter pelo menos 2 caracteres';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Tipo
                          Text(
                            'Tipo de Ambiente *',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: WattalyzeColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 12),

                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _environmentTypes.length,
                            itemBuilder: (context, index) {
                              final type = _environmentTypes[index];
                              final isSelected = _selectedType == type['value'];

                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedType = type['value'];
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? WattalyzeColors.primaryGreen
                                            .withOpacity(0.1)
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? WattalyzeColors.primaryGreen
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        type['icon']!,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          type['label']!,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? WattalyzeColors.primaryGreen
                                                : WattalyzeColors.primaryDark,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Descrição
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Descrição',
                            hint: 'Descreva as características do ambiente...',
                            icon: Icons.description_rounded,
                            maxLines: 3,
                          ),

                          const SizedBox(height: 32),

                          // Informações adicionais
                          Text(
                            'Informações Adicionais',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: WattalyzeColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Linha com Área e Ocupação
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _sizeSqmController,
                                  label: 'Área (m²)',
                                  hint: '0.0',
                                  icon: Icons.square_foot,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _occupancyController,
                                  label: 'Ocupação (pessoas)',
                                  hint: '0',
                                  icon: Icons.people_rounded,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Resto dos campos (mesmo da tela de criação)
                          _buildTextField(
                            controller: _voltageStandardController,
                            label: 'Padrão de Voltagem',
                            hint: 'Ex: 220V, 110V/220V...',
                            icon: Icons.electrical_services_rounded,
                          ),

                          const SizedBox(height: 20),

                          _buildTextField(
                            controller: _tariffTypeController,
                            label: 'Tipo de Tarifa',
                            hint: 'Ex: Convencional, Branca, Verde...',
                            icon: Icons.receipt_long_rounded,
                          ),

                          const SizedBox(height: 20),

                          _buildTextField(
                            controller: _energyProviderController,
                            label: 'Fornecedor de Energia',
                            hint: 'Ex: CEMIG, COPEL, Light...',
                            icon: Icons.business_center_rounded,
                          ),

                          const SizedBox(height: 20),

                          GestureDetector(
                            onTap: _selectInstallationDate,
                            child: AbsorbPointer(
                              child: _buildTextField(
                                controller: _installationDateController,
                                label: 'Data de Instalação',
                                hint: 'Selecione a data',
                                icon: Icons.calendar_month_rounded,
                                suffixIcon: Icons.date_range_rounded,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Ambiente padrão
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: WattalyzeColors.primaryOrange,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Definir como Ambiente Padrão',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: WattalyzeColors.primaryDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Este será o ambiente principal do sistema',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: WattalyzeColors.primaryGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isDefault,
                                  onChanged: (value) {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _isDefault = value;
                                    });
                                  },
                                  activeColor: WattalyzeColors.primaryGreen,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Botões
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.of(context).pop();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey[400]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _updateEnvironment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        WattalyzeColors.primaryGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    elevation: 4,
                                  ),
                                  child: Text(
                                    'Salvar Alterações',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100), // Espaço final
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    IconData? suffixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: WattalyzeColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: WattalyzeColors.primaryDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WattalyzeColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: WattalyzeColors.primaryGreen,
                size: 20,
              ),
            ),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: WattalyzeColors.primaryGray)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: WattalyzeColors.primaryGreen, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: WattalyzeColors.primaryRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: WattalyzeColors.primaryRed, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
