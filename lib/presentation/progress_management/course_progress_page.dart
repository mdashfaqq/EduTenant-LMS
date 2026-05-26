import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../services/api/courses_service.dart';
import '../../services/api/session_service.dart';
import '../../services/api/progress_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CourseProgressPage extends StatefulWidget {
  const CourseProgressPage({super.key});

  @override
  State<CourseProgressPage> createState() => _CourseProgressPageState();
}

class _CourseProgressPageState extends State<CourseProgressPage> {
  bool _loading = true;
  String? _error;
  bool _previewMode = false;

  DateTime _selectedDate = DateTime.now();
  int? _selectedCourseId;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _students = [];

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }


Future<void> _sendToWhatsApp(String text) async {
  final encoded = Uri.encodeComponent(text);
  final uri = Uri.parse(
    "https://api.whatsapp.com/send?text=$encoded",
  );

  final success = await launchUrl(
    uri,
    mode: LaunchMode.platformDefault,
  );

  if (!success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Could not open WhatsApp")),
    );
  }
}
  /* -------------------------------------------------- */
  /* LOAD COURSES */
  /* -------------------------------------------------- */

  Future<void> _loadCourses() async {
    try {
      final courses = await CoursesService.instance.listCourses();

      setState(() {
        _courses = courses;
        _selectedCourseId ??= courses.first['id'];
      });

      await _loadProgress();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  /* -------------------------------------------------- */
  /* LOAD DAILY PROGRESS */
  /* -------------------------------------------------- */

  Future<void> _loadProgress() async {
    if (_selectedCourseId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ProgressService.instance.listProgress(
        courseId: _selectedCourseId!,
        date: _fmt(_selectedDate),
      );

      setState(() {
        _students = data.map((e) {
          return {
            'student_id': e['student_id'],
            'name': e['student_name'],
            'description': e['description'] ?? '',
            'status': e['status'] ?? 'completed',
            'controller': TextEditingController(
              text: e['description'] ?? '',
            )
          };
        }).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  /* -------------------------------------------------- */
  /* SAVE ALL (BULK) */
  /* -------------------------------------------------- */

  Future<void> _saveAll() async {
    final list = _students.map((s) {
      return {
        'student_id': s['student_id'],
        'progress_date': _fmt(_selectedDate),
        'description': s['controller'].text,
        'status': s['status']
      };
    }).toList();

    await ProgressService.instance.saveBulkProgress({
      'course_id': _selectedCourseId,
      'created_by': SessionService.instance.currentUser?['id'],
      'progress_list': list,
    });

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(
      left: 4.w,
      right: 4.w,
      bottom: 10.h, // pushes snackbar above buttons
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    content: Row(
      children: const [
        Icon(Icons.save, color: Colors.white),
        SizedBox(width: 8),
        Text('Progress saved successfully'),
      ],
    ),
    duration: const Duration(seconds: 2),
  ),
);
  }

  /* -------------------------------------------------- */
  /* GENERATE WHATSAPP FORMAT */
  /* -------------------------------------------------- */

  String _generateReport() {
    final buffer = StringBuffer();

    buffer.writeln("Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}\n");

    for (var s in _students) {
      buffer.writeln("🟣 *${s['name']}*");

      if (s['status'] == 'leave') {
        buffer.writeln("▪️ on leave\n");
      } else {
        final text = s['controller'].text.trim();
        if (text.isNotEmpty) {
          buffer.writeln("√ $text\n");
        } else {
          buffer.writeln("\n");
        }
      }
    }

    buffer.writeln("Taqabbal ALLAHU minkum 💐");

    return buffer.toString();
  }

  /* -------------------------------------------------- */
  /* UI */
  /* -------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Daily Progress'),
      body: Column(
        children: [
          /* COURSE SELECTOR */
          Padding(
            padding: EdgeInsets.all(4.w),
            child: DropdownButtonFormField<int>(
              value: _selectedCourseId,
items: _courses
    .map<DropdownMenuItem<int>>(
      (c) => DropdownMenuItem<int>(
        value: c['id'] as int,
        child: Text(c['title'].toString()),
      ),
    )
    .toList(),
              onChanged: (val) {
                setState(() => _selectedCourseId = val);
                _loadProgress();
              },
              decoration: const InputDecoration(
                labelText: 'Course',
                prefixIcon: Icon(Icons.school),
              ),
            ),
          ),

          /* DATE PICKER */
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(
              DateFormat('MMM dd, yyyy').format(_selectedDate),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );

              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadProgress();
              }
            },
          ),

          SizedBox(height: 2.h),

Expanded(
  child: _loading
      ? const Center(child: CircularProgressIndicator())
      : _error != null
          ? Center(child: Text(_error!))
          : _previewMode
              ? _buildPreview()
              : _buildEditList(),
),

          /* ACTION BUTTONS */
if (!_previewMode)
  Padding(
    padding: EdgeInsets.all(4.w),
    child: Row(
      children: [
Expanded(
  child: ElevatedButton.icon(
    onPressed: _saveAll,
    icon: const Icon(Icons.save),
    label: const Text('Save'),
  ),
),
        SizedBox(width: 4.w),
Expanded(
  child: ElevatedButton.icon(
    onPressed: () async {
      await _saveAll();
      setState(() {
        _previewMode = true;
      });
    },
    icon: const Icon(Icons.visibility),
    label: const Text('Preview'),
  ),
),
      ],
    ),
  ),
        ],
      ),
      bottomNavigationBar:
          const CustomBottomBar(variant: BottomBarVariant.instructor),
    );
  }
  Widget _buildEditList() {
  if (_students.isEmpty) {
    return const Center(
      child: Text("No students found"),
    );
  }

  return ListView.builder(
    itemCount: _students.length,
    itemBuilder: (_, i) {
      final s = _students[i];

      return Card(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
TextField(
  controller: s['controller'],
  maxLines: null,              // allows unlimited lines
  minLines: 2,                 // shows at least 2 lines initially
  keyboardType: TextInputType.multiline,
  textInputAction: TextInputAction.newline,
  decoration: const InputDecoration(
    hintText: 'Enter lesson completed',
    border: OutlineInputBorder(),
  ),
),
              Row(
                children: [
                  Radio<String>(
                    value: 'completed',
                    groupValue: s['status'],
                    onChanged: (val) {
                      setState(() => s['status'] = val);
                    },
                  ),
                  const Text('Completed'),
                  Radio<String>(
                    value: 'leave',
                    groupValue: s['status'],
                    onChanged: (val) {
                      setState(() => s['status'] = val);
                    },
                  ),
                  const Text('Leave'),
                ],
              )
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildPreview() {
  final completed =
      _students.where((s) => s['status'] == 'completed').length;
  final leave =
      _students.where((s) => s['status'] == 'leave').length;

  return Column(
    children: [
      /// HEADER
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Daily Progress Report",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(DateFormat('MMMM dd, yyyy').format(_selectedDate)),
            SizedBox(height: 1.h),
            Text(
              "Completed: $completed | Leave: $leave | Total: ${_students.length}",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),

      /// STUDENT PREVIEW
      Expanded(
        child: ListView.builder(
          padding: EdgeInsets.all(4.w),
          itemCount: _students.length,
          itemBuilder: (_, i) {
            final s = _students[i];
            final isLeave = s['status'] == 'leave';
            final description = s['controller'].text.trim();

            return Container(
              margin: EdgeInsets.only(bottom: 2.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
boxShadow: [
  BoxShadow(
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withOpacity(0.4)
        : Colors.grey.withOpacity(0.15),
    blurRadius: 12,
    offset: const Offset(0, 4),
  ),
],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 1.h),
                  if (isLeave)
                    const Text(
                      "On Leave",
                      style: TextStyle(color: Colors.red),
                    )
                  else if (description.isEmpty)
                    const Text(
                      "No lesson entered",
                      style: TextStyle(color: Colors.orange),
                    )
                  else
                   Text(
  "✓ $description",
  style: TextStyle(
    color: Theme.of(context).colorScheme.onSurface,
  ),
),
                ],
              ),
            );
          },
        ),
      ),

      /// ACTION BUTTONS
      Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
Expanded(
  child: OutlinedButton.icon(
    onPressed: () {
      setState(() {
        _previewMode = false;
      });
    },
    icon: const Icon(Icons.edit),
    label: const Text("Back to Edit"),
  ),
),
            SizedBox(width: 3.w),
Expanded(
  child: ElevatedButton.icon(
    onPressed: () {
      final text = _generateReport();
      _sendToWhatsApp(text);
    },
    icon: const FaIcon(
      FontAwesomeIcons.whatsapp,
      color: Colors.black,
    ),
    label: const Text("Send to WhatsApp"),
  ),
),
          ],
        ),
      )
    ],
  );
}
}