import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Assignment header widget showing title, due date, and status
class AssignmentHeaderWidget extends StatelessWidget {
  final String title;
  final DateTime dueDate;
  final String status;
  final int maxScore;

  const AssignmentHeaderWidget({
    super.key,
    required this.title,
    required this.dueDate,
    required this.status,
    required this.maxScore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysRemaining = dueDate.difference(DateTime.now()).inDays;
    final hoursRemaining = dueDate.difference(DateTime.now()).inHours % 24;
    final isOverdue = daysRemaining < 0;
    final isUrgent = daysRemaining <= 2 && !isOverdue;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 2.h),

            // Due date and status row
            Row(
              children: [
                // Due date countdown
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? theme.colorScheme.error.withValues(alpha: 0.1)
                          : isUrgent
                          ? AppTheme.warningLight.withValues(alpha: 0.1)
                          : theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: 'schedule',
                          size: 18,
                          color: isOverdue
                              ? theme.colorScheme.error
                              : isUrgent
                              ? AppTheme.warningLight
                              : theme.colorScheme.primary,
                        ),
                        SizedBox(width: 2.w),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOverdue
                                    ? 'Overdue'
                                    : daysRemaining == 0
                                    ? 'Due today'
                                    : 'Due in $daysRemaining days',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isOverdue
                                      ? theme.colorScheme.error
                                      : isUrgent
                                      ? AppTheme.warningLight
                                      : theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatDueDate(dueDate),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 3.w),

                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      status,
                      theme,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(
                        status,
                        theme,
                      ).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _getStatusColor(status, theme),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 1.5.h),

            // Max score
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'star_outline',
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Maximum Score: $maxScore points',
                  style: theme.textTheme.bodyMedium?.copyWith(
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

  /// Format due date
  String _formatDueDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Get status color
  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return AppTheme.successLight;
      case 'graded':
        return theme.colorScheme.primary;
      case 'late':
        return AppTheme.warningLight;
      case 'not submitted':
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}
