import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/day_entry.dart';
import '../models/metric.dart';
import '../models/tag.dart';
import '../services/database_service.dart';
import 'wizard_screen.dart';

class DayEntryScreen extends StatefulWidget {
  final DayEntry entry;

  const DayEntryScreen({Key? key, required this.entry}) : super(key: key);

  @override
  _DayEntryScreenState createState() => _DayEntryScreenState();
}

class _DayEntryScreenState extends State<DayEntryScreen> {
  late TextEditingController _contentController;
  late DayEntry _currentEntry;
  bool _isPreviewMode = false;
  final _db = DatabaseService();

  // Element metrics (Air, Earth, Wind, Fire)
  List<Metric> _metrics = [];
  Map<int, int> _metricValues = {};
  List<Tag> _tags = [];
  bool _metricsLoaded = false;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
    _contentController = TextEditingController(text: _currentEntry.content);
    // Start in preview/view mode if there's already content
    _isPreviewMode = _currentEntry.content.isNotEmpty;
    _loadMetricsAndTags();
  }

  Future<void> _loadMetricsAndTags() async {
    try {
      final metrics = await _db.getAllMetrics();
      Map<int, int> values = {};
      List<Tag> tags = [];

      // If editing an existing entry, load its metric values and tags
      if (_currentEntry.id != null) {
        values = await _db.loadDayMetrics(_currentEntry.id!);
        tags = await _db.loadDayEntryTags(_currentEntry.id!);
      }

      // Default unset metrics to 5
      for (final m in metrics) {
        values.putIfAbsent(m.id, () => 5);
      }

      if (!mounted) return;
      setState(() {
        _metrics = metrics;
        _metricValues = values;
        _tags = tags;
        _metricsLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading metrics: $e');
    }
  }

  @override
  void dispose() {
    _contentController.clear();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    final updatedEntry = _currentEntry.copyWith(
      content: _contentController.text,
      updatedAt: DateTime.now(),
    );

    // Save element metrics to DB if we have an entry id
    _saveMetrics(updatedEntry);

    Navigator.pop(context, updatedEntry);
  }

  Future<void> _saveMetrics(DayEntry entry) async {
    if (entry.id != null && _metricValues.isNotEmpty) {
      try {
        await _db.saveDayMetrics(entry.id!, _metricValues);
      } catch (e) {
        debugPrint('Error saving metrics: $e');
      }
    }
  }

  /// Launch the daily check-in wizard, with a redo confirmation if already done.
  Future<void> _launchCheckIn() async {
    final alreadyDone = await _db.hasCompletedWizardToday();

    if (alreadyDone) {
      // Show confirmation dialog
      final redo = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Daily Check-In'),
          content: const Text('Check-in already completed today. Redo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Redo'),
            ),
          ],
        ),
      );
      if (redo != true || !mounted) return;
    }

    // Launch wizard
    final wizardResult = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const WizardScreen()),
    );
    if (wizardResult == null || !mounted) return;

    // Update current entry with new wizard data
    setState(() {
      _currentEntry = _currentEntry.copyWith(
        mood: wizardResult['mood'] ?? _currentEntry.mood,
        sleep: wizardResult['sleep'] ?? _currentEntry.sleep,
        x: wizardResult['x'] ?? _currentEntry.x,
        workload: wizardResult['workload'] ?? _currentEntry.workload,
        energy: wizardResult['energy'] ?? _currentEntry.energy,
        updatedAt: DateTime.now(),
      );
    });
  }

  String _formatDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[int.parse(parts[1])]} ${int.parse(parts[2])}, ${parts[0]}';
    } catch (_) {
      return dateKey;
    }
  }

  String _formatSleep(int? minutes) {
    if (minutes == null) return '--';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  IconData _metricIcon(Metric metric) {
    switch (metric.key) {
      case 'air':
        return Icons.air;
      case 'earth':
        return Icons.terrain;
      case 'wind':
        return Icons.wind_power;
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.circle;
    }
  }

  Color _metricColor(Metric metric) {
    switch (metric.key) {
      case 'air':
        return Colors.lightBlueAccent;
      case 'earth':
        return Colors.brown.shade300;
      case 'wind':
        return Colors.tealAccent;
      case 'fire':
        return Colors.deepOrangeAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _currentEntry;
    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(entry.dateKey)),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: 'Add Details',
            onPressed: _launchCheckIn,
          ),
          IconButton(
            icon: Icon(_isPreviewMode ? Icons.edit : Icons.preview),
            tooltip: _isPreviewMode ? 'Edit' : 'Preview',
            onPressed: () {
              setState(() => _isPreviewMode = !_isPreviewMode);
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Health Connect Metrics ---
            _buildHealthCard(entry),
            const SizedBox(height: 12),
            // --- Wizard Metrics ---
            _buildWizardCard(entry),
            const SizedBox(height: 12),
            // --- Element Metrics (Air, Earth, Wind, Fire) ---
            if (_metricsLoaded) _buildElementCard(),
            const SizedBox(height: 12),
            // --- Tags ---
            if (_tags.isNotEmpty) _buildTagsCard(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // --- Note Content ---
            if (_isPreviewMode)
              MarkdownBody(
                data: _contentController.text.isEmpty
                    ? '*No journal content yet — tap edit to write.*'
                    : _contentController.text,
                selectable: true,
              )
            else
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Journal entry (Markdown supported)...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                minLines: 10,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard(DayEntry entry) {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart, size: 18, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                const Text(
                  'Health Connect',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _healthMetric(
                  Icons.directions_walk,
                  'Steps',
                  entry.steps != null ? '${entry.steps}' : '--',
                ),
                _healthMetric(
                  Icons.favorite,
                  'Avg HR',
                  entry.avgHeartRate != null
                      ? '${entry.avgHeartRate!.round()} bpm'
                      : '--',
                ),
                _healthMetric(
                  Icons.bedtime,
                  'Sleep',
                  _formatSleep(entry.sleepMinutes),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthMetric(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.cyanAccent.withValues(alpha: 0.7)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildWizardCard(DayEntry entry) {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, size: 18, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                const Text(
                  'Check-In',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _wizardChip('Mood', entry.mood),
                _wizardChip('Sleep', entry.sleep),
                _wizardTag('X', entry.x),
                _wizardChip('Work', entry.workload),
                _wizardChip('Energy', entry.energy),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElementCard() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: Colors.amberAccent),
                const SizedBox(width: 8),
                const Text(
                  'Elements',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._metrics.map((metric) {
              final value = _metricValues[metric.id] ?? 5;
              final color = _metricColor(metric);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(_metricIcon(metric), size: 20, color: color),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      child: Text(
                        metric.name,
                        style: TextStyle(fontSize: 13, color: color),
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: value.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: color,
                        label: value.toString(),
                        onChanged: (val) {
                          setState(() {
                            _metricValues[metric.id] = val.toInt();
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$value',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsCard() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.label, size: 18, color: Colors.purpleAccent),
                const SizedBox(width: 8),
                const Text(
                  'Auto-Tags',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.purpleAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          tag.text,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.purpleAccent,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wizardChip(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _wizardTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
