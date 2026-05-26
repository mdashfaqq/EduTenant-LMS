import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class NotificationPreferencesWidget extends StatefulWidget {
  final Map<String, dynamic> preferences;
  final Function(Map<String, dynamic>) onSave;

  const NotificationPreferencesWidget({
    super.key,
    required this.preferences,
    required this.onSave,
  });

  @override
  State<NotificationPreferencesWidget> createState() =>
      _NotificationPreferencesWidgetState();
}

class _NotificationPreferencesWidgetState
    extends State<NotificationPreferencesWidget> {
  bool _isExpanded = false;
  late Map<String, bool> _localPreferences;

  @override
@override
void initState() {
  super.initState();

  _localPreferences = {
    "pushNotifications":
        widget.preferences["pushNotifications"] ?? true,
    "emailAlerts":
        widget.preferences["emailAlerts"] ?? true,
    "discussionUpdates":
        widget.preferences["discussionUpdates"] ?? false,
    "assignmentReminders":
        widget.preferences["assignmentReminders"] ?? true,
    "gradeNotifications":
        widget.preferences["gradeNotifications"] ?? true,
    "courseAnnouncements":
        widget.preferences["courseAnnouncements"] ?? true,
  };
}

  void _handleToggle(String key, bool value) {
    HapticFeedback.selectionClick();
    setState(() {
      _localPreferences[key] = value;
    });
    widget.onSave(_localPreferences);
  }

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
                      iconName: 'notifications',
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'Notification Preferences',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    CustomIconWidget(
                      iconName: _isExpanded ? 'expand_less' : 'expand_more',
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
                  children: [
                    Divider(height: 1, color: theme.dividerColor),
                    SizedBox(height: 1.h),
                    _buildSwitchTile(
                      context,
                      'Push Notifications',
                      'Receive notifications on your device',
                      'pushNotifications',
                      _localPreferences['pushNotifications'] ?? true,
                    ),
                    _buildSwitchTile(
                      context,
                      'Email Alerts',
                      'Get important updates via email',
                      'emailAlerts',
                      _localPreferences['emailAlerts'] ?? true,
                    ),
                    _buildSwitchTile(
                      context,
                      'Discussion Updates',
                      'Notify when someone replies to your posts',
                      'discussionUpdates',
                      _localPreferences['discussionUpdates'] ?? false,
                    ),
                    _buildSwitchTile(
                      context,
                      'Assignment Reminders',
                      'Get reminders for upcoming deadlines',
                      'assignmentReminders',
                      _localPreferences['assignmentReminders'] ?? true,
                    ),
                    _buildSwitchTile(
                      context,
                      'Grade Notifications',
                      'Notify when grades are posted',
                      'gradeNotifications',
                      _localPreferences['gradeNotifications'] ?? true,
                    ),
                    _buildSwitchTile(
                      context,
                      'Course Announcements',
                      'Receive course-related announcements',
                      'courseAnnouncements',
                      _localPreferences['courseAnnouncements'] ?? true,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    String key,
    bool value,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) => _handleToggle(key, newValue),
          ),
        ],
      ),
    );
  }
}
