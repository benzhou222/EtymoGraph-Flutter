import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'services/tts_service.dart';
import 'dart:ui';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize TTS early so it's ready when UI starts
  await TTSService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const EtymoGraphApp(),
    ),
  );
}

class EtymoGraphApp extends StatelessWidget {
  const EtymoGraphApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode =
        context.select<AppProvider, ThemeMode>((p) => p.themeMode);

    return MaterialApp(
      title: 'EtymoGraph',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue, brightness: Brightness.light),
        cardTheme: const CardTheme(surfaceTintColor: Colors.white),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF0f172a), // Match web dark mode
      ),
      home: const HomeScreen(),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse, // 允许鼠标拖拽
        PointerDeviceKind.trackpad,
      };
}
