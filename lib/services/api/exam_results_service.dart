import 'api_client.dart';
import 'dart:convert';
class ExamResultsService {
  ExamResultsService._internal();
  static final ExamResultsService instance = ExamResultsService._internal();

Future<List<Map<String, dynamic>>> getExamResults({
  required int examId,
}) async {
  final response = await ApiClient.instance.get(
    '/exam_results.php',
    queryParameters: {'exam_id': examId},
  );

  // Case 1: API returns wrapped response { success, data }
  if (response is Map<String, dynamic>) {
    final data = response['data'];
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  // Case 2: API returns raw list directly
  if (response is List) {
    return List<Map<String, dynamic>>.from(response);
  }

  // Case 3: Unexpected type
  return [];
}
Future<List<Map<String, dynamic>>> getResultsByStudent(int studentId) async {
  final response = await ApiClient.instance.get(
    '/student_report.php',
    queryParameters: {
      'student_id': studentId,
    },
  );

  print("RAW RESPONSE: $response");

  // Case 1: API returns full wrapper { success, message, data }
  if (response is Map<String, dynamic>) {
    final dynamic data = response['data'];

    if (data is List) {
      return List<Map<String, dynamic>>.from(
        data.map((e) => Map<String, dynamic>.from(e)),
      );
    }
  }

  // Case 2: API directly returns a list
  if (response is List) {
    return List<Map<String, dynamic>>.from(
      response.map((e) => Map<String, dynamic>.from(e)),
    );
  }

  return [];
}
  Future<void> saveExamResults({
    required int examId,
    required int totalMarks,
    required List<Map<String, dynamic>> results,
  }) async {
    final payload = {
      'exam_id': examId,
      'results': results.map((r) => {
            'student_id': r['student_id'],
            'marks': r['marks'],
            'total_marks': totalMarks,
          }).toList(),
    };

    await ApiClient.instance.post(
      '/exam_results.php',
      data: payload,
    );
  }

  Future<void> deleteExamResults({
    required int examId,
  }) async {
    await ApiClient.instance.delete(
      '/exam_results.php',
      queryParameters: {'exam_id': examId},
    );
  }
}
