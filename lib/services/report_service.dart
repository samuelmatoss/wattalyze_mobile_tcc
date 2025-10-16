import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/report_model.dart';
import '../models/device_model.dart';

class ReportService {
  static const String baseUrl = 'http://192.168.0.101:8000/api';

  // Método auxiliar para fazer requisições autenticadas com token
  static Future<http.Response> _authenticatedRequest(
    String endpoint, {
    required String token,
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    switch (method) {
      case 'GET':
        return await http.get(url, headers: headers);
      case 'POST':
        return await http.post(
          url,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'PUT':
        return await http.put(
          url,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'DELETE':
        return await http.delete(url, headers: headers);
      default:
        throw Exception('Método HTTP não suportado: $method');
    }
  }

  // Buscar lista de relatórios
  static Future<List<Report>> getReports(String token) async {
    try {
      final response = await _authenticatedRequest(
        'reports',
        token: token,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Report.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar relatórios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na comunicação com o servidor: $e');
    }
  }

  // Criar novo relatório
  static Future<Report> createReport(String token, CreateReportRequest request) async {
    try {
      final response = await _authenticatedRequest(
        'reports/generate',
        token: token,
        method: 'POST',
        body: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 202) {
        final data = json.decode(response.body);
        if (data.containsKey('report_id')) {
          // Retorna um relatório temporário com status pending
          return Report(
            id: data['report_id'],
            userId: 0, // Será atualizado quando buscar novamente
            name: request.name,
            type: request.type,
            periodType: request.periodType,
            periodStart: request.periodStart,
            periodEnd: request.periodEnd,
            format: request.format,
            status: 'pending',
            createdAt: DateTime.now(),
          );
        } else {
          return Report.fromJson(data);
        }
      } else {
        final error = json.decode(response.body);
        throw Exception('Erro ao criar relatório: ${error['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na comunicação com o servidor: $e');
    }
  }

  // Buscar relatório por ID
  static Future<Report> getReportById(String token, int reportId) async {
    try {
      final response = await _authenticatedRequest(
        'reports/$reportId',
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Report.fromJson(data);
      } else {
        throw Exception('Erro ao buscar relatório: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na comunicação com o servidor: $e');
    }
  }

  // Baixar arquivo do relatório
  static Future<String> downloadReport(String token, int reportId) async {
    try {
      // Primeiro, verificar se o relatório existe e está completo
      final report = await getReportById(token, reportId);
      
      if (!report.isCompleted || !report.hasFile) {
        throw Exception('Relatório não disponível para download');
      }

      final response = await _authenticatedRequest(
        'reports/$reportId/download',
        token: token,
      );

      if (response.statusCode == 200) {
        // Obter diretório de downloads
        final directory = await getExternalStorageDirectory();
        final downloadsDir = Directory('${directory!.path}/Downloads');
        
        // Criar diretório se não existir
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        // Gerar nome do arquivo
        final fileName = '${report.name}_${DateTime.now().millisecondsSinceEpoch}.${report.format}';
        final filePath = '${downloadsDir.path}/$fileName';

        // Salvar arquivo
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return filePath;
      } else {
        throw Exception('Erro ao baixar relatório: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao baixar arquivo: $e');
    }
  }

  // Excluir relatório
  static Future<void> deleteReport(String token, int reportId) async {
    try {
      final response = await _authenticatedRequest(
        'reports/$reportId',
        token: token,
        method: 'DELETE',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erro ao excluir relatório: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na comunicação com o servidor: $e');
    }
  }

  // Regenerar relatório
  static Future<void> regenerateReport(String token, int reportId) async {
    try {
      final response = await _authenticatedRequest(
        'reports/$reportId/regenerate',
        token: token,
        method: 'POST',
      );

      if (response.statusCode != 200 && response.statusCode != 202) {
        throw Exception('Erro ao regenerar relatório: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na comunicação com o servidor: $e');
    }
  }

  // Buscar dispositivos para seleção
  static Future<List<Device>> getDevicesForReport(String token) async {
    try {
      final response = await _authenticatedRequest(
        'devices',
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> devices = data['devices'] ?? data;
        return devices.map((json) => Device.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar dispositivos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na comunicação com o servidor: $e');
    }
  }

  // Verificar status do relatório
  static Future<String> checkReportStatus(String token, int reportId) async {
    try {
      final report = await getReportById(token, reportId);
      return report.status;
    } catch (e) {
      throw Exception('Erro ao verificar status: $e');
    }
  }

  // Obter tipos de relatório disponíveis
  static List<Map<String, dynamic>> getReportTypes() {
    return [
      {
        'value': 'consumption',
        'label': 'Consumo',
        'description': 'Relatório de consumo energético',
        'icon': 'flash_on',
      },
      {
        'value': 'cost',
        'label': 'Custo',
        'description': 'Relatório de custos energéticos',
        'icon': 'attach_money',
      },
      {
        'value': 'efficiency',
        'label': 'Eficiência',
        'description': 'Análise de eficiência energética',
        'icon': 'trending_up',
      },
      {
        'value': 'comparative',
        'label': 'Comparativo',
        'description': 'Comparação entre períodos',
        'icon': 'compare_arrows',
      },
      {
        'value': 'custom',
        'label': 'Personalizado',
        'description': 'Relatório customizado',
        'icon': 'tune',
      },
    ];
  }

  // Obter tipos de período disponíveis
  static List<Map<String, dynamic>> getPeriodTypes() {
    return [
      {
        'value': 'daily',
        'label': 'Diário',
        'description': 'Dados agrupados por dia',
      },
      {
        'value': 'weekly',
        'label': 'Semanal',
        'description': 'Dados agrupados por semana',
      },
      {
        'value': 'monthly',
        'label': 'Mensal',
        'description': 'Dados agrupados por mês',
      },
      {
        'value': 'yearly',
        'label': 'Anual',
        'description': 'Dados agrupados por ano',
      },
      {
        'value': 'custom',
        'label': 'Personalizado',
        'description': 'Período customizado',
      },
    ];
  }

  // Obter formatos disponíveis
  static List<Map<String, dynamic>> getFormats() {
    return [
      {
        'value': 'pdf',
        'label': 'PDF',
        'description': 'Documento PDF com gráficos',
        'icon': 'picture_as_pdf',
      },
      {
        'value': 'excel',
        'label': 'Excel',
        'description': 'Planilha Excel (.xlsx)',
        'icon': 'table_chart',
      },
      {
        'value': 'csv',
        'label': 'CSV',
        'description': 'Arquivo CSV para análise',
        'icon': 'grid_on',
      },
      {
        'value': 'json',
        'label': 'JSON',
        'description': 'Dados estruturados em JSON',
        'icon': 'code',
      },
    ];
  }

  // Validar período selecionado
  static String? validatePeriod(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return 'Selecione as datas de início e fim';
    }
    
    if (start.isAfter(end)) {
      return 'Data de início deve ser anterior à data de fim';
    }
    
    if (end.isAfter(DateTime.now())) {
      return 'Data de fim não pode ser futura';
    }
    
    final difference = end.difference(start).inDays;
    if (difference > 365) {
      return 'Período não pode ser superior a 365 dias';
    }
    
    if (difference < 1) {
      return 'Período deve ter pelo menos 1 dia';
    }
    
    return null;
  }

  // Calcular tamanho estimado do relatório
  static String estimateReportSize(CreateReportRequest request) {
    final days = request.periodEnd.difference(request.periodStart).inDays;
    final deviceCount = request.deviceIds?.length ?? 1;
    
    double estimatedMB = 0;
    
    switch (request.format) {
      case 'pdf':
        estimatedMB = (days * deviceCount * 0.1) + 2;
        break;
      case 'excel':
        estimatedMB = (days * deviceCount * 0.05) + 1;
        break;
      case 'csv':
        estimatedMB = (days * deviceCount * 0.01) + 0.1;
        break;
      case 'json':
        estimatedMB = (days * deviceCount * 0.02) + 0.1;
        break;
    }
    
    if (estimatedMB < 1) {
      return '${(estimatedMB * 1024).toInt()} KB';
    } else {
      return '${estimatedMB.toStringAsFixed(1)} MB';
    }
  }

  // Polling para verificar status do relatório
  static Stream<Report> pollReportStatus(String token, int reportId) async* {
    while (true) {
      try {
        final report = await getReportById(token, reportId);
        yield report;
        
        // Se o relatório foi concluído ou falhou, parar o polling
        if (report.isCompleted || report.isFailed) {
          break;
        }
        
        // Aguardar 3 segundos antes da próxima verificação
        await Future.delayed(const Duration(seconds: 3));
      } catch (e) {
        // Em caso de erro, aguardar mais tempo antes de tentar novamente
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }
}
