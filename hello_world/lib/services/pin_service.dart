import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Result of a rate-limited PIN verification attempt.
class PinVerifyResult {
  final bool success;
  final bool isLocked;
  final int remainingSeconds;

  const PinVerifyResult({
    required this.success,
    required this.isLocked,
    required this.remainingSeconds,
  });
}

/// Manages a fallback app-level PIN for devices without biometrics.
/// Stores a salted SHA-256 hash — never stores the plaintext PIN.
/// Includes brute-force protection with escalating lockouts.
class PinService {
  static const _pinHashKey = 'app_pin_hash';
  static const _pinSaltKey = 'app_pin_salt';
  static const _failedCountKey = 'pin_failed_count';
  static const _lockoutUntilKey = 'pin_lockout_until';
  final FlutterSecureStorage _storage;

  PinService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ─── PIN CRUD ───

  /// Check if a PIN has been set.
  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Set a new PIN (stores salted SHA-256 hash).
  Future<void> setPin(String pin) async {
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinHashKey, value: hash);
  }

  /// Verify a PIN against the stored hash.
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _pinHashKey);
    final storedSalt = await _storage.read(key: _pinSaltKey);
    if (storedHash == null || storedSalt == null) return false;
    final hash = _hashPin(pin, storedSalt);
    return hash == storedHash;
  }

  /// Clear the stored PIN.
  Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  // ─── Brute-Force Protection ───

  /// Get the current failed attempt count.
  Future<int> getFailedCount() async {
    final val = await _storage.read(key: _failedCountKey);
    if (val == null || val.isEmpty) return 0;
    return int.tryParse(val) ?? 0;
  }

  /// Increment the failed attempt counter and persist it.
  Future<int> incrementFailedCount() async {
    final current = await getFailedCount();
    final next = current + 1;
    await _storage.write(key: _failedCountKey, value: next.toString());
    return next;
  }

  /// Get the lockout-until timestamp, or null if not locked out.
  Future<DateTime?> getLockoutUntil() async {
    final val = await _storage.read(key: _lockoutUntilKey);
    if (val == null || val.isEmpty) return null;
    return DateTime.tryParse(val);
  }

  /// Set the lockout-until timestamp.
  Future<void> setLockoutUntil(DateTime until) async {
    await _storage.write(key: _lockoutUntilKey, value: until.toIso8601String());
  }

  /// Reset failed attempts and clear lockout.
  Future<void> resetFailedAttempts() async {
    await _storage.delete(key: _failedCountKey);
    await _storage.delete(key: _lockoutUntilKey);
  }

  // ─── Rate-Limited Verification ───

  /// Verify a PIN with escalating lockout protection.
  ///
  /// Lockout schedule:
  /// - 1-3 failures: no lockout
  /// - 4-5 failures: 2 second lockout
  /// - 6-9 failures: 30 second lockout
  /// - 10+ failures: 300 second (5 min) lockout, then counter resets
  Future<PinVerifyResult> verifyPinWithRateLimit(String pin) async {
    // Check if currently locked out
    final lockoutUntil = await getLockoutUntil();
    if (lockoutUntil != null) {
      final remaining = lockoutUntil.difference(DateTime.now()).inSeconds;
      if (remaining > 0) {
        return PinVerifyResult(
          success: false,
          isLocked: true,
          remainingSeconds: remaining,
        );
      }
      // Lockout expired — clear it but keep the counter
      await _storage.delete(key: _lockoutUntilKey);
    }

    // Verify the PIN
    final valid = await verifyPin(pin);
    if (valid) {
      await resetFailedAttempts();
      return const PinVerifyResult(
        success: true,
        isLocked: false,
        remainingSeconds: 0,
      );
    }

    // PIN was wrong — increment and apply lockout
    final count = await incrementFailedCount();
    int lockoutSeconds = 0;

    if (count >= 10) {
      lockoutSeconds = 300;
      // Reset counter after max lockout so next cycle starts fresh
      await _storage.write(key: _failedCountKey, value: '0');
    } else if (count >= 6) {
      lockoutSeconds = 30;
    } else if (count >= 4) {
      lockoutSeconds = 2;
    }

    if (lockoutSeconds > 0) {
      await setLockoutUntil(
        DateTime.now().add(Duration(seconds: lockoutSeconds)),
      );
      return PinVerifyResult(
        success: false,
        isLocked: true,
        remainingSeconds: lockoutSeconds,
      );
    }

    return const PinVerifyResult(
      success: false,
      isLocked: false,
      remainingSeconds: 0,
    );
  }
}
