/// User Model for SQLite database
class UserModel {
  final int? id;
  final String institutionCode;
  final String userId;
  final String name;
  final String email;
  final String role;
  final String? department;
  final String status;
  final String? avatar;
  final String? phone;
  final String? dateOfBirth;
  final String? address;
  final String? lastActivity;
  final String? joinDate;
  final int coursesTeaching;
  final int studentsManaged;
  final int coursesEnrolled;
  final double? gpa;
  final int? parentId;
  final int syncStatus;
  final String? lastSync;

  UserModel({
    this.id,
    required this.institutionCode,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.status = 'active',
    this.avatar,
    this.phone,
    this.dateOfBirth,
    this.address,
    this.lastActivity,
    this.joinDate,
    this.coursesTeaching = 0,
    this.studentsManaged = 0,
    this.coursesEnrolled = 0,
    this.gpa,
    this.parentId,
    this.syncStatus = 0,
    this.lastSync,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institution_code': institutionCode,
      'user_id': userId,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'status': status,
      'avatar': avatar,
      'phone': phone,
      'date_of_birth': dateOfBirth,
      'address': address,
      'last_activity': lastActivity,
      'join_date': joinDate,
      'courses_teaching': coursesTeaching,
      'students_managed': studentsManaged,
      'courses_enrolled': coursesEnrolled,
      'gpa': gpa,
      'parent_id': parentId,
      'sync_status': syncStatus,
      'last_sync': lastSync,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      institutionCode: map['institution_code'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: map['role'] as String,
      department: map['department'] as String?,
      status: map['status'] as String? ?? 'active',
      avatar: map['avatar'] as String?,
      phone: map['phone'] as String?,
      dateOfBirth: map['date_of_birth'] as String?,
      address: map['address'] as String?,
      lastActivity: map['last_activity'] as String?,
      joinDate: map['join_date'] as String?,
      coursesTeaching: map['courses_teaching'] as int? ?? 0,
      studentsManaged: map['students_managed'] as int? ?? 0,
      coursesEnrolled: map['courses_enrolled'] as int? ?? 0,
      gpa: map['gpa'] as double?,
      parentId: map['parent_id'] as int?,
      syncStatus: map['sync_status'] as int? ?? 0,
      lastSync: map['last_sync'] as String?,
    );
  }
}
