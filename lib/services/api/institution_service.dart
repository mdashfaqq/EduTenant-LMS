import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../api/session_service.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class InstitutionService {
  InstitutionService._internal();
  static final InstitutionService instance = InstitutionService._internal();

  /* --------------------------------------------------------
   * GET /institutions
   * ------------------------------------------------------*/
Future<List<Map<String, dynamic>>> listInstitutions({
  String? code,
}) async {
  debugPrint('🟣 [InstitutionService] GET institutions');

  final response = await ApiClient.instance.get(
    '/institutions.php',
    queryParameters: code != null ? {'code': code} : null,
    skipInstitutionInjection: true,
  );

  // 🔥 response is already the DATA list
  if (response is List) {
    final list = List<Map<String, dynamic>>.from(response);

    debugPrint(
        '🟢 [InstitutionService] Loaded ${list.length} institutions');

    return list;
  }

  return [];
}
/* --------------------------------------------------------
   * GET current institution (based on session)
   * ------------------------------------------------------*/

Future<Map<String, dynamic>?> getCurrentInstitution() async {
  await SessionService.instance.init(); // 🔥 CRITICAL

  final currentCode = SessionService.instance.institutionCode;

  debugPrint("Session institutionCode: $currentCode");

  if (currentCode == null) return null;

  final institutions =
      await listInstitutions(code: currentCode);

  if (institutions.isEmpty) return null;

  return institutions.first;
}

  /* --------------------------------------------------------
   * GET /institutions?code=XXXX
   * ------------------------------------------------------*/
Future<Map<String, dynamic>> getInstitution(String code) async {
  debugPrint('🟣 [InstitutionService] GET institution $code');

  final response = await ApiClient.instance.get(
    '/institutions.php',
    queryParameters: {'code': code},
    skipInstitutionInjection: true,
  );

  // 🔥 ApiClient already unwraps -> response is List
  if (response is List && response.isNotEmpty) {
    return Map<String, dynamic>.from(response.first);
  }

  throw Exception('Institution not found');
}
  /* --------------------------------------------------------
   * POST /institutions
   * ------------------------------------------------------*/
  Future<Map<String, dynamic>> createInstitution(
    Map<String, dynamic> payload,
  ) async {
    debugPrint('🟣 [InstitutionService] CREATE institution');
    debugPrint('🟣 Payload: $payload');

    final data = await ApiClient.instance.post(
      '/institutions.php',
      data: payload,
    );

    debugPrint('🟢 [InstitutionService] Institution created');
    return data as Map<String, dynamic>;
  }

  /* --------------------------------------------------------
   * PUT /institutions/{code}
   * ------------------------------------------------------*/
Future<Map<String, dynamic>> updateInstitution(
  String code,
  Map<String, dynamic> payload,
) async {
  debugPrint('🟣 [InstitutionService] UPDATE institution $code');
  debugPrint('🟣 Payload: $payload');

  final uri = Uri.parse(
    'https://www.unreadymades.com/LMS/edutenant_lms_backend/api/institutions.php?code=$code',
  );

  final token = SessionService.instance.authToken;

  final response = await http.put(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
    body: jsonEncode(payload),
  );

  debugPrint("🟡 Status: ${response.statusCode}");
  debugPrint("🟡 Body: ${response.body}");

  if (response.statusCode != 200) {
    throw Exception(response.body);
  }

  final decoded = jsonDecode(response.body);

  if (decoded['success'] != true) {
    throw Exception(decoded['message']);
  }

  return Map<String, dynamic>.from(decoded['data']);
}


Future<void> updateSubscriptionStatus(
  String code,
  String status,
) async {
  final uri = Uri.parse(
    'https://www.unreadymades.com/LMS/edutenant_lms_backend/api/institutions.php?code=$code',
  );

  final token = SessionService.instance.authToken;

  final response = await http.put(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'subscription_status': status,
    }),
  );

  debugPrint("🟡 Status: ${response.statusCode}");
  debugPrint("🟡 Body: ${response.body}");

  if (response.statusCode != 200) {
    throw Exception(response.body);
  }
}
  /* --------------------------------------------------------
   * POST /institutions/logo (multipart)
   * ------------------------------------------------------*/
  Future<String> uploadInstitutionLogo(
    String institutionCode,
    File logoFile,
  ) async {
    debugPrint('🟣 [InstitutionService] UPLOAD LOGO for $institutionCode');
    debugPrint('🟣 File: ${logoFile.path}');

final uri = Uri.parse(
  'https://www.unreadymades.com/LMS/edutenant_lms_backend/api/institutions_logo.php',
);

    final request = http.MultipartRequest('POST', uri);
    request.fields['institution_code'] = institutionCode;
    request.files.add(
      await http.MultipartFile.fromPath('logo', logoFile.path),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      debugPrint('🔴 Logo upload failed: $body');
      throw Exception(body);
    }

    final decoded = jsonDecode(body);
    final logoPath = decoded['data']['logo'];

    debugPrint('🟢 Logo uploaded: $logoPath');
    return logoPath; // relative path from backend
  }
}
