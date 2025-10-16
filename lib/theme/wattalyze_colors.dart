import 'package:flutter/material.dart';

/// Classe com todas as cores do sistema Wattalyze
/// Baseado na paleta original do projeto
class WattalyzeColors {
  // ========================================
  // CORES PRINCIPAIS WATTALYZE
  // ========================================

  /// Verde principal - cor de marca do Wattalyze
  static const Color primaryGreen = Color(0xFF27ae60);

  /// Azul escuro - cor principal do tema
  static const Color primaryDark = Color(0xFF2c3e50);

  /// Laranja - usado para temperatura e dispositivos
  static const Color primaryOrange = Color(0xFFf39c12);

  /// Vermelho - usado para alertas críticos
  static const Color primaryRed = Color(0xFFe74c3c);

  /// Azul claro - usado para ambientes e umidade
  static const Color primaryBlue = Color(0xFF3498DB);

  /// Roxo - usado para relatórios e análises
  static const Color primaryPurple = Color(0xFF9b59b6);

  /// Cinza - usado para configurações e elementos neutros
  static const Color primaryGray = Color(0xFF95a5a6);

  // ========================================
  // CORES DE BACKGROUND
  // ========================================

  /// Background claro principal
  static const Color backgroundLight = Color(0xFFF5F7FA);

  /// Background com gradiente
  static const Color backgroundGradient2 = Color(0xFFC3CFE2);

  /// Background de cards e elementos
  static const Color backgroundCard = Color(0xFFFFFFFF);

  /// Background secundário
  static const Color backgroundSecondary = Color(0xFFF8F9FA);

  // ========================================
  // CORES DE TEXTO
  // ========================================

  /// Texto principal (escuro)
  static const Color textPrimary = Color(0xFF2c3e50);

  /// Texto secundário (mais claro)
  static const Color textSecondary = Color(0xFF6c757d);

  /// Texto desativado/muted
  static const Color textMuted = Color(0xFF95a5a6);

  /// Texto em backgrounds escuros
  static const Color textLight = Color(0xFFFFFFFF);

  // ========================================
  // CORES DE STATUS
  // ========================================

  /// Sucesso - operações bem-sucedidas
  static const Color success = Color(0xFF27ae60);

  /// Aviso - alertas médios
  static const Color warning = Color(0xFFf39c12);

  /// Erro - alertas críticos
  static const Color error = Color(0xFFe74c3c);

  /// Informação - mensagens informativas
  static const Color info = Color(0xFF3498DB);

  // ========================================
  // CORES POR SEÇÃO DO APP
  // ========================================

  /// Dashboard - verde principal
  static const Color sectionDashboard = primaryGreen;

  /// Ambientes - azul claro
  static const Color sectionEnvironments = primaryBlue;

  /// Dispositivos - laranja
  static const Color sectionDevices = primaryOrange;

  /// Alertas - vermelho
  static const Color sectionAlerts = primaryRed;

  /// Relatórios - roxo
  static const Color sectionReports = primaryPurple;

  /// Configurações - cinza
  static const Color sectionSettings = primaryGray;

  // ========================================
  // CORES DE DADOS/SENSORES
  // ========================================

  /// Energia elétrica
  static const Color dataEnergy = primaryGreen;

  /// Temperatura
  static const Color dataTemperature = primaryOrange;

  /// Umidade
  static const Color dataHumidity = primaryBlue;

  /// Voltagem
  static const Color dataVoltage = primaryPurple;

  /// Corrente
  static const Color dataCurrent = Color(0xFFe67e22);

  // ========================================
  // CORES DE DISPOSITIVOS
  // ========================================

  /// Dispositivo online
  static const Color deviceOnline = primaryGreen;

  /// Dispositivo offline
  static const Color deviceOffline = primaryRed;

  /// Dispositivo em manutenção
  static const Color deviceMaintenance = primaryOrange;

  /// Dispositivo desconhecido
  static const Color deviceUnknown = primaryGray;

  // ========================================
  // CORES DE SEVERIDADE (ALERTAS)
  // ========================================

  /// Severidade alta/crítica
  static const Color severityHigh = primaryRed;

  /// Severidade média
  static const Color severityMedium = primaryOrange;

  /// Severidade baixa
  static const Color severityLow = primaryBlue;

  /// Severidade info
  static const Color severityInfo = primaryGray;

  // ========================================
  // GRADIENTES
  // ========================================

  /// Gradiente principal (verde → azul escuro)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente de background
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundLight, backgroundGradient2],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Gradiente de aviso (vermelho → laranja)
  static const LinearGradient warningGradient = LinearGradient(
    colors: [primaryRed, primaryOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente de sucesso (verde claro → verde escuro)
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF2ecc71), primaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente azul (azul claro → azul escuro)
  static const LinearGradient blueGradient = LinearGradient(
    colors: [primaryBlue, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========================================
  // MÉTODOS AUXILIARES
  // ========================================

  /// Obter cor por seção do app
  static Color getColorBySection(String section) {
    switch (section.toLowerCase()) {
      case 'dashboard':
        return sectionDashboard;
      case 'ambientes':
      case 'environments':
        return sectionEnvironments;
      case 'dispositivos':
      case 'devices':
        return sectionDevices;
      case 'alertas':
      case 'alerts':
        return sectionAlerts;
      case 'relatórios':
      case 'reports':
        return sectionReports;
      case 'configurações':
      case 'settings':
        return sectionSettings;
      default:
        return primaryGreen;
    }
  }

  /// Obter cor por tipo de dados
  static Color getColorByDataType(String dataType) {
    switch (dataType.toLowerCase()) {
      case 'energy':
      case 'energia':
        return dataEnergy;
      case 'temperature':
      case 'temperatura':
        return dataTemperature;
      case 'humidity':
      case 'umidade':
        return dataHumidity;
      case 'voltage':
      case 'voltagem':
        return dataVoltage;
      case 'current':
      case 'corrente':
        return dataCurrent;
      default:
        return primaryGray;
    }
  }

  /// Obter cor por status do dispositivo
  static Color getColorByDeviceStatus(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return deviceOnline;
      case 'offline':
        return deviceOffline;
      case 'maintenance':
      case 'manutenção':
        return deviceMaintenance;
      default:
        return deviceUnknown;
    }
  }

  /// Obter cor por severidade do alerta
  static Color getColorBySeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
      case 'alta':
      case 'crítica':
        return severityHigh;
      case 'medium':
      case 'warning':
      case 'média':
      case 'aviso':
        return severityMedium;
      case 'low':
      case 'baixa':
        return severityLow;
      case 'info':
      case 'informação':
        return severityInfo;
      default:
        return severityInfo;
    }
  }

  /// Obter ícone por tipo de dados
  static IconData getIconByDataType(String dataType) {
    switch (dataType.toLowerCase()) {
      case 'energy':
      case 'energia':
        return Icons.flash_on;
      case 'temperature':
      case 'temperatura':
        return Icons.thermostat;
      case 'humidity':
      case 'umidade':
        return Icons.water_drop;
      case 'voltage':
      case 'voltagem':
        return Icons.electrical_services;
      case 'current':
      case 'corrente':
        return Icons.bolt;
      default:
        return Icons.analytics;
    }
  }

  /// Obter ícone por status do dispositivo
  static IconData getIconByDeviceStatus(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Icons.wifi;
      case 'offline':
        return Icons.wifi_off;
      case 'maintenance':
      case 'manutenção':
        return Icons.build;
      default:
        return Icons.help_outline;
    }
  }

  /// Obter ícone por seção
  static IconData getIconBySection(String section) {
    switch (section.toLowerCase()) {
      case 'dashboard':
        return Icons.dashboard_rounded;
      case 'ambientes':
      case 'environments':
        return Icons.business_rounded;
      case 'dispositivos':
      case 'devices':
        return Icons.devices_rounded;
      case 'alertas':
      case 'alerts':
        return Icons.warning_amber_rounded;
      case 'relatórios':
      case 'reports':
        return Icons.analytics_rounded;
      case 'configurações':
      case 'settings':
        return Icons.settings_rounded;
      default:
        return Icons.dashboard_rounded;
    }
  }

  /// Obter unidade por tipo de dados
  static String getUnitByDataType(String dataType) {
    switch (dataType.toLowerCase()) {
      case 'energy':
      case 'energia':
        return 'kWh';
      case 'temperature':
      case 'temperatura':
        return '°C';
      case 'humidity':
      case 'umidade':
        return '%';
      case 'voltage':
      case 'voltagem':
        return 'V';
      case 'current':
      case 'corrente':
        return 'A';
      case 'power':
      case 'potência':
        return 'W';
      default:
        return '';
    }
  }

  /// Criar decoração de card padrão
  static BoxDecoration createCardDecoration({
    List<Color>? gradientColors,
    BoxShadow? shadow,
    double borderRadius = 16.0,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: gradientColors != null
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            )
          : null,
      color: gradientColors == null ? backgroundCard : null,
      boxShadow: shadow != null ? [shadow] : [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Criar sombra padrão
  static BoxShadow createShadow({
    Color? color,
    double blurRadius = 10.0,
    Offset offset = const Offset(0, 4),
    double opacity = 0.1,
  }) {
    return BoxShadow(
      color: (color ?? Colors.black).withOpacity(opacity),
      blurRadius: blurRadius,
      offset: offset,
    );
  }

  /// Formatação de números para exibição
  static String formatNumber(double value) {
    if (!value.isFinite || value.isNaN) return '0';

    if (value == 0) return '0';

    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    } else if (value >= 1) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  /// Formatação de data
  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  /// Mensagens de estado vazio por contexto
  static String getEmptyStateMessage(String context) {
    switch (context.toLowerCase()) {
      case 'devices':
      case 'dispositivos':
        return 'Nenhum dispositivo conectado';
      case 'alerts':
      case 'alertas':
        return 'Nenhum alerta ativo';
      case 'environments':
      case 'ambientes':
        return 'Nenhum ambiente configurado';
      case 'reports':
      case 'relatórios':
        return 'Nenhum relatório disponível';
      case 'energy':
      case 'energia':
        return 'Sem dados de consumo';
      case 'temperature':
      case 'temperatura':
        return 'Sem dados de temperatura';
      case 'humidity':
      case 'umidade':
        return 'Sem dados de umidade';
      default:
        return 'Nenhum dado disponível';
    }
  }
}