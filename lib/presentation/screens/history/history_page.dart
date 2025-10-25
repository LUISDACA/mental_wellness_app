import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HP();
}

class _HP extends State<HistoryPage> {
  List<Map<String, dynamic>> data = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sb = Supabase.instance.client;
    final res = await sb.from('emotion_entries').select().order('created_at');
    setState(() {
      data = (res as List).cast<Map<String, dynamic>>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emotional History')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: data.isEmpty
            ? const Center(child: Text('No data'))
            : LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < data.length; i++)
                          FlSpot(i.toDouble(), (data[i]['severity'] as num).toDouble()),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
