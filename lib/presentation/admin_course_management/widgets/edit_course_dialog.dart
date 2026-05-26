import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';
import '../../../services/api/fees_service.dart';
import '../../../services/api/users_service.dart';
import '../../../utils/role_utils.dart';

class EditCourseDialog extends StatefulWidget {
  final Map<String, dynamic> course;
  final Function(Map<String, dynamic>) onUpdate;

  const EditCourseDialog({
    super.key,
    required this.course,
    required this.onUpdate,
  });

  @override
  State<EditCourseDialog> createState() => _EditCourseDialogState();
}

class _EditCourseDialogState extends State<EditCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _courseCodeController;
  late TextEditingController _descriptionController;
  late TextEditingController _scheduleController;
  late TextEditingController _roomController;
  late TextEditingController _maxEnrollmentController;
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

  late String _selectedDepartment;
  late String _selectedSemester;
  late List<String> _departmentOptions;
  late List<String> _semesterOptions;
  int? _selectedInstructorId;
  String? _selectedInstructorName;
  late int _selectedCredits;
  late String _selectedStatus;
  bool _isLoadingInstructors = false;
  String? _loadInstructorError;
  List<Map<String, dynamic>> _instructors = [];
  // ================= ✅ FEE STRUCTURE STATE (STEP 1) =================
  List<Map<String, dynamic>> _feeStructures = [];
  List<int> _selectedFeeStructureIds = [];
  bool _isLoadingFees = false;
  String? _loadFeeError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course['title']);
    _courseCodeController = TextEditingController(
      text: widget.course['courseCode'],
    );
    _descriptionController = TextEditingController(
      text: widget.course['description'],
    );
    _scheduleController = TextEditingController(
      text: widget.course['schedule'],
    );
final rawFees = widget.course['fee_structure_ids'];

if (rawFees == null) {
  _selectedFeeStructureIds = [];
} else if (rawFees is List) {
  _selectedFeeStructureIds = List<int>.from(rawFees);
} else if (rawFees is String) {
  _selectedFeeStructureIds =
      rawFees.split(',').map((e) => int.parse(e)).toList();
} else {
  _selectedFeeStructureIds = [];
}

    _roomController = TextEditingController(text: widget.course['room']);
    _maxEnrollmentController = TextEditingController(
      text: widget.course['maxEnrollment'].toString(),
    );
    _selectedDepartment = widget.course['department'];
    _selectedSemester = widget.course['semester'];
    _departmentOptions = List.from(_baseDepartments);
    _semesterOptions = List.from(_baseSemesters);
    final instIdRaw = widget.course['instructorId'];
    _selectedInstructorId = instIdRaw is num
        ? instIdRaw.toInt()
        : int.tryParse(instIdRaw?.toString() ?? '');
    _selectedInstructorName = widget.course['instructor']?.toString();
    _selectedCredits = widget.course['credits'];
    _selectedStatus = widget.course['status'];
_loadFeeStructures();

    _loadInstructors();
  }

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
  

  Future<void> _loadInstructors() async {
    debugPrint('[EditCourseDialog] Loading instructors...');
    setState(() {
      _isLoadingInstructors = true;
      _loadInstructorError = null;
    });
    try {
      final users = await UsersService.instance.listUsers(role: 'instructor');
      if (!mounted) return;
      debugPrint(
        '[EditCourseDialog] Instructors fetched: ${users.length} -> ${users.map((e) => e['id']).join(', ')}',
      );
      setState(() {
        _instructors = users;


        // ensure current instructor is included even if not in list
        if (_selectedInstructorId == null && users.isNotEmpty) {
          final first = users.first;
          _selectedInstructorId = (first['id'] is num)
              ? (first['id'] as num).toInt()
              : int.tryParse(first['id']?.toString() ?? '');
          _selectedInstructorName =
              first['name']?.toString() ?? _selectedInstructorName;
        }
        _normalizeSelectedInstructor();
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('[EditCourseDialog] Failed to load instructors: $e');
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


void _handleSubmit() {
  debugPrint('EDIT SUBMIT CLICKED');

  if (!_formKey.currentState!.validate()) return;

  final payload = {
    'title': _titleController.text.trim(),

    // ✅ FIXED KEYS
    'code': _courseCodeController.text.trim(),

    // 'category': _selectedDepartment,
    // 'level': _selectedSemester,
    // 'credits': _selectedCredits,

    // ✅ FIXED KEYS
    'instructor_id': _selectedInstructorId,
    'instructor_name': _selectedInstructorName ?? 'Instructor',

    'capacity': int.parse(_maxEnrollmentController.text),
    'status': _selectedStatus,
    'schedule': _scheduleController.text.trim(),
    'room': _roomController.text.trim(),
    'description': _descriptionController.text.trim(),
     'fee_structure_ids': _selectedFeeStructureIds,
  };

  debugPrint('🟡 UPDATE payload = $payload');

  widget.onUpdate(payload);

  Navigator.pop(context);
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
                        'Edit Course',
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
                    labelText: 'Course Title',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  validator: (value) =>
                      _validateRequired(value, 'course title'),
                ),
                SizedBox(height: 2.h),

                // Course Code
                TextFormField(
                  controller: _courseCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Course Code',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  validator: (value) => _validateRequired(value, 'course code'),
                ),
                SizedBox(height: 2.h),

                // Department
                // DropdownButtonFormField<String>(
                //   value: _selectedDepartment,
                //   decoration: const InputDecoration(
                //     labelText: 'Department',
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
                //     labelText: 'Semester',
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

                // // Credits
                // DropdownButtonFormField<int>(
                //   value: _selectedCredits,
                //   decoration: const InputDecoration(
                //     labelText: 'Credits',
                //     prefixIcon: Icon(Icons.stars_outlined),
                //   ),
                //   items: [1, 2, 3, 4, 5]
                //       .map(
                //         (credits) => DropdownMenuItem(
                //           value: credits,
                //           child: Text('$credits Credits'),
                //         ),
                //       )
                //       .toList(),
                //   onChanged: (value) {
                //     setState(() => _selectedCredits = value!);
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
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.white,
            ),
          if (selected) const SizedBox(width: 4),
          Text(
            '${fee['name']} (₹${fee['amount']})',
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? Colors.white : null,
            ),
          ),
        ],
      ),
      selected: selected,
      selectedColor: Theme.of(context).colorScheme.primary,
      backgroundColor:
          Theme.of(context).colorScheme.surfaceContainerHighest,
      checkmarkColor: Colors.white,
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
                      child: const Text('Update'),
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
