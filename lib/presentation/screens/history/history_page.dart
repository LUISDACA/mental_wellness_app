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
  List<_Entry> _all = [], _view = [];

  // Filtro único
  int _days = 30; // 7 / 30 / 90

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
      for (final t in _tableCandidates) {
        try {
          final rows =
              await _sb.from(t).select().order('created_at', ascending: true);
          _activeTable = t;
          _all = rows.map<_Entry>(_Entry.fromMap).toList();
          break;
        } catch (_) {}
      }
      if (_activeTable == null) {
        throw StateError(
          'No se encontró ninguna tabla de historial. Prueba con emotions/emotion_logs/emotion_entries.',
        );
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
    _view = _all.where((e) => e.createdAt.isAfter(cutoff)).toList();
    setState(() {});
  }

  // --------- Helpers ---------
  String _fmtDate(DateTime d) =>
      DateFormat.Md(Localizations.localeOf(context).toString())
          .format(d.toLocal());

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
        return Colors.teal; // neutral u otros
    }
  }

  String _labelFor(String emo) {
    switch (emo) {
      case 'happiness':
        return 'Felicidad';
      case 'sadness':
        return 'Tristeza';
      case 'anxiety':
        return 'Ansiedad';
      case 'anger':
        return 'Enojo';
      default:
        return 'Neutral';
    }
  }

  double _avgSeverity(List<_Entry> list) => list.isEmpty
      ? 0
      : list.map((e) => e.severity).reduce((a, b) => a + b) / list.length;

  String _dominantEmotion(List<_Entry> list) {
    if (list.isEmpty) return 'neutral';
    final m = <String, int>{};
    for (final e in list) {
      m[e.emotion] = (m[e.emotion] ?? 0) + 1;
    }
    return m.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo iniciar la llamada a $number')));
    }
  }

  void _showAiAdvice(_Entry e) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.psychology_alt_outlined, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Detalle del análisis',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                Chip(
                    label: Text(_labelFor(e.emotion)),
                    visualDensity: VisualDensity.compact),
                Chip(
                  label: Text(
                      'Severidad ${e.severity}/100${e.score > 0 ? " • ${(e.score * 100).round()}%" : ""}'),
                  visualDensity: VisualDensity.compact,
                ),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (e.severity.clamp(0, 100)) / 100.0,
                  minHeight: 8,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 16),
              if ((e.textInput ?? '').trim().isNotEmpty) ...[
                Text('Lo que escribiste',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                Text(e.textInput!.trim()),
                const SizedBox(height: 14),
              ],
              Text('Lo que te sugirió la IA',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Text((e.advice ?? '').trim().isNotEmpty
                  ? e.advice!.trim()
                  : 'No se guardó consejo para este registro.'),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar')),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avg = _avgSeverity(_view);
    final dom = _dominantEmotion(_view);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial emocional')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Banners por PROMEDIO de severidad / dominante
            if (_view.isNotEmpty) ...[
              if (avg >= 80)
                _DangerBanner(
                  onCall: _call,
                  onOpenSos: () => context.push('/sos'),
                  avg: avg,
                )
              else if (avg <= 30)
                _CongratsBanner(avg: avg)
              else
                _DominantBanner(dom: dom),
            ],

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Error: $_error',
                    style: const TextStyle(color: Colors.red)),
              ),

            // Filtro (solo días) + recarga
            Row(children: [
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
              const Spacer(),
              IconButton(
                tooltip: 'Recargar',
                onPressed: _load,
                icon: const Icon(Icons.refresh),
              )
            ]),
            const SizedBox(height: 8),

            // Resumen
            _Summary(view: _view, labelFor: _labelFor),

            const SizedBox(height: 12),

            // Gráfica
            if (_loading)
              const AspectRatio(
                  aspectRatio: 1.8,
                  child: Center(child: CircularProgressIndicator()))
            else if (_view.isEmpty)
              Container(
                height: 160,
                alignment: Alignment.center,
                child: const Text(
                    'Aún no hay registros para este rango. Analiza tu estado en “Analizar emoción”.'),
              )
            else
              _Chart(
                  data: _view,
                  labeler: _fmtDate,
                  colorFor: _colorFor,
                  displayLabelFor: _labelFor),

            const SizedBox(height: 16),

            // Lista reciente (tap para ver consejo IA)
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
                      '${_labelFor(e.emotion)}  •  severidad ${e.severity}/100  •  ${(e.score * 100).round()}%'),
                  subtitle: Text(_fmtDate(e.createdAt)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAiAdvice(e),
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
  final String Function(String) displayLabelFor;

  const _Chart({
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
                  color: Colors.red.withOpacity(0.35),
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
                  color: Colors.green.withOpacity(0.35),
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
  final String Function(String) labelFor;
  const _Summary({required this.view, required this.labelFor});

  @override
  Widget build(BuildContext context) {
    if (view.isEmpty) return const SizedBox.shrink();
    final avg =
        view.map((e) => e.severity).reduce((a, b) => a + b) / view.length;
    final counts = <String, int>{};
    for (final e in view) {
      counts[e.emotion] = (counts[e.emotion] ?? 0) + 1;
    }
    final domKey =
        counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.insights),
        title: Text('Promedio de severidad: ${avg.toStringAsFixed(0)}/100'),
        subtitle: Text('Emoción dominante: ${labelFor(domKey)}'),
      ),
    );
  }
}

// ----------------- Banners -----------------

class _DangerBanner extends StatelessWidget {
  final Future<void> Function(String) onCall;
  final VoidCallback onOpenSos;
  final double avg;
  const _DangerBanner(
      {required this.onCall, required this.onOpenSos, required this.avg});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Señal de alerta 😟',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.red)),
          const SizedBox(height: 6),
          Text(
              'Tu promedio de severidad es alto (${avg.toStringAsFixed(0)}/100). '
              'Si te sientes en riesgo, busca ayuda inmediata.'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
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
          ]),
        ]),
      ),
    );
  }
}

class _CongratsBanner extends StatelessWidget {
  final double avg;
  const _CongratsBanner({required this.avg});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.withOpacity(0.07),
      child: ListTile(
        leading: const Icon(Icons.emoji_events, color: Colors.green),
        title: const Text('¡Buen trabajo!'),
        subtitle: Text(
          'Tu promedio de severidad es bajo (${avg.toStringAsFixed(0)}/100). '
          'Sigue con tus hábitos: respiración, diario y contacto positivo.',
        ),
      ),
    );
  }
}

class _DominantBanner extends StatelessWidget {
  final String dom; // happiness | sadness | anxiety | anger | neutral
  const _DominantBanner({required this.dom});

  @override
  Widget build(BuildContext context) {
    const msgs = {
      'happiness':
          'Predomina la felicidad. Mantén tus hábitos que te hacen bien y compártelos con tu red cercana.',
      'sadness':
          'La tristeza ha sido frecuente. Escríbela o compártela con alguien de confianza; una caminata suave ayuda.',
      'anxiety':
          'La ansiedad aparece seguido. Prueba respiración 4-7-8 o la técnica 5-4-3-2-1 para anclarte al presente.',
      'anger':
          'El enojo ha sido recurrente. Pausa, respira profundo y toma algo de movimiento antes de responder.',
      'neutral':
          'Tu estado general es estable. Es normal sentirse neutral; si necesitas hablar, aquí estamos.',
    };

    final colors = {
      'happiness': Colors.green.withOpacity(0.07),
      'sadness': Colors.blueGrey.withOpacity(0.08),
      'anxiety': Colors.orange.withOpacity(0.08),
      'anger': Colors.redAccent.withOpacity(0.08),
      'neutral': Colors.blueGrey.withOpacity(0.06),
    };

    final icons = {
      'happiness': Icons.emoji_emotions,
      'sadness': Icons.water_drop,
      'anxiety': Icons.self_improvement,
      'anger': Icons.flare,
      'neutral': Icons.self_improvement,
    };

    final key = msgs.containsKey(dom) ? dom : 'neutral';
    return Card(
      color: colors[key],
      child: ListTile(
        leading: Icon(icons[key]),
        title: Text('Emoción dominante: ${_labelFor(key)}'),
        subtitle: Text(msgs[key]!),
      ),
    );
  }

  String _labelFor(String emo) {
    switch (emo) {
      case 'happiness':
        return 'Felicidad';
      case 'sadness':
        return 'Tristeza';
      case 'anxiety':
        return 'Ansiedad';
      case 'anger':
        return 'Enojo';
      default:
        return 'Neutral';
    }
  }
}

// ----------------- Modelo local -----------------
class _Entry {
  final DateTime createdAt;

  /// Emoción canónica: happiness | sadness | anxiety | anger | neutral
  final String emotion;
  final double score;
  final int severity;
  final String? advice; // consejo de la IA
  final String? textInput; // lo que escribiste

  _Entry({
    required this.createdAt,
    required this.emotion,
    required this.score,
    required this.severity,
    this.advice,
    this.textInput,
  });

  factory _Entry.fromMap(Map<String, dynamic> m) {
    final rawEmotion =
        (m['detected_emotion'] ?? m['emotion'] ?? m['label'] ?? 'neutral')
            .toString();
    final dtRaw = (m['created_at'] ?? m['timestamp'] ?? m['date']).toString();
    final advice =
        (m['advice'] ?? m['ai_advice'] ?? m['response'] ?? m['message'])
            ?.toString();
    final text = (m['text_input'] ?? m['text'] ?? m['prompt'])?.toString();

    return _Entry(
      createdAt: DateTime.parse(dtRaw),
      emotion: _canonicalEmotion(rawEmotion),
      score: (m['score'] is num) ? (m['score'] as num).toDouble() : 0.0,
      severity: (m['severity'] is num) ? (m['severity'] as num).toInt() : 0,
      advice: advice,
      textInput: text,
    );
  }

  static String _canonicalEmotion(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'happiness' || s == 'felicidad' || s.contains('alegr')) {
      return 'happiness';
    }
    if (s == 'sadness' || s == 'tristeza' || s.contains('depres')) {
      return 'sadness';
    }
    if (s == 'anxiety' ||
        s == 'ansiedad' ||
        s.contains('estres') ||
        s.contains('estrés') ||
        s.contains('miedo')) {
      return 'anxiety';
    }
    if (s == 'anger' || s == 'enojo' || s == 'ira' || s.contains('rabia')) {
      return 'anger';
    }
    if (s == 'neutral' || s.contains('calm') || s.contains('tranq')) {
      return 'neutral';
    }
    return 'neutral';
  }
}
