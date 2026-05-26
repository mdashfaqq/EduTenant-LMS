import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class DailyAttendanceView extends StatefulWidget {
  final Map<String, dynamic> attendanceData;
  final DateTime selectedDate;
  final Function(String) onMarkAll;
  final Future<void> Function() onRefresh;

  const DailyAttendanceView({
    super.key,
    required this.attendanceData,
    required this.selectedDate,
    required this.onMarkAll,
    required this.onRefresh,
  });

  @override
  State<DailyAttendanceView> createState() => _DailyAttendanceViewState();
}

class _DailyAttendanceViewState extends State<DailyAttendanceView> {
  final Set<int> _selectedStudents = {};
  bool _isMultiSelectMode = false;

  void _toggleStudentSelection(int studentId) {
    setState(() {
      if (_selectedStudents.contains(studentId)) {
        _selectedStudents.remove(studentId);
      } else {
        _selectedStudents.add(studentId);
      }
      _isMultiSelectMode = _selectedStudents.isNotEmpty;
    });
    HapticFeedback.selectionClick();
  }

  void _handleBulkStatusChange(String status) {
    HapticFeedback.mediumImpact();
    setState(() {
      for (var student in widget.attendanceData['students']) {
        if (_selectedStudents.contains(student['id'])) {
          student['status'] = status;
        }
      }
      _selectedStudents.clear();
      _isMultiSelectMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked ${_selectedStudents.length} students as $status'),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final students = widget.attendanceData['students'] as List;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Column(
        children: [
          // Quick Actions
          Container(
            padding: EdgeInsets.all(3.w),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    'Mark All Present',
                    Icons.check_circle_outline,
                    const Color(0xFF059669),
                    () => widget.onMarkAll('present'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    'Mark All Absent',
                    Icons.cancel_outlined,
                    Colors.red,
                    () => widget.onMarkAll('absent'),
                  ),
                ),
              ],
            ),
          ),

          // Multi-select toolbar
          if (_isMultiSelectMode)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              color: theme.colorScheme.primaryContainer,
              child: Row(
                children: [
                  Text(
                    '${_selectedStudents.length} selected',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _handleBulkStatusChange('present'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Present'),
                  ),
                  TextButton.icon(
                    onPressed: () => _handleBulkStatusChange('absent'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Absent'),
                  ),
                ],
              ),
            ),

          // Student List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(3.w),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final isSelected = _selectedStudents.contains(student['id']);

                return _buildStudentAttendanceCard(
                  context,
                  student,
                  isSelected,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12.sp),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        padding: EdgeInsets.symmetric(vertical: 1.h),
      ),
    );
  }

  Widget _buildStudentAttendanceCard(
    BuildContext context,
    Map<String, dynamic> student,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    final status = student['status'] as String;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: () => _toggleStudentSelection(student['id']),
        onLongPress: () => _toggleStudentSelection(student['id']),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Checkbox
              if (_isMultiSelectMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleStudentSelection(student['id']),
                ),

              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      student['rollNumber'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Buttons
              Row(
                children: [
                  _buildStatusButton(
                    context,
                    'P',
                    status == 'present',
                    const Color(0xFF059669),
                    () => _updateStudentStatus(student['id'], 'present'),
                  ),
                  SizedBox(width: 2.w),
                  _buildStatusButton(
                    context,
                    'A',
                    status == 'absent',
                    Colors.red,
                    () => _updateStudentStatus(student['id'], 'absent'),
                  ),
                  SizedBox(width: 2.w),
                  _buildStatusButton(
                    context,
                    'L',
                    status == 'late',
                    Colors.orange,
                    () => _updateStudentStatus(student['id'], 'late'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    String label,
    bool isActive,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : color,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ),
      ),
    );
  }

  void _updateStudentStatus(int studentId, String newStatus) {
    HapticFeedback.mediumImpact();
    setState(() {
      final studentIndex = (widget.attendanceData['students'] as List)
          .indexWhere((s) => s['id'] == studentId);
      if (studentIndex != -1) {
        widget.attendanceData['students'][studentIndex]['status'] = newStatus;
      }
    });
  }
}
