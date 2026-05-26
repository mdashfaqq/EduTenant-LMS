import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DiscussionPostCard extends StatelessWidget {
  final Map<String, dynamic> discussion;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final VoidCallback onReport;
  final bool isOwner;
final VoidCallback? onEdit;
final VoidCallback? onDelete;

  const DiscussionPostCard({
    super.key,
    required this.discussion,
    required this.onTap,
    required this.onLike,
    required this.onBookmark,
    required this.onShare,
    required this.onReport,
      this.isOwner = false,
  this.onEdit,
  this.onDelete,

  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLiked = discussion["isLiked"] as bool;
    final isBookmarked = discussion["isBookmarked"] as bool;

    return Slidable(
      key: ValueKey(discussion["id"]),
endActionPane: ActionPane(
  motion: const DrawerMotion(),
  extentRatio: isOwner ? 0.5 : 0.5, // keeps size clean
  children: isOwner
      ? [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.lightImpact();
              onEdit?.call();
            },
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.lightImpact();
              onDelete?.call();
            },
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ]
      : [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.lightImpact();
              onShare();
            },
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.share,
            label: 'Share',
          ),
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.lightImpact();
              onReport();
            },
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.report,
            label: 'Report',
          ),
        ],
),
      child: InkWell(
        onTap: onTap,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showContextMenu(context);
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.08),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomImageWidget(
                      imageUrl: discussion["authorAvatar"] as String,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      semanticLabel: discussion["authorAvatarLabel"] as String,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          discussion["author"] as String,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatTimestamp(discussion["timestamp"] as DateTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
child: Text(
  (discussion["courseTitle"] ??
      discussion["category"] ??
      "General")
      .toString(),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                discussion["title"] as String,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1.h),
              Text(
                discussion["content"] as String,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  InkWell(
                    onTap: onLike,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 1.h,
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: isLiked ? 'favorite' : 'favorite_border',
                            color: isLiked
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '${discussion["likeCount"]}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 1.h,
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'comment',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '${discussion["replyCount"]}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onBookmark,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.all(1.h),
                      child: CustomIconWidget(
                        iconName: isBookmarked ? 'bookmark' : 'bookmark_border',
                        color: isBookmarked
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  InkWell(
                    onTap: onShare,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.all(1.h),
                      child: CustomIconWidget(
                        iconName: 'share',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    
    final theme = Theme.of(context);
    

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            if (isOwner)
  ListTile(
    leading: Icon(Icons.edit, color: theme.colorScheme.primary),
    title: Text('Edit', style: theme.textTheme.bodyLarge),
    onTap: () {
      Navigator.pop(context);
      onEdit?.call();
    },
  ),

if (isOwner)
  ListTile(
    leading: Icon(Icons.delete, color: theme.colorScheme.error),
    title: Text(
      'Delete',
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.error,
      ),
    ),
    onTap: () {
      Navigator.pop(context);
      onDelete?.call();
    },
  ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'reply',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text('Reply', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                onTap();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: discussion["isLiked"] as bool
                    ? 'favorite'
                    : 'favorite_border',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text(
                discussion["isLiked"] as bool ? 'Unlike' : 'Like',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                onLike();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'report',
                color: theme.colorScheme.error,
                size: 24,
              ),
              title: Text(
                'Report',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onReport();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: discussion["isBookmarked"] as bool
                    ? 'bookmark'
                    : 'bookmark_border',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text(
                discussion["isBookmarked"] as bool
                    ? 'Remove Bookmark'
                    : 'Bookmark',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                onBookmark();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text('Share', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                onShare();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}
