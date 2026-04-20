import 'package:flutter/material.dart';
import '../models/day_entry.dart';
import '../services/database_service.dart';
import '../services/health_service.dart';
import '../services/keyword_extractor.dart';
import 'day_entry_screen.dart';

class DayListScreen extends StatefulWidget {
  const DayListScreen({Key? key}) : super(key: key);

  @override
  DayListScreenState createState() => DayListScreenState();
}

class DayListScreenState extends State<DayListScreen> {
  List<DayEntry> _entries = [];
  final _db = DatabaseService();
  final _healthService = HealthService();
  bool _loading = true;
  bool _migrated = false;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    // Run migration from old secure storage on first launch
    if (!_migrated) {
      try {
        final count = await _db.migrateFromSecureStorage();
        if (count > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Migrated $count entries to secure database')),
          );
        }
      } catch (e) {
        debugPrint('Migration error: $e');
      }
      _migrated = true;
    }
    await _loadEntries();
  }

  Future<void> _loadEntries() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final entries = await _db.loadAllEntries();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  /// Public method — called by HomeScreen's FAB.
  Future<void> createOrEditToday() async {
    final todayKey = DayEntry.todayKey();
    final existing = await _db.loadDayEntry(todayKey);

    if (existing != null) {
      // Entry already exists for today — open it for editing
      _editEntry(existing);
      return;
    }

    // Fetch health data
    final healthMetrics = await _healthService.fetchDayMetrics(DateTime.now());

    final now = DateTime.now();
    final entry = DayEntry(
      dateKey: todayKey,
      timezoneOffset: DayEntry.currentTimezoneOffset(),
      mood: 5,
      sleep: 5,
      x: '1',
      workload: 5,
      energy: 5,
      steps: healthMetrics.steps,
      avgHeartRate: healthMetrics.avgHeartRate,
      sleepMinutes: healthMetrics.sleepMinutes,
      sleepStages: healthMetrics.sleepStages,
      content: '',
      createdAt: now,
      updatedAt: now,
    );

    // Open the editor directly — user can tap Add Details to add metrics
    if (!mounted) return;
    final result = await Navigator.push<DayEntry>(
      context,
      MaterialPageRoute(builder: (context) => DayEntryScreen(entry: entry)),
    );

    if (result != null) {
      final entryId = await _db.saveDayEntry(result);

      // Save default element metrics (Air=5, Earth=5, Wind=5, Fire=5)
      final metrics = await _db.getAllMetrics();
      final metricValues = <int, int>{};
      for (final m in metrics) {
        metricValues[m.id] = 5; // Default to 5
      }
      await _db.saveDayMetrics(entryId, metricValues);

      // Extract and save NLP tags
      if (result.content.isNotEmpty) {
        final keywords = KeywordExtractor.extract(result.content);
        await _db.saveDayEntryTags(entryId, keywords);
      }

      _loadEntries();
    }
  }

  Future<void> _editEntry(DayEntry entry) async {
    // Re-fetch health data on edit
    final date = entry.dayRange.start;
    final healthMetrics = await _healthService.fetchDayMetrics(date);

    final updatedEntry = entry.copyWith(
      steps: healthMetrics.steps ?? entry.steps,
      avgHeartRate: healthMetrics.avgHeartRate ?? entry.avgHeartRate,
      sleepMinutes: healthMetrics.sleepMinutes ?? entry.sleepMinutes,
      sleepStages: healthMetrics.sleepStages ?? entry.sleepStages,
      updatedAt: DateTime.now(),
    );

    if (!mounted) return;

    final result = await Navigator.push<DayEntry>(
      context,
      MaterialPageRoute(
          builder: (context) => DayEntryScreen(entry: updatedEntry)),
    );

    if (result != null) {
      final entryId = await _db.saveDayEntry(result);

      // Extract and save NLP tags
      if (result.content.isNotEmpty) {
        final keywords = KeywordExtractor.extract(result.content);
        await _db.saveDayEntryTags(entryId, keywords);
      }

      _loadEntries();
    }
  }

  void _deleteEntry(String dateKey) async {
    await _db.deleteDayEntry(dateKey);
    _loadEntries();
  }

  String _formatDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = months[int.parse(parts[1])];
      final day = int.parse(parts[2]);
      final year = parts[0];
      return '$month $day, $year';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No entries yet.\nTap + to start today\'s note.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return Dismissible(
                      key: Key(entry.dateKey),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Entry'),
                            content: Text(
                                'Delete entry for ${_formatDate(entry.dateKey)}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) => _deleteEntry(entry.dateKey),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: InkWell(
                          onTap: () => _editEntry(entry),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(entry.dateKey),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Mood: ${entry.mood}/10',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.cyanAccent
                                            .withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Health metrics row
                                Row(
                                  children: [
                                    _metricChip(Icons.directions_walk,
                                        '${entry.steps ?? '--'}'),
                                    const SizedBox(width: 12),
                                    _metricChip(Icons.favorite,
                                        entry.avgHeartRate != null
                                            ? '${entry.avgHeartRate!.round()} bpm'
                                            : '--'),
                                    const SizedBox(width: 12),
                                    _metricChip(Icons.bedtime,
                                        _formatSleep(entry.sleepMinutes)),
                                  ],
                                ),
                                // Note preview
                                if (entry.content.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    entry.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _metricChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}
