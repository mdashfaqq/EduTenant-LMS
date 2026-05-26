import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RecentGradesWidget extends StatefulWidget {
  final VoidCallback onViewAllTap;

  const RecentGradesWidget({super.key, required this.onViewAllTap});

  @override
  State<RecentGradesWidget> createState() => _RecentGradesWidgetState();
}

class _RecentGradesWidgetState extends State<RecentGradesWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> grades = [
      {
        "id": 1,
        "assignment": "Midterm Exam",
        "course": "MATH 301",
        "grade": 92,
        "maxGrade": 100,
        "percentage": 92.0,
        "letterGrade": "A",
        "submittedDate": "2025-12-20",
        "feedback": "Excellent work! Strong understanding of concepts.",
        "trend": "up",
      },
      {
        "id": 2,
        "assignment": "Project Phase 1",
        "course": "CS 101",
        "grade": 85,
        "maxGrade": 100,
        "percentage": 85.0,
        "letterGrade": "B+",
        "submittedDate": "2025-12-18",
        "feedback": "Good implementation. Consider edge cases.",
        "trend": "stable",
      },
      {
        "id": 3,
        "assignment": "Case Study Analysis",
        "course": "MKT 205",
        "grade": 95,
        "maxGrade": 100,
        "percentage": 95.0,
        "letterGrade": "A",
        "submittedDate": "2025-12-15",
        "feedback": "Outstanding analysis and presentation.",
        "trend": "up",
      },
      {
        "id": 4,
        "assignment": "Lab Report 3",
        "course": "PHY 201",
        "grade": 78,
        "maxGrade": 100,
        "percentage": 78.0,
        "letterGrade": "C+",
        "submittedDate": "2025-12-12",
        "feedback": "Needs more detailed analysis.",
        "trend": "down",
      },
    ];

    final displayedGrades = _isExpanded ? grades : grades.take(2).toList();
    final averageGrade =
        grades.fold<double>(
          0,
          (sum, grade) => sum + (grade["percentage"] as double),
        ) /
        grades.length;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Grades',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Average: ${averageGrade.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getGradeColor(averageGrade),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: widget.onViewAllTap,
                  child: Text(
                    'View All',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: displayedGrades.length,
            separatorBuilder: (context, index) => SizedBox(height: 1.5.h),
            itemBuilder: (context, index) {
              final grade = displayedGrades[index];
              return _buildGradeCard(
                context: context,
                theme: theme,
                grade: grade,
              );
            },
          ),
          if (grades.length > 2) ...[
            SizedBox(height: 1.h),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _isExpanded = !_isExpanded);
                },
                icon: CustomIconWidget(
                  iconName: _isExpanded ? 'expand_less' : 'expand_more',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                label: Text(
                  _isExpanded ? 'Show Less' : 'Show More',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGradeCard({
    required BuildContext context,
    required ThemeData theme,
    required Map<String, dynamic> grade,
  }) {
    final gradeColor = _getGradeColor(grade["percentage"] as double);
    final trendIcon = _getTrendIcon(grade["trend"] as String);
    final trendColor = _getTrendColor(grade["trend"] as String);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Grade Circle
              Container(
                width: 15.w,
                height: 15.w,
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: gradeColor, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        grade["letterGrade"] as String,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: gradeColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${grade["percentage"].toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: gradeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 3.w),

              // Grade Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            grade["assignment"] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        CustomIconWidget(
                          iconName: trendIcon,
                          color: trendColor,
                          size: 20,
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      grade["course"] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${grade["grade"]}/${grade["maxGrade"]} points',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: gradeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_isExpanded) ...[
            SizedBox(height: 1.5.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'feedback',
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Instructor Feedback',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    grade["feedback"] as String,
                    style: theme.textTheme.bodySmall,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Submitted: ${grade["submittedDate"]}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 90) return AppTheme.successLight;
    if (percentage >= 80) return AppTheme.warningLight;
    return AppTheme.errorLight;
  }

  String _getTrendIcon(String trend) {
    switch (trend) {
      case 'up':
        return 'trending_up';
      case 'down':
        return 'trending_down';
      default:
        return 'trending_flat';
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'up':
        return AppTheme.successLight;
      case 'down':
        return AppTheme.errorLight;
      default:
        return AppTheme.warningLight;
    }
  }
}
