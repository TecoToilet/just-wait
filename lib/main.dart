import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/gate_screen.dart';
import 'screens/home_screen.dart';
import 'screens/session_screen.dart';
import 'services/accessibility_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0D0D),
  ));
  runApp(const JustWaitApp());
}

class JustWaitApp extends StatelessWidget {
  const JustWaitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Just Wait',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          background: Color(0xFF0D0D0D),
          surface: Color(0xFF161616),
          primary: Color(0xFFAAAAAA),
        ),
        fontFamily: 'monospace',
      ),
      // Route: if launched by accessibility service with intercepted app
      // pass the package name as argument to go straight to gate
      onGenerateRoute: (settings) {
        if (settings.name == '/gate') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => GateScreen(
              interceptedPackage: args?['package'] ?? '',
              appName: args?['appName'] ?? 'App',
            ),
          );
        }
        if (settings.name == '/session') {
          final args = settings.arguments as Map<String, dynamic>?;
          final halfTime = args?['halfTime'] as bool? ?? false;
          return MaterialPageRoute(
            builder: (_) => FutureBuilder<int>(
              future: StorageService.getSessionMinutes(),
              builder: (_, snap) {
                final mins = snap.data ?? 5;
                final totalSecs = halfTime ? ((mins * 60) ~/ 2) : (mins * 60);
                return SessionScreen(
                  package: args?['package'] ?? '',
                  appName: args?['appName'] ?? 'App',
                  halfTime: halfTime,
                  totalSeconds: totalSecs,
                );
              },
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      },
      initialRoute: '/',
    );
  }
}
