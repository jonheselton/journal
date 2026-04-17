import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/day_entry.dart';

/// Manages persistent encrypted storage of DayEntry objects.
/// Each entry is stored as a separate key: "day_YYYY-MM-DD".
class StorageService {
  static const _keyPrefix = 'day_';
  final FlutterSecureStorage _storage;

  StorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  String _keyFor(String dateKey) => '$_keyPrefix$dateKey';

  /// Save or update a day entry.
  Future<void> saveDayEntry(DayEntry entry) async {
    final json = jsonEncode(entry.toJson());
    await _storage.write(key: _keyFor(entry.dateKey), value: json);
  }

  /// Load a single day entry by date key (e.g. "2026-03-23").
  Future<DayEntry?> loadDayEntry(String dateKey) async {
    final json = await _storage.read(key: _keyFor(dateKey));
    if (json == null) return null;
    return DayEntry.fromJson(jsonDecode(json));
  }

  /// Load all day entries, sorted newest first.
  Future<List<DayEntry>> loadAllEntries() async {
    final allKeys = await _storage.readAll();
    final entries = <DayEntry>[];
    for (final entry in allKeys.entries) {
      if (entry.key.startsWith(_keyPrefix) && entry.value.isNotEmpty) {
        try {
          entries.add(DayEntry.fromJson(jsonDecode(entry.value)));
        } catch (_) {
          // Skip corrupt entries
        }
      }
    }
    entries.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return entries;
  }

  /// Delete a day entry.
  Future<void> deleteDayEntry(String dateKey) async {
    await _storage.delete(key: _keyFor(dateKey));
  }

  /// Check if an entry exists for a given date.
  Future<bool> hasEntry(String dateKey) async {
    final value = await _storage.read(key: _keyFor(dateKey));
    return value != null;
  }

  /// Clear all old-format data (the "notes" key from the previous version).
  Future<void> clearLegacyData() async {
    await _storage.delete(key: 'notes');
  }
}
