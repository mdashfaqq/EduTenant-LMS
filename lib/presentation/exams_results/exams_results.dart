import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/custom_icon_widget.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/sync_status_badge.dart';
import '../../services/api/courses_service.dart';
import '../../services/api/exams_service.dart';
import '../../services/api/session_service.dart';
import './widgets/create_exam_dialog.dart';
import './widgets/exam_card_widget.dart';
import './widgets/marks_entry_sheet.dart';
import './widgets/student_result_card.dart';
import '../../services/api/exam_results_service.dart';
import '../../services/api/student_service.dart';
import '../student_report/student_full_report_screen.dart';
class ExamsResults extends StatefulWidget {
  const ExamsResults({super.key});

  @override
  State<ExamsResults> createState() => _ExamsResultsState();
}

class _ExamsResultsState extends State<ExamsResults>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCourse = 'all';
  bool _isLoading = false;
  String? _loadError;
  String _saveStatus = '';
bool _isReviewLoading = false;
  late final ScrollController _scrollController;
  bool _isInitialLoading = true;
bool get isAdmin =>
    SessionService.instance.currentUser?['role'] == 'platform_admin';
Map<int, int> _studentCountByExam = {};
bool get isTeacher =>
    SessionService.instance.currentUser?['role'] == 'teacher';

bool get isStudent =>
    SessionService.instance.currentUser?['role'] == 'student';
  List<Map<String, dynamic>> _exams = [];
  Map<int, List> _resultsByExam = {};
// TODO: Replace with API-driven exam results
final List<Map<String, dynamic>> _studentResults = [];
List<Map<String, dynamic>> _courses = [];
bool _loadingCourses = false;
bool _isExamCompleted(
  Map<String, dynamic> exam,
  List results,
) {
  final totalStudents = _studentCountByExam[exam['id']] ?? 0;

  print("CHECK → exam ${exam['id']} | results: ${results.length} / students: $totalStudents");

  if (totalStudents == 0) return false;

  return results.length == totalStudents;
}
@override
void initState() {
  super.initState();

  final role = SessionService.instance.currentUser?['role'];

  int tabLength;

  if (role == 'student') {
    tabLength = 1;
  } else if (role == 'teacher') {
    tabLength = 2;
  } else {
    tabLength = 3;
  }

  _tabController = TabController(length: tabLength, vsync: this);

_initLoad();
}

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  void _showSaveStatus(String message) {
    setState(() {
      _saveStatus = message;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _saveStatus = '';
      });
    });
  }


Future<void> _initLoad() async {
  setState(() => _isInitialLoading = true);

  await Future.wait([
    _loadExams(),
    _loadCourses(),
  ]);

  if (mounted) {
    setState(() => _isInitialLoading = false);
  }
}

Future<List<Map<String, dynamic>>> _loadStudentsForExam(
  Map<String, dynamic> exam,
) async {
  try {
    final courseId = exam['course_id'];

    if (courseId == null) {
      throw Exception('Exam has no course assigned');
    }

    // ✅ LOAD ONLY ENROLLED STUDENTS
    final enrolledStudents =
        await CoursesService.instance.listCourseStudents(courseId);

    return enrolledStudents;
  } catch (e) {
    if (!mounted) return [];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to load students: $e'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );

    return [];
  }
}

Future<void> _loadCourses() async {
  // setState(() => _loadingCourses = true);

  try {
    final courses = await CoursesService.instance.listCourses();

    debugPrint('COURSES RESPONSE: $courses'); // 👈 ADD THIS

    if (!mounted) return;

    setState(() {
      _courses = courses;
    });
  } catch (e) {
    debugPrint('Failed to load courses: $e');
  } finally {
    // if (mounted) setState(() => _loadingCourses = false);
  }
}



Future<void> _loadExams() async {
  setState(() {
    _loadError = null;
  });

  try {
    final exams = await ExamsService.instance.listExams();

    final Map<int, List> resultsMap = {};
    final Map<int, int> studentCountMap = {};

    for (final exam in exams) {
      final results = await ExamResultsService.instance
          .getExamResults(examId: exam['id']);

      final students = await CoursesService.instance
          .listCourseStudents(exam['course_id']);

      resultsMap[exam['id']] = results;
      studentCountMap[exam['id']] = students.length;

      print("Exam ${exam['id']} → results: ${results.length}, students: ${students.length}");
    }

    if (!mounted) return;

    setState(() {
      _exams = exams;
      _resultsByExam = resultsMap;
      _studentCountByExam = studentCountMap; // ✅ IMPORTANT
    });
  } catch (e) {
    if (!mounted) return;
    setState(() => _loadError = e.toString());
  }
}
  void _showCreateExamDialog() {
  showDialog(
    context: context,
    builder: (context) => CreateExamDialog(
      onAdd: (newExam) async {
        try {
          final created = await ExamsService.instance.createExam({
            'title': newExam['title'],
            'exam_id': 'EXAM_${DateTime.now().millisecondsSinceEpoch}',
            'course_id': newExam['course_id'], // ✅ direct from dialog
            'exam_date': newExam['date'],
            'start_time': newExam['time'].toString().split(' - ').first,
            'end_time': newExam['time'].toString().split(' - ').last,
            'duration': newExam['duration'],
            'total_marks': newExam['totalMarks'],
            'passing_marks': newExam['passingMarks'],
            'room': newExam['venue'],
            'status': newExam['status'],
          });

          if (!mounted) return;

          setState(() {
            _exams.add(created);
          });

          _showSaveStatus('Saved');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exam created successfully'),
            ),
          );
        } catch (e) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create exam: $e'),
            ),
          );
        }
      },
    ),
  );
}

void _showMarksEntrySheet(Map<String, dynamic> exam) async {
  print("CLICKED EXAM: ${exam['id']}");
  final students = await _loadStudentsForExam(exam);

  // ✅ Correct call (named parameter)
  final savedResults = await ExamResultsService.instance
      .getExamResults(examId: exam['id']);

final Map<int, int> marksMap = {};

for (final r in savedResults) {
  final studentIdRaw = r['student_id'];
  final studentName = r['studentName'];
  final marksRaw = r['marks_obtained'];

  if (studentIdRaw == null || marksRaw == null) continue;

  final studentId = int.tryParse(studentIdRaw.toString());

  // 🔥 FIX HERE
  final marks = double.tryParse(marksRaw.toString())?.round();

  if (studentId != null && marks != null) {
    marksMap[studentId] = marks;
  }
}
  if (!mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MarksEntrySheet(
      exam: exam,
      students: students,
      initialMarks: marksMap, // 👈 pass here
      onSave: (payload) async {
        print("SENDING EXAM ID → ${exam['id']}");
await ExamResultsService.instance.saveExamResults(
  examId: exam['id'],           // ✅ correct
  totalMarks: exam['totalMarks'],
  results: payload['marks'],    // ✅ correct
);
      },
    ),
  );
}



  List<Map<String, dynamic>> _getFilteredExams() {
    if (_selectedCourse == 'all') return _exams;
    return _exams
        .where((exam) => exam['course_id']?.toString() == _selectedCourse
)
        .toList();
  }

  List<Map<String, dynamic>> _getFilteredResults() {
    return _studentResults;
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

        title: 'Exams & Results',
        variant: AppBarVariant.standard,
actions: [
  if (isAdmin || isTeacher)
    IconButton(
      icon: const Icon(Icons.add_circle_outline),
      onPressed: _showCreateExamDialog,
      tooltip: 'Create Exam',
    ),
],
      ),
      body: _isInitialLoading
    ? const Center(
        child: CircularProgressIndicator(),
      )
    : Stack(
        children: [
          Column(
            children: [
TabBar(
  controller: _tabController,
  tabs: [
    if (!isStudent) const Tab(text: 'Exams'),
    if (!isStudent) const Tab(text: 'Marks'),
    const Tab(text: 'Review Results'),
  ],
),

            Expanded(
              child: TabBarView(
                controller: _tabController,
children: [
  if (!isStudent) _buildExamsTab(),
  if (!isStudent) _buildMarksEntryTab(),
  _buildResultsTab(),
],
              ),
            ),

          ],
        ),

        // ✅ Floating save status banner
        if (_saveStatus.isNotEmpty)
          Positioned(
            top: 2.h,
            left: 4.w,
            right: 4.w,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.primary,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.5.h,
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'check_circle',
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        _saveStatus,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ✅ Loading overlay
        // if (_isLoading)
        //   Positioned.fill(
        //     child: Container(
        //       color: Colors.black.withOpacity(0.3),
        //       child: const Center(
        //         child: CircularProgressIndicator(),
        //       ),
        //     ),
        //   ),
      ],
    ),

      floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateExamDialog,
          icon: const Icon(Icons.add),
          label: const Text('Create Exam'),
        ),
      bottomNavigationBar: CustomBottomBar(
        variant: navVariant,
      ),

    );
  }

  Widget _buildExamsTab() {
    final filteredExams = _getFilteredExams();

    return Column(
      children: [
        // Course Filter
// Course Filter (DYNAMIC)
Container(
  padding: EdgeInsets.all(4.w),
  child: _loadingCourses
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCourseFilterChip('All Courses', 'all'),

              ..._courses.map((course) {
                return Padding(
                  padding: EdgeInsets.only(left: 2.w),
                  child: _buildCourseFilterChip(
                    course['title'],          // label
                    course['id'].toString(),  // VALUE (logic)
                  ),
                );
              }).toList(),
            ],
          ),
        ),
),

        // Exams List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Text(
                      _loadError!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : filteredExams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No exams found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadExams,
                  child: ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: filteredExams.length,
                    itemBuilder: (context, index) {
                      final exam = filteredExams[index];


return ExamCardWidget(
  exam: exam,
  onTap: () {
    if (exam['status'] == 'scheduled') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Marks entry not allowed before exam starts"),
        ),
      );
      return;
    }

    _showMarksEntrySheet(exam);
  },
  onEdit: () {},
  onDelete: () {},
);
                    },
                  ),
                ),
        ),
      ],
    );
  }

Widget _buildMarksEntryTab() {
  return ListView.builder(
    padding: EdgeInsets.all(4.w),
    itemCount: _exams.length,
    itemBuilder: (context, index) {
      final exam = _exams[index];

      return Card(
        margin: EdgeInsets.only(bottom: 2.h),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(exam['title']),
          subtitle: Text(exam['course'] ?? ''),
          trailing: ElevatedButton(
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    minimumSize: const Size(40, 40), // 👈 reduces height
    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // removes extra space
    textStyle: const TextStyle(fontSize: 15),
  ),

            onPressed: () => _showMarksEntrySheet(exam),
            child: const Text('Enter Marks'),
          ),
        ),
      );
    },
  );
}

Future<void> _showReviewResults(Map<String, dynamic> exam) async {
  setState(() => _isReviewLoading = true);

  final results = await ExamResultsService.instance
      .getExamResults(examId: exam['id']);

  setState(() => _isReviewLoading = false);

  if (!mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      if (_isReviewLoading) {
        return Container(
          height: 50.h,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (results.isEmpty) {
        return Container(
          height: 50.h,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const Center(
            child: Text("No results entered yet"),
          ),
        );
      }

      // 🔥 ANALYTICS CALCULATION
      double totalMarks = 0;
      int passCount = 0;

      for (var r in results) {
        final marks =
            double.tryParse(r["marks_obtained"].toString()) ?? 0;
        totalMarks += marks;

final percentage =
    double.tryParse(r["percentage"].toString()) ?? 0;

if (percentage >= 40) {
  passCount++;
}
      }

      final average = totalMarks / results.length;
      final passPercent =
          (passCount / results.length) * 100;

      return Container(
        height: 85.h,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exam['title'],
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),

            // 📊 ANALYTICS HEADER
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text("Average"),
                      Text(
                        average.toStringAsFixed(1),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text("Pass %"),
                      Text(
                        "${passPercent.toStringAsFixed(1)}%",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text("Students"),
                      Text(
                        results.length.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 2.h),

            // 👇 STUDENT LIST
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final r = results[index];

                  return StudentResultCard(
                    result: r,
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildResultsTab() {
  if (_exams.isEmpty) {
    return const Center(child: Text("No exams available"));
  }
  if (isStudent) {
  return StudentFullReportScreen(
    studentId: SessionService.instance.currentUser?['id'],
  );
}

  return ListView.builder(
    padding: EdgeInsets.all(4.w),
    itemCount: _exams.length,
    itemBuilder: (context, index) {
      final exam = _exams[index];

      return Card(
        margin: EdgeInsets.only(bottom: 2.h),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.analytics,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(exam['title']),
          subtitle: Text(exam['course'] ?? ''),
trailing: Builder(
  builder: (context) {
    final results = _resultsByExam[exam['id']] ?? [];
print("Exam ${exam['id']} → ${_resultsByExam[exam['id']]}");
    final isCompleted = _isExamCompleted(exam, results);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isCompleted ? "Completed" : "Pending",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isCompleted
              ? Colors.green
              : Colors.orange,
        ),
      ),
    );
  },
),
          onTap: () => _showReviewResults(exam),
        ),
      );
    },
  );
}

  Widget _buildCourseFilterChip(String label, String value) {
    final theme = Theme.of(context);
    final isSelected = _selectedCourse == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCourse = value;
        });
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
