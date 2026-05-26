import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class AttendanceFiltersWidget extends StatelessWidget {
  final String selectedClass;
  final String selectedDepartment;
  final DateTime selectedDate;
  final List<String> classOptions;
  final List<String> departmentOptions;
  final Function({
    String? classFilter,
    String? departmentFilter,
    DateTime? dateFilter,
  })
  onFilterChange;

  const AttendanceFiltersWidget({
    super.key,
    required this.selectedClass,
    required this.selectedDepartment,
    required this.selectedDate,
    required this.classOptions,
    required this.departmentOptions,
    required this.onFilterChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  context,
                  'Class',
                  selectedClass == 'all' ? 'All Classes' : selectedClass,
                  Icons.class_outlined,
                  () => _showClassFilter(context),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildFilterChip(
                  context,
                  'Department',
                  selectedDepartment == 'all' ? 'All' : selectedDepartment,
                  Icons.business_outlined,
                  () => _showDepartmentFilter(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _buildFilterChip(
            context,
            'Date',
            DateFormat('MMM dd, yyyy').format(selectedDate),
            Icons.calendar_today,
            () => _showDatePicker(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showClassFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: classOptions
              .map(
                (cls) => ListTile(
                  title: Text(cls == 'all' ? 'All Classes' : cls),
                  onTap: () {
                    Navigator.pop(context);
                    onFilterChange(classFilter: cls);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showDepartmentFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: departmentOptions
              .map(
                (dept) => ListTile(
                  title: Text(dept == 'all' ? 'All Departments' : dept),
                  onTap: () {
                    Navigator.pop(context);
                    onFilterChange(departmentFilter: dept);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      onFilterChange(dateFilter: picked);
    }
  }
}
