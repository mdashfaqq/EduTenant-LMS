import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/api/users_service.dart';
import '../../../services/api/courses_service.dart';
import '../../../utils/role_utils.dart';
import '../../../services/api/institution_service.dart';
import '../../../services/api/session_service.dart';

class AddUserDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const AddUserDialog({super.key, required this.onAdd});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String _selectedRole = 'student';
  String _selectedStatus = 'active';
  final Set<int> _selectedCourseIds = {};
  final Map<int, int?> _instructorMap = {};
  bool _isCoursesLoading = false;
  String? _courseLoadError;
  List<Map<String, dynamic>> _courses = [];
  String? _selectedInstitutionId;
List<Map<String, dynamic>> _institutions = [];
bool _isLoadingInstitutions = false;
Map<int, List<Map<String, dynamic>>> _courseInstructors = {};
String discountType = 'none';
final discountController = TextEditingController();
final reasonController = TextEditingController();
  static const List<String> _roleOptions = [
    'student',
    'instructor',
    'admin',
    'platform_admin',
    'parent',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _passwordController.dispose();
    discountController.dispose();
reasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadInstitutions(); 

  }


Future<void> _loadCourseInstructors(int courseId) async {
  try {
    debugPrint("LOADING INSTRUCTORS FOR COURSE: $courseId");

    final instructors =
        await CoursesService.instance.listCourseInstructors(courseId);

    debugPrint("INSTRUCTORS RESPONSE: $instructors");

    if (!mounted) return;

setState(() {
  _courseInstructors[courseId] = instructors;
});

   

  } catch (e) {
    debugPrint("Failed to load course instructors: $e");
  }
}
Future<void> _loadCoursesForInstitution(String? institutionCode) async {
  setState(() {
    _isCoursesLoading = true;
    _courseLoadError = null;
    _courses = [];
  });

  try {
    final courses = await CoursesService.instance.listCourses(
      institutionCode: institutionCode,
    );

    if (!mounted) return;

    setState(() {
      _courses = courses;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _courseLoadError = e.toString();
    });
  } finally {
    if (!mounted) return;
    setState(() {
      _isCoursesLoading = false;
    });
  }
}

// Future<void> _loadInstructors() async {
//   try {
//     final instructors =
//         await UsersService.instance.listUsers(role: 'instructor');

//     if (!mounted) return;

//     setState(() {
//       _instructors = instructors;
//     });
//   } catch (e) {
//     debugPrint("Failed to load instructors: $e");
//   }
// }
Future<void> _loadInstitutions() async {
  final role =
      SessionService.instance.currentUser?['role']?.toString();

  if (role != 'platform_admin') return;

  setState(() => _isLoadingInstitutions = true);

  try {
    final data =
        await InstitutionService.instance.listInstitutions();
    if (!mounted) return;

    setState(() {
      _institutions = data;
    });
  } catch (e) {
    debugPrint('Failed to load institutions: $e');
  } finally {
    if (!mounted) return;
    setState(() => _isLoadingInstitutions = false);
  }
}
Future<void> _loadCourses() async {
  final role =
      SessionService.instance.currentUser?['role']?.toString();

  // 🔥 platform admin should NOT preload courses
  if (role == 'platform_admin') {
    return;
  }

  final institutionCode =
    SessionService.instance.currentUser?['institution_code'];

await _loadCoursesForInstitution(institutionCode);
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateCourseSelection() {
    if (_isCourseFieldVisible &&
        _courses.isNotEmpty &&
        _selectedCourseIds.isEmpty) {
      return 'Please select at least one course';
    }
    return null;
  }

  bool get _isCourseFieldVisible {
    final role = normalizeRoleValue(_selectedRole);
    return role == 'student' || role == 'instructor';
  }

void _showCoursePicker(FormFieldState<List<int>> formState) {

  final role =
      SessionService.instance.currentUser?['role']?.toString();

  if (role == 'platform_admin' && _selectedInstitutionId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select institution first'),
      ),
    );
    return;
  }

  if (_isCoursesLoading) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Select Courses'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    if (_courses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No courses available'),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _courses.length,
                          itemBuilder: (context, index) {
                            final course = _courses[index];
                            final cid = course['id'] as int?;
                            if (cid == null) return const SizedBox.shrink();
                            final isSelected =
                                _selectedCourseIds.contains(cid);
                            return CheckboxListTile(
                              title: Text(
                                course['title']?.toString() ??
                                    'Untitled Course',
                              ),
                              value: isSelected,
                              onChanged: (checked) {
                                setModalState(() {
if (checked == true) {
  _selectedCourseIds.add(cid);

  // 🔥 load instructors for this course
  _loadCourseInstructors(cid);

} else {
  _selectedCourseIds.remove(cid);
  _instructorMap.remove(cid);
}
                                });
                                setState(() {});
                                formState.didChange(
                                  _selectedCourseIds.toList(),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onAdd({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'role': _selectedRole,
        'department': _departmentController.text.trim().isEmpty
            ? 'N/A'
            : _departmentController.text.trim(),
        'status': _selectedStatus,
        'course_ids':
            _isCourseFieldVisible ? _selectedCourseIds.toList() : null,
            'instructor_map': _instructorMap,
             'institution_code': _selectedInstitutionId,
                   'discount_type': discountType,
      'discount_value': discountType == 'none'
          ? 0
          : double.tryParse(discountController.text) ?? 0,
      'discount_reason': reasonController.text,
        'avatar':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1e6458eb8-1766882575145.png',
        'semanticLabel': 'Default user avatar',
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
child: ConstrainedBox(
  constraints: BoxConstraints(
    maxHeight: 85.h,
    maxWidth: 90.w,
  ),
    child: ListView(
      padding: EdgeInsets.all(4.w),
 children: [
        Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add New User',
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
                    hintText: 'Enter full name',
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
                    hintText: 'Enter email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                ),
                SizedBox(height: 2.h),
                if (SessionService.instance.currentUser?['role'] ==
    'platform_admin') ...[
  _isLoadingInstitutions
      ? const Center(child: CircularProgressIndicator())
      : DropdownButtonFormField<String>(
          value: _selectedInstitutionId,
          decoration: const InputDecoration(
            labelText: 'Institution',
            prefixIcon: Icon(Icons.business),
          ),
          items: _institutions
              .map(
                (inst) => DropdownMenuItem<String>(
                  value: inst['institution_code'],
                  child: Text(inst['name']),
                ),
              )
              .toList(),
onChanged: (value) async {
  setState(() {
    _selectedInstitutionId = value;
    _selectedCourseIds.clear();
  });

  await _loadCoursesForInstitution(value);
},
          validator: (value) {
            if (value == null) {
              return 'Please select an institution';
            }
            return null;
          },
        ),
  SizedBox(height: 2.h),
],

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter temporary password',
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
                  validator: _validatePassword,
                ),
                SizedBox(height: 2.h),

                // Role Dropdown
                DropdownButtonFormField<String>(
  value: _selectedRole == 'platform_admin' ? null : _selectedRole,
  decoration: const InputDecoration(
    labelText: 'Role',
    prefixIcon: Icon(Icons.badge_outlined),
  ),
  items: _roleOptions
      .where((role) => role != 'platform_admin') // 👈 hide it here
      .map(
        (role) => DropdownMenuItem<String>(
          value: role,
          child: Text(roleLabel(role)),
        ),
      )
      .toList(),
onChanged: (value) {
  setState(() {
    _selectedRole = value!;

    // clear course selections
    _selectedCourseIds.clear();

    // clear instructor mapping
    _instructorMap.clear();
  });
},
),
SizedBox(height: 2.h),

                if (_isCourseFieldVisible) ...[
                  FormField<List<int>>(
                    validator: (_) => _validateCourseSelection(),
                    builder: (state) {
                      final selectedCourses = _courses.where((course) {
                        final cid = course['id'];
                        return cid is int && _selectedCourseIds.contains(cid);
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _isCoursesLoading
                                ? null
                                : () => _showCoursePicker(state),
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Courses',
                                prefixIcon: const Icon(Icons.school_outlined),
                                errorText: state.errorText,
                                suffixIcon: _isCoursesLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : (_courseLoadError != null
                                        ? IconButton(
                                            tooltip: 'Retry loading courses',
                                            icon: const Icon(Icons.refresh),
                                            onPressed: () {
  if (_selectedInstitutionId != null) {
    _loadCoursesForInstitution(_selectedInstitutionId);
  }
},
                                          )
                                        : const Icon(Icons.arrow_drop_down)),
                              ),
                              child: _isCoursesLoading
                                  ? const Text('Loading courses...')
                                  : _courseLoadError != null
                                      ? Text(
                                          'Could not load courses. Tap to retry.',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color:
                                                theme.colorScheme.onSurfaceVariant,
                                          ),
                                        )
                                      : (selectedCourses.isEmpty
                                          ? Text(
                                              'Tap to select courses',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: theme
                                                    .colorScheme.onSurfaceVariant,
                                              ),
                                            )
                                          : Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: selectedCourses
                                                  .map(
                                                    (course) => Chip(
                                                      label: Text(
                                                        course['title']
                                                                ?.toString() ??
                                                            'Course',
                                                      ),
                                                      onDeleted: () {
                                                        final cid = course['id'];
                                                        if (cid is int) {
                                                          setState(() {
                                                            _selectedCourseIds
                                                                .remove(cid);
                                                          });
                                                          state.didChange(
                                                            _selectedCourseIds
                                                                .toList(),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  )
                                                  .toList(),
                                            )),
                            ),
                          ),
                          if (_courseLoadError != null &&
                              !_isCoursesLoading)
                            Padding(
                              padding: EdgeInsets.only(top: 1.h),
                              child: Text(
                                'Could not load courses: $_courseLoadError',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          SizedBox(height: 2.h),
                        ],
                      );
                    },
                  ),
                ],
              if (normalizeRoleValue(_selectedRole) == 'student' &&
    _selectedCourseIds.isNotEmpty)
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
  value: _instructorMap[courseId],
          decoration: InputDecoration(
            labelText:
                'Instructor for ${course['title'] ?? 'Course'}',
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

                // Department Field
                // TextFormField(
                //   controller: _departmentController,
                //   decoration: const InputDecoration(
                //     labelText: 'Department (Optional)',
                //     hintText: 'Enter department',
                //     prefixIcon: Icon(Icons.business_outlined),
                //   ),
                // ),
                // SizedBox(height: 2.h),

DropdownButtonFormField<String>(
  value: discountType,
  decoration: const InputDecoration(
    labelText: 'Discount Type',
    border: OutlineInputBorder(),
  ),
  items: const [
    DropdownMenuItem(value: 'none', child: Text('No Discount')),
    DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
    DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (₹)')),
  ],
  onChanged: (v) {
    setState(() => discountType = v!);
  },
),

const SizedBox(height: 16),

if (discountType != 'none')
  TextField(
    controller: discountController,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(
      labelText: 'Discount Value',
      border: OutlineInputBorder(),
    ),
  ),

const SizedBox(height: 16),

if (discountType != 'none')
  TextField(
    controller: reasonController,
    decoration: const InputDecoration(
      labelText: 'Reason (Widow / Scholarship)',
      border: OutlineInputBorder(),
    ),
  ),
const SizedBox(height: 16),

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
                      child: const Text('Add User'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
