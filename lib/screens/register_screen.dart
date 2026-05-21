import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart'; 

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
  String _password = ''; // Variabel baru untuk menampung password register
  int? _buildingId;
  int _floor = 1;
  String _disabilityType = 'none';
  bool _obscurePassword = true; // State toggle pengingat password aman
  bool _isLoading = false;
  bool _isLoadingBuildings = true;
  List<Map<String, dynamic>> _buildings = [];

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    final buildings = await _apiService.getBuildings();
    if (!mounted) return;
    setState(() {
      _buildings = buildings;
      _buildingId = buildings.isNotEmpty ? buildings.first['id'] as int? : null;
      _isLoadingBuildings = false;
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_buildingId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih gedung terlebih dahulu.'),
            backgroundColor: Color(0xFFDC1010),
          ),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });

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

      final result = await _apiService.registerUser(
        name: _name,
        phone: _phone,
        password: _password,
        buildingId: _buildingId!,
        floor: _floor,
        disabilityType: _disabilityType,
        fcmToken: fcmToken,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ??
                  'Registrasi berhasil. Akun menunggu verifikasi admin.',
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: const Color(0xFFDC1010),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColorHex = Color(0xFF282E58); 
    const Color accentColorHex = Color(0xFFDC1010);  

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8), 
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/safealert-logo.png',
                  width: 96,
                  height: 112,
                  fit: BoxFit.contain,
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
                            'Registrasi Pengguna',
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
                              labelText: 'Nama Lengkap',
                              prefixIcon: Icon(Icons.person_outline, color: primaryColorHex),
                            ),
                            style: const TextStyle(color: primaryColorHex),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
                            onSaved: (val) => _name = val!.trim(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Nomor HP',
                              prefixIcon: Icon(Icons.phone_outlined, color: primaryColorHex),
                            ),
                            style: const TextStyle(color: primaryColorHex),
                            keyboardType: TextInputType.phone,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
                            onSaved: (val) => _phone = val!.trim(),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            key: ValueKey(_buildingId),
                            decoration: const InputDecoration(
                              labelText: 'Gedung',
                              prefixIcon: Icon(Icons.apartment_rounded, color: primaryColorHex),
                            ),
                            dropdownColor: const Color(0xFFF5F0E8),
                            style: const TextStyle(color: primaryColorHex, fontSize: 16),
                            initialValue: _buildingId,
                            items: _buildings
                                .map(
                                  (building) => DropdownMenuItem<int>(
                                    value: building['id'] as int,
                                    child: Text((building['name'] ?? 'Gedung').toString()),
                                  ),
                                )
                                .toList(),
                            validator: (val) => val == null ? 'Gedung wajib dipilih' : null,
                            onChanged: _isLoadingBuildings
                                ? null
                                : (val) {
                                    setState(() {
                                      _buildingId = val;
                                    });
                                  },
                            onSaved: (val) => _buildingId = val,
                          ),
                          if (!_isLoadingBuildings && _buildings.isEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Belum ada data gedung. Tambahkan gedung dari web admin dulu.',
                              style: TextStyle(color: accentColorHex, fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 16),
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
                            validator: (val) {
                              final password = val?.trim() ?? '';
                              if (password.isEmpty) return 'Password wajib diisi';
                              if (password.length < 6) return 'Password minimal 6 karakter';
                              return null;
                            },
                            onSaved: (val) => _password = val!.trim(),
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
                              final floor = val?.trim() ?? '';
                              if (floor.isEmpty) return 'Wajib diisi';
                              if (int.tryParse(floor) == null) return 'Harus berupa angka';
                              return null;
                            },
                            onSaved: (val) => _floor = int.parse(val!.trim()),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Jenis Disabilitas (Bantuan Khusus)',
                              prefixIcon: Icon(Icons.accessible_forward, color: primaryColorHex),
                            ),
                            dropdownColor: const Color(0xFFF5F0E8),
                            style: const TextStyle(color: primaryColorHex, fontSize: 16),
                            initialValue: _disabilityType,
                            items: const [
                              DropdownMenuItem(value: 'blind', child: Text('Tunanetra')),
                              DropdownMenuItem(value: 'deaf', child: Text('Tunarungu')),
                              DropdownMenuItem(value: 'none', child: Text('Tidak Ada')),
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
                                    backgroundColor: primaryColorHex, 
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
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sudah punya akun? ',
                                style: TextStyle(color: primaryColorHex.withValues(alpha: 0.6)),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  );
                                },
                                child: const Text(
                                  'Masuk di sini',
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
