import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class StudentResultCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const StudentResultCard({super.key, required this.result});

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return const Color(0xFF059669);
    if (grade.startsWith('B')) return const Color(0xFF2563EB);
    if (grade.startsWith('C')) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

final String studentName =
    result['student_name'] ?? 'Unknown';

final String grade =
    result['grade'] ?? 'F';

final double percentage =
    double.tryParse(result['percentage']?.toString() ?? '0') ?? 0;

final double marks =
    double.tryParse(result['marks_obtained']?.toString() ?? '0') ?? 0;
  final gradeColor = _getGradeColor(grade);

  return Card(
    margin: EdgeInsets.only(bottom: 2.h),
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: EdgeInsets.all(3.w),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            child: Text(
              studentName.isNotEmpty
                  ? studentName[0].toUpperCase()
                  : '?',
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  "Marks: ${marks.toStringAsFixed(0)}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  grade,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: gradeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                "${percentage.toStringAsFixed(1)}%",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
