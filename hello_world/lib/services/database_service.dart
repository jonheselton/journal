import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/day_entry.dart';
import '../models/metric.dart';
import '../models/tag.dart';

/// Encrypted SQLite database service using SQLCipher.
/// Key is stored in Android Keystore via flutter_secure_storage.
class DatabaseService {
  static const _dbName = 'daily_journal.db';
  static const _dbVersion = 1;
  static const _encKeyStorageKey = 'db_encryption_key';
  static const _migrationDoneKey = 'db_migration_done';

  static DatabaseService? _instance;
  static Database? _database;
  final FlutterSecureStorage _secureStorage;

  DatabaseService._internal({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  factory DatabaseService({FlutterSecureStorage? secureStorage}) {
    _instance ??= DatabaseService._internal(secureStorage: secureStorage);
    return _instance!;
  }

  /// Get or create the encrypted database.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Generate a cryptographically secure 256-bit key.
  String _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Retrieve or create the encryption key.
  Future<String> _getOrCreateKey() async {
    String? key = await _secureStorage.read(key: _encKeyStorageKey);
    if (key == null || key.isEmpty) {
      key = _generateKey();
      await _secureStorage.write(key: _encKeyStorageKey, value: key);
    }
    return key;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    final key = await _getOrCreateKey();

    return await openDatabase(
      path,
      password: key,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE day_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date_key TEXT NOT NULL UNIQUE,
        timezone_offset TEXT NOT NULL DEFAULT '',
        mood INTEGER NOT NULL DEFAULT 5,
        sleep INTEGER NOT NULL DEFAULT 5,
        xanax TEXT NOT NULL DEFAULT '< 0.5',
        workload INTEGER NOT NULL DEFAULT 5,
        clouds INTEGER NOT NULL DEFAULT 0,
        bubs INTEGER NOT NULL DEFAULT 5,
        energy INTEGER NOT NULL DEFAULT 5,
        steps INTEGER,
        avg_heart_rate REAL,
        sleep_minutes INTEGER,
        sleep_stages TEXT,
        content TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE metrics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        icon_index INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE day_metrics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day_entry_id INTEGER NOT NULL,
        metric_id INTEGER NOT NULL,
        value INTEGER NOT NULL DEFAULT 5,
        FOREIGN KEY (day_entry_id) REFERENCES day_entries(id) ON DELETE CASCADE,
        FOREIGN KEY (metric_id) REFERENCES metrics(id) ON DELETE CASCADE,
        UNIQUE(day_entry_id, metric_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE day_entry_tags (
        day_entry_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (day_entry_id, tag_id),
        FOREIGN KEY (day_entry_id) REFERENCES day_entries(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    // Seed default metrics: Air, Earth, Wind, Fire
    final defaults = [
      {'key': 'air', 'name': 'Air', 'icon_index': 0},
      {'key': 'earth', 'name': 'Earth', 'icon_index': 1},
      {'key': 'wind', 'name': 'Wind', 'icon_index': 2},
      {'key': 'fire', 'name': 'Fire', 'icon_index': 3},
    ];
    for (final m in defaults) {
      await db.insert('metrics', m);
    }
  }

  // ─────────────────────────────────────────
  // DayEntry CRUD
  // ─────────────────────────────────────────

  /// Insert or update a DayEntry. Returns the database row id.
  Future<int> saveDayEntry(DayEntry entry) async {
    final db = await database;
    final map = entry.toDatabaseMap();

    // Check if exists
    final existing = await db.query(
      'day_entries',
      where: 'date_key = ?',
      whereArgs: [entry.dateKey],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'day_entries',
        map,
        where: 'date_key = ?',
        whereArgs: [entry.dateKey],
      );
      return existing.first['id'] as int;
    } else {
      return await db.insert('day_entries', map);
    }
  }

  /// Load a single DayEntry by dateKey.
  Future<DayEntry?> loadDayEntry(String dateKey) async {
    final db = await database;
    final results = await db.query(
      'day_entries',
      where: 'date_key = ?',
      whereArgs: [dateKey],
    );
    if (results.isEmpty) return null;
    return DayEntry.fromDatabaseMap(results.first);
  }

  /// Load all DayEntries, sorted newest first.
  Future<List<DayEntry>> loadAllEntries() async {
    final db = await database;
    final results = await db.query(
      'day_entries',
      orderBy: 'date_key DESC',
    );
    return results.map((m) => DayEntry.fromDatabaseMap(m)).toList();
  }

  /// Delete a DayEntry by dateKey.
  Future<void> deleteDayEntry(String dateKey) async {
    final db = await database;
    await db.delete(
      'day_entries',
      where: 'date_key = ?',
      whereArgs: [dateKey],
    );
  }

  /// Get the database row id for a dateKey.
  Future<int?> getDayEntryId(String dateKey) async {
    final db = await database;
    final results = await db.query(
      'day_entries',
      columns: ['id'],
      where: 'date_key = ?',
      whereArgs: [dateKey],
    );
    if (results.isEmpty) return null;
    return results.first['id'] as int;
  }

  // ─────────────────────────────────────────
  // Metrics CRUD
  // ─────────────────────────────────────────

  /// Get all defined metrics.
  Future<List<Metric>> getAllMetrics() async {
    final db = await database;
    final results = await db.query('metrics', orderBy: 'id ASC');
    return results.map((m) => Metric.fromMap(m)).toList();
  }

  // ─────────────────────────────────────────
  // DayMetrics CRUD
  // ─────────────────────────────────────────

  /// Save metric values for a day entry.
  Future<void> saveDayMetrics(int dayEntryId, Map<int, int> metricValues) async {
    final db = await database;
    final batch = db.batch();
    for (final entry in metricValues.entries) {
      batch.insert(
        'day_metrics',
        {
          'day_entry_id': dayEntryId,
          'metric_id': entry.key,
          'value': entry.value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Load metric values for a day entry.
  Future<Map<int, int>> loadDayMetrics(int dayEntryId) async {
    final db = await database;
    final results = await db.query(
      'day_metrics',
      where: 'day_entry_id = ?',
      whereArgs: [dayEntryId],
    );
    final map = <int, int>{};
    for (final row in results) {
      map[row['metric_id'] as int] = row['value'] as int;
    }
    return map;
  }

  // ─────────────────────────────────────────
  // Tags CRUD
  // ─────────────────────────────────────────

  /// Insert a tag if it doesn't exist, return its id.
  Future<int> getOrCreateTag(String text) async {
    final db = await database;
    final normalized = text.toLowerCase().trim();
    final existing = await db.query(
      'tags',
      where: 'text = ?',
      whereArgs: [normalized],
    );
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    return await db.insert('tags', {'text': normalized});
  }

  /// Associate tags with a day entry.
  Future<void> saveDayEntryTags(int dayEntryId, List<String> tagTexts) async {
    final db = await database;

    // Remove old tag associations
    await db.delete(
      'day_entry_tags',
      where: 'day_entry_id = ?',
      whereArgs: [dayEntryId],
    );

    // Insert new ones
    for (final text in tagTexts) {
      final tagId = await getOrCreateTag(text);
      await db.insert(
        'day_entry_tags',
        {'day_entry_id': dayEntryId, 'tag_id': tagId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  /// Load tags for a day entry.
  Future<List<Tag>> loadDayEntryTags(int dayEntryId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT t.id, t.text
      FROM tags t
      INNER JOIN day_entry_tags det ON t.id = det.tag_id
      WHERE det.day_entry_id = ?
      ORDER BY t.text ASC
    ''', [dayEntryId]);
    return results.map((m) => Tag.fromMap(m)).toList();
  }

  // ─────────────────────────────────────────
  // Statistics Queries
  // ─────────────────────────────────────────

  /// Get average values for each custom metric across all entries.
  Future<Map<String, double>> getMetricAverages() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT m.name, AVG(dm.value) as avg_value
      FROM day_metrics dm
      INNER JOIN metrics m ON dm.metric_id = m.id
      GROUP BY m.id, m.name
      ORDER BY m.id ASC
    ''');
    final map = <String, double>{};
    for (final row in results) {
      map[row['name'] as String] = (row['avg_value'] as num).toDouble();
    }
    return map;
  }

  /// Get average wizard metrics (mood, sleep, energy, etc.) across all entries.
  Future<Map<String, double>> getWizardAverages() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT
        AVG(mood) as avg_mood,
        AVG(sleep) as avg_sleep,
        AVG(workload) as avg_workload,
        AVG(clouds) as avg_clouds,
        AVG(bubs) as avg_bubs,
        AVG(energy) as avg_energy
      FROM day_entries
    ''');
    if (results.isEmpty) return {};
    final row = results.first;
    return {
      'Mood': (row['avg_mood'] as num?)?.toDouble() ?? 0,
      'Sleep': (row['avg_sleep'] as num?)?.toDouble() ?? 0,
      'Workload': (row['avg_workload'] as num?)?.toDouble() ?? 0,
      'Clouds': (row['avg_clouds'] as num?)?.toDouble() ?? 0,
      'Bubs': (row['avg_bubs'] as num?)?.toDouble() ?? 0,
      'Energy': (row['avg_energy'] as num?)?.toDouble() ?? 0,
    };
  }

  /// Get top N most-used tags across all entries.
  Future<List<Map<String, dynamic>>> getTopTags({int limit = 20}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.text, COUNT(det.day_entry_id) as count
      FROM tags t
      INNER JOIN day_entry_tags det ON t.id = det.tag_id
      GROUP BY t.id, t.text
      ORDER BY count DESC
      LIMIT ?
    ''', [limit]);
  }

  /// Get entry count.
  Future<int> getEntryCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM day_entries');
    return result.first['c'] as int;
  }

  // ─────────────────────────────────────────
  // Migration from flutter_secure_storage
  // ─────────────────────────────────────────

  /// Check if migration from old storage has been done.
  Future<bool> isMigrationDone() async {
    final done = await _secureStorage.read(key: _migrationDoneKey);
    return done == 'true';
  }

  /// Mark migration as complete.
  Future<void> markMigrationDone() async {
    await _secureStorage.write(key: _migrationDoneKey, value: 'true');
  }

  /// Migrate entries from the old StorageService (flutter_secure_storage)
  /// into the new encrypted database. Call once after first DB init.
  Future<int> migrateFromSecureStorage() async {
    if (await isMigrationDone()) return 0;

    final allKeys = await _secureStorage.readAll();
    int migrated = 0;

    for (final entry in allKeys.entries) {
      if (entry.key.startsWith('day_') && entry.value.isNotEmpty) {
        try {
          final decoded = jsonDecode(entry.value) as Map<String, dynamic>;
          final dayEntry = DayEntry.fromJson(decoded);
          // Check if already in DB
          final existing = await loadDayEntry(dayEntry.dateKey);
          if (existing == null) {
            await saveDayEntry(dayEntry);
            migrated++;
          }
        } catch (e) {
          debugPrint('Migration skip for ${entry.key}: $e');
        }
      }
    }

    await markMigrationDone();
    debugPrint('DatabaseService: Migrated $migrated entries from secure storage');
    return migrated;
  }

  /// Close the database.
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
