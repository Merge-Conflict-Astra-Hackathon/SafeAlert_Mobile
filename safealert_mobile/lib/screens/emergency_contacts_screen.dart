import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  final int alarmId;
  final String message;
  final String initialStatus;

  const EmergencyContactsScreen({
    super.key,
    required this.alarmId,
    required this.message,
    this.initialStatus = 'no_response',
  });

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final ApiService _apiService = ApiService();
  bool _isSubmitting = false;
  String _currentStatus = 'Belum ada status';
  String _currentStatusKey = 'no_response';

  @override
  void initState() {
    super.initState();
    _currentStatusKey = _normalizeStatus(widget.initialStatus);
    _currentStatus = _statusLabel(_currentStatusKey);
  }

  Future<void> _changeStatus(String status) async {
    if (status == 'trapped') {
      await _submitTrappedReport();
      return;
    }

    await _submitStatus(status);
  }

  Future<void> _submitStatus(
    String status, {
    String location = '',
    String notes = '',
  }) async {
    setState(() {
      _isSubmitting = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID tidak ditemukan. Silakan login ulang.'),
        ),
      );
      return;
    }

    final result = await _apiService.sendConfirmation(
      alarmId: widget.alarmId,
      userId: userId,
      status: status,
      location: location,
      notes: notes,
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      if (result['success']) {
        _currentStatusKey = _normalizeStatus(status);
        _currentStatus = _statusLabel(_currentStatusKey);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success']
              ? 'Status berhasil diperbarui.'
              : result['message'] ?? 'Gagal memperbarui status.',
        ),
        backgroundColor: result['success']
            ? Colors.green.shade700
            : Colors.red.shade700,
      ),
    );
  }

  String _normalizeStatus(String status) {
    return status == 'evacuating' ? 'needs_help' : status;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'safe':
        return 'Saya Aman';
      case 'needs_help':
      case 'evacuating':
        return 'Sedang Evakuasi';
      case 'trapped':
        return 'Terjebak';
      default:
        return 'Belum ada status';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'safe':
        return Colors.green.shade700;
      case 'needs_help':
      case 'evacuating':
        return Colors.orange.shade800;
      case 'trapped':
        return Colors.black;
      default:
        return const Color(0xFF282E58);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'safe':
        return Icons.check_circle_rounded;
      case 'needs_help':
      case 'evacuating':
        return Icons.directions_run_rounded;
      case 'trapped':
        return Icons.error_rounded;
      default:
        return Icons.pending_actions_rounded;
    }
  }

  Widget _buildCurrentStatusCard() {
    final color = _statusColor(_currentStatusKey);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(_currentStatusKey), color: color, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Saya',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _currentStatus,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTrappedReport() async {
    final locationController = TextEditingController();
    final notesController = TextEditingController();

    final report = await showModalBottomSheet<_EmergencyReport>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Beri tahu lokasi kamu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB71C1C),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi kamu sekarang',
                  hintText: 'Contoh: Lantai 7, dekat tangga A',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Keterangan tambahan',
                  hintText: 'Contoh: pintu terkunci, asap tebal',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  final location = locationController.text.trim();
                  if (location.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lokasi wajib diisi.')),
                    );
                    return;
                  }

                  Navigator.pop(
                    context,
                    _EmergencyReport(
                      location: location,
                      notes: notesController.text.trim(),
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('Kirim Status Terjebak'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        );
      },
    );

    locationController.dispose();
    notesController.dispose();

    if (report == null) return;

    await _submitStatus(
      'trapped',
      location: report.location,
      notes: report.notes,
    );
  }

  Widget _buildEmergencyNumber({
    required String title,
    required String number,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  number,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.phone_forwarded_rounded, color: Color(0xFF282E58)),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
    String title,
    String status,
    Color color,
    IconData icon,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : () => _changeStatus(status),
        icon: Icon(icon, size: 22),
        label: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildEvacuationMapPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.map_rounded, color: Color(0xFF282E58)),
              SizedBox(width: 8),
              Text(
                'Denah Evakuasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF282E58),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 54,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 10),
                Text(
                  'Foto denah belum tersedia',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nanti area ini bisa diisi gambar denah lantai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF282E58);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCurrentStatusCard(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      size: 44,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tetap Pantau Instruksi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildEmergencyNumber(
                title: 'Pemadam Kebakaran',
                number: '113',
                icon: Icons.local_fire_department_rounded,
                color: Colors.red.shade700,
              ),
              const SizedBox(height: 12),
              _buildEmergencyNumber(
                title: 'Polisi',
                number: '110',
                icon: Icons.local_police_rounded,
                color: Colors.blue.shade700,
              ),
              const SizedBox(height: 12),
              _buildEmergencyNumber(
                title: 'Ambulans / Medis',
                number: '118 / 119',
                icon: Icons.medical_services_rounded,
                color: Colors.green.shade700,
              ),
              const SizedBox(height: 24),
              _buildEvacuationMapPlaceholder(),
              const SizedBox(height: 28),
              const Text(
                'Ubah Status Saya',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              if (_isSubmitting)
                const Center(
                  child: CircularProgressIndicator(color: primaryColor),
                ),
              if (!_isSubmitting)
                Column(
                  children: [
                    _buildStatusButton(
                      'Aman',
                      'safe',
                      Colors.green.shade700,
                      Icons.check_circle_outline,
                    ),
                    const SizedBox(height: 10),
                    _buildStatusButton(
                      'Evakuasi',
                      'evacuating',
                      Colors.orange.shade800,
                      Icons.directions_run_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildStatusButton(
                      'Terjebak',
                      'trapped',
                      Colors.black,
                      Icons.error_outline,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyReport {
  final String location;
  final String notes;

  const _EmergencyReport({required this.location, required this.notes});
}
