import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class UpcomingDeadlinesWidget extends StatelessWidget {
  final Function(int) onDeadlineSwipeRight;
  final Function(int) onDeadlineSwipeLeft;
  final Function(int) onDeadlineTap;

  const UpcomingDeadlinesWidget({
    super.key,
    required this.onDeadlineSwipeRight,
    required this.onDeadlineSwipeLeft,
    required this.onDeadlineTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> deadlines = [
      {
        "id": 1,
        "title": "Mathematics Assignment 3",
        "course": "MATH 301",
        "dueDate": "2025-12-31",
        "dueTime": "11:59 PM",
        "priority": "high",
        "status": "pending",
        "description": "Complete exercises 1-15 from Chapter 5",
      },
      {
        "id": 2,
        "title": "CS Project Milestone 2",
        "course": "CS 101",
        "dueDate": "2026-01-02",
        "dueTime": "5:00 PM",
        "priority": "medium",
        "status": "in_progress",
        "description": "Submit database design and implementation",
      },
      {
        "id": 3,
        "title": "Marketing Case Study",
        "course": "MKT 205",
        "dueDate": "2026-01-05",
        "dueTime": "2:00 PM",
        "priority": "low",
        "status": "pending",
        "description": "Analyze digital marketing campaign effectiveness",
      },
      {
        "id": 4,
        "title": "Physics Lab Report",
        "course": "PHY 201",
        "dueDate": "2026-01-07",
        "dueTime": "4:00 PM",
        "priority": "medium",
        "status": "pending",
        "description": "Document experiment results and analysis",
      },
    ];

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
                Text(
                  'Upcoming Deadlines',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.errorLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${deadlines.length} pending',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.errorLight,
                      fontWeight: FontWeight.w600,
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
            itemCount: deadlines.length,
            separatorBuilder: (context, index) => SizedBox(height: 1.5.h),
            itemBuilder: (context, index) {
              final deadline = deadlines[index];
              return _buildDeadlineCard(
                context: context,
                theme: theme,
                deadline: deadline,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineCard({
    required BuildContext context,
    required ThemeData theme,
    required Map<String, dynamic> deadline,
  }) {
    final priorityColor = _getPriorityColor(deadline["priority"] as String);
    final statusColor = _getStatusColor(deadline["status"] as String);

    return Slidable(
      key: ValueKey(deadline["id"]),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onDeadlineSwipeRight(deadline["id"] as int),
            backgroundColor: AppTheme.successLight,
            foregroundColor: Colors.white,
            icon: Icons.check,
            label: 'Complete',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onDeadlineSwipeLeft(deadline["id"] as int),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            icon: Icons.more_horiz,
            label: 'Actions',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => onDeadlineTap(deadline["id"] as int),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: priorityColor.withValues(alpha: 0.3),
              width: 1.5,
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
                  // Priority Indicator
                  Container(
                    width: 1.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  SizedBox(width: 3.w),

                  // Deadline Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                deadline["title"] as String,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                deadline["status"] == "in_progress"
                                    ? "In Progress"
                                    : "Pending",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          deadline["course"] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          deadline["description"] as String,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 1.5.h),

              // Due Date Info
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'schedule',
                      color: priorityColor,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Due: ${deadline["dueDate"]} at ${deadline["dueTime"]}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: priorityColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppTheme.errorLight;
      case 'medium':
        return AppTheme.warningLight;
      case 'low':
        return AppTheme.successLight;
      default:
        return AppTheme.successLight;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_progress':
        return AppTheme.warningLight;
      case 'pending':
        return AppTheme.errorLight;
      case 'completed':
        return AppTheme.successLight;
      default:
        return AppTheme.errorLight;
    }
  }
}
