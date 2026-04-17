import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/health_service.dart';
import '../services/pin_service.dart';
import 'day_list_screen.dart';
import 'pin_screen.dart';

/// Root screen that handles authentication (biometric + PIN fallback)
/// and re-locks the app when it returns from background.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  final PinService _pinService = PinService();
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;
  String _authMessage = 'Authenticating...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authenticate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-lock when app is resumed from background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isAuthenticated) {
      setState(() {
        _isAuthenticated = false;
        _authMessage = 'Please authenticate again.';
      });
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    try {
      setState(() {
        _isAuthenticating = true;
        _authMessage = 'Authenticating...';
      });

      final bool canAuthenticateWithBiometrics =
          await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        // No biometrics — fall back to app PIN
        await _handlePinFallback();
        return;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to access your journal',
      );

      if (!mounted) return;

      setState(() {
        _isAuthenticated = authenticated;
        _isAuthenticating = false;
        if (!authenticated) {
          _authMessage = 'Authentication failed or canceled.';
        }
      });

      if (authenticated) {
        _onAuthenticated();
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('noCredentialsSet')) {
        // Device has no credentials set — fall back to app PIN
        await _handlePinFallback();
      } else {
        setState(() {
          _isAuthenticating = false;
          _authMessage = 'Error: $e';
        });
      }
    }
  }

  /// Handle PIN-based authentication when biometrics are unavailable.
  Future<void> _handlePinFallback() async {
    final hasPin = await _pinService.hasPin();

    if (!mounted) return;

    if (!hasPin) {
      // First time — set up a PIN
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const PinScreen(isSetup: true),
        ),
      );

      if (!mounted) return;

      if (result == true) {
        setState(() {
          _isAuthenticated = true;
          _isAuthenticating = false;
        });
        _onAuthenticated();
      } else {
        setState(() {
          _isAuthenticating = false;
          _authMessage = 'A PIN is required to secure your journal.';
        });
      }
    } else {
      // Verify existing PIN
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const PinScreen(isSetup: false),
        ),
      );

      if (!mounted) return;

      if (result == true) {
        setState(() {
          _isAuthenticated = true;
          _isAuthenticating = false;
        });
        _onAuthenticated();
      } else {
        setState(() {
          _isAuthenticating = false;
          _authMessage = 'Authentication required.';
        });
      }
    }
  }

  /// Called after successful authentication — request Health Connect
  /// permissions once so subsequent screens can fetch data.
  Future<void> _onAuthenticated() async {
    try {
      final healthService = HealthService();
      final available = await healthService.isAvailable();
      if (available) {
        await healthService.requestPermissions();
      }
    } catch (_) {
      // Non-fatal — health data will just show "--"
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return const DayListScreen();
    }
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            Text(
              _authMessage,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (!_isAuthenticating)
              ElevatedButton.icon(
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock Journal'),
                onPressed: _authenticate,
              ),
          ],
        ),
      ),
    );
  }
}
