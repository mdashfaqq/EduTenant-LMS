/// Discussion Post Model for SQLite database
class DiscussionPostModel {
  final int? id;
  final String institutionCode;
  final String postId;
  final int? courseId;
  final int authorId;
  final String title;
  final String content;
  final String? category;
  final String? tags;
  final bool isPinned;
  final bool isLocked;
  final int viewsCount;
  final int likesCount;
  final int repliesCount;
  final String? createdDate;
  final String? lastModified;
  final int syncStatus;
  final String? lastSync;

  DiscussionPostModel({
    this.id,
    required this.institutionCode,
    required this.postId,
    this.courseId,
    required this.authorId,
    required this.title,
    required this.content,
    this.category,
    this.tags,
    this.isPinned = false,
    this.isLocked = false,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.createdDate,
    this.lastModified,
    this.syncStatus = 0,
    this.lastSync,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institution_code': institutionCode,
      'post_id': postId,
      'course_id': courseId,
      'author_id': authorId,
      'title': title,
      'content': content,
      'category': category,
      'tags': tags,
      'is_pinned': isPinned ? 1 : 0,
      'is_locked': isLocked ? 1 : 0,
      'views_count': viewsCount,
      'likes_count': likesCount,
      'replies_count': repliesCount,
      'created_date': createdDate,
      'last_modified': lastModified,
      'sync_status': syncStatus,
      'last_sync': lastSync,
    };
  }

  factory DiscussionPostModel.fromMap(Map<String, dynamic> map) {
    return DiscussionPostModel(
      id: map['id'] as int?,
      institutionCode: map['institution_code'] as String,
      postId: map['post_id'] as String,
      courseId: map['course_id'] as int?,
      authorId: map['author_id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String?,
      tags: map['tags'] as String?,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      isLocked: (map['is_locked'] as int? ?? 0) == 1,
      viewsCount: map['views_count'] as int? ?? 0,
      likesCount: map['likes_count'] as int? ?? 0,
      repliesCount: map['replies_count'] as int? ?? 0,
      createdDate: map['created_date'] as String?,
      lastModified: map['last_modified'] as String?,
      syncStatus: map['sync_status'] as int? ?? 0,
      lastSync: map['last_sync'] as String?,
    );
  }
}
