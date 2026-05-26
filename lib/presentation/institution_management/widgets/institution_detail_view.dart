import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

class InstitutionDetailView extends StatelessWidget {
  final Map<String, dynamic> institution;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const InstitutionDetailView({
    super.key,
    required this.institution,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = institution['subscriptionStatus'] == 'active';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Institution Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Logo
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomImageWidget(
                      imageUrl: institution['logo'],
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                      semanticLabel: institution['semanticLabel'],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    institution['name'],
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF059669).withValues(alpha: 0.1)
                          : const Color(0xFFDC2626).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Suspended',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isActive
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details Section
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(theme, 'Institution Information'),
                  SizedBox(height: 1.h),
                  _buildDetailRow(
                    theme,
                    Icons.vpn_key,
                    'Code',
                    institution['code'],
                  ),
                  _buildDetailRow(
                    theme,
                    Icons.location_on,
                    'Address',
                    institution['address'],
                  ),
                  _buildDetailRow(
                    theme,
                    Icons.email,
                    'Email',
                    institution['contactEmail'],
                  ),
                  _buildDetailRow(
                    theme,
                    Icons.phone,
                    'Phone',
                    institution['contactPhone'],
                  ),
                  _buildDetailRow(
                    theme,
                    Icons.calendar_today,
                    'Academic Year',
                    institution['academicYear'],
                  ),
                  SizedBox(height: 2.h),

                  _buildSectionTitle(theme, 'Subscription Details'),
                  SizedBox(height: 1.h),
                  _buildDetailRow(
                    theme,
                    Icons.event,
                    'Expiry Date',
                    institution['subscriptionExpiry'],
                  ),
                  _buildDetailRow(
                    theme,
                    Icons.people,
                    'Users',
                    '${institution['userCount']} / ${institution['userLimit']}',
                  ),
                  SizedBox(height: 2.h),

                  _buildSectionTitle(theme, 'Enabled Modules'),
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: (institution['modules'] as Map<String, dynamic>)
                        .entries
                        .map((entry) {
                          final isEnabled = entry.value as bool;
                          return Chip(
                            label: Text(
                              entry.key[0].toUpperCase() +
                                  entry.key.substring(1),
                            ),
                            backgroundColor: isEnabled
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            side: BorderSide(
                              color: isEnabled
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                          );
                        })
                        .toList(),
                  ),
                  SizedBox(height: 2.h),

                  _buildSectionTitle(theme, 'Audit Information'),
                  SizedBox(height: 1.h),
                  _buildDetailRow(
                    theme,
                    Icons.add_circle_outline,
                    'Created',
                    institution['createdDate'],
                  ),
                  _buildDetailRow(
                    theme,
                    Icons.update,
                    'Last Modified',
                    institution['lastModified'],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
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
}
