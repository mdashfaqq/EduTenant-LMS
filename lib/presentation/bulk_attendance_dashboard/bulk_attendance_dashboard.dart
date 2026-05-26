import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/sync_status_badge.dart';
import '../../services/api/session_service.dart';
import '../../services/api/courses_service.dart';
import '../../services/api/attendance_service.dart';
import './widgets/attendance_filters_widget.dart';
import './widgets/daily_attendance_view.dart';
import './widgets/monthly_attendance_view.dart';
import './widgets/weekly_attendance_view.dart';

/// Bulk Attendance Dashboard Screen
/// Provides comprehensive attendance management for administrators and instructors
class BulkAttendanceDashboard extends StatefulWidget {
  const BulkAttendanceDashboard({super.key});

  @override
  State<BulkAttendanceDashboard> createState() =>
      _BulkAttendanceDashboardState();
}

class _BulkAttendanceDashboardState extends State<BulkAttendanceDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentBottomNavIndex = 2;
  String _selectedClass = 'all';
  String _selectedDepartment = 'all';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _loadError;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic> _attendanceData = {
    'classes': <Map<String, dynamic>>[],
    'students': <Map<String, dynamic>>[],
    'weeklyStats': {
      'totalClasses': 0,
      'markedClasses': 0,
      'unmarkedClasses': 0,
      'averageAttendance': 0.0,
    },
    'monthlyStats': {
      'totalDays': 0,
      'presentDays': 0,
      'absentDays': 0,
      'averageAttendance': 0.0,
      'trendData': <Map<String, dynamic>>[],
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAttendanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }Future<void> _loadAttendanceData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      // 1️⃣ Session
      await SessionService.instance.init();
      final user = SessionService.instance.currentUser ?? {};
      final instructorId = user['id'];

      if (instructorId == null) {
        throw Exception('Instructor not found');
      }

      // 2️⃣ Courses
      final courses = await CoursesService.instance.listCourses();
      _courses = courses;

      if (courses.isEmpty) {
        throw Exception('No courses assigned');
      }

      _selectedClass ??= courses.first['title'];
      final selectedCourse = courses.firstWhere(
            (c) => c['title'] == _selectedClass,
        orElse: () => courses.first,
      );

      final int courseId = selectedCourse['id'];

// 3️⃣ ATTENDANCE = STUDENTS + STATUS
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
     final enrolledStudents =
    await CoursesService.instance.listCourseStudents(courseId);

      final attendance = await AttendanceService.instance.listAttendance(
        courseId: courseId,
        startDate: date,
        endDate: date,
      );

// Already includes all students
final students = enrolledStudents.map<Map<String, dynamic>>((s) {
  final record = attendance.firstWhere(
    (a) => a['student_id'] == s['id'],
    orElse: () => {},
  );

  return {
    'id': s['id'],
    'name': s['name'],
    'rollNumber': 'STU${s['id']}',
    'class': selectedCourse['title'],
    'status': record['status'] ?? 'absent',
    'weeklyPattern': <bool>[],
    'monthlyRate': 0.0,
  };
}).toList();



      // 7️⃣ Stats
      final total = students.length;
      final present =
          students.where((s) => s['status'] == 'present').length;
      final absent =
          students.where((s) => s['status'] == 'absent').length;

      final attendanceRate =
      total == 0 ? 0.0 : (present / total) * 100;

      // 8️⃣ UI Update
      setState(() {
        _attendanceData = {
          'classes': [
            {
              'name': selectedCourse['title'],
              'department': selectedCourse['department'] ?? '',
              'instructor': user['name'] ?? 'Instructor',
              'totalStudents': total,
              'present': present,
              'absent': absent,
              'attendanceRate': attendanceRate,
            }
          ],
          'students': students,
          'weeklyStats': {
            'totalClasses': 1,
            'markedClasses': attendance.isEmpty ? 0 : 1,
            'unmarkedClasses': attendance.isEmpty ? 1 : 0,
            'averageAttendance': attendanceRate,
          },
          'monthlyStats': {
            'totalDays': 0,
            'presentDays': 0,
            'absentDays': 0,
            'averageAttendance': 0.0,
            'trendData': [],
          },
        };
      });
    } catch (e) {
      setState(() => _loadError = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _handleFilterChange({
    String? classFilter,
    String? departmentFilter,
    DateTime? dateFilter,
  }) {
    setState(() {
      if (classFilter != null) _selectedClass = classFilter;
      if (departmentFilter != null) _selectedDepartment = departmentFilter;
      if (dateFilter != null) _selectedDate = dateFilter;
    });
    _loadAttendanceData();
  }

  Future<void> _handleCSVImport() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Importing attendance from ${result.files.first.name}',
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        _loadAttendanceData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to import CSV file'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleBulkMarkAll(String status) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Action'),
        content: Text(
          'Mark all students as $status for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                for (var student in _attendanceData['students']) {
                  student['status'] = status;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Marked all students as $status'),
                  backgroundColor: const Color(0xFF059669),
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _handleExportReport() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Attendance Report',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generating PDF report...'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generating CSV report...'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Export as Excel'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generating Excel report...'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navVariant = bottomBarVariantFromRole(
      SessionService.instance.currentUser?['role']?.toString(),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Bulk Attendance',
        variant: AppBarVariant.standard,
      ),
      body: Column(
        children: [
          const SyncStatusBadge(showTimestamp: true, compact: false),
          AttendanceFiltersWidget(
            selectedClass: _selectedClass,
            selectedDepartment: _selectedDepartment,
            selectedDate: _selectedDate,
            classOptions: [
              'all',
              ..._courses
                  .map((c) => c['title']?.toString() ?? '')
                  .where((title) => title.isNotEmpty),
            ].toSet().toList(),
            departmentOptions: [
              'all',
              ..._courses
                  .map((c) => c['department']?.toString() ?? '')
                  .where((dept) => dept.isNotEmpty),
            ].toSet().toList(),
            onFilterChange: _handleFilterChange,
          ),

          // Tab Bar
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              tabs: const [
                Tab(text: 'Daily', icon: Icon(Icons.today, size: 20)),
                Tab(text: 'Weekly', icon: Icon(Icons.date_range, size: 20)),
                Tab(
                  text: 'Monthly',
                  icon: Icon(Icons.calendar_month, size: 20),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      DailyAttendanceView(
                        attendanceData: _attendanceData,
                        selectedDate: _selectedDate,
                        onMarkAll: _handleBulkMarkAll,
                        onRefresh: _loadAttendanceData,
                      ),
                      WeeklyAttendanceView(
                        attendanceData: _attendanceData,
                        selectedDate: _selectedDate,
                        onRefresh: _loadAttendanceData,
                      ),
                      MonthlyAttendanceView(
                        attendanceData: _attendanceData,
                        selectedDate: _selectedDate,
                        onRefresh: _loadAttendanceData,
                      ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        variant: BottomBarVariant.instructor,
      ),

    );
  }
}
