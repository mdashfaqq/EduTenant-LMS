import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';

import '../../../services/api/users_service.dart';
import '../../../services/api/fees_service.dart';

import '../../../utils/role_utils.dart';

class CreateCourseDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const CreateCourseDialog({super.key, required this.onAdd});

  @override
  State<CreateCourseDialog> createState() => _CreateCourseDialogState();
}

class _CreateCourseDialogState extends State<CreateCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _roomController = TextEditingController();
  final _maxEnrollmentController = TextEditingController();
  
  static const List<String> _baseDepartments = [
    'Computer Science',
    'Mathematics',
    'Engineering',
  ];
  static const List<String> _baseSemesters = [
    'Fall 2025',
    'Spring 2025',
    'Summer 2025',
    'Current Semester',
  ];

  String _selectedDepartment = 'Computer Science';
  String _selectedSemester = 'Fall 2025';
  late List<String> _departmentOptions;
  late List<String> _semesterOptions;
  int? _selectedInstructorId;
  String? _selectedInstructorName;
  int _selectedCredits = 3;
  String _selectedStatus = 'active';
  bool _isLoadingInstructors = false;
  String? _loadInstructorError;
  List<Map<String, dynamic>> _instructors = [];
// ================= FEE STRUCTURES =================
List<Map<String, dynamic>> _feeStructures = [];
List<int> _selectedFeeStructureIds = [];
bool _isLoadingFees = false;
String? _loadFeeError;

  @override
  void dispose() {
    _titleController.dispose();
    _courseCodeController.dispose();
    _descriptionController.dispose();
    _scheduleController.dispose();
    _roomController.dispose();
    _maxEnrollmentController.dispose();
    super.dispose();
  }

@override
void initState() {
  super.initState();
  _departmentOptions = List.from(_baseDepartments);
  _semesterOptions = List.from(_baseSemesters);
  _loadInstructors();
  _loadFeeStructures(); // ✅ ADD THIS
}


  Future<void> _loadInstructors() async {
    debugPrint('[CreateCourseDialog] Loading instructors...');
    setState(() {
      _isLoadingInstructors = true;
      _loadInstructorError = null;
    });
    try {
      final users = await UsersService.instance.listUsers(role: 'instructor');
      if (!mounted) return;
      debugPrint(
        '[CreateCourseDialog] Instructors fetched: ${users.length} -> ${users.map((e) => e['id']).join(', ')}',
      );
      setState(() {
        _instructors = users;
        if (_instructors.isNotEmpty) {
          final first = _instructors.first;
          _selectedInstructorId = (first['id'] is num)
              ? (first['id'] as num).toInt()
              : int.tryParse(first['id']?.toString() ?? '');
          _selectedInstructorName =
              first['name']?.toString() ?? 'Instructor';
        }
        _normalizeSelectedInstructor();
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('[CreateCourseDialog] Failed to load instructors: $e');
      setState(() {
        _loadInstructorError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingInstructors = false);
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  String? _validateInstructor(int? value) {
    if (value == null) {
      return 'Please select an instructor';
    }
    return null;
  }
Future<void> _loadFeeStructures() async {
  setState(() {
    _isLoadingFees = true;
    _loadFeeError = null;
  });

  try {
    final data = await FeesService.instance.listFeeStructure();
    if (!mounted) return;
    setState(() {
      _feeStructures = data;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _loadFeeError = e.toString();
    });
  } finally {
    if (!mounted) return;
    setState(() => _isLoadingFees = false);
  }
}

  void _normalizeSelectedInstructor() {
    final ids = _instructors
        .map((inst) => (inst['id'] is num)
            ? (inst['id'] as num).toInt()
            : int.tryParse(inst['id']?.toString() ?? ''))
        .whereType<int>()
        .toSet();
    if (_selectedInstructorId != null && !ids.contains(_selectedInstructorId)) {
      if (ids.isNotEmpty) {
        _selectedInstructorId = ids.first;
        final match = _instructors.firstWhere(
          (inst) {
            final id = (inst['id'] is num)
                ? (inst['id'] as num).toInt()
                : int.tryParse(inst['id']?.toString() ?? '');
            return id == _selectedInstructorId;
          },
          orElse: () => {},
        );
        _selectedInstructorName =
            match['name']?.toString() ?? _selectedInstructorName;
      } else {
        _selectedInstructorId = null;
      }
    }
  }

  List<String> _normalizedDepartments() {
    if (!_departmentOptions.contains(_selectedDepartment)) {
      _departmentOptions = [..._departmentOptions, _selectedDepartment];
    }
    return _departmentOptions.toSet().toList();
  }

  List<String> _normalizedSemesters() {
    if (!_semesterOptions.contains(_selectedSemester)) {
      _semesterOptions = [..._semesterOptions, _selectedSemester];
    }
    return _semesterOptions.toSet().toList();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
widget.onAdd({
  'title': _titleController.text.trim(),

  // ✅ BACKEND FIELD
  'code': _courseCodeController.text.trim(),

  // 'category': _selectedDepartment,
  // 'level': _selectedSemester,
  'credits': _selectedCredits,

  // ✅ BACKEND FIELD
  'capacity': int.parse(_maxEnrollmentController.text),

  'instructor_id': _selectedInstructorId,
  'instructor_name': _selectedInstructorName,
  'status': _selectedStatus,
  'schedule': _scheduleController.text.trim(),
  'room': _roomController.text.trim(),
  'description': _descriptionController.text.trim(),
  'fee_structure_ids': _selectedFeeStructureIds,
});

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Create New Subject',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Course Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Title',
                    hintText: 'Enter subject title',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  validator: (value) =>
                      _validateRequired(value, 'subject title'),
                ),
                SizedBox(height: 2.h),

                // Course Code
                TextFormField(
                  controller: _courseCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Code',
                    hintText: 'e.g., CS101',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  validator: (value) => _validateRequired(value, 'course code'),
                ),
                SizedBox(height: 2.h),

                // // Department
                // DropdownButtonFormField<String>(
                //   value: _selectedDepartment,
                //   decoration: const InputDecoration(
                //     labelText: 'Category',
                //     prefixIcon: Icon(Icons.business_outlined),
                //   ),
                //   items: _normalizedDepartments()
                //       .map(
                //         (dept) =>
                //             DropdownMenuItem(value: dept, child: Text(dept)),
                //       )
                //       .toList(),
                //   onChanged: (value) {
                //     setState(() => _selectedDepartment = value!);
                //   },
                // ),
                // SizedBox(height: 2.h),

                // // Semester
                // DropdownButtonFormField<String>(
                //   value: _selectedSemester,
                //   decoration: const InputDecoration(
                //     labelText: 'Level',
                //     prefixIcon: Icon(Icons.calendar_today_outlined),
                //   ),
                //   items: _normalizedSemesters()
                //       .map(
                //         (sem) => DropdownMenuItem(value: sem, child: Text(sem)),
                //       )
                //       .toList(),
                //   onChanged: (value) {
                //     setState(() => _selectedSemester = value!);
                //   },
                // ),
                // SizedBox(height: 2.h),


                // Instructor
                DropdownButtonFormField<int>(
                  value: _selectedInstructorId,
                  decoration: InputDecoration(
                    labelText: 'Instructor',
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon: _isLoadingInstructors
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_loadInstructorError != null
                            ? IconButton(
                                tooltip: 'Retry loading instructors',
                                icon: const Icon(Icons.refresh),
                                onPressed: _loadInstructors,
                              )
                            : null),
                  ),
                  items: _instructors
                      .map(
                        (instructor) {
                          final id = (instructor['id'] is num)
                              ? (instructor['id'] as num).toInt()
                              : int.tryParse(instructor['id']?.toString() ?? '');
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              instructor['name']?.toString() ??
                                  roleLabel(instructor['role']?.toString()),
                            ),
                          );
                        },
                      )
                      .toList(),
                  onChanged: _isLoadingInstructors
                      ? null
                      : (value) {
                          final match = _instructors.firstWhere(
                            (inst) {
                              final id = (inst['id'] is num)
                                  ? (inst['id'] as num).toInt()
                                  : int.tryParse(inst['id']?.toString() ?? '');
                              return id == value;
                            },
                            orElse: () => {},
                          );
                          final name = match['name']?.toString();
                          setState(() {
                            _selectedInstructorId = value;
                            _selectedInstructorName =
                                name ?? _selectedInstructorName;
                          });
                        },
                  validator: _validateInstructor,
                ),
                if (_loadInstructorError != null)
                  Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Text(
                      'Could not load instructors: $_loadInstructorError',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                if (!_isLoadingInstructors &&
                    _loadInstructorError == null &&
                    _instructors.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Text(
                      'No instructors found for this institution',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                SizedBox(height: 2.h),

                // Schedule
                TextFormField(
                  controller: _scheduleController,
                  decoration: const InputDecoration(
                    labelText: 'Schedule',
                    hintText: 'e.g., Mon, Wed, Fri 9:00 AM - 10:30 AM',
                    prefixIcon: Icon(Icons.schedule_outlined),
                  ),
                  validator: (value) => _validateRequired(value, 'schedule'),
                ),
                SizedBox(height: 2.h),

                // Room
                TextFormField(
                  controller: _roomController,
                  decoration: const InputDecoration(
                    labelText: 'Room',
                    hintText: 'e.g., Room 204',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                  validator: (value) => _validateRequired(value, 'room'),
                ),
                SizedBox(height: 2.h),

                // Max Enrollment
                TextFormField(
                  controller: _maxEnrollmentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max Enrollment',
                    hintText: 'Enter maximum students',
                    prefixIcon: Icon(Icons.people_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter max enrollment';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 2.h),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter course description',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (value) => _validateRequired(value, 'description'),
                ),
                SizedBox(height: 2.h),
                // ================= FEE STRUCTURES =================
Align(
  alignment: Alignment.centerLeft,
  child: Text(
    'Applicable Fee Structures',
    style: theme.textTheme.titleSmall,
  ),
),
SizedBox(height: 1.h),

if (_isLoadingFees)
  const Center(child: CircularProgressIndicator())
else if (_loadFeeError != null)
  Text(
    'Failed to load fees: $_loadFeeError',
    style: TextStyle(color: theme.colorScheme.error),
  )
else if (_feeStructures.isEmpty)
  Text(
    'No fee structures available',
    style: theme.textTheme.bodySmall,
  )
else
  Wrap(
    spacing: 8,
    runSpacing: 8,
    children: _feeStructures.map((fee) {
      final id = fee['id'] as int;
      final selected = _selectedFeeStructureIds.contains(id);

      return FilterChip(
        label: Text('${fee['name']} (₹${fee['amount']})'),
        selected: selected,
        onSelected: (value) {
          setState(() {
            value
                ? _selectedFeeStructureIds.add(id)
                : _selectedFeeStructureIds.remove(id);
          });
        },
      );
    }).toList(),
  ),

SizedBox(height: 2.h),


                // Status
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.toggle_on_outlined),
                  ),
                  items: ['active', 'inactive']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value!);
                  },
                ),
                SizedBox(height: 3.h),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    SizedBox(width: 2.w),
                    ElevatedButton(
                      onPressed: _handleSubmit,
                      child: const Text('Create Course'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
