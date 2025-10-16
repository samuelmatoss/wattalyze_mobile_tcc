
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import 'generate_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  final String token;

  const ReportsScreen({Key? key, required this.token}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Report> _reports = [];
  bool _isLoading = true;
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      setState(() => _isLoading = true);
      final reports = await ReportService.getReports(widget.token);
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Erro ao carregar relatórios: $e');
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

  Future<void> _downloadReport(Report report) async {
    try {
      _showLoadingDialog('Baixando relatório...');
      
      final filePath = await ReportService.downloadReport(widget.token, report.id);
      
      Navigator.of(context).pop(); // Fechar loading dialog
      _showSuccessMessage('Relatório salvo em: $filePath');
    } catch (e) {
      Navigator.of(context).pop(); // Fechar loading dialog
      _showErrorMessage('Erro ao baixar: $e');
    }
  }

  Future<void> _deleteReport(Report report) async {
    final confirmed = await _showConfirmDialog(
      'Tem certeza que deseja excluir este relatório?'
    );
    
    if (confirmed) {
      try {
        await ReportService.deleteReport(widget.token, report.id);
        await _loadReports();
        _showSuccessMessage('Relatório excluí­do com sucesso!');
      } catch (e) {
        _showErrorMessage('Erro ao excluir: $e');
      }
    }
  }

  Future<void> _regenerateReport(Report report) async {
    try {
      await ReportService.regenerateReport(widget.token, report.id);
      await _loadReports();
      _showSuccessMessage('Relatório sendo regenerado...');
    } catch (e) {
      _showErrorMessage('Erro ao regenerar: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
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
    ) ?? false;
  }

  Widget _buildReportCard(Report report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Status indicator
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [report.statusColor, report.statusColor.withOpacity(0.7)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com nome e status
                Row(
                  children: [
                    Icon(
                      report.typeIcon,
                      color: const Color(0xFF27AE60),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.typeDisplayName,
                            style: const TextStyle(
                              color: Color(0xFF6C757D),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(report),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Detalhes do relatÃ³rio
                _buildDetailRow(
                  'Perí­odo',
                  report.periodDisplay,
                  Icons.date_range,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Formato',
                  report.formatDisplayName,
                  Icons.description,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Criado em',
                  report.createdAt != null 
                      ? _dateFormatter.format(report.createdAt!)
                      : '-',
                  Icons.schedule,
                ),
                
                const SizedBox(height: 16),
                
                // AÃ§Ãµes
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (report.isCompleted && report.hasFile) ...[
                      _buildActionButton(
                        onPressed: () => _downloadReport(report),
                        backgroundColor: const Color(0xFF3498DB),
                        icon: Icons.download,
                        label: 'Baixar',
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (report.isFailed) ...[
                      _buildActionButton(
                        onPressed: () => _regenerateReport(report),
                        backgroundColor: const Color(0xFFF39C12),
                        icon: Icons.refresh,
                        label: 'Regenerar',
                      ),
                      const SizedBox(width: 8),
                    ],
                    _buildActionButton(
                      onPressed: () => _deleteReport(report),
                      backgroundColor: const Color(0xFFE74C3C),
                      icon: Icons.delete,
                      label: 'Excluir',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF27AE60),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF6C757D),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(Report report) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [report.statusColor, report.statusColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            report.statusIcon,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            report.statusDisplayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required Color backgroundColor,
    required IconData icon,
    required String label,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
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
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.symmetric(horizontal: 20),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description,
              size: 80,
              color: Color(0xFF6C757D),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum relatório criado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crie seu primeiro relatório usando o botão abaixo.',
              style: TextStyle(
                color: Color(0xFF6C757D),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _navigateToGenerateReport(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Gerar Relatório',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToGenerateReport() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GenerateReportScreen(token: widget.token),
      ),
    );
    
    if (result == true) {
      // RelatÃ³rio foi criado, recarregar lista
      _loadReports();
    }
  }

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
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Relatórios',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loadReports,
                      icon: const Icon(
                        Icons.refresh,
                        color: Color(0xFF27AE60),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _reports.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _reports.length,
                            itemBuilder: (context, index) {
                              return _buildReportCard(_reports[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _reports.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _navigateToGenerateReport,
              backgroundColor: const Color(0xFF27AE60),
              icon: const Icon(Icons.add),
              label: const Text('Gerar Relatório'),
            )
          : null,
    );
  }
}