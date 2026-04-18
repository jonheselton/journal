import 'package:flutter/material.dart';
import '../services/database_service.dart';

/// Displays aggregated statistics: wizard averages, custom metric averages,
/// and top NLP-extracted tags.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _db = DatabaseService();
  bool _loading = true;
  int _entryCount = 0;
  Map<String, double> _wizardAverages = {};
  Map<String, double> _metricAverages = {};
  List<Map<String, dynamic>> _topTags = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final count = await _db.getEntryCount();
      final wizard = await _db.getWizardAverages();
      final metrics = await _db.getMetricAverages();
      final tags = await _db.getTopTags(limit: 15);
      if (!mounted) return;
      setState(() {
        _entryCount = count;
        _wizardAverages = wizard;
        _metricAverages = metrics;
        _topTags = tags;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entryCount == 0
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No entries yet.\nAdd journal entries to see statistics.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Entry count
                      _buildCountCard(),
                      const SizedBox(height: 16),
                      // Wizard Averages
                      if (_wizardAverages.isNotEmpty) ...[
                        _buildSectionHeader('Check-In Averages', Icons.psychology),
                        const SizedBox(height: 8),
                        _buildBarChart(_wizardAverages, maxValue: 10),
                        const SizedBox(height: 20),
                      ],
                      // Custom Metric Averages (Air, Earth, Wind, Fire)
                      if (_metricAverages.isNotEmpty) ...[
                        _buildSectionHeader('Element Averages', Icons.auto_awesome),
                        const SizedBox(height: 8),
                        _buildBarChart(_metricAverages, maxValue: 10),
                        const SizedBox(height: 20),
                      ],
                      // Top Tags
                      if (_topTags.isNotEmpty) ...[
                        _buildSectionHeader('Top Keywords', Icons.label),
                        const SizedBox(height: 8),
                        _buildTagCloud(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildCountCard() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.cyanAccent, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_entryCount',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
                Text(
                  _entryCount == 1 ? 'Journal Entry' : 'Journal Entries',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.orangeAccent),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(Map<String, double> data, {double maxValue = 10}) {
    final colors = [
      Colors.cyanAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.greenAccent,
      Colors.pinkAccent,
      Colors.amberAccent,
    ];

    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: data.entries.toList().asMap().entries.map((indexed) {
            final entry = indexed.value;
            final color = colors[indexed.key % colors.length];
            final fraction = (entry.value / maxValue).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      entry.key,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade300),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        backgroundColor: Colors.grey.shade800,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      entry.value.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTagCloud() {
    final maxCount = _topTags.isNotEmpty
        ? (_topTags.first['count'] as int)
        : 1;
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _topTags.map((tag) {
            final text = tag['text'] as String;
            final count = tag['count'] as int;
            final opacity = 0.4 + (0.6 * count / maxCount);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: opacity * 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: opacity * 0.5),
                ),
              ),
              child: Text(
                '$text ($count)',
                style: TextStyle(
                  fontSize: 12 + (opacity * 2),
                  color: Colors.cyanAccent.withValues(alpha: opacity),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
