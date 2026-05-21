import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  String _name = '';
  String _phone = '';
  int _floor = 1;
  String _disabilityType = 'none';
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      // Mengambil real token FCM dari Firebase (Android/iOS saja)
      String fcmToken;
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
        fcmToken = 'mock-fcm-token-web-${DateTime.now().millisecondsSinceEpoch}';
      } else {
        try {
          fcmToken = await FirebaseMessaging.instance.getToken() ??
              'mock-fcm-token-${DateTime.now().millisecondsSinceEpoch}';
        } catch (_) {
          fcmToken = 'mock-fcm-token-${DateTime.now().millisecondsSinceEpoch}';
        }
      }

      final result = await _apiService.registerUser(
        name: _name,
        phone: _phone,
        floor: _floor,
        disabilityType: _disabilityType,
        fcmToken: fcmToken,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        int userId = result['data']['id'];
        
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', userId);
        await prefs.setString('user_name', _name);
        await prefs.setString('admin_status', 'pending');

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
            backgroundColor: const Color(0xFFDC1010), // Menggunakan Warna Accent (#DC1010) untuk error gawat
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Memasukkan palet warna yang konsisten
    const Color primaryColorHex = Color(0xFF282E58); // Navy utama
    const Color accentColorHex = Color(0xFFDC1010);  // Merah bel alarm

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC), // Warna background (#FCFCFC)
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Bel Alarm disesuaikan warnanya ke Accent Red sesuai mockup desain awal
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
                        color: accentColorHex, // S-A-F-E Merah
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'ALERT',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryColorHex, // A-L-E-R-T Navy
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
                    color: primaryColorHex.withOpacity(0.7), // Navy transparan lembut
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 0, // Dibuat flat/minimalis sesuai gaya modern mockup
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
                            'Registrasi Pengguna',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColorHex, // Judul form menggunakan Navy utama
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Nama Lengkap',
                              prefixIcon: Icon(Icons.person_outline, color: primaryColorHex),
                            ),
                            style: const TextStyle(color: primaryColorHex),
                            validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                            onSaved: (val) => _name = val!,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Nomor HP',
                              prefixIcon: Icon(Icons.phone_outlined, color: primaryColorHex),
                            ),
                            style: const TextStyle(color: primaryColorHex),
                            keyboardType: TextInputType.phone,
                            validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                            onSaved: (val) => _phone = val!,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Lantai Anda Bekerja',
                              prefixIcon: Icon(Icons.business_outlined, color: primaryColorHex),
                            ),
                            style: const TextStyle(color: primaryColorHex),
                            keyboardType: TextInputType.number,
                            initialValue: '1',
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Wajib diisi';
                              if (int.tryParse(val) == null) return 'Harus berupa angka';
                              return null;
                            },
                            onSaved: (val) => _floor = int.parse(val!),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Jenis Disabilitas (Bantuan Khusus)',
                              prefixIcon: Icon(Icons.accessible_forward, color: primaryColorHex),
                            ),
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: primaryColorHex, fontSize: 16),
                            initialValue: _disabilityType,
                            items: const [
                              DropdownMenuItem(value: 'none', child: Text('Tidak Ada')),
                              DropdownMenuItem(value: 'deaf', child: Text('Tuli / Tunarungu')),
                              DropdownMenuItem(value: 'blind', child: Text('Buta / Tunanetra')),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _disabilityType = val!;
                              });
                            },
                            onSaved: (val) => _disabilityType = val!,
                          ),
                          const SizedBox(height: 32),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColorHex)))
                              : ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColorHex, // Tombol warna utama Navy (#282E58)
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Daftar Sekarang',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
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