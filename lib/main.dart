import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/landing_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/knowledge_base_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase with hardcoded credentials for local deployment stability
  const String supabaseUrl = 'https://dfoihdzpgkrtyerzzchm.supabase.co';
  const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmb2loZHpwZ2tydHllcnp6Y2htIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1NzMxMTgsImV4cCI6MjA4NzE0OTExOH0.9FGN21KeUpS0UyyFJJ1YjXLElL4AF6ym_hKAJsr_ek4';

  print('Starting Supabase Initialization...');
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
      debug: true,
    );
    print('Supabase Initialized successfully.');
  } catch (e) {
    print('CRITICAL: Supabase Initialization Failed: $e');
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load environment variables for AI features
  try {
    await dotenv.load(fileName: "assets/.env");
    print('DotEnv loaded successfully.');
  } catch (e) {
    print('DotEnv loading failed (continuing without AI keys): $e');
  }

  // Initialize Dependency Injection
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CelRon Preventive Maintenance',
      debugShowCheckedModeBanner: false,
      theme: RuggedTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/knowledge': (context) => KnowledgeBaseScreen(),
      },
    );
  }
}
