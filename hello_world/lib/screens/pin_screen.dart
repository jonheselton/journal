import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pin_service.dart';

/// PIN entry and setup screen. Used as fallback when biometrics are unavailable.
class PinScreen extends StatefulWidget {
  /// If true, this is the first-time setup flow (set + confirm PIN).
  /// If false, this is the unlock flow (enter existing PIN).
  final bool isSetup;

  const PinScreen({super.key, required this.isSetup});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _pinService = PinService();
  String _pin = '';
  String? _firstPin; // used during setup for confirmation
  String _message = '';
  bool _isConfirming = false;
  bool _isLockedOut = false;
  int _lockoutRemaining = 0;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _message = widget.isSetup ? 'Create a PIN' : 'Enter your PIN';
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _startLockoutCountdown(int seconds) {
    setState(() {
      _isLockedOut = true;
      _lockoutRemaining = seconds;
      _pin = '';
      _message = 'Locked out. Try again in ${_lockoutRemaining}s';
    });

    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _lockoutRemaining--;
        if (_lockoutRemaining <= 0) {
          _isLockedOut = false;
          _lockoutRemaining = 0;
          _message = 'Enter your PIN';
          timer.cancel();
        } else {
          _message = 'Locked out. Try again in ${_lockoutRemaining}s';
        }
      });
    });
  }

  void _onDigit(String digit) {
    if (_isLockedOut) return;
    if (_pin.length >= 6) return;
    setState(() => _pin += digit);
    if (_pin.length == 4) {
      _onPinComplete();
    }
  }

  void _onBackspace() {
    if (_isLockedOut) return;
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onPinComplete() async {
    if (widget.isSetup) {
      if (!_isConfirming) {
        // First entry
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _isConfirming = true;
          _message = 'Confirm your PIN';
        });
      } else {
        // Confirming
        if (_pin == _firstPin) {
          await _pinService.setPin(_pin);
          if (mounted) Navigator.pop(context, true);
        } else {
          setState(() {
            _pin = '';
            _firstPin = null;
            _isConfirming = false;
            _message = 'PINs didn\'t match. Try again.';
          });
          HapticFeedback.heavyImpact();
        }
      }
    } else {
      // Unlock flow — use rate-limited verification
      final result = await _pinService.verifyPinWithRateLimit(_pin);
      if (result.success) {
        if (mounted) Navigator.pop(context, true);
      } else if (result.isLocked) {
        _startLockoutCountdown(result.remainingSeconds);
        HapticFeedback.heavyImpact();
      } else {
        setState(() {
          _pin = '';
          _message = 'Wrong PIN. Try again.';
        });
        HapticFeedback.heavyImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isLockedOut ? Icons.lock : Icons.lock_outline,
              size: 48,
              color: _isLockedOut ? Colors.redAccent : Colors.cyanAccent,
            ),
            const SizedBox(height: 24),
            Text(
              _message,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: _isLockedOut ? Colors.redAccent : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length
                        ? Colors.cyanAccent
                        : Colors.grey.shade800,
                    border: Border.all(color: Colors.grey.shade600),
                  ),
                );
              }),
            ),
            const SizedBox(height: 48),
            // Number pad
            _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        _buildRow(['4', '5', '6']),
        _buildRow(['7', '8', '9']),
        _buildRow(['', '0', '⌫']),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: keys.map((key) {
          if (key.isEmpty) {
            return const SizedBox(width: 80, height: 64);
          }
          final isDisabled = _isLockedOut;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Material(
              color: isDisabled ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.grey.shade900,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: isDisabled
                    ? null
                    : (key == '⌫' ? _onBackspace : () => _onDigit(key)),
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 72,
                  height: 64,
                  child: Center(
                    child: key == '⌫'
                        ? Icon(
                            Icons.backspace_outlined,
                            size: 24,
                            color: isDisabled ? Colors.grey.shade700 : null,
                          )
                        : Text(
                            key,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: isDisabled ? Colors.grey.shade700 : null,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
