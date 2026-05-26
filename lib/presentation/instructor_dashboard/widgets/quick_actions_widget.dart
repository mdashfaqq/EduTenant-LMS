import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Quick Actions Widget
/// Horizontal scroll for Create Assignment, Send Announcement, Take Attendance, Grade Submissions
class QuickActionsWidget extends StatelessWidget {
  final VoidCallback onCreateAssignment;
  final VoidCallback onSendAnnouncement;
  final VoidCallback onTakeAttendance;
  final VoidCallback onGradeSubmissions;

  const QuickActionsWidget({
    super.key,
    required this.onCreateAssignment,
    required this.onSendAnnouncement,
    required this.onTakeAttendance,
    required this.onGradeSubmissions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 20.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildActionCard(
                  context: context,
                  icon: 'add_circle',
                  title: 'Create\nAssignment',
                  color: theme.colorScheme.primary,
                  onTap: onCreateAssignment,
                ),
                SizedBox(width: 3.w),
                _buildActionCard(
                  context: context,
                  icon: 'campaign',
                  title: 'Send\nAnnouncement',
                  color: AppTheme.warningLight,
                  onTap: onSendAnnouncement,
                ),
                SizedBox(width: 3.w),
                _buildActionCard(
                  context: context,
                  icon: 'how_to_reg',
                  title: 'Take\nAttendance',
                  color: AppTheme.successLight,
                  onTap: onTakeAttendance,
                ),
                SizedBox(width: 3.w),
                _buildActionCard(
                  context: context,
                  icon: 'grading',
                  title: 'Grade\nSubmissions',
                  color: theme.colorScheme.secondary,
                  onTap: onGradeSubmissions,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 35.w,
          padding: EdgeInsets.all(3.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(iconName: icon, color: color, size: 32),
              ),
              SizedBox(height: 2.h),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
