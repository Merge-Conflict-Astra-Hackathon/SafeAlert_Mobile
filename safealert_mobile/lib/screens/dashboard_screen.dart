import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alert_screen.dart'; 
import 'register_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _userName = '';
  String _adminStatus = 'safe'; // Default ke 'safe' sesuai kebutuhan tampilan foto kedua
  String _userFloor = '7';      // Data dummy tambahan untuk pelengkap info lokasi user
  Timer? _pollingTimer;

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
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      _adminStatus = prefs.getString('admin_status') ?? 'safe';
      _userFloor = prefs.getString('user_floor') ?? '7'; 
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
    // Polling mock API
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

  @override
  Widget build(BuildContext context) {
    const Color primaryColorHex = Color(0xFF282E58);
    const Color secondaryColorHex = Color(0xFFBED0E5);
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
              
              // ─── TOMBOL EMERGENCY CALLS (TEKS 2 UKURAN BERBEDA) ───
              // Tombol Pemadam Kebakaran (Row 1)
              ElevatedButton(
                onPressed: null, // Placeholder semata
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(fireCallColor),
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 14)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hubungi 113',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Colors.white, 
                        fontSize: 28, // Ukuran nomor lebih besar & tebal
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '(Petugas Pemadam Kebakaran)',
                      style: TextStyle(
                        fontWeight: FontWeight.w500, 
                        color: Colors.white, 
                        fontSize: 14, // Ukuran deskripsi lebih kecil
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tombol Kepolisian (Row 2)
              ElevatedButton(
                onPressed: null, // Placeholder semata
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(policeCallColor),
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 14)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hubungi 110',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Colors.white, 
                        fontSize: 28, // Ukuran nomor lebih besar & tebal
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '(Petugas Kepolisian)',
                      style: TextStyle(
                        fontWeight: FontWeight.w500, 
                        color: Colors.white, 
                        fontSize: 14, // Ukuran deskripsi lebih kecil
                      ),
                    ),
                  ],
                ),
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
      const Center(child: Text("Ini Halaman Profil Pengguna", style: TextStyle(fontSize: 18))),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50, 
      body: pages[_selectedIndex],
      
      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.white,
            selectedItemColor: primaryColorHex,
            unselectedItemColor: secondaryColorHex,
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
      ),
    );
  }
}