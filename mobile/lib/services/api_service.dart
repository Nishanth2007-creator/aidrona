import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator (maps to host localhost),
  // change to your server IP/hostname for a real device or production.
  static const String _baseUrl =
      kDebugMode ? 'http://10.0.2.2:8080/api' : 'https://api.aidrona.app/api';

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

  // ── AUTH ────────────────────────────────────────────────
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> updateUserProfile(
      String uid, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/auth/user/$uid'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> deleteAccount(String uid) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/auth/user/$uid'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> verifyDoctor(String regId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/doctor-verify'),
      headers: await _getHeaders(),
      body: jsonEncode({'reg_id': regId}),
    );
    return jsonDecode(res.body);
  }

  // ── HOME ────────────────────────────────────────────────
  Future<Map<String, dynamic>> getHomeSummary(String userId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/home/summary'),
      headers: await _getHeaders(),
      body: jsonEncode({'user_id': userId}),
    );
    return jsonDecode(res.body);
  }

  // ── BLOOD REQUEST ───────────────────────────────────────
  Future<Map<String, dynamic>> submitBloodRequest(
      Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/request/blood'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> extendRadius(
      String crisisId, double newRadius) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/request/$crisisId/radius'),
      headers: await _getHeaders(),
      body: jsonEncode({'new_radius_km': newRadius}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> openToStrangers(
      String crisisId, double lat, double lng) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/request/$crisisId/open'),
      headers: await _getHeaders(),
      body: jsonEncode({'lat': lat, 'lng': lng}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getCrisis(String crisisId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/request/$crisisId'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  /// type: 'sent' (default) | 'received'
  Future<List<dynamic>> getMyRequests(String userId,
      {String type = 'sent'}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/request/list?user_id=$userId&type=$type'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  // ── DONOR RESPONSE ──────────────────────────────────────
  Future<Map<String, dynamic>> acceptDonation(
      String crisisId, String donorId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/response/accept'),
      headers: await _getHeaders(),
      body: jsonEncode({'crisis_id': crisisId, 'donor_id': donorId}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> declineDonation(
      String crisisId, String donorId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/response/decline'),
      headers: await _getHeaders(),
      body: jsonEncode({'crisis_id': crisisId, 'donor_id': donorId}),
    );
    return jsonDecode(res.body);
  }

  // ── MEDICAL ─────────────────────────────────────────────
  Future<Map<String, dynamic>> uploadMedicalRecord(
      Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/medical/upload'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> doctorUpdateMedical(
      Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/medical/update'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getPatientSummary(String uid) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/medical/patient/$uid/summary'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getMedicalHistory(String uid) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/medical/history/$uid'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  // ── NOTIFICATIONS ───────────────────────────────────────
  Future<List<dynamic>> getUserNotifications(String uid) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/notifications/$uid'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  Future<void> markNotificationsRead(String uid) async {
    await http.post(
      Uri.parse('$_baseUrl/notifications/$uid/mark-read'),
      headers: await _getHeaders(),
    );
  }

  // ── DONOR VERIFY ────────────────────────────────────────
  Future<Map<String, dynamic>> verifyDonor(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/donor/verify'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getDonorProfile(String uid) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/donor/profile/$uid'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  // ── ESCALATE ────────────────────────────────────────────
  Future<Map<String, dynamic>> escalateToBank(String crisisId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/escalate/bank'),
      headers: await _getHeaders(),
      body: jsonEncode({'crisis_id': crisisId}),
    );
    return jsonDecode(res.body);
  }

  // ── ADMIN ───────────────────────────────────────────────
  Future<List<dynamic>> getAdminUsers() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/users'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getBloodBanks() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/banks'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getActiveCrises() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/crises'),
      headers: await _getHeaders(),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getAdminInsights(String region) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/admin/insights'),
      headers: await _getHeaders(),
      body: jsonEncode({'region': region, 'time_window': '24h'}),
    );
    return jsonDecode(res.body);
  }
}
