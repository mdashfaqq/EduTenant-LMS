import 'api_client.dart';
import 'api_utils.dart';
import 'package:flutter/foundation.dart';

class CoursesService {
  CoursesService._internal();

  static final CoursesService instance = CoursesService._internal();

  Future<List<Map<String, dynamic>>> listCourses({
    String? status,
    String? search,
    int? instructorId,
      String? institutionCode,
  }) async {
final params = <String, dynamic>{};

if (status != null && status.isNotEmpty && status != 'all') {
  params['status'] = status;
}

if (search != null && search.isNotEmpty) {
  params['search'] = search;
}

if (instructorId != null) {
  params['instructor_id'] = instructorId;
}

// 🔥 allow override
if (institutionCode != null && institutionCode.isNotEmpty) {
  params['institution_code'] = institutionCode;
}

    final data = await ApiClient.instance.get(
      '/courses.php',
      queryParameters: params.isEmpty ? null : params,
    );

    final items = (data as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return items.map(_toUiCourse).toList();
  }

  Future<List<Map<String, dynamic>>> listCourseStudents(int courseId) async {
  debugPrint('🚨 listCourseStudents CALLED for courseId = $courseId');

  final data = await ApiClient.instance.get(
    '/courses.php/$courseId/students',
  );

  debugPrint('📦 RAW students response = $data');

  final items = (data as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>();

  return items.map((s) {
    return {
      'id': s['id'],
      'name': s['name'] ?? '',
      'email': s['email'] ?? '',
      'role': s['role'] ?? 'student',

      // ✅ ADD SAFE DEFAULTS (important)
      'roll': 'STU${s['id']}',
      'status': 'absent', // attendance overlay will update this
    };
  }).toList();
}

Future<List<Map<String, dynamic>>> listCourseInstructors(int courseId) async {
  final data = await ApiClient.instance.get(
    '/courses.php/$courseId/instructors',
  );

  final items = (data as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>();

  return items;
}

  Future<Map<String, dynamic>> createCourse(
    Map<String, dynamic> payload,
  ) async {
    final data = await ApiClient.instance.post('/courses.php', data: payload);
    return _toUiCourse(data as Map<String, dynamic>);
  }
Future<void> updateCourse(
  int id,
  Map<String, dynamic> payload,
) async {
  await ApiClient.instance.put(
    '/courses.php/$id',
    data: payload,
  );
}


Future<void> deleteCourse(int id) async {
  await ApiClient.instance.delete(
    '/courses.php/$id',
  );
}

  Map<String, dynamic> _toUiCourse(Map<String, dynamic> course) {
    final startDate = course['start_date']?.toString();
    final thumbnail = (course['thumbnail'] as String?)?.isNotEmpty == true
        ? course['thumbnail']
        : 'assets/images/no-image.jpg';
    final instructorAvatar =
        (course['instructor_avatar'] as String?)?.isNotEmpty == true
            ? course['instructor_avatar']
            : 'assets/images/no-image.jpg';
    return {
      'id': course['id'],
      'title': course['title'] ?? 'Untitled Course',
      
      'courseCode': course['code'] ?? '',
      'department': course['category'] ?? 'General',
      'semester': _semesterFromDate(startDate),
      'credits': course['credits'] ?? 0,
      'instructor': course['instructor_name'] ?? 'TBD',
      'instructorId': course['instructor_id'],
      'enrollmentCount': course['enrollmentCount'] ?? 0,
      'maxEnrollment': course['capacity'] ?? 0,
      'status': course['status'] ?? 'active',
      'thumbnail': thumbnail,
      'semanticLabel': 'Course thumbnail',
      'schedule': course['schedule'] ?? 'TBD',
      'room': course['room'] ?? 'TBD',
      'description': course['description'] ?? '',
      'progress': 0.0,
      'nextAssignment': null,
      'dueDate': null,
      'unreadCount': 0,
      'isPinned': false,
      'instructorAvatar': instructorAvatar,
      'instructorAvatarLabel': 'Instructor avatar',
      'thumbnailLabel': 'Course thumbnail',
      'startDate': formatDate(startDate, fallback: 'N/A'),
      'endDate': formatDate(course['end_date']?.toString(), fallback: 'N/A'),
      'fee_structure_ids': course['fee_structure_ids'],
    };
  }

  String _semesterFromDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Current Semester';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return 'Current Semester';
    }

    final month = parsed.month;
    final year = parsed.year;
    if (month >= 1 && month <= 5) {
      return 'Spring $year';
    }
    if (month >= 6 && month <= 8) {
      return 'Summer $year';
    }
    return 'Fall $year';
  }
}
