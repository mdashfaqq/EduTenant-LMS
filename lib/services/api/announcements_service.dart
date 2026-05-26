import 'api_client.dart';
import 'package:dio/dio.dart';
class AnnouncementsService {
  AnnouncementsService._();
  static final AnnouncementsService instance = AnnouncementsService._();

  /* =======================================================
     GET: Fetch announcements for a course
     GET /announcements.php?course_id=ID
  ======================================================== */
  Future<List<Map<String, dynamic>>> getByCourse(int courseId) async {
    final res = await ApiClient.instance.get(
      '/announcements.php',
      queryParameters: {
        'course_id': courseId,
      },
    );

    // ApiClient already unwraps -> returns List
    if (res is List) {
      return res.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    return [];
  }

  /* =======================================================
     POST: Create announcement (admin/teacher)
     POST /announcements.php
  ======================================================== */
  // Future<void> create({
  //   required int courseId,
  //   required String title,
  //   required String content,
  //   String? targetAudience,
  //   String priority = 'normal',
  //   String? expiryDate,
  // }) async {
  //   await ApiClient.instance.post(
  //     '/announcements.php',
  //     data: {
  //       'course_id': courseId,
  //       'title': title,
  //       'content': content,
  //       'target_audience': targetAudience,
  //       'priority': priority,
  //       'expiry_date': expiryDate,
  //     },
  //   );
  // }


Future<void> create({
  required int courseId,
  required String title,
  required String content,
  String? targetAudience,
  String priority = 'normal',
  String? expiryDate,
  List<MultipartFile>? files,
}) async {
  final data = {
    'course_id': courseId,
    'title': title,
    'content': content,
    if (targetAudience != null) 'target_audience': targetAudience,
    'priority': priority,
    if (expiryDate != null) 'expiry_date': expiryDate,
  };

  if (files != null && files.isNotEmpty) {
    await ApiClient.instance.postMultipart(
      '/announcements.php',
      data: data,
      files: files,
    );
  } else {
    await ApiClient.instance.post(
      '/announcements.php',
      data: data,
    );
  }
}
    /* =======================================================
     UPDATE ANNOUNCEMENT
  ======================================================== */
  // Future<void> update({
  //   required int announcementId,
  //   required String title,
  //   required String content,
  // }) async {
  //   await ApiClient.instance.put(
  //     '/announcements.php',
  //     data: {
  //       'id': announcementId,
  //       'title': title,
  //       'content': content,
  //     },
  //   );
  // }


  Future<void> update({
  required int announcementId,
  required String title,
  required String content,
  List<MultipartFile>? files, // ✅ NEW
}) async {
  if (files != null && files.isNotEmpty) {
    await ApiClient.instance.postMultipart(
      '/announcements.php',
      data: {
        'announcement_id': announcementId,
        'title': title,
        'content': content,
      },
      files: files,
    );
  } else {
    await ApiClient.instance.put(
      '/announcements.php',
      data: {
        'announcement_id': announcementId,
        'title': title,
        'content': content,
      },
    );
  }
}

  /* =======================================================
     DELETE ANNOUNCEMENT
  ======================================================== */
Future<void> delete(String announcementId) async {
  await ApiClient.instance.delete(
    '/announcements.php',
    data: {
      'announcement_id': announcementId,
    },
  );
}
}



