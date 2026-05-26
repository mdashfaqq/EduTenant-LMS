import 'api_client.dart';

class ExamsService {
  ExamsService._internal();

  static final ExamsService instance = ExamsService._internal();

  Future<List<Map<String, dynamic>>> listExams({
    int? courseId,
    String? status,
  }) async {
    final params = <String, dynamic>{};
    if (courseId != null) {
      params['course_id'] = courseId;
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      params['status'] = status;
    }

    final data = await ApiClient.instance.get(
      '/exams.php',
      queryParameters: params.isEmpty ? null : params,
    );

    final items = (data as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return items.map(_toUiExam).toList();
  }

Future<Map<String, dynamic>> createExam(
  Map<String, dynamic> payload,
) async {
  final data = await ApiClient.instance.post(
    '/exams.php',
    data: payload,
  );

  // 🔥 Backend returns LIST, not object
  final exam = data is List ? data.first : data;

  return _toUiExam(exam as Map<String, dynamic>);
}



  Future<Map<String, dynamic>> updateExam(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final data = await ApiClient.instance.put('/exams/$id', data: payload);
    return _toUiExam(data as Map<String, dynamic>);
  }

  Future<void> deleteExam(int id) async {
    await ApiClient.instance.delete('/exams/$id');
  }

Map<String, dynamic> _toUiExam(Map<String, dynamic> exam) {
  final start = exam['start_time']?.toString();
  final end = exam['end_time']?.toString();
  final timeRange =
      (start != null && end != null) ? '$start - $end' : 'TBD';

  return {
    'id': exam['id'],
    'course_id': exam['course_id'],

    'title': exam['title'] ?? 'Untitled Exam',
    'course': exam['course_title'] ?? 'Course',

    // ✅ KEEP UI fields
    'date': exam['exam_date'] ?? '',
    'time': timeRange,

    // ✅ ADD RAW FIELDS (CRITICAL FIX)
    'exam_date': exam['exam_date'],
    'start_time': exam['start_time'],
    'end_time': exam['end_time'],

    'courseCode': exam['course_id'] != null
        ? 'COURSE ${exam['course_id']}'
        : '',

    'duration': exam['duration'] ?? 0,
    'totalMarks': exam['total_marks'] ?? 0,
    'passingMarks': exam['passing_marks'] ?? 0,
    'venue': exam['room'] ?? 'TBD',
    'status': exam['status'] ?? 'scheduled',
  };
}
}