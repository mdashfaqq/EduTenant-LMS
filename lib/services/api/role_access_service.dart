// 

import 'dart:convert';

import 'api_client.dart';
import 'session_service.dart';

class RoleAccessService {
  RoleAccessService._internal();

  static final RoleAccessService instance = RoleAccessService._internal();

  Future<List<Map<String, dynamic>>> listPermissions() async {

    final user = SessionService.instance.currentUser;
    final role = user?['role'];
    final institutionCode = user?['institution_code'];

    final data = await ApiClient.instance.get(
      '/role_permissions.php',
      queryParameters: {
        if (role != 'platform_admin' && institutionCode != null)
          'institution_code': institutionCode,
      },
    );

    final items = (data as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return items.map((item) {
      return {
        'role': item['role'] ?? '',
        'permissions': _decodePermissions(item['permissions']),
      };
    }).toList();
  }

  Future<Map<String, dynamic>> updatePermissions({
    required String role,
    required List<String> permissions,
  }) async {

    final user = SessionService.instance.currentUser;
    final userRole = user?['role'];
    final institutionCode = user?['institution_code'];

    final data = await ApiClient.instance.post(
      '/role_permissions.php',
      data: {
        'role': role,
        'permissions': permissions,
        if (userRole != 'platform_admin' && institutionCode != null)
          'institution_code': institutionCode,
      },
    );

    return data as Map<String, dynamic>;
  }

  List<String> _decodePermissions(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }

    if (raw is String) {
      if (raw.startsWith('[')) {
        try {
          final decoded = jsonDecode(raw) as List<dynamic>;
          return decoded.map((e) => e.toString()).toList();
        } catch (_) {
          return [];
        }
      }
      return [raw];
    }

    return [];
  }
}