/// Course Model for SQLite database
class CourseModel {
  final int? id;
  final String institutionCode;
  final String courseId;
  final String title;
  final String code;
  final String? description;
  final int? instructorId;
  final String? instructorName;
  final String? category;
  final String? level;
  final int? credits;
  final String? duration;
  final String? startDate;
  final String? endDate;
  final String? schedule;
  final String? room;
  final int? capacity;
  final int enrolledCount;
  final String status;
  final String? thumbnail;
  final String? syllabusUrl;
  final String? createdDate;
  final String? lastModified;
  final int syncStatus;
  final String? lastSync;

  CourseModel({
    this.id,
    required this.institutionCode,
    required this.courseId,
    required this.title,
    required this.code,
    this.description,
    this.instructorId,
    this.instructorName,
    this.category,
    this.level,
    this.credits,
    this.duration,
    this.startDate,
    this.endDate,
    this.schedule,
    this.room,
    this.capacity,
    this.enrolledCount = 0,
    this.status = 'active',
    this.thumbnail,
    this.syllabusUrl,
    this.createdDate,
    this.lastModified,
    this.syncStatus = 0,
    this.lastSync,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institution_code': institutionCode,
      'course_id': courseId,
      'title': title,
      'code': code,
      'description': description,
      'instructor_id': instructorId,
      'instructor_name': instructorName,
      'category': category,
      'level': level,
      'credits': credits,
      'duration': duration,
      'start_date': startDate,
      'end_date': endDate,
      'schedule': schedule,
      'room': room,
      'capacity': capacity,
      'enrolled_count': enrolledCount,
      'status': status,
      'thumbnail': thumbnail,
      'syllabus_url': syllabusUrl,
      'created_date': createdDate,
      'last_modified': lastModified,
      'sync_status': syncStatus,
      'last_sync': lastSync,
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'] as int?,
      institutionCode: map['institution_code'] as String,
      courseId: map['course_id'] as String,
      title: map['title'] as String,
      code: map['code'] as String,
      description: map['description'] as String?,
      instructorId: map['instructor_id'] as int?,
      instructorName: map['instructor_name'] as String?,
      category: map['category'] as String?,
      level: map['level'] as String?,
      credits: map['credits'] as int?,
      duration: map['duration'] as String?,
      startDate: map['start_date'] as String?,
      endDate: map['end_date'] as String?,
      schedule: map['schedule'] as String?,
      room: map['room'] as String?,
      capacity: map['capacity'] as int?,
      enrolledCount: map['enrolled_count'] as int? ?? 0,
      status: map['status'] as String? ?? 'active',
      thumbnail: map['thumbnail'] as String?,
      syllabusUrl: map['syllabus_url'] as String?,
      createdDate: map['created_date'] as String?,
      lastModified: map['last_modified'] as String?,
      syncStatus: map['sync_status'] as int? ?? 0,
      lastSync: map['last_sync'] as String?,
    );
  }
}
