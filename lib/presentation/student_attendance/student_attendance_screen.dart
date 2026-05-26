import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/sync_status_badge.dart';
import '../../services/api/attendance_service.dart';
import '../../services/api/session_service.dart';
import '../../utils/role_utils.dart';

/// Student Attendance Screen
/// Displays attendance percentage (read-only)
class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  bool _isLoading = false;
  String? _error;

  double _overallPercentage = 0.0;
  List<Map<String, dynamic>> _courseStats = [];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await SessionService.instance.init();
      final studentId = SessionService.instance.currentUser?['id'];

      if (studentId == null) {
        throw Exception('Student not logged in');
      }

final records =
    await AttendanceService.instance.listStudentAttendance(
  studentId: studentId,
);

      if (records.isEmpty) {
        setState(() {
          _overallPercentage = 0;
          _courseStats = [];
        });
        return;
      }

      // Group attendance by course
      final Map<int, List<Map<String, dynamic>>> byCourse = {};

      for (final r in records) {
        final courseId = r['course_id'] as int;
        byCourse.putIfAbsent(courseId, () => []).add(r);
      }

      final total = records.length;
      final present =
          records.where((r) => r['status'] == 'present').length;

      final overall =
          total == 0 ? 0.0 : (present / total) * 100;

      final courseStats = byCourse.entries.map((entry) {
        final totalClasses = entry.value.length;
        final presentCount =
            entry.value.where((r) => r['status'] == 'present').length;

        return {
          'course_id': entry.key,
          'course_name':
              entry.value.first['course_title'] ?? 'Course',
          'percentage': totalClasses == 0
              ? 0.0
              : (presentCount / totalClasses) * 100,
        };
      }).toList();

      setState(() {
        _overallPercentage = overall;
        _courseStats = courseStats;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'My Attendance',
        variant: AppBarVariant.standard,
      ),
      body: Column(
        children: [
          const SyncStatusBadge(showTimestamp: true, compact: false),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.all(4.w),
                        children: [
                          _OverallAttendanceCard(
                            percentage: _overallPercentage,
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Course-wise Attendance',
                            style: theme.textTheme.titleMedium,
                          ),
                          SizedBox(height: 2.h),
                          ..._courseStats.map(
                            (course) => _CourseAttendanceCard(
                              title: course['course_name'],
                              percentage: course['percentage'],
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        variant: BottomBarVariant.student,
      ),
    );
  }
}

/// Overall attendance percentage card
class _OverallAttendanceCard extends StatelessWidget {
  final double percentage;

  const _OverallAttendanceCard({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Column(
          children: [
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Overall Attendance'),
          ],
        ),
      ),
    );
  }
}

/// Course-wise attendance card
class _CourseAttendanceCard extends StatelessWidget {
  final String title;
  final double percentage;

  const _CourseAttendanceCard({
    required this.title,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: const Icon(Icons.school_outlined),
        title: Text(title),
        trailing: Text(
          '${percentage.toStringAsFixed(0)}%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
