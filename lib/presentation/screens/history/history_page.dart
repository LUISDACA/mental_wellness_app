import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _sb = Supabase.instance.client;

  // 👉 Cambia si tu tabla se llama distinto
  final _tableCandidates = const [
    'emotions',
    'emotion_logs',
    'emotion_entries'
  ];

  String? _activeTable;
  List<_Entry> _all = [];
  List<_Entry> _view = [];

  // Filtros
  int _days = 30; // 7 / 30 / 90
  String _emoFilter =
      'all'; // all | happiness | sadness | anxiety | anger | neutral

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // busca la primera tabla que exista
      for (final t in _tableCandidates) {
        try {
          final rows =
              await _sb.from(t).select().order('created_at', ascending: true);
          _activeTable = t;
          _all = rows.map<_Entry>(_Entry.fromMap).toList();
          break;
        } catch (_) {
          // intenta siguiente
        }
      }
      if (_activeTable == null) {
        throw StateError(
            'No se encontró ninguna tabla de historial. Prueba con emotions/emotion_logs/emotion_entries.');
      }
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final cutoff = DateTime.now().toUtc().subtract(Duration(days: _days));
    final tmp = _all.where((e) => e.createdAt.isAfter(cutoff)).toList();
    final tmp2 = _emoFilter == 'all'
        ? tmp
        : tmp.where((e) => e.emotion == _emoFilter).toList();
    _view = tmp2;
    setState(() {});
  }

  // --------- Helpers de UI ---------
  String _fmtDate(DateTime d) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.Md(locale).format(d.toLocal());
  }

  Color _colorFor(String emo) {
    switch (emo) {
      case 'happiness':
        return Colors.green;
      case 'sadness':
        return Colors.blueGrey;
      case 'anxiety':
        return Colors.orange;
      case 'anger':
        return Colors.redAccent;
      default:
        return Colors.teal;
    }
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo iniciar la llamada a $number')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _view.isNotEmpty ? _view.last : null;
    // ✅ paréntesis para que sea bool con Dart
    final danger = (last?.severity ?? 0) >= 80;
    final low = (last?.severity ?? 0) <= 30;

    return Scaffold(
      appBar: AppBar(title: const Text('Emotional History')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Mensaje contextual
            if (danger)
              _DangerBanner(
                onCall: _call,
                onOpenSos: () => context.push('/sos'),
              ),
            if (!danger && low) const _CongratsBanner(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Error: $_error',
                    style: const TextStyle(color: Colors.red)),
              ),

            // Filtros
            Row(
              children: [
                DropdownButton<int>(
                  value: _days,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _days = v);
                    _applyFilters();
                  },
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7 días')),
                    DropdownMenuItem(value: 30, child: Text('30 días')),
                    DropdownMenuItem(value: 90, child: Text('90 días')),
                  ],
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _emoFilter,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _emoFilter = v);
                    _applyFilters();
                  },
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Todas')),
                    DropdownMenuItem(
                        value: 'happiness', child: Text('Felicidad')),
                    DropdownMenuItem(value: 'sadness', child: Text('Tristeza')),
                    DropdownMenuItem(value: 'anxiety', child: Text('Ansiedad')),
                    DropdownMenuItem(value: 'anger', child: Text('Enojo')),
                    DropdownMenuItem(value: 'neutral', child: Text('Neutral')),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Recargar',
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                )
              ],
            ),
            const SizedBox(height: 8),

            // Resumen
            _Summary(view: _view),

            const SizedBox(height: 12),

            // Gráfica
            if (_loading)
              const AspectRatio(
                aspectRatio: 1.8,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_view.isEmpty)
              Container(
                height: 160,
                alignment: Alignment.center,
                child: const Text(
                    'Aún no hay registros para este rango. Analiza tu estado en “Analyze Emotion”.'),
              )
            else
              _Chart(
                data: _view,
                labeler: _fmtDate,
                colorFor: _colorFor,
              ),

            const SizedBox(height: 16),

            // Lista reciente
            if (_view.isNotEmpty) ...[
              Text('Registros recientes',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              for (final e in _view.reversed.take(10))
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _colorFor(e.emotion).withOpacity(0.15),
                    child: Icon(Icons.favorite, color: _colorFor(e.emotion)),
                  ),
                  title: Text(
                      '${e.emotion}  •  severidad ${e.severity}/100  •  ${(e.score * 100).round()}%'),
                  subtitle: Text(_fmtDate(e.createdAt)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ----------------- Widgets -----------------

class _Chart extends StatelessWidget {
  final List<_Entry> data;
  final String Function(DateTime) labeler;
  final Color Function(String) colorFor;

  const _Chart({
    required this.data,
    required this.labeler,
    required this.colorFor,
  });

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].severity.toDouble()));
    }

    const dangerLine = 80.0;
    const lowLine = 30.0;

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
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 10,
                    reservedSize: 32,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 11),
                    ),
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
                        child: Text(
                          labeler(data[i].createdAt),
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
              ),
              // Líneas guía
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: dangerLine,
                  color: Colors.red.withOpacity(0.35),
                  strokeWidth: 2,
                  dashArray: [8, 6],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: const TextStyle(color: Colors.red, fontSize: 11),
                    labelResolver: (_) => 'RIESGO (≥80)',
                  ),
                ),
                HorizontalLine(
                  y: lowLine,
                  color: Colors.green.withOpacity(0.35),
                  strokeWidth: 2,
                  dashArray: [8, 6],
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
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((t) {
                      final i = t.x.toInt();
                      final e = data[i];
                      return LineTooltipItem(
                        '${e.emotion} • ${e.severity}/100\n${DateFormat.yMMMd().add_Hm().format(e.createdAt.toLocal())}',
                        TextStyle(
                          color: colorFor(e.emotion),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
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
                        Theme.of(context).colorScheme.primary.withOpacity(0.25),
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

class _Summary extends StatelessWidget {
  final List<_Entry> view;
  const _Summary({required this.view});

  @override
  Widget build(BuildContext context) {
    if (view.isEmpty) return const SizedBox.shrink();

    final avg =
        view.map((e) => e.severity).fold<int>(0, (a, b) => a + b) / view.length;
    final emoCount = <String, int>{};
    for (final e in view) {
      emoCount[e.emotion] = (emoCount[e.emotion] ?? 0) + 1;
    }
    final dominant = (emoCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.insights),
        title: Text('Promedio de severidad: ${avg.toStringAsFixed(0)}/100'),
        subtitle: Text('Emoción dominante: $dominant'),
      ),
    );
  }
}

class _DangerBanner extends StatelessWidget {
  final Future<void> Function(String) onCall;
  final VoidCallback onOpenSos;
  const _DangerBanner({required this.onCall, required this.onOpenSos});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Señal de alerta 😟',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.red)),
            const SizedBox(height: 6),
            const Text(
              'Tu severidad reciente es alta. Te recomiendo buscar ayuda inmediata. '
              'Si estás en peligro, llama a emergencias.',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilledButton.icon(
                  onPressed: onOpenSos,
                  icon: const Icon(Icons.health_and_safety),
                  label: const Text('Abrir SOS'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onCall('911'),
                  icon: const Icon(Icons.call),
                  label: const Text('Llamar 911'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onCall('123'),
                  icon: const Icon(Icons.call),
                  label: const Text('Llamar 123'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CongratsBanner extends StatelessWidget {
  const _CongratsBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.withOpacity(0.07),
      child: const ListTile(
        leading: Icon(Icons.emoji_events, color: Colors.green),
        title: Text('¡Buen trabajo!'),
        subtitle: Text(
          'Tu severidad reciente es baja. Mantén las rutinas que te ayudan: respiración, '
          'diario y contacto social positivo.',
        ),
      ),
    );
  }
}

// ----------------- Modelo local -----------------
class _Entry {
  final DateTime createdAt;
  final String emotion;
  final double score;
  final int severity;

  _Entry({
    required this.createdAt,
    required this.emotion,
    required this.score,
    required this.severity,
  });

  factory _Entry.fromMap(Map<String, dynamic> m) {
    final dtRaw = (m['created_at'] ?? m['timestamp'] ?? m['date']).toString();
    return _Entry(
      createdAt: DateTime.parse(dtRaw),
      emotion: (m['emotion'] ?? 'neutral') as String,
      score: (m['score'] is num) ? (m['score'] as num).toDouble() : 0.0,
      severity: (m['severity'] is num) ? (m['severity'] as num).toInt() : 0,
    );
  }
}
