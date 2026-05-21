import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'alert_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _userName = '';
  String _userFloor = '7';
  Timer? _pollingTimer;
  final ApiService _apiService = ApiService();
  final TextEditingController _floorController = TextEditingController();
  bool _isShowingAlert = false;
  bool _isSavingFloor = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupFirebaseMessaging();
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkAlarm();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _floorController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      _userFloor = prefs.getString('user_floor') ?? '7'; 
      _floorController.text = _userFloor;
    });
  }

  void _setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;
      if (message.data['type'] == 'emergency') {
        int alarmId = int.tryParse(message.data['alarm_id'] ?? '') ?? 1;
        String msg = message.data['message'] ?? 'EVAKUASI SEKARANG!';
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlertScreen(
              alarmId: alarmId,
              message: msg,
            ),
          ),
        );
      } else if (message.data['type'] == 'cancel') {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  Future<void> _checkAlarm() async {
    if (_isShowingAlert) return;

    final alarm = await _apiService.checkActiveAlarm();
    if (alarm == null || !mounted) return;

    _isShowingAlert = true;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertScreen(
          alarmId: alarm['id'] as int,
          message: alarm['message'] as String,
        ),
      ),
    );
    _isShowingAlert = false;
  }

  void _simulateIncomingAlarm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertScreen(
          alarmId: 1, 
          message: 'SIMULASI: EVAKUASI SEKARANG! Kebakaran di lantai Anda.',
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _updateFloor() async {
    final floor = int.tryParse(_floorController.text.trim());
    if (floor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor lantai harus berupa angka.')),
      );
      return;
    }

    setState(() {
      _isSavingFloor = true;
    });

    final result = await _apiService.updateFloor(floor: floor);

    if (!mounted) return;
    setState(() {
      _isSavingFloor = false;
    });

    if (result['success']) {
      setState(() {
        _userFloor = floor.toString();
        _floorController.text = _userFloor;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: const Color(0xFFDC1010),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColorHex = Color(0xFF282E58);
    const Color fireCallColor = Color(0xFFBA3525); // Warna tombol 113
    const Color policeCallColor = Color(0xFF2545BA); // Warna tombol 110

    // 1. DAFTAR LAYOUT HALAMAN INTERNAL
    final List<Widget> pages = [
      // ==================== TAB 0: BERANDA (SESUAI MOCKUP FOTO KEDUA) ====================
      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              
              // ─── CARD STATUS UTAMA (ANDA AMAN) ───
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Lingkaran Ikon Status Aman
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.shade100, width: 2),
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 80,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Status Anda:',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ANDA AMAN',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // ─── INFORMASI USER (RATA KIRI) ───
              const Text(
                'Informasi Pengguna',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Nama: $_userName',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColorHex,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Lokasi: Lantai $_userFloor',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.gpp_good_rounded, size: 18, color: Colors.green.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Sistem Pemantauan Aktif',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // ─── TOMBOL EMERGENCY CALLS ───
              Row(
                children: [
                  // Tombol Pemadam Kebakaran (113)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Tambahkan fungsi launchUrl('tel:113') nanti jika package url_launcher dipasang
                      },
                      icon: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 22),
                      label: const Text(
                        'Panggil 113\n(Pemadam)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: fireCallColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Tombol Kepolisian (110)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Tambahkan fungsi launchUrl('tel:110')
                      },
                      icon: const Icon(Icons.local_police_rounded, color: Colors.white, size: 22),
                      label: const Text(
                        'Panggil 110\n(Polisi)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: policeCallColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // ─── DEMO / HACKATHON TOOLS (DIPERTAHANKAN) ───
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.developer_mode, color: Colors.red[800], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Demo / Hackathon Tools',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[800]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _simulateIncomingAlarm,
                        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                        label: const Text('Simulasikan Menerima Alarm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      
      // ==================== TAB 1 & 2: SCREEN LAINNYA ====================
      const Center(child: Text("Ini Halaman Jalur Evakuasi", style: TextStyle(fontSize: 18))),
      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Profil Pengguna',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColorHex,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Data profil lain dikelola admin. Dari mobile, Anda hanya bisa memperbarui nomor lantai.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nama: $_userName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColorHex,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lantai saat ini: $_userFloor',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _floorController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nomor lantai',
                        prefixIcon: Icon(Icons.business_outlined, color: primaryColorHex),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isSavingFloor ? null : _updateFloor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColorHex,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSavingFloor
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Simpan Nomor Lantai',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Latar belakang abu-abu terang bersih mewah
      // appBar dihapus sepenuhnya agar bagian atas bersih tanpa teks & tombol logout
      body: pages[_selectedIndex],
      
      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: primaryColorHex,
          unselectedItemColor: Colors.grey.shade500,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_run_rounded), 
              label: 'Evakuasi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
