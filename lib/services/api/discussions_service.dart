import 'api_client.dart';

class DiscussionsService {
  DiscussionsService._internal();

  static final DiscussionsService instance = DiscussionsService._internal();

  // Future<List<Map<String, dynamic>>> listPosts({
  //   int? courseId,
  //   String? category,
  //   int? limit,
  //   int? offset,
  // }) async {
  //   final params = <String, dynamic>{};
  //   if (courseId != null) {
  //     params['course_id'] = courseId;
  //   }
  //   if (category != null && category.isNotEmpty && category != 'All') {
  //     params['category'] = category;
  //   }
  //   if (limit != null) {
  //     params['limit'] = limit;
  //   }
  //   if (offset != null) {
  //     params['offset'] = offset;
  //   }

  //   final data = await ApiClient.instance.get(
  //     '/discussions.php',
  //     queryParameters: params.isEmpty ? null : params,
  //   );

  //   final items = (data as List<dynamic>? ?? [])
  //       .cast<Map<String, dynamic>>();
  //   return items.map(_toUiPost).toList();
  // }

Future<void> toggleLike(int postId) async {
  try {
    await ApiClient.instance.post(
      '/discussions.php?like=1',
      data: {
        "post_id": postId,
      },
    );
  } catch (e) {
    throw Exception("Like API failed: $e");
  }
}
Future<List<Map<String, dynamic>>> listPosts({
  int? courseId,
  String? category,
  int? limit,
  int? offset,
}) async {
  final params = <String, dynamic>{};

  if (courseId != null) params['course_id'] = courseId;
  if (category != null && category.isNotEmpty && category != 'All') {
    params['category'] = category;
  }
  if (limit != null) params['limit'] = limit;
  if (offset != null) params['offset'] = offset;

  final data = await ApiClient.instance.get(
    '/discussions.php',
    queryParameters: params.isEmpty ? null : params,
  );

  // ✅ ApiClient already returns the inner data list
  final items = (data as List<dynamic>? ?? []);

  return items
      .cast<Map<String, dynamic>>()
      .map(_toUiPost)
      .toList();
}

  Future<Map<String, dynamic>> createPost(
    Map<String, dynamic> payload,
  ) async {
    final data = await ApiClient.instance.post('/discussions.php', data: payload);
    return _toUiPost(data as Map<String, dynamic>);
  }

Future<Map<String, dynamic>> updatePost(
  int postId,
  Map<String, dynamic> payload,
) async {
  final data = await ApiClient.instance.put(
    '/discussions.php/$postId',
    data: payload,
  );

  return _toUiPost(data as Map<String, dynamic>);
}
Future<void> deletePost(int postId) async {
  await ApiClient.instance.delete(
    '/discussions.php/$postId',
  );
}
  Future<List<Map<String, dynamic>>> listReplies(int postId) async {
    final data = await ApiClient.instance.get('/discussions.php/$postId/replies');
    final items = (data as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return items.map(_toUiReply).toList();
  }

  Future<Map<String, dynamic>> addReply(
    int postId,
    Map<String, dynamic> payload,
  ) async {
    final data = await ApiClient.instance.post(
      '/discussions.php/$postId/replies',
      data: payload,
    );
    return _toUiReply(data as Map<String, dynamic>);
  }

  Map<String, dynamic> _toUiPost(Map<String, dynamic> post) {
    return {
      'id': post['id'],
      'author_id': post['author_id'],
      'title': post['title'] ?? '',
      'content': post['content'] ?? '',
      'author': post['author_name'] ?? 'Unknown',
      'authorAvatar': _avatarOrPlaceholder(post['author_avatar']),
      'authorAvatarLabel': 'Author avatar',
      'timestamp': _parseDate(post['created_date']),
      'replyCount': post['replies_count'] ?? 0,
      'likeCount': post['likes_count'] ?? 0,
      'isLiked': post['is_liked'] ?? false,
      'isBookmarked': false,
      'category': post['category'] ?? 'General',
      'replies': <Map<String, dynamic>>[],
      'isPinned': post['is_pinned'] == 1 || post['is_pinned'] == true,
      'isLocked': post['is_locked'] == 1 || post['is_locked'] == true,
          'courseTitle': post['course_title'],
    };
  }

  Map<String, dynamic> _toUiReply(Map<String, dynamic> reply) {
    return {
      'id': reply['id'],
      'content': reply['content'] ?? '',
      'author': reply['author_name'] ?? 'Unknown',
      'authorAvatar': _avatarOrPlaceholder(reply['author_avatar']),
      'authorAvatarLabel': 'Author avatar',
      'timestamp': _parseDate(reply['created_date']),
      'likeCount': reply['likes_count'] ?? 0,
     'isLiked': reply['is_liked'] ?? false,
    };
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.parse(value.toString()).toLocal();
  }




  String _avatarOrPlaceholder(dynamic value) {
    if (value == null) {
      return 'assets/images/no-image.jpg';
    }
    final avatar = value.toString();
    if (avatar.isEmpty) {
      return 'assets/images/no-image.jpg';
    }
    return avatar;
  }
}
