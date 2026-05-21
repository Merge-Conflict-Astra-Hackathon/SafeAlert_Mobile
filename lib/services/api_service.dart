import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    const overrideUrl = String.fromEnvironment('SAFEALERT_API_URL');
    if (overrideUrl.isNotEmpty) return overrideUrl;

    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    // Android emulator maps host machine localhost to 10.0.2.2.
    return 'http://10.0.2.2:8000/api';
  }

  static String resolveAssetUrl(String url) {
    if (url.isEmpty || url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final apiUri = Uri.parse(baseUrl);
    return apiUri.replace(path: url).toString();
  }

  Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> _decodeListResponse(http.Response response) {
    if (response.body.isEmpty) return [];
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  Future<Set<int>> _respondedAlarmIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getStringList('responded_alarm_ids')
        ?.map(int.tryParse)
        .whereType<int>()
        .toSet() ??
        <int>{};
  }

  Future<void> markAlarmResponded(int alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await _respondedAlarmIds();
    ids.add(alarmId);
    await prefs.setStringList(
      'responded_alarm_ids',
      ids.map((id) => id.toString()).toList(),
    );
  }

  Future<bool> hasRespondedToAlarm(int alarmId) async {
    final ids = await _respondedAlarmIds();
    return ids.contains(alarmId);
  }

  Future<void> _saveSession(Map<String, dynamic> responseData) async {
    final data = (responseData['data'] ?? responseData) as Map<String, dynamic>;
    final tokens = responseData['tokens'] as Map<String, dynamic>?;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('user_id', data['id'] as int);
    await prefs.setString('user_name', (data['name'] ?? 'Pengguna').toString());
    await prefs.setString(
      'admin_status',
      (data['admin_status'] ?? 'pending').toString(),
    );
    await prefs.setString('user_floor', (data['floor'] ?? '').toString());
    await prefs.setString('building_id', (data['building_id'] ?? '').toString());
    await prefs.setString(
      'building_name',
      (data['building_name'] ?? '').toString(),
    );

    if (tokens != null) {
      await prefs.setString('access_token', (tokens['access'] ?? '').toString());
      await prefs.setString(
        'refresh_token',
        (tokens['refresh'] ?? '').toString(),
      );
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String phone,
    required String password,
    required int buildingId,
    required int floor,
    required String disabilityType,
    required String fcmToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/'),
        headers: await _headers(),
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'password': password,
          'building_id': buildingId,
          'floor': floor,
          'disability_type': disabilityType,
          'fcm_token': fcmToken,
        }),
      );
      final responseData = _decodeResponse(response);

      if (response.statusCode == 201) {
        await _saveSession(responseData);
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Registrasi gagal',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getBuildings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/buildings/'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return _decodeListResponse(response);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> loginUser({
    required String phone,
    required String password,
    required String fcmToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: await _headers(),
        body: jsonEncode({
          'phone': phone,
          'password': password,
          'fcm_token': fcmToken,
        }),
      );
      final responseData = _decodeResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _saveSession(responseData);
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': 'Login berhasil',
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Nomor HP atau password salah.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  Future<Map<String, dynamic>> sendConfirmation({
    required int alarmId,
    required int userId,
    required String status,
    String location = '',
    String notes = '',
  }) async {
    final normalizedStatus = status == 'evacuating' ? 'needs_help' : status;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/confirmations/confirm_status/'),
        headers: await _headers(withAuth: true),
        body: jsonEncode({
          'alert_id': alarmId,
          'status': normalizedStatus,
          'location': location,
          'notes': notes,
        }),
      );
      final responseData = _decodeResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await markAlarmResponded(alarmId);
        return {'success': true, 'data': responseData};
      }

      return {
        'success': false,
        'message': responseData['error'] ??
            responseData['message'] ??
            'Terjadi kesalahan',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  Future<Map<String, dynamic>?> checkActiveAlarm() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/alerts/active_alerts/'),
        headers: await _headers(withAuth: true),
      );

      if (response.statusCode == 200) {
        final alerts = jsonDecode(response.body) as List<dynamic>;
        if (alerts.isEmpty) return null;
        final respondedIds = await _respondedAlarmIds();
        final alert = alerts
            .whereType<Map<String, dynamic>>()
            .firstWhere(
              (alert) => !respondedIds.contains(alert['id'] as int),
              orElse: () => <String, dynamic>{},
            );
        if (alert.isEmpty) return null;
        return {
          'id': alert['id'],
          'message': alert['description'] ?? alert['title'] ?? 'EVAKUASI SEKARANG!',
        };
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>> updateFloor({required int floor}) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/update_floor/'),
        headers: await _headers(withAuth: true),
        body: jsonEncode({'floor': floor}),
      );
      final responseData = _decodeResponse(response);

      if (response.statusCode == 200) {
        await _saveSession(responseData);
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Nomor lantai berhasil diperbarui.',
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal memperbarui nomor lantai.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
