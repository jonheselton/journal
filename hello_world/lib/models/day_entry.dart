import 'package:flutter/material.dart';

class DayEntry {
  final int? id; // Database row id (null for new entries)
  final String dateKey; // "2026-03-23" (local date)
  final String timezoneOffset; // e.g. "-05:00"

  // Wizard fields (manual)
  final int mood;
  final int sleep; // subjective 1-10
  final String x; // '1' = 0, '2' = < 1, '3' = > 1
  final int workload;
  final int energy;

  // Health Connect fields (auto-fetched)
  final int? steps;
  final double? avgHeartRate;
  final int? sleepMinutes;
  final String? sleepStages; // JSON-encoded stage breakdown

  // Free-form note
  final String content; // markdown body

  final DateTime createdAt;
  final DateTime updatedAt;

  DayEntry({
    this.id,
    required this.dateKey,
    required this.timezoneOffset,
    required this.mood,
    required this.sleep,
    required this.x,
    required this.workload,
    required this.energy,
    this.steps,
    this.avgHeartRate,
    this.sleepMinutes,
    this.sleepStages,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  DayEntry copyWith({
    int? id,
    String? dateKey,
    String? timezoneOffset,
    int? mood,
    int? sleep,
    String? x,
    int? workload,
    int? energy,
    int? steps,
    double? avgHeartRate,
    int? sleepMinutes,
    String? sleepStages,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DayEntry(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      timezoneOffset: timezoneOffset ?? this.timezoneOffset,
      mood: mood ?? this.mood,
      sleep: sleep ?? this.sleep,
      x: x ?? this.x,
      workload: workload ?? this.workload,
      energy: energy ?? this.energy,
      steps: steps ?? this.steps,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      sleepStages: sleepStages ?? this.sleepStages,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── JSON serialization (legacy / flutter_secure_storage compat) ───

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'timezoneOffset': timezoneOffset,
        'mood': mood,
        'sleep': sleep,
        'x': x,
        'workload': workload,
        'energy': energy,
        'steps': steps,
        'avgHeartRate': avgHeartRate,
        'sleepMinutes': sleepMinutes,
        'sleepStages': sleepStages,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Legacy xanax value → new x value mapping.
  static String _mapLegacyXanax(String? legacy) {
    switch (legacy) {
      case '0.5 <= 1.0':
        return '2';
      case '1.0 <= 1.5':
        return '3';
      case '< 0.5':
      case 'None':
      case null:
      default:
        return '1';
    }
  }

  factory DayEntry.fromJson(Map<String, dynamic> json) {
    // Support both new 'x' key and legacy 'xanax' key
    String xValue;
    if (json.containsKey('x')) {
      xValue = json['x'] ?? '1';
    } else if (json.containsKey('xanax')) {
      xValue = _mapLegacyXanax(json['xanax'] as String?);
    } else {
      xValue = '1';
    }

    return DayEntry(
      dateKey: json['dateKey'],
      timezoneOffset: json['timezoneOffset'] ?? '',
      mood: json['mood'] ?? 5,
      sleep: json['sleep'] ?? 5,
      x: xValue,
      workload: json['workload'] ?? 5,
      energy: json['energy'] ?? 5,
      steps: json['steps'],
      avgHeartRate: json['avgHeartRate']?.toDouble(),
      sleepMinutes: json['sleepMinutes'],
      sleepStages: json['sleepStages'],
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // ─── Database serialization (SQLCipher) ───

  Map<String, dynamic> toDatabaseMap() => {
        'date_key': dateKey,
        'timezone_offset': timezoneOffset,
        'mood': mood,
        'sleep': sleep,
        'x': x,
        'workload': workload,
        'energy': energy,
        'steps': steps,
        'avg_heart_rate': avgHeartRate,
        'sleep_minutes': sleepMinutes,
        'sleep_stages': sleepStages,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory DayEntry.fromDatabaseMap(Map<String, dynamic> map) {
    // Support both new 'x' column and legacy 'xanax' column for migration compat
    String xValue;
    if (map.containsKey('x') && map['x'] != null) {
      xValue = map['x'] as String;
    } else if (map.containsKey('xanax') && map['xanax'] != null) {
      xValue = _mapLegacyXanax(map['xanax'] as String?);
    } else {
      xValue = '1';
    }

    return DayEntry(
      id: map['id'] as int?,
      dateKey: map['date_key'] as String,
      timezoneOffset: (map['timezone_offset'] as String?) ?? '',
      mood: (map['mood'] as int?) ?? 5,
      sleep: (map['sleep'] as int?) ?? 5,
      x: xValue,
      workload: (map['workload'] as int?) ?? 5,
      energy: (map['energy'] as int?) ?? 5,
      steps: map['steps'] as int?,
      avgHeartRate: (map['avg_heart_rate'] as num?)?.toDouble(),
      sleepMinutes: map['sleep_minutes'] as int?,
      sleepStages: map['sleep_stages'] as String?,
      content: (map['content'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // ─── Utilities ───

  /// Returns the local date for "today" as a YYYY-MM-DD key.
  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Returns the current timezone offset as a string like "-05:00".
  static String currentTimezoneOffset() {
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';
    return '$sign$hours:$minutes';
  }

  /// Returns midnight-to-midnight DateTime range for this entry's date in local time.
  DateTimeRange get dayRange {
    final parts = dateKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    final start = DateTime(year, month, day);
    final end = DateTime(year, month, day, 23, 59, 59);
    return DateTimeRange(start: start, end: end);
  }
}
