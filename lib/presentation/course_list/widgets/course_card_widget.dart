import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/app_export.dart';

class CourseCardWidget extends StatefulWidget {
  final Map<String, dynamic> course;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(String) onQuickAction;

  const CourseCardWidget({
    super.key,
    required this.course,
    required this.onTap,
    required this.onLongPress,
    required this.onQuickAction,
  });

  @override
  State<CourseCardWidget> createState() => _CourseCardWidgetState();
}



class _CourseCardWidgetState extends State<CourseCardWidget> {
  bool _expanded = false;
Color _getBaseColor(int id) {
  final colors = [
    const Color(0xFFE3F2FD), // light blue
    const Color(0xFFE8F5E9), // light green
    const Color(0xFFFFF3E0), // light orange
    const Color(0xFFF3E5F5), // light purple
    const Color(0xFFE0F7FA), // light cyan
    const Color(0xFFFFEBEE), // light pink
  ];

  return colors[id % colors.length];
}
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = widget.course;
    final isPinned = course['isPinned'] as bool;
    final unreadCount = course['unreadCount'] as int;
    final progress = course['progress'] as double;
    final nextAssignment = course['nextAssignment'] as String?;
    final dueDate = course['dueDate'] as String?;

    // return Slidable(
    //   key: ValueKey(course['id']),
    //   endActionPane: ActionPane(
    //     motion: const ScrollMotion(),
    //     children: [
    //       SlidableAction(
    //         onPressed: (context) => onQuickAction('assignments'),
    //         backgroundColor: theme.colorScheme.primary,
    //         foregroundColor: theme.colorScheme.onPrimary,
    //         icon: Icons.assignment,
    //         label: 'Assignments',
    //       ),
    //       SlidableAction(
    //         onPressed: (context) => onQuickAction('grades'),
    //         backgroundColor: theme.colorScheme.secondary,
    //         foregroundColor: theme.colorScheme.onSecondary,
    //         icon: Icons.grade,
    //         label: 'Grades',
    //       ),
    //       SlidableAction(
    //         onPressed: (context) => onQuickAction('discussions'),
    //         backgroundColor: theme.colorScheme.tertiary,
    //         foregroundColor: theme.colorScheme.onTertiary,
    //         icon: Icons.forum,
    //         label: 'Discussions',
    //       ),
    //     ],
    //   ),
    //   child: 
return GestureDetector(
  onTap: widget.onTap,
  onLongPress: widget.onLongPress,
  child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course thumbnail with pinned badge
              Stack(
                children: [
Container(
  height: 180,
  width: double.infinity,
  decoration: BoxDecoration(
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(12),
    ),
    gradient: LinearGradient(
      colors: [
        _getBaseColor(course['id']),
        _getBaseColor(course['id']).withOpacity(0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  child: Stack(
    children: [
      Positioned(
        right: -30,
        top: -30,
        child: Icon(
          Icons.school,
          size: 120,
          color: Colors.black.withOpacity(0.04),
        ),
      ),
      Center(
        child: Text(
          (course['title'] as String)
              .trim()
              .substring(0, 1)
              .toUpperCase(),
          style: theme.textTheme.displayMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  ),
),
                  isPinned
                      ? Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomIconWidget(
                                  iconName: 'push_pin',
                                  color: theme.colorScheme.onPrimary,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Pinned',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  unreadCount > 0
                      ? Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unreadCount new',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onError,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),

              // Course details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course title and code
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course['title'] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            course['courseCode'] as String,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Instructor info
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CustomImageWidget(
                            imageUrl: course['instructorAvatar'] as String,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            semanticLabel:
                                course['instructorAvatarLabel'] as String,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            course['instructor'] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
const SizedBox(height: 12),

// Course description (NEW)
if (course['description'] != null &&
    (course['description'] as String).isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final text = course['description'] as String;

        final textSpan = TextSpan(
          text: text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );

        final tp = TextPainter(
          text: textSpan,
          maxLines: 2,
          textDirection: TextDirection.ltr,
        );

        tp.layout(maxWidth: constraints.maxWidth);

        final isOverflowing = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCrossFade(
              firstChild: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              secondChild: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),

            if (isOverflowing) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                child: Text(
                  _expanded ? 'Read less' : 'Read more',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    ),
  ),

// Progress bar
// Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'Progress',
//                               style: theme.textTheme.bodySmall?.copyWith(
//                                 color: theme.colorScheme.onSurfaceVariant,
//                               ),
//                             ),
//                             Text(
//                               '${(progress * 100).toInt()}%',
//                               style: theme.textTheme.bodySmall?.copyWith(
//                                 color: theme.colorScheme.primary,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(4),
//                           child: LinearProgressIndicator(
//                             value: progress,
//                             minHeight: 8,
//                             backgroundColor:
//                                 theme.colorScheme.surfaceContainerHighest,
//                             valueColor: AlwaysStoppedAnimation<Color>(
//                               progress >= 1.0
//                                   ? theme.colorScheme.tertiary
//                                   : theme.colorScheme.primary,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

                    // Next assignment (if available)
                    nextAssignment != null && dueDate != null
                        ? Column(
                            children: [
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'assignment',
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nextAssignment,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Due: ${_formatDate(dueDate)}',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    CustomIconWidget(
                                      iconName: 'chevron_right',
                                      color: theme.colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : progress >= 1.0
                        ? Column(
                            children: [
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.tertiaryContainer
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.tertiary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'check_circle',
                                      color: theme.colorScheme.tertiary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Course Completed',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.tertiary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = date.difference(now).inDays;

      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Tomorrow';
      } else if (difference < 7) {
        return 'in $difference days';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
