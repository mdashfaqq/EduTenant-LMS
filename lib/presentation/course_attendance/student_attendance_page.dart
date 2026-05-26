import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../services/api/courses_service.dart';
import '../../services/api/attendance_service.dart';
import '../../services/api/session_service.dart';

class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({super.key});

  @override
  State<StudentAttendancePage> createState() =>
      _StudentAttendancePageState();
}

class _StudentAttendancePageState
    extends State<StudentAttendancePage> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _courses = [];
  Map<int, Map<String, int>> _summary = {};

  String _fmt(DateTime d) =>
      DateFormat('yyyy-MM-dd').format(d);

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }
Future<void> _loadAttendance() async {
  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    final studentId =
        SessionService.instance.currentUser?['id'];

    if (studentId == null) {
      throw Exception("Student ID not found");
    }

    final courses =
        await CoursesService.instance.listCourses();

    final Map<int, Map<String, int>> summary = {};

    for (var course in courses) {
      final int courseId = course['id'];

      // ✅ Backend requires course_id
      final attendance =
          await AttendanceService.instance.listAttendance(
        courseId: courseId,
        studentId: studentId, // sent but backend doesn't filter
        startDate: '2020-01-01',
        endDate: _fmt(DateTime.now()),
      );

      summary[courseId] = {
        'present': 0,
        'absent': 0,
      };

      // ⚠ Backend returns ALL students in course
      // So we manually filter here
      for (var row in attendance) {
        final rowStudentId = row['student_id'] is int
    ? row['student_id']
    : int.tryParse(row['student_id'].toString());

if (rowStudentId != studentId) continue;

        if (row['status'] == 'present') {
          summary[courseId]!['present'] =
              summary[courseId]!['present']! + 1;
        } else if (row['status'] == 'absent') {
          summary[courseId]!['absent'] =
              summary[courseId]!['absent']! + 1;
        }
      }
    }

    setState(() {
      _courses = courses;
      _summary = summary;
    });
  } catch (e) {
    setState(() => _error = e.toString());
  } finally {
    setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          const CustomAppBar(title: 'My Attendance'),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  padding:
                      EdgeInsets.symmetric(vertical: 2.h),
                  itemCount: _courses.length,
                  itemBuilder: (_, i) {
                    final course = _courses[i];
                    final stats =
                        _summary[course['id']] ??
                            {'present': 0, 'absent': 0};

                    final total =
                        stats['present']! +
                            stats['absent']!;

                    final percent = total == 0
                        ? 0.0
                        : (stats['present']! /
                                total) *
                            100;

                    final isLow = percent < 75;

                    return Card(
                      margin: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.h),
                      child: ListTile(
                        title: Text(course['title']),
                        subtitle: Text(
                          "Present: ${stats['present']} | "
                          "Absent: ${stats['absent']}",
                        ),
                        trailing: Text(
                          "${percent.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color: isLow
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar:
          const CustomBottomBar(
              variant: BottomBarVariant.student),
    );
  }
}