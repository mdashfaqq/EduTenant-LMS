import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../../../services/api/auth_service.dart';
import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../services/api/session_service.dart';

class SecuritySettingsWidget extends StatefulWidget {
  final Map<String, dynamic> security;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onPasswordChange;

  const SecuritySettingsWidget({
    super.key,
    required this.security,
    required this.onSave,
    required this.onPasswordChange,
  });

  @override
  State<SecuritySettingsWidget> createState() => _SecuritySettingsWidgetState();
}

class _SecuritySettingsWidgetState extends State<SecuritySettingsWidget> {
  bool _isExpanded = false;
  late Map<String, dynamic> _localSecurity;
final LocalAuthentication _auth = LocalAuthentication();

@override
void initState() {
  super.initState();
  final user = SessionService.instance.currentUser;

_localSecurity = Map<String, dynamic>.from(widget.security);

if (user != null) {
  _localSecurity['lastPasswordChange'] =
      user['last_password_change'];
}

  // Load real saved value
  _localSecurity['biometricEnabled'] =
      SessionService.instance.biometricEnabled;
}


void _handleBiometricToggle(bool value) async {
  if (value) {
    _showPasswordVerificationDialog();
  } else {
    HapticFeedback.selectionClick();

    await SessionService.instance.setBiometricEnabled(false);

    setState(() {
      _localSecurity['biometricEnabled'] = false;
    });

    widget.onSave(_localSecurity);
  }
}


  void _showPasswordVerificationDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text('Verify Password', style: theme.textTheme.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please enter your current password to enable biometric authentication.',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
onPressed: () async {
  Navigator.pop(context);
  await _verifyAndEnableBiometric(passwordController.text);
},

              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }
Future<void> _verifyAndEnableBiometric(String password) async {
  if (password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password required')),
    );
    return;
  }

  try {
    // 🔐 STEP 1 — Verify LMS password via server
    final isValid = await AuthService.instance.verifyPassword(
      password: password,
    );

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect password')),
      );
      return;
    }

    // 🔐 STEP 2 — Fingerprint verification
    final authenticated = await _auth.authenticate(
      localizedReason:
          'Confirm fingerprint to enable biometric login',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );

    if (!authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fingerprint verification failed')),
      );
      return;
    }

    // 🔐 STEP 3 — NOW enable biometric
    await SessionService.instance.setBiometricEnabled(true);

    setState(() {
      _localSecurity['biometricEnabled'] = true;
    });

    widget.onSave(_localSecurity);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometric enabled successfully')),
    );

  } catch (e) {
    debugPrint("Biometric error: $e");
  }
}



  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text('Change Password', style: theme.textTheme.titleLarge),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
ElevatedButton(
  onPressed: () async {
    if (newPasswordController.text !=
        confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    Navigator.pop(context);

    await _handlePasswordChange(
      currentPassword: currentPasswordController.text.trim(),
      newPassword: newPasswordController.text.trim(),
    );
  },
  child: const Text('Change Password'),
),
          ],
        );
      },
    );
  }

Future<void> _handlePasswordChange({
  required String currentPassword,
  required String newPassword,
}) async {
  if (currentPassword.isEmpty || newPassword.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All fields are required')),
    );
    return;
  }

  final success = await AuthService.instance.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  if (!success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to change password')),
    );
    return;
  }

  // 🔥 ADD THIS BLOCK
  final user = SessionService.instance.currentUser;

  setState(() {
    _localSecurity['lastPasswordChange'] =
        user?['last_password_change'];
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Password changed successfully')),
  );
}

  void _showSessionManagementDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text('Active Sessions', style: theme.textTheme.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSessionItem(
                context,
                'Current Device',
                'iPhone 13 Pro',
                'Active now',
                true,
              ),
              SizedBox(height: 2.h),
              _buildSessionItem(
                context,
                'MacBook Pro',
                'Last active 2 hours ago',
                'San Francisco, CA',
                false,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleEndAllSessions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: const Text('End All Other Sessions'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSessionItem(
    BuildContext context,
    String device,
    String details,
    String location,
    bool isCurrent,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: device.contains('iPhone') ? 'phone_iphone' : 'laptop_mac',
            color: theme.colorScheme.primary,
            size: 24,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  details,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  location,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Current',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleEndAllSessions() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All other sessions ended'),
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
                      iconName: 'security',
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'Security',
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
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Biometric Authentication',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                'Use fingerprint or face ID to login',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value:
                              _localSecurity['biometricEnabled'] as bool? ??
                              false,
                          onChanged: _handleBiometricToggle,
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CustomIconWidget(
                        iconName: 'lock_reset',
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      title: Text(
                        'Change Password',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Last changed: ${_localSecurity['lastPasswordChange'] as String? ?? 'Never'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: CustomIconWidget(
                        iconName: 'chevron_right',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      onTap: _showChangePasswordDialog,
                    ),
                    SizedBox(height: 1.h),
                    // ListTile(
                    //   contentPadding: EdgeInsets.zero,
                    //   leading: CustomIconWidget(
                    //     iconName: 'devices',
                    //     color: theme.colorScheme.primary,
                    //     size: 24,
                    //   ),
                    //   title: Text(
                    //     'Session Management',
                    //     style: theme.textTheme.bodyLarge?.copyWith(
                    //       fontWeight: FontWeight.w500,
                    //     ),
                    //   ),
                    //   subtitle: Text(
                    //     'Manage active sessions on other devices',
                    //     style: theme.textTheme.bodySmall?.copyWith(
                    //       color: theme.colorScheme.onSurfaceVariant,
                    //     ),
                    //   ),
                    //   trailing: CustomIconWidget(
                    //     iconName: 'chevron_right',
                    //     color: theme.colorScheme.onSurfaceVariant,
                    //     size: 24,
                    //   ),
                    //   onTap: _showSessionManagementDialog,
                    // ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
