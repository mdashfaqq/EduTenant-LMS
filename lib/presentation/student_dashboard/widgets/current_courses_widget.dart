import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CurrentCoursesWidget extends StatelessWidget {
  final Function(int) onCourseTap;
  final Function(int) onCourseLongPress;

  const CurrentCoursesWidget({
    super.key,
    required this.onCourseTap,
    required this.onCourseLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> courses = [
      {
        "id": 1,
        "name": "Advanced Mathematics",
        "code": "MATH 301",
        "progress": 0.75,
        "nextClass": "Today, 10:00 AM",
        "instructor": "Dr. Michael Chen",
        "color": theme.colorScheme.primary,
        "announcement": "New assignment posted",
      },
      {
        "id": 2,
        "name": "Computer Science Fundamentals",
        "code": "CS 101",
        "progress": 0.60,
        "nextClass": "Tomorrow, 2:00 PM",
        "instructor": "Prof. Emily Rodriguez",
        "color": theme.colorScheme.secondary,
        "announcement": null,
      },
      {
        "id": 3,
        "name": "Digital Marketing",
        "code": "MKT 205",
        "progress": 0.85,
        "nextClass": "Friday, 11:00 AM",
        "instructor": "Dr. James Wilson",
        "color": AppTheme.successLight,
        "announcement": "Quiz scheduled for next week",
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
                  'Current Courses',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => onCourseTap(0),
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
            itemCount: courses.length,
            separatorBuilder: (context, index) => SizedBox(height: 2.h),
            itemBuilder: (context, index) {
              final course = courses[index];
              return _buildCourseCard(
                context: context,
                theme: theme,
                course: course,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard({
    required BuildContext context,
    required ThemeData theme,
    required Map<String, dynamic> course,
  }) {
    return InkWell(
      onTap: () => onCourseTap(course["id"] as int),
      onLongPress: () => onCourseLongPress(course["id"] as int),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                // Progress Ring
                SizedBox(
                  width: 15.w,
                  height: 15.w,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: course["progress"] as double,
                        strokeWidth: 4,
                        backgroundColor: theme.colorScheme.outline.withValues(
                          alpha: 0.2,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          course["color"] as Color,
                        ),
                      ),
                      Center(
                        child: Text(
                          '${((course["progress"] as double) * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 3.w),

                // Course Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course["name"] as String,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        course["code"] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // More Options
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'more_vert',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () => onCourseLongPress(course["id"] as int),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Next Class Info
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: (course["color"] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'schedule',
                    color: course["color"] as Color,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Next class: ${course["nextClass"]}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: course["color"] as Color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Announcement Badge
            if (course["announcement"] != null) ...[
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.warningLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'campaign',
                      color: AppTheme.warningLight,
                      size: 14,
                    ),
                    SizedBox(width: 1.w),
                    Flexible(
                      child: Text(
                        course["announcement"] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.warningLight,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
