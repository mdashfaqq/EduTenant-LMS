import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '/../services/api/courses_service.dart';

class CreateExamDialog extends StatefulWidget {
final Future<void> Function(Map<String, dynamic>) onAdd;

  

  const CreateExamDialog({super.key, required this.onAdd});

  @override
  State<CreateExamDialog> createState() => _CreateExamDialogState();
}

class _CreateExamDialogState extends State<CreateExamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _venueController = TextEditingController();
  final _totalMarksController = TextEditingController(text: '100');
  final _passingMarksController = TextEditingController(text: '40');
  final _durationController = TextEditingController(text: '180');
bool _isSaving = false;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String _selectedStatus = 'scheduled';

  @override
  void dispose() {
    _titleController.dispose();

    _venueController.dispose();
    _totalMarksController.dispose();
    _passingMarksController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

List<Map<String, dynamic>> _courses = [];
Map<String, dynamic>? _selectedCourse;
bool _loadingCourses = true;


  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

@override
void initState() {
  super.initState();
  _loadCourses();
}

Future<void> _loadCourses() async {
  try {
    final courses = await CoursesService.instance.listCourses();
    setState(() {
      _courses = courses;
      _loadingCourses = false;
    });
  } catch (e) {
    setState(() => _loadingCourses = false);
  }
}

Future<void> _handleSubmit() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isSaving = true);

  try {
    final durationMinutes = int.parse(_durationController.text);
    final start = DateTime(
      0,
      1,
      1,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final end = start.add(Duration(minutes: durationMinutes));
    final endTime = TimeOfDay(hour: end.hour, minute: end.minute);

    await widget.onAdd({
      'title': _titleController.text.trim(),
      
      'course_id': _selectedCourse!['id'],
      'date': _selectedDate.toString().split(' ')[0],
      'time': '${_selectedTime.format(context)} - ${endTime.format(context)}',
      'duration': durationMinutes,
      'totalMarks': int.parse(_totalMarksController.text),
      'passingMarks': int.parse(_passingMarksController.text),
      'venue': _venueController.text.trim(),
      'status': _selectedStatus,
      'questionTypes': {
        'multipleChoice': 0,
        'shortAnswer': 0,
        'essay': 0,
      },
    });

    if (mounted) Navigator.pop(context);
  } finally {
    if (mounted) setState(() => _isSaving = false);
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
                        'Create Exam',
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

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Exam Title *',
                    hintText: 'Midterm Examination',
                    prefixIcon: Icon(Icons.assignment),
                  ),
                  validator: (value) => _validateRequired(value, 'exam title'),
                ),
                SizedBox(height: 2.h),

DropdownButtonFormField<Map<String, dynamic>>(
  value: _selectedCourse,
  isExpanded: true,
  decoration: const InputDecoration(
    labelText: 'Course *',
    prefixIcon: Icon(Icons.school),
  ),
  items: _loadingCourses
      ? []
      : _courses.map((course) {
          return DropdownMenuItem(
            value: course,
            child: Text(
              '${course['title']} (${course['courseCode'] ?? course['id']})',
            ),
          );
        }).toList(),
  onChanged: _loadingCourses
      ? null
      : (value) => setState(() => _selectedCourse = value),
  validator: (value) =>
      value == null ? 'Please select a course' : null,
),

SizedBox(height: 2.h),


                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date *',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _selectedDate.toString().split(' ')[0],
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: InkWell(
                        onTap: _selectTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Time *',
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(
                            _selectedTime.format(context),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes) *',
                    hintText: '180',
                    prefixIcon: Icon(Icons.timer),
                  ),
                 validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter duration';
  }

  final minutes = int.tryParse(value);
  if (minutes == null || minutes <= 0) {
    return 'Duration must be a positive number';
  }

  return null;
},

                ),
                SizedBox(height: 2.h),

                TextFormField(
                  controller: _venueController,
                  decoration: const InputDecoration(
                    labelText: 'Venue *',
                    hintText: 'Hall A',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) => _validateRequired(value, 'venue'),
                ),
                SizedBox(height: 2.h),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
  controller: _totalMarksController,
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(
    labelText: 'Total Marks *',
    prefixIcon: Icon(Icons.grade),
  ),
  onChanged: (_) {
    _formKey.currentState?.validate();
  },
  validator: (value) =>
      _validateRequired(value, 'total marks'),
),

                    ),
                    SizedBox(width: 2.w),
Expanded(
  child: TextFormField(
    controller: _passingMarksController,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(
      labelText: 'Passing Marks *',
      prefixIcon: Icon(Icons.check_circle),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please enter passing marks';
      }

      final passing = int.tryParse(value);
      final total = int.tryParse(_totalMarksController.text);

      if (passing == null) {
        return 'Passing marks must be a number';
      }

      if (total != null && passing > total) {
        return 'Passing marks cannot exceed total marks';
      }

      return null;
    },
  ),
),

                  ],
                ),
                SizedBox(height: 2.h),

                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status *',
                    prefixIcon: Icon(Icons.info),
                  ),
                  items: const [
DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),

                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),
                SizedBox(height: 2.h),

                Row(
                  
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    SizedBox(width: 2.w),
                    ElevatedButton(
                     onPressed: _isSaving ? null : _handleSubmit,

                      child: const Text('Create Exam'),
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
