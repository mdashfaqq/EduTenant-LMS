import 'api_client.dart';

class ProgressService {
  ProgressService._internal();
  static final ProgressService instance = ProgressService._internal();

  Future<List<Map<String, dynamic>>> listProgress({
    required int courseId,
    required String date,
  }) async {
    final res = await ApiClient.instance.get(
      '/progress.php',
      queryParameters: {
        'course_id': courseId,
        'date': date,
      },
    );

    final List list = res is List ? res : [];
    return list.cast<Map<String, dynamic>>();
  }

Future<void> saveBulkProgress(Map<String, dynamic> payload) async {
  await ApiClient.instance.post(
    '/progress.php',
    queryParameters: {'bulk': 1},
    data: payload,
  );
}
  Future<void> saveProgress(Map<String, dynamic> payload) async {
    await ApiClient.instance.post('/progress.php', data: payload);
  }
}