import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';

import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // 🔔 Notifications
  await NotificationService.init();

  // 🔥 Background service
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  Workmanager().registerPeriodicTask(
    "1",
    taskName,
    frequency: const Duration(hours: 24),
  );

  runApp(const LifeAdminApp());
}

class LifeAdminApp extends StatefulWidget {
  const LifeAdminApp({super.key});

  @override
  State<LifeAdminApp> createState() => _LifeAdminAppState();
}

class _LifeAdminAppState extends State<LifeAdminApp> {

  bool isDark = false;

  void toggleTheme() {
    setState(() {
      isDark = !isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Life Admin',

      // 🌞 LIGHT THEME (IMPROVED)
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF6C63FF),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        cardColor: Colors.white,
        useMaterial3: true,
      ),

      // 🌙 DARK THEME (IMPROVED)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
      ),

      // 🌙 SWITCH
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

      // 🚀 START APP
      home: SplashScreen(toggleTheme: toggleTheme),
    );
  }
}