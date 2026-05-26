import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
class AcademicDetailsWidget extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onSave;
  final String role;

  const AcademicDetailsWidget({
    super.key,
    required this.userData,
    required this.role,
    required this.onSave,
  });

  @override
  State<AcademicDetailsWidget> createState() =>
      _AcademicDetailsWidgetState();
}

class _AcademicDetailsWidgetState extends State<AcademicDetailsWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Card(
        child: Column(
          children: [
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'school',
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        _getTitle(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    CustomIconWidget(
                      iconName:
                          _isExpanded ? 'expand_less' : 'expand_more',
                      color: theme.colorScheme.onSurface,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded)
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(height: 1),
                    SizedBox(height: 2.h),
                    ..._buildRoleDetails(context),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ Dynamic Title
  String _getTitle() {
    if (widget.role == 'student') return "Academic Details";
    if (widget.role == 'instructor') return "Teaching Details";
    if (widget.role == 'admin' || widget.role == 'platform_admin') {
      return "Administrative Details";
    }
    return "Details";
  }

  // ✅ Role-Based Data
  List<Widget> _buildRoleDetails(BuildContext context) {
    if (widget.role == 'student') {
      return [
        _infoRow(context, "Department",
            widget.userData['department'] ?? '-'),
        _infoRow(context, "Courses Enrolled",
            (widget.userData['coursesEnrolled'] ?? 0).toString()),
        _infoRow(context, "GPA",
            widget.userData['gpa']?.toString() ?? '-'),
        _infoRow(context, "Join Date",
            widget.userData['joinDate'] ?? '-'),
      ];
    }

    if (widget.role == 'instructor') {
      return [
        _infoRow(context, "Department",
            widget.userData['department'] ?? '-'),
        _infoRow(context, "Courses Teaching",
            (widget.userData['coursesTeaching'] ?? 0).toString()),
        _infoRow(context, "Students Managed",
            (widget.userData['studentsManaged'] ?? 0).toString()),
        _infoRow(context, "Join Date",
            widget.userData['joinDate'] ?? '-'),
      ];
    }

    if (widget.role == 'admin' ||
        widget.role == 'platform_admin') {
      return [
        _infoRow(context, "Department",
            widget.userData['department'] ?? '-'),
        _infoRow(context, "Status",
            widget.userData['status'] ?? '-'),
        _infoRow(context, "Last Activity",
            widget.userData['last_activity'] ?? '-'),
        _infoRow(context, "Join Date",
            widget.userData['joinDate'] ?? '-'),
      ];
    }

    return [];
  }

  Widget _infoRow(
      BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  value,
                  style:
                      theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}