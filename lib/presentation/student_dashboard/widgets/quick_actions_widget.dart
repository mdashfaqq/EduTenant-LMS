import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickActionsWidget extends StatelessWidget {
  final Function(String) onActionTap;

  const QuickActionsWidget({super.key, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> quickActions = [
      {
        "id": "submit",
        "icon": "upload_file",
        "label": "Submit Assignment",
        "color": theme.colorScheme.primary,
      },
      {
        "id": "grades",
        "icon": "grade",
        "label": "View Grades",
        "color": theme.colorScheme.secondary,
      },
      {
        "id": "attendance",
        "icon": "event_available",
        "label": "Check Attendance",
        "color": AppTheme.successLight,
      },
      {
        "id": "schedule",
        "icon": "calendar_today",
        "label": "My Schedule",
        "color": AppTheme.warningLight,
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 1.5.h),
          SizedBox(
            height: 14.h,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              scrollDirection: Axis.horizontal,
              itemCount: quickActions.length,
              separatorBuilder: (context, index) => SizedBox(width: 3.w),
              itemBuilder: (context, index) {
                final action = quickActions[index];
                return _buildActionCard(
                  context: context,
                  theme: theme,
                  action: action,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required ThemeData theme,
    required Map<String, dynamic> action,
  }) {
    return InkWell(
      onTap: () => onActionTap(action["id"] as String),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 28.w,
        padding: EdgeInsets.all(3.w),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: (action["color"] as Color).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: action["icon"] as String,
                  color: action["color"] as Color,
                  size: 24,
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              action["label"] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
