import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class PrivacySettingsWidget extends StatefulWidget {
  final Map<String, dynamic> settings;
  final Function(Map<String, dynamic>) onSave;

  const PrivacySettingsWidget({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  State<PrivacySettingsWidget> createState() => _PrivacySettingsWidgetState();
}

class _PrivacySettingsWidgetState extends State<PrivacySettingsWidget> {
  bool _isExpanded = false;
  late Map<String, dynamic> _localSettings;

  @override
  void initState() {
    super.initState();
    _localSettings = Map<String, dynamic>.from(widget.settings);
  }

  void _handleVisibilityChange(String value) {
    HapticFeedback.selectionClick();
    setState(() {
      _localSettings['profileVisibility'] = value;
    });
    widget.onSave(_localSettings);
  }

  void _handleToggle(String key, bool value) {
    HapticFeedback.selectionClick();
    setState(() {
      _localSettings[key] = value;
    });
    widget.onSave(_localSettings);
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
                      iconName: 'lock',
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'Privacy Settings',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(height: 1, color: theme.dividerColor),
                    SizedBox(height: 2.h),
                    Text(
                      'Profile Visibility',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildRadioTile(
                      context,
                      'Public',
                      'Everyone can view your profile',
                      'Public',
                    ),
                    _buildRadioTile(
                      context,
                      'Institution Only',
                      'Only members of your institution',
                      'Institution Only',
                    ),
                    _buildRadioTile(
                      context,
                      'Private',
                      'Only you can view your profile',
                      'Private',
                    ),
                    SizedBox(height: 2.h),
                    _buildSwitchTile(
                      context,
                      'Show Email Address',
                      'Display your email on your profile',
                      'showEmail',
                      _localSettings['showEmail'] as bool? ?? false,
                    ),
                    _buildSwitchTile(
                      context,
                      'Show Phone Number',
                      'Display your phone number on your profile',
                      'showPhone',
                      _localSettings['showPhone'] as bool? ?? false,
                    ),
                    _buildSwitchTile(
                      context,
                      'Data Sharing',
                      'Allow anonymous usage data collection',
                      'dataSharing',
                      _localSettings['dataSharing'] as bool? ?? false,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile(
    BuildContext context,
    String title,
    String subtitle,
    String value,
  ) {
    final theme = Theme.of(context);
    final isSelected = _localSettings['profileVisibility'] == value;

    return InkWell(
      onTap: () => _handleVisibilityChange(value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _localSettings['profileVisibility'] as String?,
              onChanged: (newValue) {
                if (newValue != null) {
                  _handleVisibilityChange(newValue);
                }
              },
            ),
            SizedBox(width: 2.w),
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
