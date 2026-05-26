import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'api_utils.dart';

class UsersService {
  UsersService._internal();

  static final UsersService instance = UsersService._internal();

  Future<List<Map<String, dynamic>>> listUsers({
    String? role,
    String? search,
  }) async {
    final params = <String, dynamic>{};
    if (role != null && role.isNotEmpty && role != 'all') {
      params['role'] = role;
    }
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    debugPrint(
      '[UsersService] listUsers -> role: ${role ?? "all"}, search: ${search ?? "-"}, params: $params',
    );

    final data = await ApiClient.instance.get(
      '/users.php',
      queryParameters: params.isEmpty ? null : params,
    );

    final items = (data as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return items.map(_toUiUser).toList();
  }

  Future<Map<String, dynamic>> createUser(
    Map<String, dynamic> payload,
  ) async {
    final data = await ApiClient.instance.post('/users.php', data: payload);
    return _toUiUser(data as Map<String, dynamic>);
  }


Future<Map<String, dynamic>> updateUser(
  int id,
  Map<String, dynamic> payload,
) async {

  debugPrint("========== UPDATE USER ==========");
  debugPrint("User ID: $id");
  debugPrint("Payload: $payload");

  try {

    final data = await ApiClient.instance.put(
      '/users.php/$id',
      data: payload,
    );

    debugPrint("Update Success Response:");
    debugPrint(data.toString());

    return _toUiUser(data as Map<String, dynamic>);
  } catch (e) {

    debugPrint("UPDATE USER FAILED");
    debugPrint(e.toString());

    rethrow;
  }
}

  Future<void> deleteUser(int id) async {
    await ApiClient.instance.delete('/users.php/$id');
  }

Future<List<Map<String, dynamic>>> getStudentInstructors(int studentId) async {
  final data = await ApiClient.instance.get(
    '/users.php/$studentId/instructors',
  );

  final items = (data as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>();

  return items;
}
  
Future<Map<String, dynamic>> getUserById(int id) async {
  final data = await ApiClient.instance.get(
    '/users.php',
    queryParameters: {
      'id': id,
    },
  );

  return _toUiUser(Map<String, dynamic>.from(data));
}
  Map<String, dynamic> _toUiUser(Map<String, dynamic> user) {
    final id = (user['id'] is num)
        ? (user['id'] as num).toInt()
        : int.tryParse(user['id']?.toString() ?? '') ?? 0;
    List<int> courseIds = [];
    final rawCourseIds = user['course_ids'];
    if (rawCourseIds is List) {
      courseIds = rawCourseIds.map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e > 0).toList();
    } else if (rawCourseIds is String && rawCourseIds.isNotEmpty) {
      try {
        final decoded = rawCourseIds.contains('[')
            ? (jsonDecode(rawCourseIds) as List<dynamic>?)
            : null;
        if (decoded != null) {
          courseIds = decoded
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e > 0)
              .toList();
        }
      } catch (_) {
        // ignore parse errors and keep empty list
      }
    }

    return {
      'id': id,
      'name': user['name'] ?? 'Unknown',
      'email': user['email'] ?? '',
      'role': user['role'] ?? 'Student',
      'institution_name': user['institution_name'],
      'department': user['department'] ?? 'N/A',
      'courseIds': courseIds,
      'status': user['status'] ?? 'active',
      'avatar': user['avatar'],
      'semanticLabel': 'User avatar',
     'lastActivity': user['last_activity'],
      'joinDate': formatDate(user['join_date']?.toString()),
      'coursesTeaching': user['courses_teaching'] ?? 0,
      'studentsManaged': user['students_managed'] ?? 0,
      'coursesEnrolled': user['courses_enrolled'] ?? 0,
      'gpa': user['gpa'],
      'parentId': user['parent_id'],
        'discount_type': user['discount_type'],
  'discount_value': user['discount_value'],
  'discount_reason': user['discount_reason'],
    };
  }
}
