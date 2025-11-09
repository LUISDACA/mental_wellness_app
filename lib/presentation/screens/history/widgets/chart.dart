import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/history_entry.dart';

class HistoryChart extends StatelessWidget {
  final List<HistoryEntry> data;
  final String Function(DateTime) labeler;
  final Color Function(String) colorFor;
  final String Function(String) displayLabelFor;

  const HistoryChart({
    super.key,
    required this.data,
    required this.labeler,
    required this.colorFor,
    required this.displayLabelFor,
  });

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), data[i].severity.toDouble())
    ];

    const dangerLine = 80.0, lowLine = 30.0;

    return AspectRatio(
      aspectRatio: 1.8,
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 10,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 10,
                    reservedSize: 32,
                    getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                        style: const TextStyle(fontSize: 11)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: max(1, (data.length / 6).floorToDouble()),
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= data.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(labeler(data[i].createdAt),
                            style: const TextStyle(fontSize: 11)),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
              ),
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: dangerLine,
                  color: Colors.red.withValues(alpha: 0.35),
                  strokeWidth: 2,
                  dashArray: const [8, 6],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: const TextStyle(color: Colors.red, fontSize: 11),
                    labelResolver: (_) => 'RIESGO (≥80)',
                  ),
                ),
                HorizontalLine(
                  y: lowLine,
                  color: Colors.green.withValues(alpha: 0.35),
                  strokeWidth: 2,
                  dashArray: const [8, 6],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: const TextStyle(color: Colors.green, fontSize: 11),
                    labelResolver: (_) => 'BIENESTAR (≤30)',
                  ),
                ),
              ]),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touchedSpots) => touchedSpots.map((t) {
                    final i = t.x.toInt(), e = data[i];
                    return LineTooltipItem(
                      '${displayLabelFor(e.emotion)} • ${e.severity}/100\n'
                      '${DateFormat.yMMMd().add_Hm().format(e.createdAt.toLocal())}',
                      TextStyle(
                          color: colorFor(e.emotion),
                          fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                ),
              ),
              borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Theme.of(context).dividerColor)),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 3,
                  color: Theme.of(context).colorScheme.primary,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.25),
                        Colors.transparent
                      ],
                    ),
                  ),
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}