import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Attached resources widget with downloadable files
class AttachedResourcesWidget extends StatefulWidget {
  final List<Map<String, dynamic>> resources;

  const AttachedResourcesWidget({super.key, required this.resources});

  @override
  State<AttachedResourcesWidget> createState() =>
      _AttachedResourcesWidgetState();
}

class _AttachedResourcesWidgetState extends State<AttachedResourcesWidget> {
  final Map<int, double> _downloadProgress = {};

  /// Simulate file download
  Future<void> _downloadFile(int resourceId) async {
    setState(() => _downloadProgress[resourceId] = 0.0);

    // Simulate download progress
    for (var i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() => _downloadProgress[resourceId] = i / 100);
      }
    }

    if (mounted) {
      setState(() => _downloadProgress.remove(resourceId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File downloaded successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'attach_file',
                size: 20,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Text(
                'Attached Resources',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Resources list
          ...widget.resources.map((resource) {
            final resourceId = resource["id"] as int;
            final isDownloading = _downloadProgress.containsKey(resourceId);
            final progress = _downloadProgress[resourceId] ?? 0.0;

            return Padding(
              padding: EdgeInsets.only(bottom: 1.5.h),
              child: InkWell(
                onTap: isDownloading ? null : () => _downloadFile(resourceId),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // File icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getFileTypeColor(
                                resource["type"] as String,
                                theme,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: CustomIconWidget(
                                iconName: _getFileTypeIcon(
                                  resource["type"] as String,
                                ),
                                size: 24,
                                color: _getFileTypeColor(
                                  resource["type"] as String,
                                  theme,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 3.w),

                          // File info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  resource["name"] as String,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  resource["size"] as String,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Download button
                          if (!isDownloading)
                            CustomIconWidget(
                              iconName: 'download',
                              size: 24,
                              color: theme.colorScheme.primary,
                            )
                          else
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Progress bar
                      if (isDownloading) ...[
                        SizedBox(height: 1.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: theme.colorScheme.outline
                                .withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Get file type icon
  String _getFileTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return 'picture_as_pdf';
      case 'zip':
        return 'folder_zip';
      case 'doc':
      case 'docx':
        return 'description';
      default:
        return 'insert_drive_file';
    }
  }

  /// Get file type color
  Color _getFileTypeColor(String type, ThemeData theme) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return AppTheme.errorLight;
      case 'zip':
        return AppTheme.warningLight;
      case 'doc':
      case 'docx':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}
