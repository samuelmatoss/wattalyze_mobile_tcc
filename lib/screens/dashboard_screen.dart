import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_response.dart';
import '../utils/dashboard_utils.dart';
import '../widgets/stat_card_widget.dart';
import '../widgets/device_card_widget2.dart';
import '../widgets/alert_list_widget.dart';
import '../widgets/consumption_chart_widget.dart';

class DashboardScreen extends StatefulWidget {
  final String token;

  const DashboardScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late DashboardService _dashboardService;
  late AnimationController _animationController;

  DashboardResponse? _dashboardData;
  bool _isLoading = true;
  String? _error;
  String _selectedDataType = 'energy';

  @override
  void initState() {
    super.initState();
    _dashboardService = DashboardService(widget.token);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _dashboardService.getDashboardData();

      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });

        // FIX: Garantir que o valor de animaÃ§Ã£o estÃ¡ no range correto
        _animationController.reset();
        await _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFC3CFE2),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: DashboardUtils.primaryGreen,
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

    if (_dashboardData == null) {
      return _buildEmptyState();
    }

    return _buildDashboard();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: DashboardUtils.primaryGreen,
          ),
          SizedBox(height: 16),
          Text(
            'Carregando dados...',
            style: TextStyle(
              color: DashboardUtils.textMuted,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar dados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DashboardUtils.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadDashboardData,
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardUtils.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Tentar Novamente',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_outlined,
            size: 64,
            color: DashboardUtils.textMuted,
          ),
          SizedBox(height: 16),
          Text(
            'Nenhum dado disponí­vel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: DashboardUtils.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          // EstatÃ­sticas
          _buildStatsSection(),
          const SizedBox(height: 32),

          // GrÃ¡fico de Consumo
          _buildChartSection(),
          const SizedBox(height: 32),

          // Dispositivos
          _buildDevicesSection(),
          const SizedBox(height: 32),

          // Alertas
          _buildAlertsSection(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // FIX: Clampar valor da animaÃ§Ã£o para evitar overflow
        final clampedValue = _animationController.value.clamp(0.0, 1.0);

        return FadeTransition(
          opacity: AlwaysStoppedAnimation(clampedValue),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: AlwaysStoppedAnimation(clampedValue),
              curve: Curves.easeOutCubic,
            )),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        DashboardUtils.primaryGreen,
                        DashboardUtils.primaryDark
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: DashboardUtils.primaryGreen.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: DashboardUtils.primaryDark,
                        ),
                      ),
                      Text(
                        'Monitoramento em tempo real',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _refresh,
                  icon: const Icon(
                    Icons.refresh,
                    color: DashboardUtils.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    final stats = [
      {
        'title': 'Consumo Total (7 dias)',
        'value': '${_dashboardData!.totalConsumption.toStringAsFixed(2)} kWh',
        'subtitle': 'Últimos 7 dias',
        'icon': Icons.flash_on,
        'color': DashboardUtils.primaryDark,
        'delay': 0.1,
      },
      {
        'title': 'Dispositivos Ativos',
        'value': '${_dashboardData!.devices.length}',
        'subtitle': 'Online agora',
        'icon': Icons.devices,
        'color': DashboardUtils.primaryGreen,
        'delay': 0.2,
      },
      {
        'title': 'Alertas Ativos',
        'value': '${_dashboardData!.alerts.length}',
        'subtitle': 'Requer atenção',
        'icon': Icons.warning_amber,
        'color': const Color(0xFFE74C3C),
        'delay': 0.3,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estatá­sticas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        ...stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;

          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final delay = stat['delay'] as double;
              // FIX: Clampar e calcular progresso corretamente
              final clampedValue = _animationController.value.clamp(0.0, 1.0);
              final adjustedValue = (clampedValue - delay).clamp(0.0, 1.0);
              final progress = adjustedValue / (1.0 - delay).clamp(0.1, 1.0);

              return Transform.translate(
                offset: Offset(0, 50 * (1 - progress)),
                child: Opacity(
                  opacity: progress,
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: index < stats.length - 1 ? 16 : 0),
                    child: StatCardWidget(
                      title: stat['title'] as String,
                      value: stat['value'] as String,
                      subtitle: stat['subtitle'] as String,
                      icon: stat['icon'] as IconData,
                      color: stat['color'] as Color,
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildChartSection() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // FIX: Clampar valor da animaÃ§Ã£o
        final clampedValue = _animationController.value.clamp(0.0, 1.0);
        final adjustedValue = (clampedValue - 0.4).clamp(0.0, 1.0);
        final progress = adjustedValue / 0.6;

        return Transform.translate(
          offset: Offset(0, 50 * (1 - progress)),
          child: Opacity(
            opacity: progress,
            child: Container(
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
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Consumo Diário',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: DashboardUtils.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Análise dos últimos 7 dias',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedDataType,
                          onChanged: (value) {
                            setState(() {
                              _selectedDataType = value!;
                            });
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'energy',
                              child: Text('Energia (kWh)'),
                            ),
                            DropdownMenuItem(
                              value: 'temperature',
                              child: Text('Temperatura (Â°C)'),
                            ),
                            DropdownMenuItem(
                              value: 'humidity',
                              child: Text('Umidade (%)'),
                            ),
                          ],
                          underline: Container(),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 300,
                    padding:
                        const EdgeInsets.only(left: 10, right: 20, bottom: 20),
                    child: ConsumptionChartWidget(
                      dailyConsumption: _dashboardData!.dailyConsumption,
                      devices: _dashboardData!.devices,
                      selectedType: _selectedDataType,
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

  Widget _buildDevicesSection() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // FIX: Clampar valor da animaÃ§Ã£o
        final clampedValue = _animationController.value.clamp(0.0, 1.0);
        final adjustedValue = (clampedValue - 0.5).clamp(0.0, 1.0);
        final progress = adjustedValue / 0.5;

        return Transform.translate(
          offset: Offset(0, 50 * (1 - progress)),
          child: Opacity(
            opacity: progress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dispositivos Conectados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                if (_dashboardData!.devices.isEmpty)
                  Container(
                    width: double.infinity,
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
                      children: [
                        Icon(
                          Icons.devices_other,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum dispositivo conectado',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _dashboardData!.devices.length,
                    itemBuilder: (context, index) {
                      final device = _dashboardData!.devices[index];
                      return DeviceCardWidget(
                        device: device,
                        dailyConsumption: _dashboardData!.dailyConsumption,
                        animationDelay: 0.6 + (index * 0.1),
                        animationController: _animationController,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertsSection() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final clampedValue = _animationController.value.clamp(0.0, 1.0);
        final adjustedValue = (clampedValue - 0.7).clamp(0.0, 0.3);
        final progress = (adjustedValue / 0.3).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, 50 * (1 - progress)),
          child: Opacity(
            opacity: progress,
            child: Container(
              width: double.infinity, // âœ… ocupa toda a largura
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
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Centro de Alertas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: DashboardUtils.primaryDark,
                      ),
                    ),
                  ),
                  AlertListWidget(alerts: _dashboardData!.alerts),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}