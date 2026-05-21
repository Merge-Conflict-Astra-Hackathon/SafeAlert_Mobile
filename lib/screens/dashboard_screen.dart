import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'alert_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool firebaseReady;

  const DashboardScreen({super.key, this.firebaseReady = true});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _userName = '';
  String _userFloor = '7';
  String _adminStatus = 'pending';
  String _buildingName = '';
  String _floorPlanUrl = '';
  Timer? _pollingTimer;
  final ApiService _apiService = ApiService();
  final TextEditingController _floorController = TextEditingController();
  bool _isShowingAlert = false;
  bool _isSavingFloor = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    if (widget.firebaseReady) {
      _setupFirebaseMessaging();
    }

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _refreshUserProfile();
      await _checkAlarm();
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
    final buildingIdText = prefs.getString('building_id') ?? '';
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      _userFloor = prefs.getString('user_floor') ?? '7';
      _adminStatus = prefs.getString('admin_status') ?? 'pending';
      _buildingName = prefs.getString('building_name') ?? '';
      _floorController.text = _userFloor;
    });
    await _loadFloorPlan(buildingIdText);
    await _refreshUserProfile();
  }

  Future<void> _refreshUserProfile() async {
    final data = await _apiService.refreshCurrentUser();
    if (data == null || !mounted) return;

    final floorPlan = ApiService.resolveAssetUrl(
      (data['floor_plan'] ?? '').toString(),
    );
    final buildingIdText = (data['building_id'] ?? '').toString();
    setState(() {
      _userName = (data['name'] ?? _userName).toString();
      _userFloor = (data['floor'] ?? _userFloor).toString();
      _adminStatus = (data['admin_status'] ?? _adminStatus).toString();
      _buildingName = (data['building_name'] ?? _buildingName).toString();
      if (floorPlan.isNotEmpty) {
        _floorPlanUrl = floorPlan;
      }
      _floorController.text = _userFloor;
    });

    if (_floorPlanUrl.isEmpty) {
      await _loadFloorPlan(buildingIdText);
    }
  }

  Future<void> _loadFloorPlan(String buildingIdText) async {
    if (buildingIdText.isEmpty) return;

    final buildingId = int.tryParse(buildingIdText);
    if (buildingId == null) return;

    final buildings = await _apiService.getBuildings();
    final building = buildings.cast<Map<String, dynamic>?>().firstWhere(
      (item) => item?['id'] == buildingId,
      orElse: () => null,
    );
    if (building == null || !mounted) return;

    final floorPlan = (building['floor_plan'] ?? '').toString();
    setState(() {
      _buildingName = (building['name'] ?? _buildingName).toString();
      _floorPlanUrl = ApiService.resolveAssetUrl(floorPlan);
    });
  }

  void _openFloorPlanViewer() {
    if (_floorPlanUrl.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FloorPlanViewerScreen(
          imageUrl: _floorPlanUrl,
          buildingName: _buildingName.isEmpty ? 'Denah Gedung' : _buildingName,
        ),
      ),
    );
  }

  void _setupFirebaseMessaging() {
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        await _handleRemoteMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        await _handleRemoteMessage(message);
      });

      FirebaseMessaging.instance
          .getInitialMessage()
          .then((message) async {
            if (message != null) {
              await _handleRemoteMessage(message);
            }
          })
          .catchError((error) {
            debugPrint('[Firebase] Initial message failed: $error');
          });
    } catch (e) {
      debugPrint('[Firebase] Messaging listener failed: $e');
    }
  }

  Future<void> _handleRemoteMessage(RemoteMessage message) async {
    if (!mounted) return;

    if (message.data['type'] == 'emergency') {
      final alarmId = int.tryParse(message.data['alarm_id'] ?? '') ?? 1;
      final msg = message.data['message'] ?? 'EVAKUASI SEKARANG!';

      if (_isShowingAlert) return;
      _isShowingAlert = true;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlertScreen(alarmId: alarmId, message: msg),
        ),
      );
      _isShowingAlert = false;
    } else if (message.data['type'] == 'cancel') {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _checkAlarm() async {
    if (_adminStatus != 'active') return;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: const Color(0xFFDC1010),
        ),
      );
    }
  }

  Future<void> _logout() async {
    _pollingTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('admin_status');
    await prefs.remove('user_floor');
    await prefs.remove('building_id');
    await prefs.remove('building_name');
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColorHex = Color(0xFF282E58);
    const Color pageBg = Color(0xFFF6F3EE);
    const Color cardBg = Color(0xFFFFFEFC);
    const Color cardBorder = Color(0xFFE8E2D8);
    const Color safeGreen = Color(0xFF168447);
    const Color fireCallColor = Color(0xFFBA3525); // Warna tombol 113
    const Color policeCallColor = Color(0xFF2545BA); // Warna tombol 110
    const Color medicalCallColor = Color(0xFF20945B); // Warna tombol 118/119
    final bool isVerified = _adminStatus == 'active';
    final initials = _userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    Widget emergencyCallButton({
      required String title,
      required String subtitle,
      required Color color,
    }) {
      return Container(
        height: 57,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                title.replaceFirst('Hubungi ', ''),
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget sectionLabel(String text) {
      return Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      );
    }

    BoxDecoration softCardDecoration({double radius = 16}) {
      return BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      );
    }

    // 1. DAFTAR LAYOUT HALAMAN INTERNAL
    final List<Widget> pages = [
      // ==================== TAB 0: BERANDA (SESUAI MOCKUP FOTO KEDUA) ====================
      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 15, 8, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 0),

              // ─── CARD STATUS UTAMA (ANDA AMAN) ───
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 26,
                  horizontal: 16,
                ),
                decoration: softCardDecoration(),
                child: Column(
                  children: [
                    // Lingkaran Ikon Status Aman
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: isVerified
                            ? const Color(0xFFE7F8EE)
                            : const Color(0xFFFFF4DF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isVerified
                              ? const Color(0xFFAEEBC7)
                              : const Color(0xFFFFD48A),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isVerified
                            ? Icons.shield_outlined
                            : Icons.hourglass_top_rounded,
                        size: 29,
                        color: isVerified ? safeGreen : Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'STATUS ANDA',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isVerified ? 'Anda Aman' : 'Menunggu Verifikasi',
                      style: TextStyle(
                        fontSize: isVerified ? 20 : 18,
                        fontWeight: FontWeight.w800,
                        color: isVerified ? safeGreen : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ─── INFORMASI USER (RATA KIRI) ───
              Container(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
                decoration: softCardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionLabel('INFORMASI PENGGUNA'),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF0FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFC8D6FF)),
                          ),
                          child: Center(
                            child: Text(
                              initials.isEmpty ? 'U' : initials,
                              style: const TextStyle(
                                color: Color(0xFF3156C8),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: primaryColorHex,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Lantai $_userFloor',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isVerified
                            ? const Color(0xFFE9F8EF)
                            : const Color(0xFFFFF3DF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isVerified
                              ? const Color(0xFFB8E8C9)
                              : const Color(0xFFFFD89A),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isVerified
                                  ? const Color(0xFF2BBE6A)
                                  : const Color(0xFFE49B22),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            isVerified
                                ? 'Sistem Pemantauan Aktif'
                                : 'Menunggu Verifikasi Admin',
                            style: TextStyle(
                              color: isVerified
                                  ? const Color(0xFF147D45)
                                  : const Color(0xFF9A5A00),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              sectionLabel('KONTAK DARURAT'),
              const SizedBox(height: 12),

              // ─── TOMBOL EMERGENCY CALLS ───
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  emergencyCallButton(
                    title: 'Hubungi 113',
                    subtitle: 'Panggil Petugas Pemadam Kebakaran',
                    color: fireCallColor,
                  ),
                  const SizedBox(height: 10),
                  emergencyCallButton(
                    title: 'Hubungi 110',
                    subtitle: 'Panggil Polisi',
                    color: policeCallColor,
                  ),
                  const SizedBox(height: 10),
                  emergencyCallButton(
                    title: 'Hubungi 118/119',
                    subtitle: 'Panggil Ambulans / Medis',
                    color: medicalCallColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Denah Evakuasi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColorHex,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _buildingName.isEmpty
                    ? 'Denah mengikuti gedung yang terhubung dengan akun Anda.'
                    : 'Gedung: $_buildingName',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0E8),
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
                clipBehavior: Clip.antiAlias,
                child: _floorPlanUrl.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 36,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 72,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Denah gedung belum tersedia',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColorHex,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Admin dapat menambahkan image denah dari dashboard web pada menu Gedung.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : InkWell(
                        onTap: _openFloorPlanViewer,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Image.network(
                                _floorPlanUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: primaryColorHex,
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.broken_image_outlined,
                                            size: 56,
                                            color: Color(0xFFDC1010),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Gagal memuat denah gedung.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.fullscreen_rounded,
                                    color: primaryColorHex,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ketuk denah untuk layar penuh',
                                    style: TextStyle(
                                      color: primaryColorHex,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
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
                  color: const Color(0xFFF5F0E8),
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
                        prefixIcon: Icon(
                          Icons.business_outlined,
                          color: primaryColorHex,
                        ),
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
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC1010),
                  side: const BorderSide(color: Color(0xFFDC1010)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: pageBg,
      // appBar dihapus sepenuhnya agar bagian atas bersih tanpa teks & tombol logout
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
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: cardBg,
            selectedItemColor: const Color(0xFF3156C8),
            unselectedItemColor: Colors.grey.shade400,
            type: BottomNavigationBarType.fixed,
            enableFeedback: false,
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

class FloorPlanViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String buildingName;

  const FloorPlanViewerScreen({
    super.key,
    required this.imageUrl,
    required this.buildingName,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColorHex = Color(0xFF282E58);

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
                return const CircularProgressIndicator(color: primaryColorHex);
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
