/// Institution Model for SQLite database
class InstitutionModel {
  final int? id;
  final String institutionCode;
  final String name;
  final String? logo;
  final String? address;
  final String? contactEmail;
  final String? contactPhone;
  final String subscriptionStatus;
  final String? subscriptionExpiry;
  final int userCount;
  final int userLimit;
  final String? academicYear;
  final String? primaryColor;
  final bool modulesCourses;
  final bool modulesAssignments;
  final bool modulesGrades;
  final bool modulesAttendance;
  final bool modulesFees;
  final bool modulesDiscussions;
  final bool modulesExams;
  final String? createdDate;
  final String? lastModified;
  final int syncStatus;
  final String? lastSync;

  InstitutionModel({
    this.id,
    required this.institutionCode,
    required this.name,
    this.logo,
    this.address,
    this.contactEmail,
    this.contactPhone,
    this.subscriptionStatus = 'active',
    this.subscriptionExpiry,
    this.userCount = 0,
    this.userLimit = 1000,
    this.academicYear,
    this.primaryColor,
    this.modulesCourses = true,
    this.modulesAssignments = true,
    this.modulesGrades = true,
    this.modulesAttendance = true,
    this.modulesFees = true,
    this.modulesDiscussions = true,
    this.modulesExams = true,
    this.createdDate,
    this.lastModified,
    this.syncStatus = 0,
    this.lastSync,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institution_code': institutionCode,
      'name': name,
      'logo': logo,
      'address': address,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'subscription_status': subscriptionStatus,
      'subscription_expiry': subscriptionExpiry,
      'user_count': userCount,
      'user_limit': userLimit,
      'academic_year': academicYear,
      'primary_color': primaryColor,
      'modules_courses': modulesCourses ? 1 : 0,
      'modules_assignments': modulesAssignments ? 1 : 0,
      'modules_grades': modulesGrades ? 1 : 0,
      'modules_attendance': modulesAttendance ? 1 : 0,
      'modules_fees': modulesFees ? 1 : 0,
      'modules_discussions': modulesDiscussions ? 1 : 0,
      'modules_exams': modulesExams ? 1 : 0,
      'created_date': createdDate,
      'last_modified': lastModified,
      'sync_status': syncStatus,
      'last_sync': lastSync,
    };
  }

  factory InstitutionModel.fromMap(Map<String, dynamic> map) {
    return InstitutionModel(
      id: map['id'] as int?,
      institutionCode: map['institution_code'] as String,
      name: map['name'] as String,
      logo: map['logo'] as String?,
      address: map['address'] as String?,
      contactEmail: map['contact_email'] as String?,
      contactPhone: map['contact_phone'] as String?,
      subscriptionStatus: map['subscription_status'] as String? ?? 'active',
      subscriptionExpiry: map['subscription_expiry'] as String?,
      userCount: map['user_count'] as int? ?? 0,
      userLimit: map['user_limit'] as int? ?? 1000,
      academicYear: map['academic_year'] as String?,
      primaryColor: map['primary_color'] as String?,
      modulesCourses: (map['modules_courses'] as int? ?? 1) == 1,
      modulesAssignments: (map['modules_assignments'] as int? ?? 1) == 1,
      modulesGrades: (map['modules_grades'] as int? ?? 1) == 1,
      modulesAttendance: (map['modules_attendance'] as int? ?? 1) == 1,
      modulesFees: (map['modules_fees'] as int? ?? 1) == 1,
      modulesDiscussions: (map['modules_discussions'] as int? ?? 1) == 1,
      modulesExams: (map['modules_exams'] as int? ?? 1) == 1,
      createdDate: map['created_date'] as String?,
      lastModified: map['last_modified'] as String?,
      syncStatus: map['sync_status'] as int? ?? 0,
      lastSync: map['last_sync'] as String?,
    );
  }
}
