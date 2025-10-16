import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/device_model.dart';
import '../../models/shared_models.dart';
import '../../services/device_service.dart';
import '../../widgets/device_card_widget.dart';
import '../../widgets/device_row_widget.dart';
import '../../widgets/filter_bottom_sheet.dart';
import 'create_screen.dart';

enum ViewMode { card, list }

class DeviceIndexScreen extends StatefulWidget {
  final String token;

  const DeviceIndexScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<DeviceIndexScreen> createState() => _DeviceIndexScreenState();
}

class _DeviceIndexScreenState extends State<DeviceIndexScreen>
    with TickerProviderStateMixin {
  late DeviceService _deviceService;
  late TabController _tabController;

  List<Device> _devices = [];
  List<Device> _filteredDevices = [];
  List<DeviceEnvironment> _environments = [];
  List<DeviceType> _deviceTypes = [];
  Map<String, InfluxData> _influxData = {};
  Map<String, List<DailyMeasurement>> _dailyConsumption = {};

  bool _isLoading = true;
  String? _error;
  ViewMode _viewMode = ViewMode.card;
  String _searchQuery = '';
  String _statusFilter = 'all';
  int? _environmentFilter;
  int? _deviceTypeFilter;

  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Paleta de cores moderna e vibrante
  static const primaryGreen = Color(0xFF00D9A3);
  static const primaryDark = Color(0xFF00B386);
  static const bgGradientStart = Color(0xFFF8FAFC);
  static const bgGradientEnd = Color(0xFFE2E8F0);
  static const cardBg = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _deviceService = DeviceService(widget.token);
    _tabController = TabController(length: 3, vsync: this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadDevices();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterDevices();
    });
  }

  Future<void> _loadDevices() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _deviceService.getDevices();

      if (!mounted) return;

      setState(() {
        _devices = response.devices;
        _environments = response.environments;
        _deviceTypes = response.deviceTypes;
        _influxData = response.influxData;
        _dailyConsumption = response.dailyConsumption;
        _isLoading = false;
        _filterDevices();
      });

      _animationController.forward(from: 0.0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Erro ao carregar dispositivos: $e';
      });
    }
  }

  void _filterDevices() {
    _filteredDevices = _devices.where((device) {
      final searchLower = _searchQuery.toLowerCase();
      final searchMatch = _searchQuery.isEmpty ||
          device.name.toLowerCase().contains(searchLower) ||
          device.macAddress.toLowerCase().contains(searchLower) ||
          (device.location?.toLowerCase().contains(searchLower) ?? false);

      final statusMatch =
          _statusFilter == 'all' || device.status == _statusFilter;
      final environmentMatch = _environmentFilter == null ||
          device.environmentId == _environmentFilter;
      final deviceTypeMatch =
          _deviceTypeFilter == null || device.deviceTypeId == _deviceTypeFilter;

      return searchMatch && statusMatch && environmentMatch && deviceTypeMatch;
    }).toList();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        environments: _environments,
        deviceTypes: _deviceTypes,
        currentStatus: _statusFilter,
        currentEnvironment: _environmentFilter,
        currentDeviceType: _deviceTypeFilter,
        onFiltersChanged: (status, environmentId, deviceTypeId) {
          setState(() {
            _statusFilter = status;
            _environmentFilter = environmentId;
            _deviceTypeFilter = deviceTypeId;
            _filterDevices();
          });
        },
      ),
    );
  }

  void _showDeleteConfirmation(Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[400]!, Colors.red[600]!],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.warning_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirmar Exclusão',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja excluir o dispositivo "${device.name}"?',
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.red[700]),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Esta ação não pode ser desfeita.',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Cancelar',
                style: TextStyle(
                    color: Colors.grey[700], fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteDevice(device.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Excluir',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDevice(int deviceId) async {
    try {
      await _deviceService.deleteDevice(deviceId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Dispositivo excluído com sucesso!',
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
      _loadDevices();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('Erro ao excluir: $e',
                      style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgGradientStart, bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchAndFilters(),
              _buildTabBar(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            )),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryGreen, primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.devices_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dispositivos IoT',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_devices.length} ${_devices.length == 1 ? 'dispositivo' : 'dispositivos'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildIconButton(
                    icon: _viewMode == ViewMode.card
                        ? Icons.view_list_rounded
                        : Icons.view_module_rounded,
                    onPressed: () {
                      setState(() {
                        _viewMode = _viewMode == ViewMode.card
                            ? ViewMode.list
                            : ViewMode.card;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _loadDevices,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: primaryGreen, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final progress = Curves.easeOut.transform(_animationController.value);

        return Transform.translate(
          offset: Offset(0, 20 * (1 - progress)),
          child: Opacity(
            opacity: progress,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Adicionar Dispositivo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DeviceCreateScreen(authToken: widget.token),
                            ),
                          );
                          _loadDevices(); // Atualiza a lista após criar
                        },
                        icon:
                            const Icon(Icons.add_rounded, color: Colors.white),
                        label: const Text(
                          'Novo',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.grey[200]!, width: 1.5),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'Buscar dispositivos...',
                              hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500),
                              prefixIcon: Icon(Icons.search_rounded,
                                  color: Colors.grey[400], size: 22),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          gradient: _hasActiveFilters()
                              ? const LinearGradient(
                                  colors: [primaryGreen, primaryDark])
                              : null,
                          color: _hasActiveFilters() ? null : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _hasActiveFilters()
                              ? [
                                  BoxShadow(
                                    color: primaryGreen.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _showFilterBottomSheet,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.tune_rounded,
                                color: _hasActiveFilters()
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_hasActiveFilters()) ...[
                    const SizedBox(height: 12),
                    _buildActiveFilters(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _hasActiveFilters() {
    return _statusFilter != 'all' ||
        _environmentFilter != null ||
        _deviceTypeFilter != null;
  }

  Widget _buildActiveFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (_statusFilter != 'all')
            _buildFilterChip(
              label: 'Status: $_statusFilter',
              onDelete: () {
                setState(() {
                  _statusFilter = 'all';
                  _filterDevices();
                });
              },
            ),
          if (_environmentFilter != null)
            _buildFilterChip(
              label:
                  'Ambiente: ${_environments.firstWhere((e) => e.id == _environmentFilter).name}',
              onDelete: () {
                setState(() {
                  _environmentFilter = null;
                  _filterDevices();
                });
              },
            ),
          if (_deviceTypeFilter != null)
            _buildFilterChip(
              label:
                  'Tipo: ${_deviceTypes.firstWhere((t) => t.id == _deviceTypeFilter).name}',
              onDelete: () {
                setState(() {
                  _deviceTypeFilter = null;
                  _filterDevices();
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      {required String label, required VoidCallback onDelete}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: primaryDark),
        ),
        onDeleted: onDelete,
        deleteIcon: const Icon(Icons.close_rounded, size: 16),
        backgroundColor: primaryGreen.withOpacity(0.12),
        side: BorderSide(color: primaryGreen.withOpacity(0.3), width: 1.5),
        deleteIconColor: primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  Widget _buildTabBar() {
  final statusCounts = _getStatusCounts();

  return AnimatedBuilder(
    animation: _animationController,
    builder: (context, child) {
      final progress = Curves.easeOut.transform(_animationController.value);

      return Transform.translate(
        offset: Offset(0, 20 * (1 - progress)),
        child: Opacity(
          opacity: progress,
          child: Container(
            
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: primaryGreen,
              unselectedLabelColor: textSecondary,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12),
              unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12),
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryGreen.withOpacity(0.15),
                    primaryDark.withOpacity(0.15)
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              tabs: [
                _buildTab('Todos', _devices.length),
                _buildTab('Online', statusCounts['online']!),
                _buildTab('Offline', statusCounts['offline']!),
              ],
              onTap: (index) {
                setState(() {
                  _statusFilter = ['all', 'online', 'offline'][index];
                  _filterDevices();
                });
              },
            ),
          ),
        ),
      );
    },
  );
}


  Widget _buildTab(String label, int count) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primaryDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _getStatusCounts() {
    final counts = <String, int>{'online': 0, 'offline': 0};
    for (final device in _devices) {
      counts[device.status] = (counts[device.status] ?? 0) + 1;
    }
    return counts;
  }

  Widget _buildBody() {
    if (_isLoading) {
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
                color: primaryGreen,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Carregando dispositivos...',
              style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15),
            ),
          ],
        ),
      );
    }

    if (_error != null) return _buildErrorState();
    if (_devices.isEmpty) return _buildEmptyState();
    if (_filteredDevices.isEmpty) return _buildNoResultsState();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildDeviceList(_filteredDevices),
          _buildDeviceList(
              _filteredDevices.where((d) => d.status == 'online').toList()),
          _buildDeviceList(
              _filteredDevices.where((d) => d.status == 'offline').toList()),
          _buildDeviceList(_filteredDevices
              .toList()),
        ],
      ),
    );
  }

  Widget _buildDeviceList(List<Device> devices) {
    if (devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Nenhum dispositivo encontrado',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, _viewMode == ViewMode.card ? 100 : 20),
        itemCount: devices.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 40.0,
              child: FadeInAnimation(
                child: _viewMode == ViewMode.card
                    ? DeviceCardWidget(
                        device: devices[index],
                        influxData: _influxData[devices[index].id.toString()],
                        dailyConsumption:
                            _dailyConsumption[devices[index].id.toString()] ??
                                [],
                        onDelete: () => _showDeleteConfirmation(devices[index]),
                        onEdit: () => _navigateToEdit(devices[index]),
                      )
                    : DeviceRowWidget(
                        device: devices[index],
                        influxData: _influxData[devices[index].id.toString()],
                        dailyConsumption:
                            _dailyConsumption[devices[index].id.toString()] ??
                                [],
                        onDelete: () => _showDeleteConfirmation(devices[index]),
                        onEdit: () => _navigateToEdit(devices[index]),
                      ),
              ),
            ),
          );
        },
      ),
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
              'Erro ao carregar',
              style: TextStyle(
                  fontSize: 22,
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
              onPressed: _loadDevices,
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

  Widget _buildEmptyState() {
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
                  colors: [
                    primaryGreen.withOpacity(0.2),
                    primaryDark.withOpacity(0.2)
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.devices_other_rounded,
                  size: 48, color: primaryGreen),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum dispositivo',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Adicione dispositivos para começar\no monitoramento IoT',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DeviceCreateScreen(authToken: widget.token),
                  ),
                ).then((_) => _loadDevices());
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar Dispositivo',
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

  Widget _buildNoResultsState() {
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
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.search_off_rounded,
                  size: 48, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum resultado',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tente ajustar os filtros ou a busca\npara encontrar dispositivos',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _statusFilter = 'all';
                  _environmentFilter = null;
                  _deviceTypeFilter = null;
                  _filterDevices();
                });
              },
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Limpar Filtros',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                foregroundColor: primaryGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                backgroundColor: primaryGreen.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final scale = Curves.elasticOut.transform(_animationController.value);

        return Transform.scale(
          scale: scale,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DeviceCreateScreen(authToken: widget.token),
                ),
              ).then((_) => _loadDevices());
            },
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            label: const Text(
              'Adicionar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: primaryGreen,
            elevation: 8,
            extendedPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        );
      },
    );
  }

  void _navigateToEdit(Device device) {
    Navigator.pushNamed(
      context,
      '/devices/edit',
      arguments: {'device': device, 'authToken': widget.token},
    ).then((_) => _loadDevices());
  }
}
