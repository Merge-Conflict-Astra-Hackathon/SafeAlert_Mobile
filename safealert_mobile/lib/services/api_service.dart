import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Gunakan 10.0.2.2 untuk Android Emulator
  // Gunakan 192.168.0.109 untuk HP fisik (IP lokal PC Anda di jaringan Wi-Fi yang sama)
  // Gunakan 127.0.0.1 untuk Web/Chrome
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8089/api';
    // Ganti ke 'http://192.168.0.109:8089/api' jika menggunakan HP fisik
    return 'http://10.0.2.2:8089/api';
  }

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String phone,
    required int floor,
    required String disabilityType,
    required String fcmToken,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'floor': floor,
        'disability_type': disabilityType,
        'fcm_token': fcmToken,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      final data = jsonDecode(response.body);
      return {'success': false, 'message': data['message'] ?? 'Terjadi kesalahan'};
    }
  }

  Future<Map<String, dynamic>> sendConfirmation({
    required int alarmId,
    required int userId,
    required String status,
  }) async {
    final url = Uri.parse('$baseUrl/confirm/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'alarm_id': alarmId,
        'user_id': userId,
        'user_reported_status': status,
      }),
    );

    if (response.statusCode == 201) {
      return {'success': true};
    } else {
      final data = jsonDecode(response.body);
      return {'success': false, 'message': data['message'] ?? 'Terjadi kesalahan'};
    }
  }

  // Polling check for active alarm
  Future<Map<String, dynamic>?> checkActiveAlarm() async {
    // Membutuhkan endpoint khusus untuk public alarm jika ada
    // Saat ini, backend memerlukan IsAuthenticated untuk '/api/alarms/' yang admin-only
    // Untuk simulasi MVP tanpa notif FCM:
    // Kita asumsikan ada endpoint ini atau gunakan data mock jika gagal
    try {
      final url = Uri.parse('$baseUrl/alarms/active/'); // Contoh jika nanti ada
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }
}
