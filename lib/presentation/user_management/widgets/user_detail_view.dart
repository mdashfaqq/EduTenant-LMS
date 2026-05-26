import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/role_utils.dart';

class UserDetailView extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onResetPassword;

  const UserDetailView({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onDelete,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = user['status'] == 'active';
    final normalizedRole = normalizeRoleValue(user['role']?.toString());

    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'User Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'close',
                    size: 24,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: CustomImageWidget(
                                imageUrl: user['avatar'],
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                                semanticLabel: user['semanticLabel'],
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF059669)
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.surface,
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          user['name'],
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            roleLabel(user['role']?.toString()),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Basic Information
                  Text(
                    'Basic Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  _buildInfoRow(
                    context,
                    'Email',
                    user['email'],
                    Icons.email_outlined,
                  ),
                  _buildInfoRow(
                    context,
                    'Department',
                    user['department'],
                    Icons.business_outlined,
                  ),
                  _buildInfoRow(
                    context,
                    'Status',
                    user['status'].toString().toUpperCase(),
                    Icons.toggle_on_outlined,
                  ),
                  _buildInfoRow(
                    context,
                    'Join Date',
                    user['joinDate'],
                    Icons.calendar_today_outlined,
                  ),
                  _buildInfoRow(
                    context,
                    'Last Activity',
                    user['lastActivity'],
                    Icons.access_time,
                  ),

                  SizedBox(height: 3.h),

                  // Role-specific Information
                  if (normalizedRole == 'instructor')
                    ..._buildInstructorInfo(context),
                  if (normalizedRole == 'student')
                    ..._buildStudentInfo(context),
                  if (normalizedRole == 'parent') ..._buildParentInfo(context),

                  SizedBox(height: 3.h),

                  // Action Buttons
                  Text(
                    'Actions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  _buildActionButton(
                    context,
                    'Edit User',
                    Icons.edit_outlined,
                    onEdit,
                    theme.colorScheme.primary,
                  ),
                  SizedBox(height: 1.h),
                  _buildActionButton(
                    context,
                    'Reset Password',
                    Icons.lock_reset_outlined,
                    onResetPassword,
                    const Color(0xFFD97706),
                  ),
                  SizedBox(height: 1.h),
                  _buildActionButton(
                    context,
                    'Delete User',
                    Icons.delete_outline,
                    onDelete,
                    theme.colorScheme.error,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
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

  List<Widget> _buildInstructorInfo(BuildContext context) {
    final theme = Theme.of(context);
    return [
      Text(
        'Teaching Information',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 1.h),
      _buildInfoRow(
        context,
        'Courses Teaching',
        user['coursesTeaching']?.toString() ?? '0',
        Icons.school_outlined,
      ),
      _buildInfoRow(
        context,
        'Students Managed',
        user['studentsManaged']?.toString() ?? '0',
        Icons.people_outline,
      ),
    ];
  }

  List<Widget> _buildStudentInfo(BuildContext context) {
    final theme = Theme.of(context);
    return [
      Text(
        'Academic Information',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 1.h),
      _buildInfoRow(
        context,
        'Courses Enrolled',
        user['coursesEnrolled']?.toString() ?? '0',
        Icons.school_outlined,
      ),
      _buildInfoRow(
        context,
        'GPA',
        user['gpa']?.toString() ?? 'N/A',
        Icons.grade_outlined,
      ),
    ];
  }

  List<Widget> _buildParentInfo(BuildContext context) {
    final theme = Theme.of(context);
    return [
      Text(
        'Parent Information',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 1.h),
      _buildInfoRow(
        context,
        'Linked Students',
        (user['linkedStudents'] as List?)?.join(', ') ?? 'None',
        Icons.family_restroom_outlined,
      ),
    ];
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
