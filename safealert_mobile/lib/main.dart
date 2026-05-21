import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase hanya tersedia pada platform Android/iOS dengan konfigurasi native.
  // Pada web/Windows (untuk demo), inisialisasi dilewati agar app tetap bisa berjalan.
  if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Firebase init gagal (misal: google-services.json tidak ada/cocok).
      // App tetap berjalan dalam mode tanpa FCM (mock mode).
      debugPrint('[Firebase] Init failed, running without FCM: $e');
    }
  }
  
  // Cek apakah user sudah login/register sebelumnya
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? userId = prefs.getInt('user_id');

  runApp(SafeAlertApp(initialRoute: userId == null ? '/register' : '/dashboard'));
}

class SafeAlertApp extends StatelessWidget {
  final String initialRoute;

  const SafeAlertApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    // Definisi hex color baru sesuai request
    const Color primaryColorHex = Color(0xFF282E58);
    const Color secondaryColorHex = Color(0xFFBED0E5);
    const Color accentColorHex = Color(0xFFDC1010);
    const Color backgroundColorHex = Color(0xFFFCFCFC);

    return MaterialApp(
      title: 'SafeAlert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: backgroundColorHex,
        primaryColor: primaryColorHex,
        
        // Pengaturan skema warna global aplikasi
        colorScheme: const ColorScheme.light(
          primary: primaryColorHex,
          secondary: secondaryColorHex,
          surface: backgroundColorHex,
          error: accentColorHex,
        ),
        
        // Menyesuaikan AppBar dengan warna background utama (#FCFCFC) dan teks gelap (#282E58)
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColorHex,
          foregroundColor: primaryColorHex, 
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: primaryColorHex),
          titleTextStyle: TextStyle(
            color: primaryColorHex,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Kontras teks default disesuaikan ke warna utama (Navy) agar konsisten dengan mockup
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: primaryColorHex, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Color(0xFF333333)),
          bodyMedium: TextStyle(color: Color(0xFF666666)),
        ),
        
        // Mengubah warna tombol utama menjadi Warna Utama (#282E58) sesuai desain registrasi
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColorHex, 
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            elevation: 2,
          ),
        ),
        
        // Pengaturan desain Input Form (Text Field)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColorHex, width: 2), // Garis fokus navy
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}