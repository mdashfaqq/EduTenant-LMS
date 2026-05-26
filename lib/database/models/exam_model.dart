/// Exam Model for SQLite database
class ExamModel {
  final int? id;
  final String institutionCode;
  final String examId;
  final int courseId;
  final String title;
  final String? description;
  final String? examDate;
  final String? startTime;
  final String? endTime;
  final int? duration;
  final int? totalMarks;
  final int? passingMarks;
  final String? examType;
  final String? room;
  final String status;
  final int? createdBy;
  final String? createdDate;
  final int syncStatus;
  final String? lastSync;

  ExamModel({
    this.id,
    required this.institutionCode,
    required this.examId,
    required this.courseId,
    required this.title,
    this.description,
    this.examDate,
    this.startTime,
    this.endTime,
    this.duration,
    this.totalMarks,
    this.passingMarks,
    this.examType,
    this.room,
    this.status = 'scheduled',
    this.createdBy,
    this.createdDate,
    this.syncStatus = 0,
    this.lastSync,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institution_code': institutionCode,
      'exam_id': examId,
      'course_id': courseId,
      'title': title,
      'description': description,
      'exam_date': examDate,
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'total_marks': totalMarks,
      'passing_marks': passingMarks,
      'exam_type': examType,
      'room': room,
      'status': status,
      'created_by': createdBy,
      'created_date': createdDate,
      'sync_status': syncStatus,
      'last_sync': lastSync,
    };
  }

  factory ExamModel.fromMap(Map<String, dynamic> map) {
    return ExamModel(
      id: map['id'] as int?,
      institutionCode: map['institution_code'] as String,
      examId: map['exam_id'] as String,
      courseId: map['course_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      examDate: map['exam_date'] as String?,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      duration: map['duration'] as int?,
      totalMarks: map['total_marks'] as int?,
      passingMarks: map['passing_marks'] as int?,
      examType: map['exam_type'] as String?,
      room: map['room'] as String?,
      status: map['status'] as String? ?? 'scheduled',
      createdBy: map['created_by'] as int?,
      createdDate: map['created_date'] as String?,
      syncStatus: map['sync_status'] as int? ?? 0,
      lastSync: map['last_sync'] as String?,
    );
  }
}
