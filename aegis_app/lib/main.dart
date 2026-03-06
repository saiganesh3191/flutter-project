import 'package:flutter/material.dart';
import 'local_database.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local database (Hive)
  await LocalDatabase.initialize();
  
  runApp(const AegisAIApp());
}

class AegisAIApp extends StatelessWidget {
  const AegisAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AegisAI',
      theme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
