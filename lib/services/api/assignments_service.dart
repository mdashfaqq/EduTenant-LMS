import 'api_client.dart';

class AssignmentsService {
  AssignmentsService._internal();
  static final AssignmentsService instance = AssignmentsService._internal();

  /// GET /assignments.php
  Future<List<Map<String, dynamic>>> listAssignments({
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

    final response = await ApiClient.instance.get(
      '/assignments.php',
      queryParameters: params.isEmpty ? null : params,
    );

    // API returns { success, message, data }
    return (response['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  /// GET /assignments.php/{id}
  /// Returns aggregated assignment data
  Future<Map<String, dynamic>> getAssignment(int id) async {
    final response =
        await ApiClient.instance.get('/assignments.php/$id');

    // response['data'] contains:
    // assignment, requirements, submissionGuidelines, attachedResources, previousSubmissions
    return response['data'] as Map<String, dynamic>;
  }

  /// POST /assignments.php
  Future<Map<String, dynamic>> createAssignment(
    Map<String, dynamic> payload,
  ) async {
    final response = await ApiClient.instance.post(
      '/assignments.php',
      data: payload,
    );

    return response['data'] as Map<String, dynamic>;
  }

  /// PUT /assignments.php/{id}
  Future<Map<String, dynamic>> updateAssignment(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final response = await ApiClient.instance.put(
      '/assignments.php/$id',
      data: payload,
    );

    return response['data'] as Map<String, dynamic>;
  }

  /// DELETE /assignments.php/{id}
  Future<void> deleteAssignment(int id) async {
    await ApiClient.instance.delete('/assignments.php/$id');
  }
}
