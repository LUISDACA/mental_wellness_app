import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'models/history_entry.dart';
import 'utils/history_utils.dart';
import 'widgets/chart.dart';
import 'widgets/summary_card.dart';
import 'widgets/banners.dart';
import 'widgets/recent_list.dart';

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
  List<HistoryEntry> _all = [], _view = [];

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
          _all = rows.map<HistoryEntry>(HistoryEntry.fromMap).toList();
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
  String _fmtDate(DateTime d) => formatDateShort(context, d);

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

  @override
  Widget build(BuildContext context) {
    final avg = avgSeverity(_view);
    final dom = dominantEmotion(_view);

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
                DangerBanner(
                  onCall: _call,
                  onOpenSos: () => context.push('/sos'),
                  avg: avg,
                )
              else if (avg <= 30)
                CongratsBanner(avg: avg)
              else
                DominantBanner(dom: dom),
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
            SummaryCard(view: _view, labelFor: labelForEmotion),

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
              HistoryChart(
                data: _view,
                labeler: _fmtDate,
                colorFor: colorForEmotion,
                displayLabelFor: labelForEmotion,
              ),

            const SizedBox(height: 16),

            // Lista reciente (tap para ver consejo IA)
            if (_view.isNotEmpty) RecentList(entries: _view),
          ],
        ),
      ),
    );
  }
}
// Eliminado: widgets y modelo local movidos a archivos dedicados en /widgets, /utils y /models
