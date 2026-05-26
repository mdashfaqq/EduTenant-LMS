import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji_picker;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../../services/api/session_service.dart';
import '../../../core/app_export.dart';

class PostDetailView extends StatefulWidget {
  final Map<String, dynamic> discussion;
  final Function(Map<String, dynamic>) onReplyAdded;
  final VoidCallback onLikeToggled;
  final VoidCallback onBookmarkToggled;

  const PostDetailView({
    super.key,
    required this.discussion,
    required this.onReplyAdded,
    required this.onLikeToggled,
    required this.onBookmarkToggled,
  });

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}


class _PostDetailViewState extends State<PostDetailView> {
  final TextEditingController _replyController = TextEditingController();

  late List<Map<String, dynamic>> replies;

  final FocusNode _replyFocusNode = FocusNode();
  bool _showEmojiPicker = false;
  Map<String, dynamic>? _replyingTo;


  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  @override
void initState() {
  super.initState();
  replies = List<Map<String, dynamic>>.from(
    widget.discussion["replies"] ?? [],
  );
}


void _addReply() {
  if (_replyController.text.trim().isEmpty) return;

final currentUser = SessionService.instance.currentUser;

final tempReply = {
  "id": "temp-${DateTime.now().millisecondsSinceEpoch}",
  "content": _replyController.text.trim(),
  "author": currentUser?["name"] ?? "You",
  "authorAvatar": widget.discussion["authorAvatar"],
  "authorAvatarLabel": "Your profile",
  "timestamp": DateTime.now(),
  "likeCount": 0,
  "isLiked": false,
};
  setState(() {
    replies.add(tempReply); // optimistic UI
  });

  widget.onReplyAdded(tempReply); // backend call

  _replyController.clear();
  _replyFocusNode.unfocus();
}


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    return Scaffold(
      appBar: AppBar(
        title: Text('Discussion'),
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: widget.discussion["isBookmarked"] as bool
                  ? 'bookmark'
                  : 'bookmark_border',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onBookmarkToggled();
              setState(() {});
            },
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'share',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality coming soon'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(
                            alpha: 0.08,
                          ),
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
                              borderRadius: BorderRadius.circular(24),
                              child: CustomImageWidget(
                                imageUrl:
                                    widget.discussion["authorAvatar"] as String,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                semanticLabel:
                                    widget.discussion["authorAvatarLabel"]
                                        as String,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.discussion["author"] as String,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _formatTimestamp(
                                      widget.discussion["timestamp"]
                                          as DateTime,
                                    ),
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
                                widget.discussion["category"] as String,
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
                          widget.discussion["title"] as String,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          widget.discussion["content"] as String,
                          style: theme.textTheme.bodyMedium,
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onLikeToggled();
                        
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 1.h,
                                ),
                                child: Row(
                                  children: [
                                    CustomIconWidget(
                                      iconName:
                                          widget.discussion["isLiked"] as bool
                                          ? 'favorite'
                                          : 'favorite_border',
                                      color:
                                          widget.discussion["isLiked"] as bool
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                                      '${widget.discussion["likeCount"]}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
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
                                    '${replies.length}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (replies.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'Replies (${replies.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      itemCount: replies.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 2.h),
                      itemBuilder: (context, index) {
                        final reply = replies[index] as Map<String, dynamic>;
                        return _buildReplyCard(reply, theme);
                      },
                    ),
                  ],
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
          if (_showEmojiPicker)
            SizedBox(
              height: 30.h,
              child: emoji_picker.EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _replyController.text += emoji.emoji;
                },
                config: emoji_picker.Config(
                  height: 30.h,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: emoji_picker.EmojiViewConfig(
                    columns: 7,
                    emojiSizeMax: 32,
                  ),
                ),
              ),
            ),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_replyingTo != null)
                    Container(
                      padding: EdgeInsets.all(2.w),
                      margin: EdgeInsets.only(bottom: 2.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Replying to ${_replyingTo!["author"]}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _replyingTo = null;
                              });
                            },
                            child: CustomIconWidget(
                              iconName: 'close',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: CustomIconWidget(
                          iconName: _showEmojiPicker
                              ? 'keyboard'
                              : 'emoji_emotions',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _showEmojiPicker = !_showEmojiPicker;
                          });
                          if (!_showEmojiPicker) {
                            _replyFocusNode.requestFocus();
                          }
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          focusNode: _replyFocusNode,
                          decoration: InputDecoration(
                            hintText: 'Write a reply...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 1.5.h,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          onTap: () {
                            if (_showEmojiPicker) {
                              setState(() {
                                _showEmojiPicker = false;
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 2.w),
                      IconButton(
                        icon: CustomIconWidget(
                          iconName: 'send',
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        onPressed: _addReply,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(Map<String, dynamic> reply, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomImageWidget(
                  imageUrl: reply["authorAvatar"] as String,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  semanticLabel: reply["authorAvatarLabel"] as String,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply["author"] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatTimestamp(reply["timestamp"] as DateTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(reply["content"] as String, style: theme.textTheme.bodyMedium),
          SizedBox(height: 1.h),
          Row(
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    final isLiked = reply["isLiked"] as bool;
                    reply["isLiked"] = !isLiked;
                    reply["likeCount"] =
                        ((reply["likeCount"] as int) + (isLiked ? -1 : 1));
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: reply["isLiked"] as bool
                            ? 'favorite'
                            : 'favorite_border',
                        color: reply["isLiked"] as bool
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${reply["likeCount"]}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              InkWell(
                onTap: () {
                  setState(() {
                    _replyingTo = reply;
                  });
                  _replyFocusNode.requestFocus();
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'reply',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Reply',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
