import 'api_client.dart';
import 'session_service.dart';

class StudentsService {
  StudentsService._internal();
  static final StudentsService instance = StudentsService._internal();

  Future<List<Map<String, dynamic>>> listStudents() async {
    final session = SessionService.instance;
    await session.init();

    final response = await ApiClient.instance.get(
      '/users.php',
      queryParameters: {
        'role': 'student',
        'institution_code': session.institutionCode,
      },
    );

    // 🔥 CASE 1: ApiClient already returned data list
    if (response is List) {
      return response
          .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e),
          )
          .toList();
    }

    // 🔥 CASE 2: ApiClient returned full JSON
    if (response is Map<String, dynamic>) {
      final List data = response['data'];
      return data
          .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e),
          )
          .toList();
    }

    throw Exception(
      'Unexpected users.php response: ${response.runtimeType}',
    );
  }
}
