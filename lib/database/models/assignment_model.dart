/// Assignment Model for SQLite database
class AssignmentModel {
  final int? id;
  final String institutionCode;
  final String assignmentId;
  final int courseId;
  final String title;
  final String? description;
  final String? type;
  final int? totalPoints;
  final String? dueDate;
  final String? submissionType;
  final String status;
  final int? createdBy;
  final String? createdDate;
  final String? lastModified;
  final int syncStatus;
  final String? lastSync;

  AssignmentModel({
    this.id,
    required this.institutionCode,
    required this.assignmentId,
    required this.courseId,
    required this.title,
    this.description,
    this.type,
    this.totalPoints,
    this.dueDate,
    this.submissionType,
    this.status = 'active',
    this.createdBy,
    this.createdDate,
    this.lastModified,
    this.syncStatus = 0,
    this.lastSync,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institution_code': institutionCode,
      'assignment_id': assignmentId,
      'course_id': courseId,
      'title': title,
      'description': description,
      'type': type,
      'total_points': totalPoints,
      'due_date': dueDate,
      'submission_type': submissionType,
      'status': status,
      'created_by': createdBy,
      'created_date': createdDate,
      'last_modified': lastModified,
      'sync_status': syncStatus,
      'last_sync': lastSync,
    };
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map) {
    return AssignmentModel(
      id: map['id'] as int?,
      institutionCode: map['institution_code'] as String,
      assignmentId: map['assignment_id'] as String,
      courseId: map['course_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      type: map['type'] as String?,
      totalPoints: map['total_points'] as int?,
      dueDate: map['due_date'] as String?,
      submissionType: map['submission_type'] as String?,
      status: map['status'] as String? ?? 'active',
      createdBy: map['created_by'] as int?,
      createdDate: map['created_date'] as String?,
      lastModified: map['last_modified'] as String?,
      syncStatus: map['sync_status'] as int? ?? 0,
      lastSync: map['last_sync'] as String?,
    );
  }
}
