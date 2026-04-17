import 'dart:convert';
import 'package:health/health.dart';
import 'package:flutter/material.dart';

/// Health metrics fetched from Health Connect for a single day.
class DayHealthMetrics {
  final int? steps;
  final double? avgHeartRate;
  final int? sleepMinutes;
  final String? sleepStages; // JSON-encoded map of stage -> minutes

  DayHealthMetrics({
    this.steps,
    this.avgHeartRate,
    this.sleepMinutes,
    this.sleepStages,
  });
}

/// Wraps the `health` package to fetch daily metrics from Health Connect.
class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  bool _isConfigured = false;
  bool _hasPermissions = false;

  /// Health data types we need to read.
  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_SESSION,
  ];

  /// Configure the health plugin. Call once at app startup.
  Future<void> configure() async {
    if (_isConfigured) return;
    await Health().configure();
    _isConfigured = true;
  }

  /// Request permissions for reading health data.
  /// Returns true if permissions were granted.
  Future<bool> requestPermissions() async {
    try {
      await configure();
      final permissions = _types.map((_) => HealthDataAccess.READ).toList();
      _hasPermissions = await Health().requestAuthorization(
        _types,
        permissions: permissions,
      );
      return _hasPermissions;
    } catch (e) {
      debugPrint('HealthService: Permission request failed: $e');
      return false;
    }
  }

  /// Check if Health Connect is available on this device.
  Future<bool> isAvailable() async {
    try {
      await configure();
      final status = await Health().getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (e) {
      debugPrint('HealthService: Availability check failed: $e');
      return false;
    }
  }

  /// Fetch health metrics for a specific date (midnight-to-midnight local).
  /// Returns null values for any metric that fails or is unavailable.
  Future<DayHealthMetrics> fetchDayMetrics(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    int? steps;
    double? avgHeartRate;
    int? sleepMinutes;
    String? sleepStages;

    try {
      await configure();

      if (!_hasPermissions) {
        await requestPermissions();
      }

      if (!_hasPermissions) {
        return DayHealthMetrics();
      }

      // Fetch steps
      steps = await _fetchSteps(start, end);

      // Fetch heart rate
      avgHeartRate = await _fetchAvgHeartRate(start, end);

      // Fetch sleep
      final sleepData = await _fetchSleep(start, end);
      sleepMinutes = sleepData['minutes'] as int?;
      sleepStages = sleepData['stages'] as String?;
    } catch (e) {
      debugPrint('HealthService: fetchDayMetrics error: $e');
    }

    return DayHealthMetrics(
      steps: steps,
      avgHeartRate: avgHeartRate,
      sleepMinutes: sleepMinutes,
      sleepStages: sleepStages,
    );
  }

  Future<int?> _fetchSteps(DateTime start, DateTime end) async {
    try {
      final stepsTotal = await Health().getTotalStepsInInterval(start, end);
      return stepsTotal;
    } catch (e) {
      debugPrint('HealthService: Steps fetch failed: $e');
      return null;
    }
  }

  Future<double?> _fetchAvgHeartRate(DateTime start, DateTime end) async {
    try {
      final data = await Health().getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );
      if (data.isEmpty) return null;

      double sum = 0;
      int count = 0;
      for (final point in data) {
        final value = point.value;
        if (value is NumericHealthValue) {
          sum += value.numericValue.toDouble();
          count++;
        }
      }
      return count > 0 ? (sum / count) : null;
    } catch (e) {
      debugPrint('HealthService: Heart rate fetch failed: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _fetchSleep(
      DateTime start, DateTime end) async {
    try {
      final data = await Health().getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_SESSION],
        startTime: start,
        endTime: end,
      );
      if (data.isEmpty) return {};

      int totalMinutes = 0;
      final stageMap = <String, int>{};

      for (final point in data) {
        final duration = point.dateTo.difference(point.dateFrom).inMinutes;
        totalMinutes += duration;

        // Extract sleep stage info if available
        final value = point.value;
        String stage = 'UNKNOWN';
        if (value is NumericHealthValue) {
          stage = 'SLEEP';
        }
        stageMap[stage] = (stageMap[stage] ?? 0) + duration;
      }

      return {
        'minutes': totalMinutes,
        'stages': jsonEncode(stageMap),
      };
    } catch (e) {
      debugPrint('HealthService: Sleep fetch failed: $e');
      return {};
    }
  }
}
