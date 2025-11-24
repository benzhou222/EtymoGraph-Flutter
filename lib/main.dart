import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';

void main() {
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
