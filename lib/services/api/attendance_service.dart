import 'api_client.dart';

class AttendanceService {
  AttendanceService._internal();
  static final AttendanceService instance = AttendanceService._internal();

  /// Instructor/Admin attendance (course-based)
  Future<List<Map<String, dynamic>>> listAttendance({
    required int courseId,
    int? classId,
    int? instructorId,
    int? studentId,
    String? startDate,
    String? endDate,
    String? department,
    String? courseName,
  }) async {
    final params = <String, dynamic>{};

    // REQUIRED for instructor/admin
    params['course_id'] = courseId;

    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (classId != null) params['class_id'] = classId;
    if (studentId != null) params['student_id'] = studentId;
    if (instructorId != null) params['instructor_id'] = instructorId;
    if (department != null && department.isNotEmpty && department != 'all') {
      params['department'] = department;
    }
    if (courseName != null && courseName.isNotEmpty && courseName != 'all') {
      params['course'] = courseName;
    }

    final res = await ApiClient.instance.get(
      '/attendance.php',
      queryParameters: params,
    );

final List list = res is List ? res : [];


    return list.cast<Map<String, dynamic>>();
  }

  /// ✅ Student-only attendance (overall view)
  Future<List<Map<String, dynamic>>> listStudentAttendance({
    required int studentId,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, dynamic>{
      'student_id': studentId,
    };

    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    final res = await ApiClient.instance.get(
      '/attendance.php',
      queryParameters: params,
    );

 final List list = res is List ? res : [];


    return list.cast<Map<String, dynamic>>();
  }

  Future<double> getDashboardAttendance() async {
    final res = await ApiClient.instance.get(
      '/attendance.php?dashboard=1',
    );

    return (res['attendance_percentage'] ?? 0).toDouble();
  }
Future<void> markAttendance(
  Map<String, dynamic> payload,
) async {
  await ApiClient.instance.post('/attendance.php', data: payload);
}



Future<Map<String, dynamic>> bulkMarkAttendance(
  Map<String, dynamic> payload,
) async {
  final data = await ApiClient.instance.post(
    '/attendance.php',
    queryParameters: {'bulk': 1},
    data: payload,
  );

  return data as Map<String, dynamic>;
}

}
