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
  String _buildingName = '';
  String _floorPlanUrl = '';

  @override
  void initState() {
    super.initState();
    _currentStatusKey = _normalizeStatus(widget.initialStatus);
    _currentStatus = _statusLabel(_currentStatusKey);
    _loadFloorPlan();
  }

  Future<void> _loadFloorPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final buildingId = int.tryParse(prefs.getString('building_id') ?? '');
    final buildingName = prefs.getString('building_name') ?? '';

    if (mounted && buildingName.isNotEmpty) {
      setState(() {
        _buildingName = buildingName;
      });
    }

    if (buildingId == null) return;

    final buildings = await _apiService.getBuildings();
    final building = buildings.cast<Map<String, dynamic>?>().firstWhere(
      (item) => item?['id'] == buildingId,
      orElse: () => null,
    );
    if (building == null || !mounted) return;

    setState(() {
      _buildingName = (building['name'] ?? _buildingName).toString();
      _floorPlanUrl = ApiService.resolveAssetUrl(
        (building['floor_plan'] ?? '').toString(),
      );
    });
  }

  void _openFloorPlanViewer() {
    if (_floorPlanUrl.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FloorPlanViewerScreen(
          imageUrl: _floorPlanUrl,
          buildingName: _buildingName.isEmpty ? 'Denah Gedung' : _buildingName,
        ),
      ),
    );
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
      backgroundColor: const Color(0xFFF5F0E8),
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
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: TextAlign.left,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            number,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 0.4,
            ),
          ),
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

  Widget _buildEvacuationMap() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
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
          if (_buildingName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _buildingName,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _floorPlanUrl.isEmpty
                ? Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F8),
                      border: Border.all(color: Colors.grey.shade300),
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
                      ],
                    ),
                  )
                : InkWell(
                    onTap: _openFloorPlanViewer,
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.network(
                        _floorPlanUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF282E58),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF2F4F8),
                            alignment: Alignment.center,
                            child: Text(
                              'Gagal memuat denah gedung.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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
      backgroundColor: const Color(0xFFF5F0E8),
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
                color: Colors.red.shade700,
              ),
              const SizedBox(height: 12),
              _buildEmergencyNumber(
                title: 'Polisi',
                number: '110',
                color: Colors.blue.shade700,
              ),
              const SizedBox(height: 12),
              _buildEmergencyNumber(
                title: 'Ambulans / Medis',
                number: '118 / 119',
                color: Colors.green.shade700,
              ),
              const SizedBox(height: 24),
              _buildEvacuationMap(),
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

class _FloorPlanViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String buildingName;

  const _FloorPlanViewerScreen({
    required this.imageUrl,
    required this.buildingName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          buildingName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Center(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const CircularProgressIndicator(color: Colors.white);
              },
              errorBuilder: (context, error, stackTrace) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Gagal memuat denah gedung.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
