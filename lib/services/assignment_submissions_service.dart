import '/services/api/api_client.dart';


class AssignmentSubmissionsService {
  AssignmentSubmissionsService._internal();
  static final AssignmentSubmissionsService instance =
      AssignmentSubmissionsService._internal();

  /// POST /assignment-submissions.php
  Future<void> submitAssignment({
    required String assignmentCode,
    String? submissionText,
    String? fileUrl,
  }) async {
    await ApiClient.instance.post(
      '/assignment-submissions.php',
      data: {
        'assignment_id': assignmentCode,
        'submission_text': submissionText,
        'file_url': fileUrl,
      },
    );
  }
}
