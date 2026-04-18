import 'package:flutter/material.dart';
import '../services/pin_service.dart';
import '../services/notification_service.dart';
import 'pin_screen.dart';

/// Tab 3: Settings — app configuration, security, notifications, data, about.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _pinService = PinService();
  final _notificationService = NotificationService();

  bool _hasPin = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final hasPin = await _pinService.hasPin();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
    });
  }

  // ──────────────────────────────────────────
  // Actions
  // ──────────────────────────────────────────

  Future<void> _changePin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const PinScreen(isSetup: true),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN updated successfully')),
      );
      _loadSettings();
    }
  }

  Future<void> _resetPin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset PIN'),
        content: const Text(
            'This will remove your current PIN. You will need to set a new one on next launch.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Reset', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _pinService.clearPin();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN has been reset')),
      );
      _loadSettings();
    }
  }

  void _toggleNotifications(bool value) {
    setState(() => _notificationsEnabled = value);
    if (value) {
      _notificationService.scheduleDailyNoonReminder();
    } else {
      _notificationService.cancelAll();
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Journal'),
        content: const Text(
            'Journal export to Markdown/PDF is coming in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Daily Journal',
        applicationVersion: '1.0.0',
        applicationIcon: const Icon(
          Icons.book,
          size: 48,
          color: Colors.cyanAccent,
        ),
        children: [
          const SizedBox(height: 16),
          const Text(
            'A private, offline-first health journal with encrypted storage.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Security ──
          _buildSectionHeader('Security'),
          _buildListTile(
            icon: Icons.lock_outline,
            iconColor: Colors.cyanAccent,
            title: _hasPin ? 'Change PIN' : 'Set Up PIN',
            subtitle: _hasPin ? 'Update your app PIN' : 'Secure your journal',
            onTap: _changePin,
          ),
          if (_hasPin)
            _buildListTile(
              icon: Icons.lock_reset,
              iconColor: Colors.redAccent,
              title: 'Reset PIN',
              subtitle: 'Remove current PIN',
              onTap: _resetPin,
            ),
          const Divider(height: 32, indent: 16, endIndent: 16),

          // ── Notifications ──
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            secondary: Icon(
              Icons.notifications_outlined,
              color: Colors.orangeAccent,
            ),
            title: const Text('Daily Reminder'),
            subtitle: const Text('Remind me at noon to journal'),
            value: _notificationsEnabled,
            activeThumbColor: Colors.cyanAccent,
            onChanged: _toggleNotifications,
          ),
          const Divider(height: 32, indent: 16, endIndent: 16),

          // ── Data ──
          _buildSectionHeader('Data'),
          _buildListTile(
            icon: Icons.file_download_outlined,
            iconColor: Colors.greenAccent,
            title: 'Export Journal',
            subtitle: 'Export entries to Markdown or PDF',
            onTap: _showExportDialog,
          ),
          _buildListTile(
            icon: Icons.backup_outlined,
            iconColor: Colors.amberAccent,
            title: 'Backup Database',
            subtitle: 'Create an encrypted backup',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Database backup coming in a future update')),
              );
            },
          ),
          const Divider(height: 32, indent: 16, endIndent: 16),

          // ── About ──
          _buildSectionHeader('About'),
          _buildListTile(
            icon: Icons.info_outline,
            iconColor: Colors.grey.shade400,
            title: 'About Daily Journal',
            subtitle: 'Version, privacy, and more',
            onTap: _showAboutDialog,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade600),
      onTap: onTap,
    );
  }
}
