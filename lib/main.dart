import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Note: Firebase initialization will fail without google-services.json
  // For now, I'll wrap it in a try-catch or comment it out for the UI build
  try {
    // await Firebase.initializeApp();
  } catch (e) {
    print("Firebase initialization error: $e");
  }
  
  runApp(const CelRonApp());
}

class CelRonApp extends StatelessWidget {
  const CelRonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CEL-RON Condition Monitoring',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003366), // Professional Dark Blue
          primary: const Color(0xFF003366),
          secondary: const Color(0xFFCC0000), // Red from logo
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003366),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
