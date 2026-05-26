import '../presentation/course_attendance/course_attendance_page.dart';
import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/discussion_forum/discussion_forum.dart';
import '../presentation/instructor_dashboard/instructor_dashboard.dart';
import '../presentation/grade_management/grade_management.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/profile_settings/profile_settings.dart';
import '../presentation/assignment_detail/assignment_detail.dart';
import '../presentation/institution_setup/institution_setup.dart';
import '../presentation/student_dashboard/student_dashboard.dart';
import '../presentation/course_list/course_list.dart';
import '../presentation/attendance_management/attendance_management.dart';
import '../presentation/fees_management/fees_management.dart';
import '../presentation/user_management/user_management.dart';
import '../presentation/institution_management/institution_management.dart';
import '../presentation/exams_results/exams_results.dart';
import '../presentation/admin_course_management/admin_course_management.dart';
import '../presentation/cash_payment_management/cash_payment_management.dart';
import '../presentation/bulk_attendance_dashboard/bulk_attendance_dashboard.dart';
import '../presentation/role_access_management/role_access_management.dart';
import '../presentation/platform_admin_dashboard/platform_admin_dashboard.dart';
import '../presentation/admin_dashboard/admin_dashboard_page.dart';
import '../presentation/student_attendance/student_attendance_screen.dart';
import '../presentation/course_attendance/course_attendance_page.dart';
import '../presentation/coursedetailpage.dart';
import '../presentation/create-announcement.dart';
import'../presentation/student_report/student_full_report_screen.dart';
import '../services/api/session_service.dart';
import '../presentation/progress_management/course_progress_page.dart';
import '../presentation/course_attendance/student_attendance_page.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String discussionForum = '/discussion-forum';
  static const String instructorDashboard = '/instructor-dashboard';
  static const String gradeManagement = '/grade-management';
  static const String login = '/login-screen';
  static const String profileSettings = '/profile-settings';
  static const String assignmentDetail = '/assignment-detail';
  static const String institutionSetup = '/institution-setup';
  static const String studentDashboard = '/student-dashboard';
  static const String courseList = '/course-list';
  static const String attendanceManagement = '/attendance-management';
  static const String feesManagement = '/fees-management';
  static const String userManagement = '/user-management';
  static const String institutionManagement = '/institution-management';
  static const String examsResults = '/exams-results';
  static const String adminCourseManagement = '/admin-course-management';
  static const String cashPaymentManagement = '/cash-payment-management';
  static const String bulkAttendanceDashboard = '/bulk-attendance-dashboard';
  static const String roleAccessManagement = '/role-access-management';
  static const String platformAdminDashboard = '/platform-admin-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String studentAttendance = '/student-attendance-page';
static const String courseAttendance = '/course-attendance';
static const String courseDetail = '/course-detail';
static const String createAnnouncement = '/create-announcement';
static const String studentFullReportScreen = '/student-full-report-screen';
static const String courseProgress = '/course-progress-page';
// static const studentAttendance = '/student-attendance';


  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    discussionForum: (context) => const DiscussionForum(),
    instructorDashboard: (context) => const InstructorDashboard(),
    gradeManagement: (context) => const GradeManagement(),
    login: (context) => const LoginScreen(),
    profileSettings: (context) => const ProfileSettings(),
    assignmentDetail: (context) => const AssignmentDetail(),
    institutionSetup: (context) => const InstitutionSetup(),
    studentDashboard: (context) => const StudentDashboard(),
    courseList: (context) => const CourseList(),
    attendanceManagement: (context) => const AttendanceManagement(),
    feesManagement: (context) => const FeesManagement(),
    userManagement: (context) => const UserManagement(),
    institutionManagement: (context) => const InstitutionManagement(),
    examsResults: (context) => const ExamsResults(),
    adminCourseManagement: (context) => const AdminCourseManagement(),
    cashPaymentManagement: (context) => const CashPaymentManagement(),
    bulkAttendanceDashboard: (context) => const BulkAttendanceDashboard(),
    roleAccessManagement: (context) => const RoleAccessManagement(),
    platformAdminDashboard: (context) => const PlatformAdminDashboard(),
    adminDashboard: (context) => const AdminDashboardPage(),
    studentAttendance: (context) => const StudentAttendanceScreen(),
   courseAttendance: (context) => const CourseAttendancePage(),
courseDetail: (context) => const CourseDetailPage(),
createAnnouncement: (context) => const CreateAnnouncementPage(),
studentFullReportScreen: (context) {
  final studentId =
      SessionService.instance.currentUser?['id'];

  return StudentFullReportScreen(
    studentId: studentId,
  );
},
courseProgress: (context) => const CourseProgressPage(),
studentAttendance: (context) =>
    const StudentAttendancePage(),
  };
}
