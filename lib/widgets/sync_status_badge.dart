import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../services/sync_status_service.dart';

/// Reusable sync status badge widget
/// Displays current sync status with visual indicators and timestamps
class SyncStatusBadge extends StatelessWidget {
  final bool showTimestamp;
  final bool compact;
  final EdgeInsetsGeometry? margin;

  const SyncStatusBadge({
    super.key,
    this.showTimestamp = true,
    this.compact = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SyncStatusService.instance,
      builder: (context, _) {
        final statusInfo = SyncStatusService.instance.currentStatus;
        return _buildBadge(context, statusInfo);
      },
    );
  }

  Widget _buildBadge(BuildContext context, SyncStatusInfo statusInfo) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final badgeColor = _getStatusColor(statusInfo.status, colorScheme);
    final icon = _getStatusIcon(statusInfo.status);

    if (compact) {
      return Container(
        margin: margin ?? EdgeInsets.symmetric(horizontal: 2.w),
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
        decoration: BoxDecoration(
          color: badgeColor.withAlpha(26),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: badgeColor.withAlpha(77), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.sp, color: badgeColor),
            if (statusInfo.status == SyncStatus.syncing) ...[
              SizedBox(width: 1.w),
              SizedBox(
                width: 12.sp,
                height: 12.sp,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: badgeColor.withAlpha(77), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: badgeColor),
          SizedBox(width: 2.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                statusInfo.statusText,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
              if (showTimestamp && statusInfo.lastSyncTime != null) ...[
                SizedBox(height: 0.2.h),
                Text(
                  'Last sync: ${statusInfo.timeAgo}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: theme.textTheme.bodySmall?.color?.withAlpha(179),
                  ),
                ),
              ],
              if (statusInfo.pendingChanges > 0) ...[
                SizedBox(height: 0.2.h),
                Text(
                  '${statusInfo.pendingChanges} pending changes',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          if (statusInfo.status == SyncStatus.syncing) ...[
            SizedBox(width: 2.w),
            SizedBox(
              width: 16.sp,
              height: 16.sp,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(SyncStatus status, ColorScheme colorScheme) {
    switch (status) {
      case SyncStatus.offline:
        return Colors.grey;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.synchronized:
        return Colors.green;
      case SyncStatus.error:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.offline:
        return Icons.cloud_off;
      case SyncStatus.syncing:
        return Icons.cloud_sync;
      case SyncStatus.synchronized:
        return Icons.cloud_done;
      case SyncStatus.error:
        return Icons.error_outline;
    }
  }
}
