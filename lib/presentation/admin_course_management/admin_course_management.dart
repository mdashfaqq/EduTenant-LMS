import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/sync_status_badge.dart';
import '../../services/api/courses_service.dart';
import './widgets/course_management_card.dart';
import './widgets/create_course_dialog.dart';
import './widgets/edit_course_dialog.dart';
import '../../widgets/main_drawer.dart';
import '../../services/api/session_service.dart';
import '../../widgets/custom_bottom_bar.dart';

/// Admin Course Management Screen
/// Provides comprehensive course administration with full CRUD operations
class AdminCourseManagement extends StatefulWidget {
  const AdminCourseManagement({super.key});

  @override
  State<AdminCourseManagement> createState() => _AdminCourseManagementState();
}

class _AdminCourseManagementState extends State<AdminCourseManagement> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDepartment = 'all';
  String _selectedSemester = 'all';
  String _selectedStatus = 'all';
  List<Map<String, dynamic>> _filteredCourses = [];

  bool _isLoading = false;
  String? _loadError;

  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCourses);
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final courses = await CoursesService.instance.listCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _filteredCourses = List.from(courses);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _filterCourses() {
    setState(() {
      _filteredCourses = _courses.where((course) {
        final matchesSearch =
            course['title'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            course['courseCode'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
        final matchesDepartment =
            _selectedDepartment == 'all' ||
            course['department'] == _selectedDepartment;
        final matchesSemester =
            _selectedSemester == 'all' ||
            course['semester'] == _selectedSemester;
        final matchesStatus =
            _selectedStatus == 'all' || course['status'] == _selectedStatus;
        return matchesSearch &&
            matchesDepartment &&
            matchesSemester &&
            matchesStatus;
      }).toList();
    });
  }

void _showCreateCourseDialog() {
  HapticFeedback.mediumImpact();

  showDialog(
    context: context,
    builder: (context) => CreateCourseDialog(
      onAdd: (courseData) async {
        try {
          debugPrint('🟡 createCourse payload = $courseData');

          await CoursesService.instance.createCourse(courseData);

          debugPrint('🟢 Course created → reloading list');

          await _loadCourses();

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course created successfully')),
          );
        } catch (e, st) {
          debugPrint('🔴 Course create failed: $e');
          debugPrint('🔴 StackTrace:\n$st');

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create course: $e')),
          );
        }
      },
    ),
  );
}



  void _showEditCourseDialog(Map<String, dynamic> course) {
    final parentContext = context; // ✅ SAVE THIS

    showDialog(
      context: context,
      builder: (dialogContext) => EditCourseDialog(
        course: course,
        onUpdate: (updatedData) async {
await CoursesService.instance.updateCourse(
  course['id'],
  updatedData,
);

if (!mounted) return;

// 🔥 Reload from backend (source of truth)
await _loadCourses();

ScaffoldMessenger.of(parentContext).showSnackBar(
  const SnackBar(content: Text('Course updated successfully')),
);


          // ✅ USE PARENT CONTEXT
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(content: Text('Course updated successfully')),
          );
        },
      ),
    );
  }

  void _deleteCourse(int courseId) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text(
          'Are you sure you want to delete this course? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDeleteCourse(courseId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteCourse(int courseId) async {
    try {
      await CoursesService.instance.deleteCourse(courseId);
      if (!mounted) return;
      setState(() {
        _courses.removeWhere((c) => c['id'] == courseId);
        _filterCourses();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete course: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      
      appBar: CustomAppBar(
        title: 'Course Management',
        variant: AppBarVariant.dashboard,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showCreateCourseDialog,
            tooltip: 'Create New Course',
          ),
        ],
      ),
      drawer: MainDrawer(
        currentRoute: '/admin-course-management',
        variant: bottomBarVariantFromRole(
          SessionService.instance.currentUser?['role']?.toString(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          HapticFeedback.selectionClick();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Active Filters
          if (_selectedDepartment != 'all' ||
              _selectedSemester != 'all' ||
              _selectedStatus != 'all')
            Container(
              height: 5.h,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_selectedDepartment != 'all')
                    _buildFilterChip(
                      'Department: $_selectedDepartment',
                      () => setState(() {
                        _selectedDepartment = 'all';
                        _filterCourses();
                      }),
                    ),
                  if (_selectedSemester != 'all')
                    _buildFilterChip(
                      'Semester: $_selectedSemester',
                      () => setState(() {
                        _selectedSemester = 'all';
                        _filterCourses();
                      }),
                    ),
                  if (_selectedStatus != 'all')
                    _buildFilterChip(
                      'Status: $_selectedStatus',
                      () => setState(() {
                        _selectedStatus = 'all';
                        _filterCourses();
                      }),
                    ),
                ],
              ),
            ),

          // Course List
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
                : _filteredCourses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No courses found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = _filteredCourses[index];
return CourseManagementCard(
  course: course,
  onTap: () {
    Navigator.pushNamed(

      context,
      '/course-detail',
      arguments: course,
    );
  },
  onEdit: () => _showEditCourseDialog(course),
  onDelete: () => _deleteCourse(course['id']),
);
                    },
          ),

       ) ],
      
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCourseDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Course'),
      ),
      bottomNavigationBar: CustomBottomBar(
        variant: BottomBarVariant.admin,
      ),

    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Padding(
      padding: EdgeInsets.only(right: 2.w),
      child: Chip(
        label: Text(label),
        onDeleted: onDelete,
        deleteIcon: const Icon(Icons.close, size: 18),
      ),
    );
  }

  void _showFilterSheet() {
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
              'Filter Courses',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              value: _selectedDepartment,
              decoration: const InputDecoration(
                labelText: 'Department',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              items: ['all', 'Computer Science', 'Mathematics', 'Engineering']
                  .map(
                    (dept) => DropdownMenuItem(
                      value: dept,
                      child: Text(dept == 'all' ? 'All Departments' : dept),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDepartment = value!;
                  _filterCourses();
                });
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              value: _selectedSemester,
              decoration: const InputDecoration(
                labelText: 'Semester',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              items: ['all', 'Fall 2025', 'Spring 2025', 'Summer 2025']
                  .map(
                    (sem) => DropdownMenuItem(
                      value: sem,
                      child: Text(sem == 'all' ? 'All Semesters' : sem),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSemester = value!;
                  _filterCourses();
                });
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.toggle_on_outlined),
              ),
              items: ['all', 'active', 'inactive']
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(
                        status == 'all' ? 'All Status' : status.toUpperCase(),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                  _filterCourses();
                });
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
