import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../../../core/app_export.dart';
import '../../../utils/role_utils.dart';
import '../../../services/api/session_service.dart';
class UserCardWidget extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
final Map<String, String> institutionMap;

  const UserCardWidget({
    super.key,
    required this.user,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
    required this.institutionMap,
  });

  Color _getRoleColor(BuildContext context, String? role) {
    final theme = Theme.of(context);
    switch (normalizeRoleValue(role)) {
      case 'platform_admin':
      case 'admin':
        return theme.colorScheme.error;
      case 'instructor':
        return const Color(0xFF2563EB);
      case 'student':
        return const Color(0xFF059669);
      case 'parent':
        return const Color(0xFFD97706);
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

String formatLastActive(String? value) {
  if (value == null || value.isEmpty) return '—';

  try {
    // 🔥 FIX: Convert to ISO format
   final fixed = value.replaceFirst(' ', 'T') + 'Z';

    final date = DateTime.parse(fixed).toLocal();
    final now = DateTime.now().toLocal();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return DateFormat('dd MMM yyyy').format(date);
  } catch (e) {
    print("PARSE ERROR: $e | VALUE: $value");
    return '—';
  }
}
  @override
  Widget build(BuildContext context) {
    print("USER RAW: ${user}");
print("LAST ACTIVITY: ${user['lastActivity']}");
    final theme = Theme.of(context);
    final isActive = user['status'] == 'active';
final currentRole =
    SessionService.instance.currentUser?['role']?.toString();
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              // Selection Checkbox (Multi-select mode)
              if (isMultiSelectMode)
                Padding(
                  padding: EdgeInsets.only(right: 3.w),
                  child: Checkbox(value: isSelected, onChanged: (_) => onTap()),
                ),

              // Avatar
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: CustomImageWidget(
                      imageUrl: user['avatar'],
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                      semanticLabel: user['semanticLabel'],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF059669) : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(width: 3.w),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user['name'],
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(
                              context,
                              user['role'],
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            roleLabel(user['role']?.toString()),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _getRoleColor(context, user['role']),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'email',
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 1.w),
                        Expanded(
                          child: Text(
                            user['email'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                   if (currentRole == 'platform_admin') ...[
  SizedBox(height: 0.5.h),
  Row(
    children: [
      CustomIconWidget(
        iconName: 'business',
        size: 14,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      SizedBox(width: 1.w),
      Expanded(
        child: Text(
          (user['institution_name'] ?? '').toString().isNotEmpty
              ? user['institution_name']
              : 'No Institution',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  ),
],
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'access_time',
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 1.w),
Text(
  'Last active: ${formatLastActive(user['lastActivity']?.toString())}',

  style: theme.textTheme.bodySmall?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  ),
),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick Actions (Not in multi-select mode)
              if (!isMultiSelectMode)
                PopupMenuButton<String>(
                  icon: CustomIconWidget(
                    iconName: 'more_vert',
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
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
}
