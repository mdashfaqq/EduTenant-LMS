import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/api/users_service.dart';
import '../../../services/api/courses_service.dart';
import '../../../utils/role_utils.dart';
import '../../../services/api/session_service.dart';

class EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(Map<String, dynamic>) onUpdate;
final String currentUserRole;
  const EditUserDialog({
    super.key,
    required this.user,
    required this.onUpdate,
    required this.currentUserRole, // 👈 REQUIRED
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _departmentController;
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  late String _selectedRole;
  late String _selectedStatus;
  final Set<int> _selectedCourseIds = {};
final Map<int, int?> _instructorMap = {};

List<Map<String, dynamic>> _courses = [];
Map<int, List<Map<String, dynamic>>> _courseInstructors = {};

bool _isCoursesLoading = false;
String? _courseLoadError;
late String _discountType;
late TextEditingController _discountController;
late TextEditingController _reasonController;
late List<String> _roleOptions;

@override
void initState() {
  super.initState();
if (widget.user['courseIds'] != null) {
  _selectedCourseIds.addAll(
    List<int>.from(widget.user['courseIds']),

  );
  print("USER DATA: ${widget.user}");
print("TYPE: ${widget.user['discount_type']}");
print("VALUE: ${widget.user['discount_value']}");
}
  _nameController = TextEditingController(text: widget.user['name']);
  _emailController = TextEditingController(text: widget.user['email']);
  _departmentController =
      TextEditingController(text: widget.user['department']);

  _selectedRole = normalizeRoleValue(widget.user['role']?.toString());
  _roleOptions = [
  'student',
  'instructor',
  'admin',
  'parent',
];

_discountType = (widget.user['discount_type'] ?? 'none')
    .toString()
    .toLowerCase()
    .trim();

final discountVal = widget.user['discount_value'];

_discountController = TextEditingController(
  text: (discountVal != null)
      ? double.tryParse(discountVal.toString())?.toString() ?? ''
      : '',
);

_reasonController = TextEditingController(
  text: widget.user['discount_reason'] ?? '',
);

if (widget.currentUserRole == 'platform_admin') {
  _roleOptions.add('platform_admin');
}
  _selectedStatus = widget.user['status'];

_loadCourses();

if (_selectedRole == 'student') {
  _loadStudentInstructorMapping();
}

if (_selectedRole == 'instructor') {
  _loadInstructorCourses();
}
}
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _passwordController.dispose();
    _discountController.dispose();
_reasonController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter name';
    }
    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

Future<void> _loadInstructorCourses() async {
  try {
    final institutionCode =
        SessionService.instance.currentUser?['institution_code'];

    final courses = await CoursesService.instance.listCourses(
      institutionCode: institutionCode,
    );

    for (var course in courses) {
      final courseId = course['id'];

      final instructors =
          await CoursesService.instance.listCourseInstructors(courseId);

      final isTeaching = instructors.any(
        (inst) => inst['id'] == widget.user['id'],
      );

      if (isTeaching) {
        _selectedCourseIds.add(courseId);
      }
    }

    setState(() {});
  } catch (e) {
    debugPrint("Failed loading instructor courses: $e");
  }
}

Future<void> _loadCourses() async {
  try {
    final currentUser = SessionService.instance.currentUser;

    final isPlatformAdmin =
        currentUser?['role'] == 'platform_admin';

    final institutionCode =
        isPlatformAdmin ? null : currentUser?['institution_code'];

    final courses = await CoursesService.instance.listCourses(
      institutionCode: institutionCode,
    );

    debugPrint("Loaded courses: ${courses.length}");

    if (!mounted) return;

    setState(() {
      _courses = courses;
    });
  } catch (e) {
    debugPrint("Failed loading courses: $e");
  }
}

Future<void> _loadCourseInstructors(int courseId) async {
  try {
    final instructors =
        await CoursesService.instance.listCourseInstructors(courseId);

    if (!mounted) return;

    setState(() {
      _courseInstructors[courseId] = instructors;
    });
  } catch (e) {
    debugPrint("Failed loading instructors: $e");
  }
}

Future<void> _loadStudentInstructorMapping() async {
  try {
    final data = await UsersService.instance
        .getStudentInstructors(widget.user['id']);

    for (var row in data) {
      final courseId = row['course_id'];
      final instructorId = row['instructor_id'];

      _selectedCourseIds.add(courseId);
      _instructorMap[courseId] = instructorId;

      await _loadCourseInstructors(courseId);
    }

    setState(() {});
  } catch (e) {
    debugPrint("Failed loading mappings: $e");
  }
}

void _handleSubmit() {
  if (_formKey.currentState!.validate()) {
    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _selectedRole,
      'department': _departmentController.text.trim(),
      'status': _selectedStatus,
      'course_ids': _selectedCourseIds.toList(),
      'discount_type': _discountType,
'discount_value': _discountType == 'none'
    ? 0
    : double.tryParse(_discountController.text) ?? 0,
'discount_reason': _reasonController.text,
      'instructor_map': Map.fromEntries(
        _instructorMap.entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key.toString(), e.value)),
      ),
    };

    if (_passwordController.text.trim().isNotEmpty) {
      payload['password'] = _passwordController.text;
    }
    

    widget.onUpdate(payload);
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
                        'Edit User',
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

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: _validateName,
                ),
                SizedBox(height: 2.h),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                ),
                SizedBox(height: 2.h),

                // Password Field (Optional)
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'New Password (Optional)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 2.h),

                // Role Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: _roleOptions
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(roleLabel(role)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedRole = value!);
                  },
                ),
                SizedBox(height: 2.h),

                SizedBox(height: 2.h),

/// COURSE SELECTION
if (_selectedRole == 'student' || _selectedRole == 'instructor')
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Courses",
        style: Theme.of(context).textTheme.titleSmall,
      ),
      SizedBox(height: 1.h),

      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _courses.map((course) {
          final cid = course['id'];
          final selected = _selectedCourseIds.contains(cid);

return FilterChip(
  label: Text(
    course['title'],
    style: TextStyle(
      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      color: selected ? Colors.white : null,
    ),
  ),

  selected: selected,

  selectedColor: Theme.of(context).colorScheme.primary,

  backgroundColor:
      Theme.of(context).colorScheme.surfaceContainerHighest,

  checkmarkColor: Colors.white, // single tick

  onSelected: (value) async {
    setState(() {
      if (value) {
        _selectedCourseIds.add(cid);
      } else {
        _selectedCourseIds.remove(cid);
        _instructorMap.remove(cid);
      }
    });

    if (value) {
      await _loadCourseInstructors(cid);
    }
  },
);
        }).toList(),
      ),

      SizedBox(height: 2.h),
    ],
  ),

/// INSTRUCTOR SELECTION
if (_selectedRole == 'student' && _selectedCourseIds.isNotEmpty)
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: _selectedCourseIds.map((courseId) {
      final course = _courses.firstWhere(
        (c) => c['id'] == courseId,
        orElse: () => {},
      );

      return Padding(
        padding: EdgeInsets.only(bottom: 2.h),
        child: DropdownButtonFormField<int>(
          isExpanded: true,
          value: (_courseInstructors[courseId] ?? [])
        .any((inst) => inst['id'] == _instructorMap[courseId])
    ? _instructorMap[courseId]
    : null,
          decoration: InputDecoration(
            labelText: 'Instructor for ${course['title'] ?? 'Course'}',
            prefixIcon: const Icon(Icons.person_outline),
          ),
          items: (_courseInstructors[courseId] ?? []).map((inst) {
            return DropdownMenuItem<int>(
              value: inst['id'],
              child: Text(inst['name']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _instructorMap[courseId] = value;
            });
          },
        ),
      );
    }).toList(),
  ),
  //               if (normalizeRoleValue(_selectedRole) == 'student' &&
  //   _selectedCourseIds.isNotEmpty)
  // Column(
  //   crossAxisAlignment: CrossAxisAlignment.start,
  //   children: _selectedCourseIds.map((courseId) {
  //     final course = _courses.firstWhere(
  //       (c) => c['id'] == courseId,
  //       orElse: () => {},
  //     );

      

  //     return Padding(
  //       padding: EdgeInsets.only(bottom: 2.h),
  //       child: DropdownButtonFormField<int>(
  //         isExpanded: true,
  //         value: _instructorMap[courseId],
  //         decoration: InputDecoration(
  //           labelText: 'Instructor for ${course['title'] ?? 'Course'}',
  //           prefixIcon: const Icon(Icons.person_outline),
  //         ),
  //         items: (_courseInstructors[courseId] ?? []).map((inst) {
  //           return DropdownMenuItem<int>(
  //             value: inst['id'],
  //             child: Text(inst['name']),
  //           );
  //         }).toList(),
  //         onChanged: (value) {
  //           setState(() {
  //             _instructorMap[courseId] = value;
  //           });
  //         },
  //       ),
  //     );
  //   }).toList(),
  // ),

                // Department Field
                // TextFormField(
                //   controller: _departmentController,
                //   decoration: const InputDecoration(
                //     labelText: 'Department',
                //     prefixIcon: Icon(Icons.business_outlined),
                //   ),
                // ),
                // SizedBox(height: 2.h),

                // Status Dropdown
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
SizedBox(height: 2.h),

DropdownButtonFormField<String>(
  value: _discountType,
  decoration: const InputDecoration(
    labelText: 'Discount Type',
    prefixIcon: Icon(Icons.percent),
  ),
  items: const [
    DropdownMenuItem(value: 'none', child: Text('No Discount')),
    DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
    DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (₹)')),
  ],
  onChanged: (v) {
    setState(() => _discountType = v!);
  },
),

SizedBox(height: 2.h),

if (_discountType != 'none')
  TextFormField(
    controller: _discountController,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(
      labelText: 'Discount Value',
      prefixIcon: Icon(Icons.money_off),
    ),
  ),

SizedBox(height: 2.h),

if (_discountType != 'none')
  TextFormField(
    controller: _reasonController,
    decoration: const InputDecoration(
      labelText: 'Reason (Widow / Scholarship)',
      prefixIcon: Icon(Icons.info_outline),
    ),
  ),
 SizedBox(width: 2.w),
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

