import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import './course_attendance_report_page.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/sync_status_badge.dart';
import '../../services/api/courses_service.dart';
import '../../services/api/attendance_service.dart';
import '../../services/api/session_service.dart';

class CourseAttendancePage extends StatefulWidget {
  const CourseAttendancePage({super.key});

  @override
  State<CourseAttendancePage> createState() => _CourseAttendancePageState();
}

class _CourseAttendancePageState extends State<CourseAttendancePage> {
  bool _loading = true;
  String? _error;

  DateTime _selectedDate = DateTime.now();
  int? _selectedCourseId;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _students = [];
bool _weeklyMode = false;
Map<int, Map<String, String?>> _weeklyData = {};
List<DateTime> _weekDates = [];
  // --------------------------------------------------
  // Lifecycle
  // --------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  // --------------------------------------------------
  // Helpers
  // --------------------------------------------------

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  // --------------------------------------------------
  // Load courses
  // --------------------------------------------------

  Future<void> _loadCourses() async {
    try {
      final courses = await CoursesService.instance.listCourses();
      if (courses.isEmpty) {
        throw Exception('No courses assigned');
      }

      setState(() {
        _courses = courses;
        _selectedCourseId ??= courses.first['id'];
      });

      await _loadAttendance();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // --------------------------------------------------
  // Load daily attendance (BACKEND-ALIGNED)
  // --------------------------------------------------
Future<void> _loadAttendance() async {
  if (_selectedCourseId == null) return;

  final int requestedCourseId = _selectedCourseId!;
  final String requestedDate = _fmt(_selectedDate);

  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    // 1️⃣ Enrolled students
    final enrolled =
        await CoursesService.instance.listCourseStudents(requestedCourseId);

    // ⛔ IGNORE stale response
    if (_selectedCourseId != requestedCourseId ||
        _fmt(_selectedDate) != requestedDate) {
      return;
    }

    // 2️⃣ Attendance for EXACT date
    final attendance =
        await AttendanceService.instance.listAttendance(
      courseId: requestedCourseId,
      startDate: requestedDate,
      endDate: requestedDate,
    );

    // ⛔ IGNORE stale response
    if (_selectedCourseId != requestedCourseId ||
        _fmt(_selectedDate) != requestedDate) {
      return;
    }

    final students = enrolled.map<Map<String, dynamic>>((s) {
      final record = attendance.firstWhere(
        (a) => a['student_id'] == s['id'],
        orElse: () => {},
      );

      return {
        'id': s['id'],
        'name': s['name'],
        'roll': 'STU${s['id']}',
       'status': record['status'], // may be null

      };
    }).toList();

    if (!mounted) return;
    setState(() => _students = students);
  } catch (e) {
    if (!mounted) return;
    setState(() => _error = e.toString());
  } finally {
    if (mounted &&
        _selectedCourseId == requestedCourseId &&
        _fmt(_selectedDate) == requestedDate) {
      setState(() => _loading = false);
    }
  }
}



Future<void> _loadWeeklyAttendance() async {
  if (_selectedCourseId == null) return;

  final int requestedCourseId = _selectedCourseId!;
  final DateTime start = _selectedDate.subtract(const Duration(days: 4));
  final DateTime end = _selectedDate;

  final String startStr = _fmt(start);
  final String endStr = _fmt(end);

  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    final enrolled =
        await CoursesService.instance.listCourseStudents(requestedCourseId);

    final attendance =
        await AttendanceService.instance.listAttendance(
      courseId: requestedCourseId,
      startDate: startStr,
      endDate: endStr,
    );

final map = <int, Map<String, String?>>{};

for (var row in attendance) {
  final studentIdRaw = row['student_id'];
  final dateRaw = row['attendance_date'];
  final statusRaw = row['status'];

  if (studentIdRaw == null || dateRaw == null) continue;

  final int studentId = studentIdRaw is int
      ? studentIdRaw
      : int.tryParse(studentIdRaw.toString()) ?? 0;

  final String date = dateRaw.toString();

  map.putIfAbsent(studentId, () => {});
  map[studentId]![date] = statusRaw?.toString();
}
_weekDates = List.generate(
  end.difference(start).inDays + 1,
  (i) => start.add(Duration(days: i)),
);
    if (!mounted) return;

    setState(() {
      _students = enrolled;
      _weeklyData = map;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() => _error = e.toString());
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}

  // --------------------------------------------------
  // Mark daily attendance (BACKEND-ALIGNED)
  // --------------------------------------------------

Future<void> _markDaily(int studentId, String status) async {
  final int courseId = _selectedCourseId!; // 🔒 freeze course

  await AttendanceService.instance.markAttendance({
    'course_id': courseId,
    'student_id': studentId,
    'attendance_date': _fmt(_selectedDate),
    'status': status,
    'marked_by': SessionService.instance.currentUser?['id'],
  });

  if (!mounted || _selectedCourseId != courseId) return;
  debugPrint(
  'MARK → course=$_selectedCourseId date=${_fmt(_selectedDate)} student=$studentId'
);


  setState(() {
    final i = _students.indexWhere((s) => s['id'] == studentId);
    if (i != -1) _students[i]['status'] = status;
  });
}



Future<void> _saveWeeklyAttendance() async {
  if (_selectedCourseId == null) return;

  final List<Map<String, dynamic>> list = [];

  for (var student in _students) {
    final studentId = student['id'];

    for (var date in _weekDates) {
      final dateStr = _fmt(date);
      final status = _weeklyData[studentId]?[dateStr];

      if (status == null) continue;

      list.add({
        'student_id': studentId,
        'attendance_date': dateStr,
        'status': status,
      });
    }
  }

  await AttendanceService.instance.bulkMarkAttendance({
    'course_id': _selectedCourseId,
    'marked_by': SessionService.instance.currentUser?['id'],
    'attendance_list': list,
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Weekly attendance saved')),
  );
}
  // --------------------------------------------------
  // UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
  title: 'Attendance',
  actions: [
    IconButton(
      tooltip: 'View Attendance Report',
      icon: const Icon(Icons.analytics),
onPressed: _selectedCourseId == null
    ? null
    : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseAttendanceReportPage(
              courseId: _selectedCourseId!,
            ),
          ),
        );
      },
    ),
  ],
),
      body: Column(
        children: [
          // ---------------- Course selector ----------------
          Padding(
            padding: EdgeInsets.all(4.w),
            child: DropdownButtonFormField<int>(
              value: _selectedCourseId,
              decoration: const InputDecoration(
                labelText: 'Course',
                prefixIcon: Icon(Icons.school),
              ),
              items: _courses
                  .map<DropdownMenuItem<int>>(
                    (c) => DropdownMenuItem<int>(
                      value: c['id'],
                      child: Text(c['title']),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                setState(() => _selectedCourseId = id);
                _loadAttendance();
              },
            ),
          ),
// SizedBox(height: 2.h),
// Padding(
//   padding: EdgeInsets.symmetric(horizontal: 4.w),
//   child: SizedBox(
//     width: double.infinity,
//     child: ElevatedButton.icon(
//       icon: const Icon(Icons.analytics),
//       label: const Text('View Attendance Report'),
//       onPressed: () {
//         if (_selectedCourseId == null) return;

//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => CourseAttendanceReportPage(
//               courseId: _selectedCourseId!,
//             ),
//           ),
//         );
//       },
//     ),
//   ),
// ),

SizedBox(height: 3.h),

SwitchListTile(
  title: const Text('Weekly View'),
  value: _weeklyMode,
  onChanged: (val) {
    setState(() => _weeklyMode = val);
    if (val) {
      _loadWeeklyAttendance();
    } else {
      _loadAttendance();
    }
    
    
  },
),

if (_weeklyMode)
  Padding(
    padding: EdgeInsets.symmetric(horizontal: 4.w),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.save),
        label: const Text('Save Weekly Attendance'),
        onPressed: _saveWeeklyAttendance,
      ),
    ),
  ),
SizedBox(height: 2.h),
          // ---------------- Date picker ----------------
          
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
onTap: () async {
  final now = DateTime.now();

  // Monday of current week
  final currentWeekStart =
      now.subtract(Duration(days: now.weekday - 1));

  // Monday of previous week
  final previousWeekStart =
      currentWeekStart.subtract(const Duration(days: 7));

  final picked = await showDatePicker(
    context: context,
    initialDate: _selectedDate,
    firstDate: previousWeekStart,
    lastDate: now,
  );

  if (picked != null) {
    setState(() => _selectedDate = picked);

    if (_weeklyMode) {
      _loadWeeklyAttendance();
    } else {
      _loadAttendance();
    }
  }
}
          ),

       SizedBox(height: 2.h),

          // ---------------- Content ----------------
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                   : _weeklyMode ? _buildWeekly() : _buildDaily(),
          ),
        ],
      ),
      bottomNavigationBar:
          const CustomBottomBar(variant: BottomBarVariant.instructor),
    );
  }



  // --------------------------------------------------
  // Daily list
  // --------------------------------------------------

  Widget _buildDaily() {
    if (_students.isEmpty) {
      return const Center(
        child: Text(
          'No students enrolled in this course',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (_, i) {
        final s = _students[i];
        return ListTile(
            visualDensity: const VisualDensity(vertical: -3), // 🔥 tighter spacing
          title: Text(s['name']),
          subtitle: Text(s['roll']),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.check_circle,
color: s['status'] == 'present'
    ? Colors.green
    : s['status'] == null
        ? Colors.grey
        : Colors.grey,

                ),
                onPressed: () => _markDaily(s['id'], 'present'),
              ),
              IconButton(
                icon: Icon(
                  Icons.cancel,
color: s['status'] == 'absent'
    ? Colors.red
    : s['status'] == null
        ? Colors.grey
        : Colors.grey,

                ),
                onPressed: () => _markDaily(s['id'], 'absent'),
              ),
            ],
          ),
        );
      },
    );
  }

Widget _buildWeekly() {
  if (_students.isEmpty) {
    return const Center(
      child: Text(
        'No students enrolled in this course',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: [
        const DataColumn(label: Text('Student')),
        ..._weekDates.map(
          (d) => DataColumn(
            label: Text(DateFormat('dd').format(d)),
          ),
        ),
      ],
      rows: _students.map((s) {
        return DataRow(
          cells: [
            DataCell(Text(s['name'])),
            ..._weekDates.map((d) {
              final status =
                  _weeklyData[s['id']]?[_fmt(d)];

              IconData icon;
              Color color;

              if (status == 'present') {
                icon = Icons.check_circle;
                color = Colors.green;
              } else if (status == 'absent') {
                icon = Icons.cancel;
                color = Colors.red;
              } else {
                icon = Icons.remove_circle;
                color = Colors.grey;
              }

return DataCell(
  GestureDetector(
    onTap: () {
      final studentId = s['id'];
      final dateStr = _fmt(d);

      setState(() {
        final current = _weeklyData[studentId]?[dateStr];

        if (current == 'present') {
          _weeklyData[studentId]![dateStr] = 'absent';
        } else {
          _weeklyData.putIfAbsent(studentId, () => {});
          _weeklyData[studentId]![dateStr] = 'present';
        }
      });
    },
    child: Icon(icon, color: color, size: 18),
  ),
);
            }),
          ],
        );
      }).toList(),
    ),
  );
}
}

