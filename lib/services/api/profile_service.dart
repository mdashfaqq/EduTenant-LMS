import 'package:http/http.dart' as http;
import 'dart:convert';
import 'session_service.dart';
import 'api_config.dart';
import 'package:flutter/foundation.dart'; 

class ProfileService {
  ProfileService._internal();
  static final ProfileService instance = ProfileService._internal();

Future<Map<String, dynamic>> getProfile() async {
  final token = SessionService.instance.authToken;

  if (token == null) {
    throw Exception("Auth token is null");
  }

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/profile'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  debugPrint("PROFILE STATUS: ${response.statusCode}");
  debugPrint("PROFILE BODY: ${response.body}");

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception(
        "Failed to load profile (${response.statusCode})");
  }
}

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final token = SessionService.instance.authToken;

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }
}