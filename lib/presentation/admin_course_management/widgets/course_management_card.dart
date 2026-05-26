import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class CourseManagementCard extends StatefulWidget {
  final Map<String, dynamic> course;
  final VoidCallback onEdit;
  final VoidCallback? onTap;
  final VoidCallback onDelete;


  const CourseManagementCard({
    super.key,
    required this.course,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });
  
  

  @override
  State<CourseManagementCard> createState() =>
      _CourseManagementCardState();
}

class _CourseManagementCardState
    extends State<CourseManagementCard>
    with SingleTickerProviderStateMixin {

  bool _expanded = false;


    late AnimationController _iconController;
late Animation<double> _floatAnimation;
late Animation<double> _scaleAnimation;
late Animation<double> _opacityAnimation;
  @override
void initState() {
  super.initState();

  _iconController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
    CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
  );

  _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
    CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
  );

  _opacityAnimation = Tween<double>(begin: 0.06, end: 0.12).animate(
    CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
  );
}

@override
void dispose() {
  _iconController.dispose();
  super.dispose();
}
  Color _getBaseColor(int id) {
  final colors = [
    const Color(0xFFE3F2FD),
    const Color(0xFFE8F5E9),
    const Color(0xFFFFF3E0),
    const Color(0xFFF3E5F5),
    const Color(0xFFE0F7FA),
    const Color(0xFFFFEBEE),
  ];

  return colors[id % colors.length];
}
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = widget.course;
    final int enrolled =
        int.tryParse(course['enrollmentCount']?.toString() ?? '') ?? 0;

    final int capacity =
        int.tryParse(course['maxEnrollment']?.toString() ?? '') ?? 0;

    final int enrollmentPercentage =
    capacity > 0 ? ((enrolled / capacity) * 100).clamp(0, 100).round() : 0;

    final isActive = course['status'] == 'active';



     final double progress =
      capacity > 0 ? enrolled / capacity : 0.0;
    return Slidable(
      key: ValueKey(course['id']),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.mediumImpact();
              widget.onEdit();
            },
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.mediumImpact();
             widget.onDelete();
            },
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
child: InkWell(
  onTap: widget.onTap,
  borderRadius: BorderRadius.circular(12),
  child: Card(
    margin: EdgeInsets.only(bottom: 2.h),
    child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Stack(
                children: [
Container(
  height: 200,
  width: double.infinity,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    gradient: LinearGradient(
      colors: [
        _getBaseColor(course['id']),
        _getBaseColor(course['id']).withOpacity(0.75),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  child: Stack(
    children: [

      /// Rotating light orb
      AnimatedBuilder(
        animation: _iconController,
        builder: (_, __) {
          return Positioned(
            right: -60,
            top: -60,
            child: Transform.rotate(
              angle: _iconController.value * 6.28,
              child: Container(
                height: 220,
                width: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),

      /// Floating icon
AnimatedBuilder(
  animation: _iconController,
  builder: (_, __) {
    final base = _getBaseColor(widget.course['id']);

    return Positioned(
      left: 10,
      top: -5 + _floatAnimation.value,
      child: Icon(
        Icons.school,
        size: 70,
        color: Color.lerp(base, Colors.black, 0.4)!
            .withOpacity(0.35),
      ),
    );
  },
),

      /// Title
      Center(
        child: Text(
          course['title'],
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
        ),
      ),
    ],
  ),
),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF059669) : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'INACTIVE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Course Details
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course['title'],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              course['courseCode'],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // child: Text(
                        //   '${course['credits']} Credits',
                        //   style: theme.textTheme.bodySmall?.copyWith(
                        //     color: theme.colorScheme.primary,
                        //     fontWeight: FontWeight.w600,
                        //   ),
                        // ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),

                  // Instructor
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        course['instructor'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),

                  // Schedule
                  // Row(
                  //   children: [
                  //     Icon(
                  //       Icons.schedule_outlined,
                  //       size: 18,
                  //       color: theme.colorScheme.onSurfaceVariant,
                  //     ),
                  //     SizedBox(width: 2.w),
                  //     Expanded(
                  //       child: Text(
                  //         course['schedule'],
                  //         style: theme.textTheme.bodySmall?.copyWith(
                  //           color: theme.colorScheme.onSurfaceVariant,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // SizedBox(height: 1.h),

                  // Department & Semester
                  // Row(
                  //   children: [
                  //     Icon(
                  //       Icons.business_outlined,
                  //       size: 18,
                  //       color: theme.colorScheme.onSurfaceVariant,
                  //     ),
                  //     SizedBox(width: 2.w),
                  //     Text(
                  //       '${course['department']} • ${course['semester']}',
                  //       style: theme.textTheme.bodySmall?.copyWith(
                  //         color: theme.colorScheme.onSurfaceVariant,
                  //       ),
                  //     ),
                  //   ],
                  // ),
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



                  // Enrollment Progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Enrollment',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$enrolled/$capacity ($enrollmentPercentage%)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),


LinearProgressIndicator(
  value: progress.clamp(0.0, 1.0),
  backgroundColor: theme.colorScheme.surfaceContainerHighest,
  valueColor: AlwaysStoppedAnimation<Color>(
    enrollmentPercentage >= 90
        ? theme.colorScheme.error
        : theme.colorScheme.primary,
  ),


                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

        ),
      ),
    ));
  }
}
