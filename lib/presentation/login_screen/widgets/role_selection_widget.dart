import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Role Selection Widget
/// Displays role selection chips for multi-role users
class RoleSelectionWidget extends StatelessWidget {
  final List<String> availableRoles;
  final String? selectedRole;
  final Function(String) onRoleSelected;

  const RoleSelectionWidget({
    super.key,
    required this.availableRoles,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Admin':
        return Icons.admin_panel_settings;
      case 'Instructor':
        return Icons.school;
      case 'Student':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'Admin':
        return 'Manage institution settings and users';
      case 'Instructor':
        return 'Create courses and manage students';
      case 'Student':
        return 'Access courses and learning materials';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Your Role',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 1.h),

        Text(
          'Choose how you want to access the system',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 3.h),

        // Role Cards
        ...availableRoles.map(
          (role) => Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onRoleSelected(role);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: selectedRole == role
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedRole == role
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: selectedRole == role ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: _getRoleIcon(
                          role,
                        ).codePoint.toRadixString(16),
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),

                    SizedBox(width: 4.w),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: selectedRole == role
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            _getRoleDescription(role),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (selectedRole == role)
                      CustomIconWidget(
                        iconName: 'check_circle',
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
