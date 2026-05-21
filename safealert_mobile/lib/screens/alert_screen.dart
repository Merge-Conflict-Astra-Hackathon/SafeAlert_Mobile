import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/alert_device_service.dart';
import '../services/api_service.dart';

class AlertScreen extends StatefulWidget {
  final int alarmId;
  final String message;

  const AlertScreen({super.key, required this.alarmId, required this.message});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AlertDeviceService _alertDeviceService = AlertDeviceService();
  bool _isLoading = false;
  bool _isConfirmed = false;
  bool _isAlertModeActive = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _activateAlertMode();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _restoreAlertMode();
    super.dispose();
  }

  Future<void> _activateAlertMode() async {
    _isAlertModeActive = true;
    await _alertDeviceService.activateAlertMode();
  }

  Future<void> _restoreAlertMode() async {
    if (!_isAlertModeActive) return;
    _isAlertModeActive = false;
    await _alertDeviceService.restoreAlertMode();
  }

  Future<void> _submitStatus(String status) async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User ID tidak ditemukan.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final result = await _apiService.sendConfirmation(
      alarmId: widget.alarmId,
      userId: userId,
      status: status,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      await _restoreAlertMode();
      setState(() {
        _isConfirmed = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status berhasil dikirim. Tetap tenang!')),
      );
      
      // Kembali ke dashboard setelah beberapa detik
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } else {
      if (result['message'] != null && result['message'].toString().contains('sudah memberikan konfirmasi')) {
         await _restoreAlertMode();
         setState(() { _isConfirmed = true; });
         if (!mounted) return;
         Navigator.pop(context);
      } else {
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  Widget _buildStatusButton(String title, String status, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        height: 70,
        child: ElevatedButton(
          onPressed: _isLoading || _isConfirmed ? null : () => _submitStatus(status),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB71C1C), // Deep Red Background
      appBar: AppBar(
        title: const Text('PERINGATAN DARURAT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_animationController.value * 0.1),
                    child: const Icon(Icons.warning_rounded, size: 100, color: Colors.white),
                  );
                },
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        'INSTRUKSI EVAKUASI',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB71C1C),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'LAPORKAN STATUS ANDA:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading) 
                const Center(child: CircularProgressIndicator(color: Colors.white)),
              if (!_isLoading && !_isConfirmed) ...[
                _buildStatusButton('SAYA AMAN', 'safe', Colors.green.shade700, Icons.check_circle_outline),
                _buildStatusButton('EVAKUASI', 'evacuating', Colors.orange.shade800, Icons.directions_run_rounded),
                _buildStatusButton('TERJEBAK', 'trapped', Colors.black, Icons.error_outline),
              ],
              if (_isConfirmed)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 64),
                      const SizedBox(height: 12),
                      const Text(
                        'Status berhasil dilaporkan.\nHarap tetap tenang dan ikuti instruksi petugas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
