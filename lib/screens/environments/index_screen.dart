import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import '../../services/environment_service.dart';
import '../../models/environment_model.dart';
import '../../models/shared_models.dart';
import '../../theme/wattalyze_colors.dart';
import 'create_screen.dart';
import 'edit_screen.dart';

class EnvironmentsScreen extends StatefulWidget {
  final String token;

  const EnvironmentsScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<EnvironmentsScreen> createState() => _EnvironmentsScreenState();
}

class _EnvironmentsScreenState extends State<EnvironmentsScreen>
    with TickerProviderStateMixin {
  late EnvironmentService _environmentService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Environment> _environments = [];
  Map<String, ConsumptionData> _environmentConsumption = {};
  Map<int, String> _selectedTypes = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _environmentService = EnvironmentService(widget.token);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadEnvironments();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadEnvironments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _environmentService.getEnvironments();

      setState(() {
        _environments = response.environments;
        _environmentConsumption = response.environmentDailyConsumption;

        // Inicializar tipos selecionados
        for (var env in _environments) {
          _selectedTypes[env.id] = 'energy';
        }

        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();
    await _loadEnvironments();
  }

  Future<void> _deleteEnvironment(Environment environment) async {
    final confirmed = await _showDeleteDialog(environment.name);
    if (confirmed != true) return;

    try {
      await _environmentService.deleteEnvironment(environment.id);
      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Ambiente ""${environment.name}"" excluído com sucesso'),
          backgroundColor: WattalyzeColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      _loadEnvironments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir ambiente: $e'),
          backgroundColor: WattalyzeColors.primaryRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<bool?> _showDeleteDialog(String environmentName) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
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
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      WattalyzeColors.primaryRed,
                      WattalyzeColors.primaryOrange
                    ],
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Excluir Ambiente',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: WattalyzeColors.primaryDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tem certeza que deseja excluir o ambiente ""$environmentName""? Esta ação não pode ser desfeita.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: WattalyzeColors.primaryGray,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildDialogButton(
                      'Cancelar',
                      Colors.grey[100]!,
                      WattalyzeColors.primaryGray,
                      () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDialogButton(
                      'Excluir',
                      WattalyzeColors.primaryRed,
                      Colors.white,
                      () => Navigator.of(context).pop(true),
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

  Widget _buildDialogButton(
      String text, Color bg, Color textColor, VoidCallback onTap) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: bg == Colors.grey[100]
            ? Border.all(color: Colors.grey[300]!, width: 1)
            : null,
        boxShadow: bg != Colors.grey[100]
            ? [
                BoxShadow(
                    color: bg.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: textColor,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Container(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: WattalyzeColors.primaryGreen,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_environments.isEmpty) {
      return _buildEmptyState();
    }

    return _buildEnvironmentsList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Center(
                  child: CircularProgressIndicator(
                    color: WattalyzeColors.primaryGreen,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Carregando ambientes...',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: WattalyzeColors.primaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: WattalyzeColors.primaryRed,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'Erro ao Carregar',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: WattalyzeColors.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: WattalyzeColors.primaryGray,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadEnvironments,
              style: ElevatedButton.styleFrom(
                backgroundColor: WattalyzeColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Tentar Novamente',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(40),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          WattalyzeColors.primaryGreen,
                          WattalyzeColors.primaryBlue
                        ],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Nenhum Ambiente',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: WattalyzeColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Comece criando seu primeiro ambiente para monitorar o consumo de energia.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: WattalyzeColors.primaryGray,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // BOTÃO PARA CRIAR AMBIENTE
                  ElevatedButton.icon(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              EnvironmentCreateScreen(token: widget.token),
                        ),
                      );
                      if (result == true) {
                        _loadEnvironments();
                      }
                    },
                    icon: const Icon(Icons.add_rounded,
                        size: 22, color: Colors.white),
                    label: Text(
                      'Criar Ambiente',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WattalyzeColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 16),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnvironmentsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header moderno
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - _fadeAnimation.value)),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
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
                                Icons.business_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ambientes',
                                    style: GoogleFonts.inter(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: WattalyzeColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_environments.length} ${_environments.length == 1 ? 'ambiente configurado' : 'ambientes configurados'}',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: WattalyzeColors.primaryGray,
                                    ),
                                  ),
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
            },
          ),

          const SizedBox(height: 24),

          const SizedBox(height: 16),

          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _fadeAnimation.value,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            EnvironmentCreateScreen(token: widget.token),
                      ),
                    );
                    if (result == true) {
                      _loadEnvironments();
                    }
                  },
                  icon: const Icon(Icons.add_rounded,
                      size: 22, color: Colors.white),
                  label: Text(
                    'Novo Ambiente',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WattalyzeColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 120, vertical: 30),
                    elevation: 4,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Lista de ambientes
          ..._environments.asMap().entries.map((entry) {
            final index = entry.key;
            final environment = entry.value;
            return AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                final delay = 0.1 + (index * 0.1);
                final progress =
                    ((_fadeAnimation.value - delay) / (1.0 - delay))
                        .clamp(0.0, 1.0);

                return Transform.translate(
                  offset: Offset(0, 50 * (1 - progress)),
                  child: Opacity(
                    opacity: progress,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: _buildEnvironmentCard(environment),
                    ),
                  ),
                );
              },
            );
          }).toList(),

          const SizedBox(height: 100), // Espaço para FAB
        ],
      ),
    );
  }

  Widget _buildEnvironmentCard(Environment environment) {
    final consumptionData = _environmentConsumption[environment.id.toString()];
    final selectedType = _selectedTypes[environment.id] ?? 'energy';

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // Cabeçalho do ambiente
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      WattalyzeColors.primaryDark,
                      WattalyzeColors.primaryDark.withOpacity(0.8)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  environment.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (environment.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    'Padrão',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getEnvironmentTypeLabel(environment.type),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Menu de ações
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: PopupMenuButton<String>(
                        onSelected: (value) =>
                            _handleEnvironmentAction(value, environment),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded,
                                    color: WattalyzeColors.primaryBlue,
                                    size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  'Editar',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded,
                                    color: WattalyzeColors.primaryRed,
                                    size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  'Excluir',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    color: WattalyzeColors.primaryRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 8,
                      ),
                    ),
                  ],
                ),
              ),

              // Conteúdo do card
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações básicas
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          _buildInfoStat('Tipo',
                              _getEnvironmentTypeLabel(environment.type)),
                          if (environment.sizeSqm != null)
                            _buildInfoStat('Área',
                                '${environment.sizeSqm!.toStringAsFixed(0)}m²'),
                          if (environment.occupancy != null)
                            _buildInfoStat(
                                'Ocupação', '${environment.occupancy} pessoas'),
                          _buildInfoStat('Dispositivos',
                              '${environment.devices?.length ?? 0}'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seletor de tipo de dado
                    Row(
                      children: [
                        Icon(
                          _getDataTypeIcon(selectedType),
                          color: _getDataTypeColor(selectedType),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getDataTypeLabel(selectedType),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: WattalyzeColors.primaryDark,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: DropdownButton<String>(
                            value: selectedType,
                            onChanged: (value) {
                              if (value != null) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedTypes[environment.id] = value;
                                });
                              }
                            },
                            items: [
                              DropdownMenuItem(
                                value: 'energy',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.flash_on,
                                        size: 16,
                                        color: WattalyzeColors.primaryGreen),
                                    const SizedBox(width: 8),
                                    Text('Energia (kWh)',
                                        style: GoogleFonts.inter(fontSize: 14)),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'temperature',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.thermostat,
                                        size: 16,
                                        color: WattalyzeColors.primaryOrange),
                                    const SizedBox(width: 8),
                                    Text('Temperatura (°C)',
                                        style: GoogleFonts.inter(fontSize: 14)),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'humidity',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.water_drop,
                                        size: 16,
                                        color: WattalyzeColors.primaryBlue),
                                    const SizedBox(width: 8),
                                    Text('Umidade (%)',
                                        style: GoogleFonts.inter(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                            underline: Container(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Gráfico
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: _buildChart(
                          environment.id, consumptionData, selectedType),
                    ),

                    const SizedBox(height: 20),

                    // Dispositivos conectados
                    _buildDevicesSection(environment),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: WattalyzeColors.primaryGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: WattalyzeColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
      int environmentId, ConsumptionData? data, String selectedType) {
    if (data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Sem dados disponíveis',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    List<DailyMeasurement> measurements = [];
    switch (selectedType) {
      case 'energy':
        measurements = data.energy;
        break;
      case 'temperature':
        measurements = data.temperature;
        break;
      case 'humidity':
        measurements = data.humidity;
        break;
    }

    if (measurements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getDataTypeIcon(selectedType),
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Sem dados de ${_getDataTypeLabel(selectedType).toLowerCase()}',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxValue(measurements, selectedType),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final value = rod.toY;
              final unit = _getDataTypeUnit(selectedType);
              return BarTooltipItem(
                '${value.toStringAsFixed(2)} $unit',
                GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < measurements.length) {
                  final date = DateTime.parse(measurements[value.toInt()].date);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: measurements.asMap().entries.map((entry) {
          final index = entry.key;
          final measurement = entry.value;
          final value = measurement.value;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: _getDataTypeColor(selectedType),
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDevicesSection(Environment environment) {
    final devices = environment.devices ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WattalyzeColors.primaryDark,
            WattalyzeColors.primaryDark.withOpacity(0.9)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.devices_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Dispositivos Conectados',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: WattalyzeColors.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${devices.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (devices.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Colors.white70,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhum dispositivo conectado',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione dispositivos para monitorar',
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: devices
                  .map((device) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sensors,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              device.name.length > 15
                                  ? '${device.name.substring(0, 15)}...'
                                  : device.name,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  // Métodos auxiliares
  String _getEnvironmentTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'residential':
        return 'Residencial';
      case 'commercial':
        return 'Comercial';
      case 'industrial':
        return 'Industrial';
      case 'public':
        return 'Público';
      default:
        return type;
    }
  }

  String _getDataTypeLabel(String type) {
    switch (type) {
      case 'energy':
        return 'Energia';
      case 'temperature':
        return 'Temperatura';
      case 'humidity':
        return 'Umidade';
      default:
        return type;
    }
  }

  String _getDataTypeUnit(String type) {
    switch (type) {
      case 'energy':
        return 'kWh';
      case 'temperature':
        return '°C';
      case 'humidity':
        return '%';
      default:
        return '';
    }
  }

  IconData _getDataTypeIcon(String type) {
    switch (type) {
      case 'energy':
        return Icons.flash_on;
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      default:
        return Icons.analytics;
    }
  }

  Color _getDataTypeColor(String type) {
    switch (type) {
      case 'energy':
        return WattalyzeColors.primaryGreen;
      case 'temperature':
        return WattalyzeColors.primaryOrange;
      case 'humidity':
        return WattalyzeColors.primaryBlue;
      default:
        return WattalyzeColors.primaryGray;
    }
  }

  double _getMaxValue(
      List<DailyMeasurement> measurements, String selectedType) {
    if (measurements.isEmpty) return 100.0;

    final values = measurements.map((m) => m.value).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return maxValue > 0 ? maxValue * 1.2 : 100.0;
  }

  void _handleEnvironmentAction(String action, Environment environment) async {
    switch (action) {
      case 'edit':
        HapticFeedback.lightImpact();
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EnvironmentEditScreen(
              token: widget.token,
              environment: environment,
            ),
          ),
        );
        if (result == true) {
          _loadEnvironments();
        }
        break;
      case 'delete':
        HapticFeedback.heavyImpact();
        await _deleteEnvironment(environment);
        break;
    }
  }
}
