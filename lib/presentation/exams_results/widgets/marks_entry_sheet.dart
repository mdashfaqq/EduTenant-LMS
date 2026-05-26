import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/api/exam_results_service.dart';
class MarksEntrySheet extends StatefulWidget {
  final Map<String, dynamic> exam;
  final List<Map<String, dynamic>> students;
  final Future<void> Function(Map<String, dynamic>) onSave;
final Map<int, int> initialMarks;
  const MarksEntrySheet({
    super.key,
    required this.exam,
    required this.students,
    required this.onSave,
     required this.initialMarks
  });

  @override
  State<MarksEntrySheet> createState() => _MarksEntrySheetState();
}

class _MarksEntrySheetState extends State<MarksEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, TextEditingController> _marksControllers = {};
  bool _isSaving = false;

@override
void initState() {
  super.initState();

  for (final student in widget.students) {
    final id = student['id'];

    final controller = TextEditingController();

    // ✅ If mark exists in DB, prefill it
    if (widget.initialMarks.containsKey(id)) {
      controller.text = widget.initialMarks[id].toString();
    }

    _marksControllers[id] = controller;
  }
}

  @override
  void dispose() {
    for (final controller in _marksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final List<Map<String, dynamic>> marks = [];

      _marksControllers.forEach((studentId, controller) {
        if (controller.text.isNotEmpty) {
          marks.add({
            'student_id': studentId,
            'marks': int.parse(controller.text),
          });
        }
      });

      await widget.onSave({
        'exam_id': widget.exam['id'],
        'marks': marks,
      });

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalMarks = widget.exam['totalMarks'] ?? 100;

    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // HEADER
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marks Entry',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '${widget.exam['title']} • ${widget.exam['course']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // STUDENT LIST
            Expanded(
              child: widget.students.isEmpty
                  ? Center(
                      child: Text(
                        'No students enrolled',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(4.w),
                      itemCount: widget.students.length,
                      itemBuilder: (context, index) {
                        final student = widget.students[index];
                        final controller =
                            _marksControllers[student['id']]!;

                        return Card(
                          margin: EdgeInsets.only(bottom: 2.h),
                          child: Padding(
                            padding: EdgeInsets.all(3.w),
                            child: Row(
                              children: [
CircleAvatar(
  radius: 22,
  backgroundImage: student['avatar'] != null &&
          student['avatar'].toString().isNotEmpty
      ? NetworkImage(student['avatar'])
      : null,
  child: student['avatar'] == null ||
          student['avatar'].toString().isEmpty
      ? Text(
          student['name'][0].toUpperCase(),
        )
      : null,
),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student['name'],
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
Text(
  student['rollNumber'] ??
      student['roll'] ??
      'STU${student['id']}',
),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 22.w,
                                  child: TextFormField(
                                    controller: controller,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      suffixText: '/$totalMarks',
                                      border: const OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                        vertical: 1.h,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.isEmpty) {
                                        return null; // absent allowed
                                      }

                                      final marks =
                                          int.tryParse(value);
                                      if (marks == null) {
                                        return 'Invalid';
                                      }

                                      if (marks < 0 ||
                                          marks > totalMarks) {
                                        return '0–$totalMarks';
                                      }

                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // SAVE BUTTON
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Marks'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
