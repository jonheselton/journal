import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications and schedule daily reminder
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.scheduleDailyNoonReminder();

  runApp(const NoteApp());
}

class NoteApp extends StatelessWidget {
  const NoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.highContrastDark(),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthScreen(),
    );
  }
}
