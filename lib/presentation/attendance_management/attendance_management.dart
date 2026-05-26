import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/sync_status_badge.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../services/api/attendance_service.dart';
import '../../services/api/courses_service.dart';
import '../../services/api/session_service.dart';
import './widgets/attendance_header_widget.dart';
import './widgets/student_attendance_card.dart';
import './widgets/attendance_statistics_widget.dart';
import './widgets/quick_mark_actions_widget.dart';

/// Attendance Management Screen
/// Enables instructors to efficiently track and manage student attendance
class AttendanceManagement extends StatefulWidget {
  const AttendanceManagement({super.key});

  @override
  State<AttendanceManagement> createState() => _AttendanceManagementState();
}

class _AttendanceManagementState extends State<AttendanceManagement> {
  int _currentBottomNavIndex = 2;
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _selectedCourse;
  int? _currentCourseId; // TEMP: course_id used as class_id

  bool _isLoading = false;
  bool _isSyncing = false;
  String? _loadError;
  List<Map<String, dynamic>> _courses = [];

  Map<String, dynamic> _attendanceData = {
    "classDetails": {
      "courseName": "Class",
      "courseCode": "N/A",
      "section": "N/A",
      "course_id":null,
      "time": "TBD",
      "room": "TBD",
    },
    "statistics": {
      "totalStudents": 0,
      "present": 0,
      "absent": 0,
      "late": 0,
      "excused": 0,
      "attendanceRate": 0.0,
    },
    "students": <Map<String, dynamic>>[],
  };

  @override
  void initState() {
    super.initState();
    
    _loadAttendanceData();
  }
  

  Future<void> _loadAttendanceData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      // 1️⃣ Session
      await SessionService.instance.init();

      // 2️⃣ Courses
      final courses = await CoursesService.instance.listCourses();
      _courses = courses;

      if (courses.isEmpty) {
        throw Exception('No courses assigned to you yet.');
      }

      // 3️⃣ Selected course
      _selectedCourse ??= courses.first;
      final int courseId = _selectedCourse!['id'];
      _currentCourseId = courseId;

      // 4️⃣ Attendance = STUDENTS + STATUS
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final enrolledStudents =
    await CoursesService.instance.listCourseStudents(courseId);

      final records = await AttendanceService.instance.listAttendance(
        courseId: courseId,
        startDate: date,
      );

      debugPrint('================ ATTENDANCE API DEBUG ================');
      debugPrint('Course ID: $courseId');
      debugPrint('Date: $date');
      debugPrint('Records type: ${records.runtimeType}');
      debugPrint('Records length: ${records.length}');
      debugPrint('Records raw data: $records');
      debugPrint('======================================================');


final students = enrolledStudents.map<Map<String, dynamic>>((s) {
  final record = records.firstWhere(
    (r) => r['student_id'] == s['id'],
    orElse: () => {},
  );

  return {
    'id': s['id'],
    'name': s['name'],
    'rollNumber': 'STU${s['id']}',
    'avatar': 'assets/images/no-image.jpg',
    'semanticLabel': 'Student avatar',
    'status': record['status'] ?? 'absent', // 👈 DEFAULT
    'attendancePattern': <bool>[],
    'attendanceRate': 0.0,
  };
}).toList();


      // 5️⃣ Statistics
      final total = students.length;
      final present = students.where((s) => s['status'] == 'present').length;
      final absent = students.where((s) => s['status'] == 'absent').length;
      final late = students.where((s) => s['status'] == 'late').length;
      final excused = students.where((s) => s['status'] == 'excused').length;

      final attendanceRate =
      total == 0 ? 0.0 : ((present + late) / total * 100);

      if (!mounted) return;

      setState(() {
        _attendanceData = {
          'classDetails': {
            'courseName': _selectedCourse!['title'],
            'courseCode': _selectedCourse!['courseCode'] ?? 'N/A',
            'course_id': courseId,
            'section': 'N/A',
            'time': 'TBD',
            'room': 'TBD',
          },
          'statistics': {
            'totalStudents': total,
            'present': present,
            'absent': absent,
            'late': late,
            'excused': excused,
            'attendanceRate': attendanceRate,
          },
          'students': students,
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }


  void _handleDateChange(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
    HapticFeedback.selectionClick();
    _loadAttendanceData();
  }

  void _handleCourseChange(Map<String, dynamic>? course) {
    setState(() {
      _selectedCourse = course;
      _currentCourseId
      = course?['id'] as int?;
    });
    HapticFeedback.selectionClick();
    _loadAttendanceData();
  }

  Future<void> _handleAttendanceToggle(
    int studentId,
    String newStatus,
  ) async {
    final classId = _currentCourseId
    ;
    if (classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class ID is missing.')),
      );
      return;
    }

    final currentUser = SessionService.instance.currentUser;
    final markedBy = currentUser?['id'];

    try {
await AttendanceService.instance.markAttendance({
'course_id': _currentCourseId,

  'student_id': studentId,
  'status': newStatus,
  'marked_by': SessionService.instance.currentUser?['id'],
});

      if (!mounted) return;
      setState(() {
        final studentIndex = (_attendanceData['students'] as List).indexWhere(
          (s) => s['id'] == studentId,
        );
        if (studentIndex != -1) {
          _attendanceData['students'][studentIndex]['status'] = newStatus;
          _updateStatistics();
        }
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark attendance: $e')),
      );
    }
  }

  void _updateStatistics() {
    final students = _attendanceData['students'] as List;
    final present = students.where((s) => s['status'] == 'present').length;
    final absent = students.where((s) => s['status'] == 'absent').length;
    final late = students.where((s) => s['status'] == 'late').length;
    final excused = students.where((s) => s['status'] == 'excused').length;

    setState(() {
      _attendanceData['statistics']['present'] = present;
      _attendanceData['statistics']['absent'] = absent;
      _attendanceData['statistics']['late'] = late;
      _attendanceData['statistics']['excused'] = excused;
      _attendanceData['statistics']['attendanceRate'] =
          ((present + late) / students.length * 100).roundToDouble();
    });
  }

  void _handleQuickMarkAll(String status) {
    final classId = _currentCourseId
    ;
    if (classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class ID is missing.')),
      );
      return;
    }

    final currentUser = SessionService.instance.currentUser;
    final markedBy = currentUser?['id'];
    final students = List<Map<String, dynamic>>.from(
      _attendanceData['students'] as List,
    );

    AttendanceService.instance.bulkMarkAttendance({
      'class_id': classId,
      'marked_by': markedBy,
      'attendance_list': students
          .map(
            (student) => {
              'student_id': student['id'],
              'status': status,
            },
          )
          .toList(),
    }).then((_) {
      if (!mounted) return;
      setState(() {
        for (var student in _attendanceData['students']) {
          student['status'] = status;
        }
        _updateStatistics();
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked all students as ${status.toUpperCase()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bulk update failed: $error')),
      );
    });
  }

  void _handleBulkMarkByPeriod(String period) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk Mark - ${period.toUpperCase()}'),
        content: Text(
          'This will mark attendance for all students for the selected $period period. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bulk $period attendance marked successfully'),
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    HapticFeedback.mediumImpact();

    await _loadAttendanceData();

    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance synced successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleExportReport() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Attendance Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting PDF...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting CSV...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == _currentBottomNavIndex) return;

    setState(() => _currentBottomNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Attendance Management',
        variant: AppBarVariant.standard,
      ),
      body: Column(
        children: [
          const SyncStatusBadge(showTimestamp: true, compact: false),
          if (_courses.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: DropdownButtonFormField<int>(
                value: _selectedCourse?['id'] as int?,
                decoration: const InputDecoration(
                  labelText: 'Course',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: _courses
                    .map(
                      (course) => DropdownMenuItem<int>(
                        value: course['id'] as int?,
                        child: Text(
                          '${course['title'] ?? 'Course'} (${course['courseCode'] ?? ''})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  final course = _courses.firstWhere(
                    (c) => c['id'] == value,
                    orElse: () => {},
                  );
                  _handleCourseChange(course.isEmpty ? null : course);
                },
              ),
            ),
          if (_courses.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Text(
                'No courses found for your account.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          AttendanceHeaderWidget(
            classDetails:
                _attendanceData['classDetails'] as Map<String, dynamic>,
            selectedDate: _selectedDate,
            onDateChange: _handleDateChange,
          ),
          AttendanceStatisticsWidget(
            statistics: _attendanceData['statistics'] as Map<String, dynamic>,
          ),
          SizedBox(height: 2.h) as Widget,
          QuickMarkActionsWidget(
            onMarkAll: _handleQuickMarkAll,
            onBulkMarkByPeriod: _handleBulkMarkByPeriod,
          ),
          SizedBox(height: 2.h) as Widget,
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Text(
                        _loadError!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    itemCount: _attendanceData['students'].length,
                    itemBuilder: (context, index) {
                      final student = _attendanceData['students'][index];
                      return StudentAttendanceCard(
                        student: student,
                        onStatusChange: (newStatus) {
                          _handleAttendanceToggle(student['id'], newStatus);
                        },
                      );
                    },
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
