import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator (maps to host localhost),
  // change to your server IP/hostname for a real device or production.
  static String get _baseUrl {
    if (kDebugMode) {
      if (kIsWeb) {
        return 'http://localhost:8085/api';
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:8085/api'; // Android Emulator alias
      }
      return 'http://localhost:8085/api'; // Windows / iOS Simulator
    }
    return 'https://api.aidrona.app/api';
  }

  static const Duration _timeout = Duration(seconds: 10);

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeMap(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (_) {
      return {'error': 'Invalid response', 'status': res.statusCode};
    }
  }

  List<dynamic> _decodeList(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── AUTH ────────────────────────────────────────────────
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> updateUserProfile(
      String uid, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/auth/user/$uid'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> deleteAccount(String uid) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/auth/user/$uid'),
      headers: await _getHeaders(),
    ).timeout(_timeout);
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> verifyDoctor(String regId, {String? phone}) async {
    final body = {'reg_id': regId};
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/doctor-verify'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    return _decodeMap(res);
  }

  // ── HOME ────────────────────────────────────────────────
  Future<Map<String, dynamic>> getHomeSummary(String userId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/home/summary'),
      headers: await _getHeaders(),
      body: jsonEncode({'user_id': userId}),
    ).timeout(_timeout);
    return _decodeMap(res);
  }

  // ── BLOOD REQUEST ───────────────────────────────────────
  Future<Map<String, dynamic>> submitBloodRequest(
      Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/request/blood'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30)); // longer for AI triage
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> extendRadius(
      String crisisId, double newRadius) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/request/$crisisId/radius'),
      headers: await _getHeaders(),
      body: jsonEncode({'new_radius_km': newRadius}),
    ).timeout(_timeout);
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> openToStrangers(
      String crisisId, double lat, double lng) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/request/$crisisId/open'),
      headers: await _getHeaders(),
      body: jsonEncode({'lat': lat, 'lng': lng}),
    ).timeout(_timeout);
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> getCrisis(String crisisId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/request/$crisisId'),
      headers: await _getHeaders(),
    ).timeout(_timeout);
    return _decodeMap(res);
  }

  /// type: 'sent' (default) | 'received'
  Future<List<dynamic>> getMyRequests(String userId,
      {String type = 'sent'}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/request/list?user_id=$userId&type=$type'),
      headers: await _getHeaders(),
    ).timeout(_timeout);
    return _decodeList(res);
  }

  // ── DONOR RESPONSE ──────────────────────────────────────
  Future<Map<String, dynamic>> acceptDonation(
      String crisisId, String donorId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/response/accept'),
      headers: await _getHeaders(),
      body: jsonEncode({'crisis_id': crisisId, 'donor_id': donorId}),
    ).timeout(_timeout);
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> declineDonation(
      String crisisId, String donorId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/response/decline'),
      headers: await _getHeaders(),
      body: jsonEncode({'crisis_id': crisisId, 'donor_id': donorId}),
    ).timeout(_timeout);
    return _decodeMap(res);
  }

  // ── MEDICAL ─────────────────────────────────────────────
  Future<Map<String, dynamic>> uploadMedicalRecord(
      Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/medical/upload'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30)); // longer for AI processing
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> doctorUpdateMedical(
      Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/medical/update'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> getPatientSummary(String uid) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/medical/patient/$uid/summary'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 30));
    return _decodeMap(res);
  }

  Future<List<dynamic>> getMedicalHistory(String uid) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/medical/history/$uid'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 30));
    return _decodeList(res);
  }

  // ── NOTIFICATIONS ───────────────────────────────────────
  Future<List<dynamic>> getUserNotifications(String uid) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/notifications/$uid'),
      headers: await _getHeaders(),
    ).timeout(_timeout);
    return _decodeList(res);
  }

  Future<void> markNotificationsRead(String uid) async {
    await http.post(
      Uri.parse('$_baseUrl/notifications/$uid/mark-read'),
      headers: await _getHeaders(),
    ).timeout(_timeout);
  }

  // ── DONOR VERIFY ────────────────────────────────────────
  Future<Map<String, dynamic>> verifyDonor(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/donor/verify'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> getDonorProfile(String uid) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/donor/profile/$uid'),
      headers: await _getHeaders(),
    ).timeout(_timeout);
    return _decodeMap(res);
  }

  // ── ESCALATE ────────────────────────────────────────────
  Future<Map<String, dynamic>> escalateToBank(String crisisId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/escalate/bank'),
      headers: await _getHeaders(),
      body: jsonEncode({'crisis_id': crisisId}),
    ).timeout(_timeout);
    return _decodeMap(res);
  }

  // ── ADMIN ───────────────────────────────────────────────
  Future<List<dynamic>> getAdminUsers() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/users'),
      headers: await _getHeaders(),
    ).timeout(_timeout);
    return _decodeList(res);
  }

  Future<List<dynamic>> getBloodBanks() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/banks'),
      headers: await _getHeaders(),
    ).timeout(_timeout);
    return _decodeList(res);
  }

  Future<List<dynamic>> getActiveCrises() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/crises'),
      headers: await _getHeaders(),
    ).timeout(_timeout);
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> getAdminInsights(String region) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/admin/insights'),
      headers: await _getHeaders(),
      body: jsonEncode({'region': region, 'time_window': '24h'}),
    ).timeout(const Duration(seconds: 20)); // AI processing
    return _decodeMap(res);
  }
}
