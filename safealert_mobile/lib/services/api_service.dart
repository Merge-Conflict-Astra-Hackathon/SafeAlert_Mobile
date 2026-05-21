import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    const overrideUrl = String.fromEnvironment('SAFEALERT_API_URL');
    if (overrideUrl.isNotEmpty) return overrideUrl;

    if (kIsWeb) return 'http://127.0.0.1:8089/api';
    // Android emulator maps host machine localhost to 10.0.2.2.
    return 'http://10.0.2.2:8089/api';
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

  Future<void> _saveSession(Map<String, dynamic> responseData) async {
    final data = (responseData['data'] ?? responseData) as Map<String, dynamic>;
    final tokens = responseData['tokens'] as Map<String, dynamic>?;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('user_id', data['id'] as int);
    await prefs.setString('user_name', (data['name'] ?? 'Pengguna').toString());
    await prefs.setString(
      'admin_status',
      (data['admin_status'] ?? 'active').toString(),
    );
    await prefs.setString('user_floor', (data['floor'] ?? '').toString());

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
          'floor': floor,
          'disability_type': disabilityType,
          'fcm_token': fcmToken,
        }),
      );
      final responseData = _decodeResponse(response);

      if (response.statusCode == 201) {
        await _saveSession(responseData);
        return {'success': true, 'data': responseData['data']};
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Registrasi gagal',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
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
  }) async {
    final normalizedStatus = status == 'evacuating' ? 'needs_help' : status;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/confirmations/confirm_status/'),
        headers: await _headers(withAuth: true),
        body: jsonEncode({
          'alert_id': alarmId,
          'status': normalizedStatus,
        }),
      );
      final responseData = _decodeResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
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
        final alert = alerts.first as Map<String, dynamic>;
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
