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
  String _userName = '';
  String _adminStatus = 'pending';
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupFirebaseMessaging();
    
    // Simulate polling for MVP / Hackathon
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
      _adminStatus = prefs.getString('admin_status') ?? 'pending';
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
    // Di aplikasi produksi, bagian ini digantikan oleh listener FCM
    // Untuk hackathon, panggil API untuk mengecek alarm aktif
  }

  void _simulateIncomingAlarm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertScreen(
          alarmId: 1, // Mock alarm ID
          message: 'SIMULASI: EVAKUASI SEKARANG! Kebakaran di lantai Anda.',
        ),
      ),
    );
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isVerified = _adminStatus != 'pending';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting Banner
            Text(
              'Halo, $_userName',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              'Tetap aman dan selalu waspada.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            
            // Status Card
            Card(
              elevation: 4,
              shadowColor: isVerified ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: isVerified 
                      ? [Colors.green.shade50, Colors.white]
                      : [Colors.orange.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isVerified ? Colors.green.shade200 : Colors.orange.shade200,
                    width: 1.5,
                  )
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      isVerified ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
                      size: 64,
                      color: isVerified ? Colors.green[700] : Colors.orange[700],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isVerified ? 'Status Terverifikasi' : 'Menunggu Verifikasi Admin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isVerified ? Colors.green[900] : Colors.orange[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isVerified 
                        ? 'Aplikasi aktif memantau notifikasi darurat. Pastikan koneksi internet Anda stabil.'
                        : 'Pendaftaran Anda sedang ditinjau. Anda akan mendapatkan notifikasi setelah disetujui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Dev Tool / Hackathon Demo Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
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
    );
  }
}
