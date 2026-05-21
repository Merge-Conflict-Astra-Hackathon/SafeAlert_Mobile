import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  String _phone = '';
  String _password = ''; // Variabel baru untuk menampung password
  bool _obscurePassword = true; // State untuk toggle lihat/sembunyikan password
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      // Mengambil real token FCM dari Firebase untuk login device baru
      String fcmToken;
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
        fcmToken = '';
      } else {
        try {
          fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
        } catch (e) {
          debugPrint('[Firebase] FCM token unavailable: $e');
          fcmToken = '';
        }
      }

      // Memanggil fungsi login pada ApiService dengan parameter password tambahan
      final result = await _apiService.loginUser(
        phone: _phone,
        password: _password, // Mengirim password ke API
        fcmToken: fcmToken,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        int userId = result['data']['id'];
        String name = result['data']['name'] ?? 'Pengguna';

        // Simpan sesi login baru ke lokal SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', userId);
        await prefs.setString('user_name', name);
        await prefs.setString('admin_status', result['data']['admin_status'] ?? 'pending');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: const Color(0xFFDC1010), // Warna Accent Merah
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColorHex = Color(0xFF282E58); // Navy utama
    const Color accentColorHex = Color(0xFFDC1010);  // Merah aksen

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  size: 80,
                  color: accentColorHex,
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SAFE',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: accentColorHex,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'ALERT',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryColorHex,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Sistem Evakuasi Darurat Inklusif',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: primaryColorHex.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 0,
                  color: const Color(0xFFF5F0E8),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Masuk Aplikasi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColorHex,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Nomor HP Terdaftar',
                              prefixIcon: Icon(Icons.phone_outlined, color: primaryColorHex),
                            ),
                            style: const TextStyle(color: primaryColorHex),
                            keyboardType: TextInputType.phone,
                            validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                            onSaved: (val) => _phone = val!,
                          ),
                          const SizedBox(height: 16),
                          // 👇 INPUT TEXTFORMFIELD PASSWORD BARU 👇
                          TextFormField(
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Kata Sandi (Password)',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryColorHex),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: primaryColorHex.withValues(alpha: 0.6),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            style: const TextStyle(color: primaryColorHex),
                            validator: (val) => val == null || val.isEmpty ? 'Password wajib diisi' : null,
                            onSaved: (val) => _password = val!,
                          ),
                          const SizedBox(height: 32),
                          _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(primaryColorHex),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColorHex,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Masuk',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Belum punya akun? ',
                                style: TextStyle(color: primaryColorHex.withValues(alpha: 0.6)),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                  );
                                },
                                child: const Text(
                                  'Daftar di sini',
                                  style: TextStyle(
                                    color: primaryColorHex,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
