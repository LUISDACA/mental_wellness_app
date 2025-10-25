import 'package:flutter/material.dart';
import '../../core/env.dart';
import '../../data/services/health_service.dart';

class StatusBanner extends StatefulWidget {
  const StatusBanner({super.key});
  @override
  State<StatusBanner> createState() => _StatusBannerState();
}

class _StatusBannerState extends State<StatusBanner> {
  Future<HealthCheckResult>? _future;

  @override
  void initState() {
    super.initState();
    _future = HealthService().run();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Diagnostics', style: style.titleMedium),
          const SizedBox(height: 8),
          Text('SUPABASE_URL: ${Env.supabaseUrl.isEmpty ? "(missing)" : "OK (set)"}'),
          Text('GEMINI_API_KEY: ${Env.geminiApiKey.isEmpty ? "(missing)" : "OK (set)"}'),
          const SizedBox(height: 8),
          FutureBuilder(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final r = snapshot.data as HealthCheckResult;
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _Dot(ok: r.supabaseOk),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Supabase connectivity: ${r.supabaseOk ? "OK" : "ERROR"}')),
                ]),
                if (!r.supabaseOk && r.supabaseError != null) Text(r.supabaseError!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 4),
                Row(children: [
                  _Dot(ok: r.geminiOk),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Gemini API: ${r.geminiOk ? "OK" : "ERROR"}')),
                ]),
                if (!r.geminiOk && r.geminiError != null) Text(r.geminiError!, style: const TextStyle(color: Colors.red)),
              ]);
            },
          ),
        ]),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool ok;
  const _Dot({required this.ok});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(
        color: ok ? Colors.green : Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}
