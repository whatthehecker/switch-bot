import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:switch_bot_frontend/screens/login_screen.dart';

void _configureLogger() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

void main() {
  _configureLogger();

  runApp(const SwitchBotApp());
}

class SwitchBotApp extends StatelessWidget {
  const SwitchBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Switch Bot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.orange,
          accentColor: Colors.orangeAccent,
        ),
      ),
      home: const LoginScreen(
        autoConnect: true,
      ),
    );
  }
}
