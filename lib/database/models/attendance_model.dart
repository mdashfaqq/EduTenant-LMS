/// Attendance Model for SQLite database
class AttendanceModel {
  final int? id;
  final String institutionCode;
  final int classId;
  final int studentId;
  final String status;
  final String? markedAt;
  final int? markedBy;
  final String? notes;
  final int syncStatus;
  final String? lastSync;

  AttendanceModel({
    this.id,
    required this.institutionCode,
    required this.classId,
    required this.studentId,
    required this.status,
    this.markedAt,
    this.markedBy,
    this.notes,
    this.syncStatus = 0,
    this.lastSync,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institution_code': institutionCode,
      'class_id': classId,
      'student_id': studentId,
      'status': status,
      'marked_at': markedAt,
      'marked_by': markedBy,
      'notes': notes,
      'sync_status': syncStatus,
      'last_sync': lastSync,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] as int?,
      institutionCode: map['institution_code'] as String,
      classId: map['class_id'] as int,
      studentId: map['student_id'] as int,
      status: map['status'] as String,
      markedAt: map['marked_at'] as String?,
      markedBy: map['marked_by'] as int?,
      notes: map['notes'] as String?,
      syncStatus: map['sync_status'] as int? ?? 0,
      lastSync: map['last_sync'] as String?,
    );
  }
}
