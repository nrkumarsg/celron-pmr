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
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  // Initialize Supabase with credentials from .env
  final supabaseUrl = dotenv.env['VITE_SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['VITE_SUPABASE_ANON_KEY'] ?? '';

  assert(supabaseUrl.isNotEmpty, 'VITE_SUPABASE_URL is missing from .env');
  assert(supabaseKey.isNotEmpty, 'VITE_SUPABASE_ANON_KEY is missing from .env');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
