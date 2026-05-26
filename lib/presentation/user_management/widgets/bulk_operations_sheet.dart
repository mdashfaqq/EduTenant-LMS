import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../utils/role_utils.dart';

class BulkOperationsSheet extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onBulkImport;
  final Function(String) onBulkStatusChange;
  final Function(String) onBulkRoleChange;
  final VoidCallback onBulkDelete;

  const BulkOperationsSheet({
    super.key,
    required this.selectedCount,
    required this.onBulkImport,
    required this.onBulkStatusChange,
    required this.onBulkRoleChange,
    required this.onBulkDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bulk Operations',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$selectedCount selected',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Import CSV
          _buildOperationTile(
            context,
            'Import from CSV',
            'Bulk import users from CSV file',
            Icons.upload_file_outlined,
            onBulkImport,
            theme.colorScheme.primary,
          ),

          // Change Status
          _buildOperationTile(
            context,
            'Change Status',
            'Activate or deactivate selected users',
            Icons.toggle_on_outlined,
            () => _showStatusOptions(context),
            const Color(0xFF059669),
          ),

          // Change Role
          _buildOperationTile(
            context,
            'Change Role',
            'Update role for selected users',
            Icons.badge_outlined,
            () => _showRoleOptions(context),
            const Color(0xFFD97706),
          ),

          // Delete Users
          _buildOperationTile(
            context,
            'Delete Users',
            'Permanently delete selected users',
            Icons.delete_outline,
            onBulkDelete,
            theme.colorScheme.error,
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildOperationTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(3.w),
        margin: EdgeInsets.only(bottom: 1.h),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF059669),
              ),
              title: const Text('Activate'),
              onTap: () {
                Navigator.pop(context);
                onBulkStatusChange('active');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: Colors.grey),
              title: const Text('Deactivate'),
              onTap: () {
                Navigator.pop(context);
                onBulkStatusChange('inactive');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleOptions(BuildContext context) {
    const roles = [
      'student',
      'instructor',
      'admin',
      'platform_admin',
      'parent',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles
              .map(
                (role) => ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(roleLabel(role)),
                  onTap: () {
                    Navigator.pop(context);
                    onBulkRoleChange(role);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
