import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/dashboard_response.dart';
import '../utils/dashboard_utils.dart';

class ConsumptionChartWidget extends StatelessWidget {
  final Map<String, dynamic> dailyConsumption;
  final List<Device> devices;
  final String selectedType;

  const ConsumptionChartWidget({
    Key? key,
    required this.dailyConsumption,
    required this.devices,
    required this.selectedType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chartData = _processRealChartData();

    if (chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum dado de $selectedType disponível',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Conecte dispositivos compatíveis para visualizar dados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // FIX CRÍTICO: Calcular valores uma única vez para garantir consistência
    final safeMaxY = _calculateSafeMaxY(chartData);
    final safeHorizontalInterval = _calculateSafeHorizontalInterval(safeMaxY);

    // DEBUG: Verificar valores antes de usar
    print('DEBUG ChartWidget:');
    print('  chartData.length: ${chartData.length}');
    print('  safeMaxY: $safeMaxY');
    print('  safeHorizontalInterval: $safeHorizontalInterval');

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          // FIX: Usar valor pré-calculado e validado
          horizontalInterval: safeHorizontalInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < chartData.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      chartData[index].label,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
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
              // FIX: Usar mesmo valor pré-calculado
              interval: safeHorizontalInterval,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    _formatAxisValue(value),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (chartData.length - 1).toDouble(),
        minY: 0,
        // FIX: Usar valor pré-calculado
        maxY: safeMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: chartData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            gradient: _getGradient(),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: _getMainColor(),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _getMainColor().withOpacity(0.3),
                  _getMainColor().withOpacity(0.1),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black87,
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                if (index >= 0 && index < chartData.length) {
                  final data = chartData[index];
                  return LineTooltipItem(
                    '${data.label}\n${_formatTooltipValue(data.value)} ${_getUnit()}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                FlLine(color: _getMainColor(), strokeWidth: 2),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: _getMainColor(),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  /// Processar dados reais da API com validação rigorosa
  List<ChartDataPoint> _processRealChartData() {
    final aggregated = <String, double>{};

    try {
      // Processar dados reais de todos os dispositivos
      dailyConsumption.forEach((deviceId, deviceData) {
        if (deviceData is Map<String, dynamic> && deviceData.containsKey(selectedType)) {
          final measurements = deviceData[selectedType] as List?;

          if (measurements != null) {
            for (var measurement in measurements) {
              if (measurement is Map<String, dynamic>) {
                final date = measurement['date'] as String?;
                final value = (measurement['value'] as num?)?.toDouble();

                // Validação rigorosa dos dados
                if (date != null && 
                    value != null && 
                    value.isFinite && 
                    !value.isNaN && 
                    value >= 0) {

                  if (selectedType == 'energy') {
                    aggregated[date] = (aggregated[date] ?? 0.0) + value;
                  } else {
                    // Para sensores, usar média
                    if (aggregated.containsKey(date)) {
                      aggregated[date] = (aggregated[date]! + value) / 2;
                    } else {
                      aggregated[date] = value;
                    }
                  }
                }
              }
            }
          }
        }
      });
    } catch (e) {
      print('ERROR processing chart data: $e');
      return [];
    }

    // Se não há dados válidos, retornar lista vazia
    if (aggregated.isEmpty) {
      return [];
    }

    try {
      // Ordenar por data e converter para ChartDataPoint
      final sortedEntries = aggregated.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      return sortedEntries.map((entry) {
        return ChartDataPoint(
          label: DashboardUtils.formatDate(entry.key),
          value: entry.value,
          date: entry.key,
        );
      }).toList();
    } catch (e) {
      print('ERROR formatting chart data: $e');
      return [];
    }
  }

  /// FIX CRÍTICO: Calcular maxY com múltiplas validações
  double _calculateSafeMaxY(List<ChartDataPoint> data) {
    if (data.isEmpty) {
      print('DEBUG: No chart data, using fallback maxY');
      return 100.0;
    }

    try {
      final validValues = data
          .where((e) => e.value.isFinite && !e.value.isNaN && e.value >= 0)
          .map((e) => e.value)
          .toList();

      if (validValues.isEmpty) {
        print('DEBUG: No valid values, using fallback maxY');
        return 100.0;
      }

      final maxValue = validValues.reduce((prev, curr) => prev > curr ? prev : curr);

      if (maxValue <= 0 || !maxValue.isFinite || maxValue.isNaN) {
        print('DEBUG: Invalid maxValue ($maxValue), using fallback');
        return 100.0;
      }

      // Adicionar margem, mas garantir mínimo
      final result = maxValue * 1.2;
      final finalResult = result > 10.0 ? result : 10.0;

      print('DEBUG: Calculated maxY = $finalResult (from maxValue $maxValue)');
      return finalResult;

    } catch (e) {
      print('ERROR calculating maxY: $e');
      return 100.0;
    }
  }

  /// FIX CRÍTICO: Calcular horizontalInterval com garantias absolutas
  double _calculateSafeHorizontalInterval(double maxY) {
    try {
      // Validações múltiplas
      if (!maxY.isFinite || maxY.isNaN || maxY <= 0) {
        print('DEBUG: Invalid maxY ($maxY) for interval, using fallback');
        return 20.0;
      }

      // Calcular intervalo básico
      double interval = maxY / 5; // 5 linhas horizontais

      // Múltiplas verificações de segurança
      if (!interval.isFinite || interval.isNaN || interval <= 0) {
        print('DEBUG: Invalid calculated interval ($interval), using fallback');
        return 20.0;
      }

      // Garantir mínimo absoluto
      if (interval < 1.0) {
        interval = 1.0;
      }

      print('DEBUG: Final horizontalInterval = $interval');

      // Verificação final antes de retornar
      assert(interval > 0, 'horizontalInterval must be > 0');
      assert(interval.isFinite, 'horizontalInterval must be finite');
      assert(!interval.isNaN, 'horizontalInterval cannot be NaN');

      return interval;

    } catch (e) {
      print('ERROR calculating horizontalInterval: $e');
      return 20.0; // Fallback absoluto
    }
  }

  Color _getMainColor() {
    switch (selectedType) {
      case 'energy':
        return DashboardUtils.primaryGreen;
      case 'temperature':
        return DashboardUtils.primaryOrange;
      case 'humidity':
        return const Color(0xFF3498DB);
      default:
        return DashboardUtils.primaryGreen;
    }
  }

  LinearGradient _getGradient() {
    final color = _getMainColor();
    return LinearGradient(
      colors: [color, color.withOpacity(0.8)],
    );
  }

  String _getUnit() {
    switch (selectedType) {
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

  String _formatAxisValue(double value) {
    if (!value.isFinite || value.isNaN) return '0';

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    } else if (value >= 1) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  String _formatTooltipValue(double value) {
    if (!value.isFinite || value.isNaN) return '0.00';
    return value.toStringAsFixed(2);
  }
}

class ChartDataPoint {
  final String label;
  final double value;
  final String date;

  ChartDataPoint({
    required this.label,
    required this.value,
    required this.date,
  });
}