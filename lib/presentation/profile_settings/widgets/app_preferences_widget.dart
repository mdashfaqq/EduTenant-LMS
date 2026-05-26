import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme_controller.dart';
import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class AppPreferencesWidget extends StatefulWidget {
  final Map<String, dynamic> preferences;
  final Function(Map<String, dynamic>) onSave;

  const AppPreferencesWidget({
    super.key,
    required this.preferences,
    required this.onSave,
  });

  @override
  State<AppPreferencesWidget> createState() => _AppPreferencesWidgetState();
}

class _AppPreferencesWidgetState extends State<AppPreferencesWidget> {
  bool _isExpanded = false;
  late Map<String, dynamic> _localPreferences;

  @override
  void initState() {
    super.initState();
    _localPreferences = Map<String, dynamic>.from(widget.preferences);
  }

  void _handleThemeChange(String value) {
    HapticFeedback.selectionClick();
    setState(() {
      _localPreferences['theme'] = value;

context.read<ThemeController>().setTheme(value);

    });
  }

  void _handleLanguageChange(String value) {
    HapticFeedback.selectionClick();
    setState(() {
      _localPreferences['language'] = value;
    });
    widget.onSave(_localPreferences);
  }

  void _handleStorageLimitChange(double value) {
    setState(() {
      _localPreferences['offlineStorageLimit'] = value;
    });
  }

  void _handleStorageLimitChangeEnd(double value) {
    HapticFeedback.selectionClick();
    widget.onSave(_localPreferences);
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text('Clear Cache', style: theme.textTheme.titleLarge),
          content: Text(
            'This will remove all offline content and free up storage space. You can download content again later.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleClearCache();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _handleClearCache() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared successfully'),
        duration: Duration(seconds: 2),
      ),
    );
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
                      iconName: 'settings',
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'App Preferences',
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
                      'Theme',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildThemeOption('System Default'),
                    _buildThemeOption('Light'),
                    _buildThemeOption('Dark'),
                    SizedBox(height: 2.h),
                    // Text(
                    //   'Language',
                    //   style: theme.textTheme.bodyLarge?.copyWith(
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                    // SizedBox(height: 1.h),
                    // _buildLanguageOption('English'),
                    // _buildLanguageOption('Spanish'),
                    // _buildLanguageOption('French'),
                    // SizedBox(height: 2.h),
                    // Text(
                    //   'Offline Storage Limit',
                    //   style: theme.textTheme.bodyLarge?.copyWith(
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                    // SizedBox(height: 1.h),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: Slider(
                    //         value:
                    //             (_localPreferences['offlineStorageLimit']
                    //                     as num?)
                    //                 ?.toDouble() ??
                    //             2.5,
                    //         min: 0.5,
                    //         max: 5.0,
                    //         divisions: 9,
                    //         label:
                    //             '${(_localPreferences['offlineStorageLimit'] as num?)?.toStringAsFixed(1) ?? '2.5'} GB',
                    //         onChanged: _handleStorageLimitChange,
                    //         onChangeEnd: _handleStorageLimitChangeEnd,
                    //       ),
                    //     ),
                    //     SizedBox(width: 2.w),
                    //     Text(
                    //       '${(_localPreferences['offlineStorageLimit'] as num?)?.toStringAsFixed(1) ?? '2.5'} GB',
                    //       style: theme.textTheme.bodyMedium?.copyWith(
                    //         fontWeight: FontWeight.w500,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // SizedBox(height: 2.h),
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: OutlinedButton.icon(
                    //     onPressed: _showClearCacheDialog,
                    //     icon: CustomIconWidget(
                    //       iconName: 'delete_outline',
                    //       color: theme.colorScheme.error,
                    //       size: 20,
                    //     ),
                    //     label: Text(
                    //       'Clear Cache',
                    //       style: TextStyle(color: theme.colorScheme.error),
                    //     ),
                    //     style: OutlinedButton.styleFrom(
                    //       side: BorderSide(color: theme.colorScheme.error),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String themeLabel) {
  final themeController = context.watch<ThemeController>();
  final currentMode = themeController.themeMode;

  String currentThemeString;

  if (currentMode == ThemeMode.light) {
    currentThemeString = 'Light';
  } else if (currentMode == ThemeMode.dark) {
    currentThemeString = 'Dark';
  } else {
    currentThemeString = 'System Default';
  }

  return InkWell(
    onTap: () => _handleThemeChange(themeLabel),
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Radio<String>(
            value: themeLabel,
            groupValue: currentThemeString, // 🔥 USE CONTROLLER VALUE
            onChanged: (value) {
              if (value != null) {
                _handleThemeChange(value);
              }
            },
          ),
          SizedBox(width: 2.w),
          Text(themeLabel, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    ),
  );
}
  Widget _buildLanguageOption(String language) {
    final theme = Theme.of(context);
    final isSelected = _localPreferences['language'] == language;

    return InkWell(
      onTap: () => _handleLanguageChange(language),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: Row(
          children: [
            Radio<String>(
              value: language,
              groupValue: _localPreferences['language'] as String?,
              onChanged: (value) {
                if (value != null) {
                  _handleLanguageChange(value);
                }
              },
            ),
            SizedBox(width: 2.w),
            Text(language, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
