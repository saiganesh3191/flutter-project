import 'package:flutter/material.dart';
import 'local_database.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/client_home_screen.dart';

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
      home: const InitialScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _isLoading = true;
  Widget? _nextScreen;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final role = LocalDatabase.getUserRole();
    final userPhone = LocalDatabase.getUserPhone();
    
    if (role == null || userPhone == null) {
      // Not logged in - show login screen
      setState(() {
        _nextScreen = const LoginScreen();
        _isLoading = false;
      });
    } else if (role == 'admin') {
      // Admin - check if has contacts
      final contacts = LocalDatabase.getContacts();
      setState(() {
        _nextScreen = contacts.isEmpty ? const OnboardingScreen() : const HomeScreen();
        _isLoading = false;
      });
    } else {
      // Contact - go to client home
      setState(() {
        _nextScreen = const ClientHomeScreen();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red.shade400, Colors.red.shade700],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'lib/assets/app logo.jpeg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      );
    }

    return _nextScreen!;
  }
}
