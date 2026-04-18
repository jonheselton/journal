import 'package:flutter/material.dart';
import '../models/day_entry.dart';
import '../services/database_service.dart';

/// Tab 2: Insights — statistics dashboard, trends, and tag cloud.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _db = DatabaseService();
  bool _loading = true;
  int _entryCount = 0;
  Map<String, double> _wizardAverages = {};
  Map<String, double> _metricAverages = {};
  List<Map<String, dynamic>> _topTags = [];
  List<DayEntry> _recentEntries = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final count = await _db.getEntryCount();
      final wizard = await _db.getWizardAverages();
      final metrics = await _db.getMetricAverages();
      final tags = await _db.getTopTags(limit: 15);
      final entries = await _db.loadAllEntries();

      if (!mounted) return;
      setState(() {
        _entryCount = count;
        _wizardAverages = wizard;
        _metricAverages = metrics;
        _topTags = tags;
        // Take the most recent 14 entries for trend display
        _recentEntries = entries.take(14).toList().reversed.toList();
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
      appBar: AppBar(
        title: const Text('Insights'),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entryCount == 0
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No entries yet.\nAdd journal entries to see insights.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildCountCard(),
                      const SizedBox(height: 16),
                      // Mood & Energy Trend
                      if (_recentEntries.length >= 2) ...[
                        _buildTrendCard(),
                        const SizedBox(height: 16),
                      ],
                      // Check-In Averages
                      if (_wizardAverages.isNotEmpty) ...[
                        _buildSectionHeader(
                            'Check-In Averages', Icons.psychology),
                        const SizedBox(height: 8),
                        _buildBarChart(_wizardAverages, maxValue: 10),
                        const SizedBox(height: 16),
                      ],
                      // Element Averages
                      if (_metricAverages.isNotEmpty) ...[
                        _buildSectionHeader(
                            'Element Averages', Icons.auto_awesome),
                        const SizedBox(height: 8),
                        _buildBarChart(_metricAverages, maxValue: 10),
                        const SizedBox(height: 16),
                      ],
                      // Tag Cloud
                      if (_topTags.isNotEmpty) ...[
                        _buildSectionHeader('Top Tags', Icons.label),
                        const SizedBox(height: 8),
                        _buildTagCloud(),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
    );
  }

  // ──────────────────────────────────────────
  // Widgets
  // ──────────────────────────────────────────

  Widget _buildCountCard() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.cyanAccent, size: 32),
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

  Widget _buildTrendCard() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up,
                    size: 18, color: Colors.greenAccent),
                const SizedBox(width: 8),
                const Text(
                  'Recent Trends',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  'Last ${_recentEntries.length} entries',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSparkline('Mood', _recentEntries.map((e) => e.mood).toList(),
                Colors.cyanAccent),
            const SizedBox(height: 12),
            _buildSparkline(
                'Energy',
                _recentEntries.map((e) => e.energy).toList(),
                Colors.orangeAccent),
            const SizedBox(height: 12),
            _buildSparkline(
                'Sleep',
                _recentEntries.map((e) => e.sleep).toList(),
                Colors.purpleAccent),
          ],
        ),
      ),
    );
  }

  /// Simple sparkline-style trend using a row of colored dots/bars.
  Widget _buildSparkline(String label, List<int> values, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 28,
            child: CustomPaint(
              painter: _SparklinePainter(
                values: values.map((v) => v.toDouble()).toList(),
                color: color,
                maxValue: 10,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 20,
          child: Text(
            values.isNotEmpty ? '${values.last}' : '--',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagCloud() {
    // Calculate max count for sizing
    final maxCount = _topTags.fold<int>(
      1,
      (prev, tag) => (tag['count'] as int) > prev ? (tag['count'] as int) : prev,
    );

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
            // Scale font size between 11 and 18 based on frequency
            final fontSize = 11.0 + (count / maxCount) * 7.0;
            final opacity = 0.4 + (count / maxCount) * 0.6;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withValues(alpha: opacity * 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.purpleAccent.withValues(alpha: opacity * 0.4),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.purpleAccent.withValues(alpha: opacity),
                  fontWeight:
                      count == maxCount ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade300),
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
}

// ──────────────────────────────────────────
// Custom sparkline painter
// ──────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double maxValue;

  _SparklinePainter({
    required this.values,
    required this.color,
    this.maxValue = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final step = values.length > 1 ? size.width / (values.length - 1) : 0.0;

    for (int i = 0; i < values.length; i++) {
      final x = i * step;
      final y = size.height - (values[i] / maxValue) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Draw dots at each data point
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }

    // Close fill path
    fillPath.lineTo((values.length - 1) * step, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
