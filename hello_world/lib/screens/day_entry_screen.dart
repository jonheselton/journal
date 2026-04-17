import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/day_entry.dart';

class DayEntryScreen extends StatefulWidget {
  final DayEntry entry;

  const DayEntryScreen({Key? key, required this.entry}) : super(key: key);

  @override
  _DayEntryScreenState createState() => _DayEntryScreenState();
}

class _DayEntryScreenState extends State<DayEntryScreen> {
  late TextEditingController _contentController;
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.entry.content);
    // Start in preview/view mode if there's already content
    _isPreviewMode = widget.entry.content.isNotEmpty;
  }

  @override
  void dispose() {
    _contentController.clear();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    final updatedEntry = widget.entry.copyWith(
      content: _contentController.text,
      updatedAt: DateTime.now(),
    );
    Navigator.pop(context, updatedEntry);
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

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(entry.dateKey)),
        actions: [
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
                _wizardTag('Xanax', entry.xanax),
                _wizardChip('Work', entry.workload),
                _wizardChip('Clouds', entry.clouds),
                _wizardChip('Bubs', entry.bubs),
                _wizardChip('Energy', entry.energy),
              ],
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
