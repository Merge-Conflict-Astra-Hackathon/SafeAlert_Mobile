import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/alert_device_service.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'emergency_contacts_screen.dart';

class AlertScreen extends StatefulWidget {
  final int alarmId;
  final String message;

  const AlertScreen({super.key, required this.alarmId, required this.message});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AlertDeviceService _alertDeviceService = AlertDeviceService();
  bool _isLoading = false;
  bool _isConfirmed = false;
  bool _isAlertModeActive = false;
  Timer? _alarmStatusTimer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _activateAlertMode();
    _alarmStatusTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _closeIfAlarmInactive();
    });
  }

  @override
  void dispose() {
    _alarmStatusTimer?.cancel();
    _animationController.dispose();
    _restoreAlertMode();
    super.dispose();
  }

  Future<void> _closeIfAlarmInactive() async {
    final isActive = await _apiService.isAlarmActive(widget.alarmId);
    if (isActive || !mounted) return;

    _alarmStatusTimer?.cancel();
    await _restoreAlertMode();
    await _apiService.resetAlarmSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
      (route) => false,
    );
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

  Future<void> _handleStatusTap(String status) async {
    if (status == 'trapped') {
      await _showTrappedInputSheet();
      return;
    }

    final instruction = status == 'safe'
        ? 'Your Safe Now, Listen For Further Instruction'
        : 'Keep aware to your surrounding';

    await _submitStatus(status, successMessage: instruction);
  }

  Future<void> _submitStatus(
    String status, {
    String location = '',
    String notes = '',
    String? successMessage,
  }) async {
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
      location: location,
      notes: notes,
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
      await _showInstructionDialog(
        successMessage ?? 'Status berhasil dikirim. Tetap tenang!',
      );
      _goToEmergencyContacts(status);
    } else {
      if (result['message'] != null && result['message'].toString().contains('sudah memberikan konfirmasi')) {
         await _restoreAlertMode();
         setState(() { _isConfirmed = true; });
         if (!mounted) return;
         _goToEmergencyContacts(status);
      } else {
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  void _goToEmergencyContacts(String status) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyContactsScreen(
          alarmId: widget.alarmId,
          message: widget.message,
          initialStatus: status,
        ),
      ),
    );
  }

  Future<void> _showInstructionDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Status Terkirim'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTrappedInputSheet() async {
    await _showInstructionDialog('Beri tahu lokasi kamu');
    if (!mounted) return;

    final locationController = TextEditingController();
    final notesController = TextEditingController();

    final result = await Navigator.push<_TrappedReport>(
      context,
      MaterialPageRoute(
        builder: (context) => _TrappedInputScreen(
          locationController: locationController,
          notesController: notesController,
        ),
      ),
    );

    locationController.dispose();
    notesController.dispose();

    if (result == null) return;

    await _submitStatus(
      'trapped',
      location: result.location,
      notes: result.notes,
      successMessage: 'Laporan lokasi kamu sudah dikirim ke admin.',
    );
  }

  Widget _buildStatusButton(String title, String status, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        height: 70,
        child: ElevatedButton(
          onPressed: _isLoading || _isConfirmed ? null : () => _handleStatusTap(status),
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
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final backgroundColor = Color.lerp(
          Colors.white,
          const Color(0xFFB71C1C),
          _animationController.value,
        )!;
        final foregroundColor = _animationController.value > 0.45
            ? Colors.white
            : const Color(0xFFB71C1C);

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text(
              'PERINGATAN DARURAT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: foregroundColor,
              ),
            ),
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
                    child: Icon(
                      Icons.warning_rounded,
                      size: 100,
                      color: foregroundColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: const Color(0xFFF5F0E8),
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
              Text(
                'LAPORKAN STATUS ANDA:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: foregroundColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading) 
                Center(child: CircularProgressIndicator(color: foregroundColor)),
              if (!_isLoading && !_isConfirmed) ...[
                _buildStatusButton('SAYA AMAN', 'safe', Colors.green.shade700, Icons.check_circle_outline),
                _buildStatusButton('EVAKUASI', 'evacuating', Colors.orange.shade800, Icons.directions_run_rounded),
                _buildStatusButton('TERJEBAK', 'trapped', Colors.black, Icons.error_outline),
              ],
              if (_isConfirmed)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0E8).withValues(alpha: 0.9),
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
      },
    );
  }
}

class _TrappedReport {
  final String location;
  final String notes;

  const _TrappedReport({
    required this.location,
    required this.notes,
  });
}

class _TrappedInputScreen extends StatelessWidget {
  final TextEditingController locationController;
  final TextEditingController notesController;

  const _TrappedInputScreen({
    required this.locationController,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF282E58);
    const dangerColor = Color(0xFFB71C1C);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: const Text('Laporkan Lokasi'),
        backgroundColor: dangerColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.location_on_rounded, size: 56, color: dangerColor),
                    SizedBox(height: 12),
                    Text(
                      'Beri tahu lokasi kamu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: dangerColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Informasi ini akan masuk ke dashboard admin agar petugas bisa melihat keterangan setiap user.',
                      textAlign: TextAlign.center,
                      style: TextStyle(height: 1.4, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi kamu sekarang',
                  hintText: 'Contoh: Lantai 7, dekat tangga darurat A',
                  prefixIcon: Icon(Icons.place_outlined, color: primaryColor),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan tambahan',
                  hintText: 'Contoh: asap tebal, pintu terkunci, butuh bantuan kursi roda',
                  prefixIcon: Icon(Icons.notes_outlined, color: primaryColor),
                  alignLabelWithHint: true,
                ),
                minLines: 4,
                maxLines: 6,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final location = locationController.text.trim();
                  final notes = notesController.text.trim();

                  if (location.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lokasi wajib diisi agar admin bisa membantu.'),
                        backgroundColor: dangerColor,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(
                    context,
                    _TrappedReport(location: location, notes: notes),
                  );
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('Kirim ke Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dangerColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
