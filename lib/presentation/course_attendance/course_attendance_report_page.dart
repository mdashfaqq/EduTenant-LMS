import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../services/api/attendance_service.dart';
import '../../services/api/courses_service.dart';

class CourseAttendanceReportPage extends StatefulWidget {
  final int courseId;

  const CourseAttendanceReportPage({
    super.key,
    required this.courseId,
  });

  @override
  State<CourseAttendanceReportPage> createState() =>
      _CourseAttendanceReportPageState();
}

class _CourseAttendanceReportPageState
    extends State<CourseAttendanceReportPage> {
  bool _loading = true;
  String? _error;

  DateTime _startDate =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  List<Map<String, dynamic>> _students = [];
  Map<int, Map<String, int>> _summary = {};

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final enrolled =
          await CoursesService.instance.listCourseStudents(
        widget.courseId,
      );

      final attendance =
          await AttendanceService.instance.listAttendance(
        courseId: widget.courseId,
        startDate: _fmt(_startDate),
        endDate: _fmt(_endDate),
      );

      final Map<int, Map<String, int>> summary = {};

      for (var s in enrolled) {
        summary[s['id']] = {
          'present': 0,
          'absent': 0,
        };
      }

      for (var row in attendance) {
        final id = row['student_id'];
        final status = row['status'];

        if (!summary.containsKey(id)) continue;

        if (status == 'present') {
          summary[id]!['present'] =
              summary[id]!['present']! + 1;
        } else if (status == 'absent') {
          summary[id]!['absent'] =
              summary[id]!['absent']! + 1;
        }
      }

      setState(() {
        _students = enrolled;
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
      appBar: const CustomAppBar(title: 'Attendance Report'),
      body: Column(
        children: [
          SizedBox(height: 2.h),

          // Date Range
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "${DateFormat('MMM dd').format(_startDate)} - "
                    "${DateFormat('MMM dd').format(_endDate)}",
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: DateTimeRange(
                        start: _startDate,
                        end: _endDate,
                      ),
                    );

                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                      _loadReport();
                    }
                  },
                  child: const Text("Change"),
                )
              ],
            ),
          ),

          SizedBox(height: 2.h),

          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (_, i) {
                          final s = _students[i];
                          final stats =
                              _summary[s['id']] ??
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

                          return ListTile(
                            title: Text(s['name']),
                            subtitle: Text(
                                "Present: ${stats['present']} | "
                                "Absent: ${stats['absent']}"),
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
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar:
          const CustomBottomBar(
              variant: BottomBarVariant.instructor),
    );
  }
}