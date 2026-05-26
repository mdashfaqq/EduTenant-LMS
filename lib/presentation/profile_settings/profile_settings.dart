import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/sync_status_badge.dart';
import '../../services/api/session_service.dart';
import '../../utils/role_utils.dart';
import './widgets/academic_details_widget.dart';
import './widgets/app_preferences_widget.dart';
import './widgets/notification_preferences_widget.dart';
import './widgets/personal_information_widget.dart';
import './widgets/privacy_settings_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/security_settings_widget.dart';
import '../../services/api/users_service.dart';

//
//
//

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {

  final ScrollController _scrollController = ScrollController();
  String get _currentRole =>
    (SessionService.instance.currentUser?['role'] ?? '')
        .toString()
        .toLowerCase();

late Map<String, dynamic> _userData;

String get _role =>
    (SessionService.instance.currentUser?['role'] ?? '')
        .toString()
        .toLowerCase();

bool get isStudent => _role == 'student';
bool get isTeacher => _role == 'instructor';
bool get isAdmin => _role == 'admin';
  bool _isLoading = false;
  String _saveStatus = '';

  @override
  void initState() {
    super.initState();
          _loadUser();
    _hydrateFromSession();
    _refreshUserFromBackend();

  }

void _loadUser() {
  final user = SessionService.instance.currentUser;

  if (user == null) {
    _userData = {};
    return;
  }

  _userData = _deepConvert(user);
}


Future<void> _refreshUserFromBackend() async {
  
  final userId = SessionService.instance.currentUser?['id'];
  if (userId == null) return;

  try {
    
    final freshUser =
        await UsersService.instance.getUserById(userId);
print("FRESH USER → $freshUser");
    await SessionService.instance.setCurrentUser(freshUser);

    setState(() {
      _userData = Map<String, dynamic>.from(freshUser);

      // 🔥 ADD THIS LINE
      _userData['institution'] =
          SessionService.instance.institutionName;
    });

  } catch (e) {
    debugPrint("Failed to refresh user: $e");
  }
}
Map<String, dynamic> _deepConvert(Map source) {
  return source.map<String, dynamic>((key, value) {
    if (value is Map) {
      return MapEntry(key.toString(), _deepConvert(value));
    } else {
      return MapEntry(key.toString(), value);
    }
  });
}
  void _hydrateFromSession() {
    print("Institution from session: ${SessionService.instance.institutionName}");
    final user = SessionService.instance.currentUser;
    if (user == null) return;

    _userData['name'] = user['name'] ?? _userData['name'];
    _userData['email'] = user['email'] ?? _userData['email'];
    _userData['role'] = roleLabel(user['role']?.toString());

    final institutionName = SessionService.instance.institutionName;
    if (institutionName != null && institutionName.trim().isNotEmpty) {
      _userData['institution'] = institutionName;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'camera_alt',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('Take Photo', style: theme.textTheme.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  _handlePhotoSelection('camera');
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'photo_library',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: theme.textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handlePhotoSelection('gallery');
                },
              ),
              if (_userData["avatar"] != null)
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'delete',
                    color: theme.colorScheme.error,
                    size: 24,
                  ),
                  title: Text(
                    'Remove Photo',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _handlePhotoRemoval();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _handlePhotoSelection(String source) {
    HapticFeedback.selectionClick();
    setState(() {
      _saveStatus = 'Photo updated successfully';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _saveStatus = '';
        });
      }
    });
  }

  void _handlePhotoRemoval() {
    HapticFeedback.selectionClick();
    setState(() {
      _userData["avatar"] = null;
      _saveStatus = 'Photo removed successfully';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _saveStatus = '';
        });
      }
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text('Logout', style: theme.textTheme.titleLarge),
          content: Text(
            'Are you sure you want to logout? Your session will be cleared.',
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
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

void _performLogout() async {
  HapticFeedback.selectionClick();

  final role =
      SessionService.instance.currentUser?['role']?.toString().toLowerCase();

  await SessionService.instance.clearSession();

  if (!mounted) return;

  if (role == 'platform_admin') {
    // Platform admin exits global scope
    await SessionService.instance.clearInstitution();

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/institution-setup',
      (route) => false,
    );
  } else {
    // Institution users remain in tenant scope
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login-screen',
      (route) => false,
    );
  }
}

void _handleSave(String section, Map<String, dynamic> updatedData) async {
  HapticFeedback.selectionClick();

  final userId = SessionService.instance.currentUser?['id'];
  if (userId == null) return;

  setState(() {
    _isLoading = true;
    _saveStatus = '';
  });

  try {
    final updatedUser =
        await UsersService.instance.updateUser(userId, updatedData);

    // 🔥 Update session with returned backend data
  await SessionService.instance.setCurrentUser(updatedUser);

    setState(() {
      _userData = Map<String, dynamic>.from(updatedUser);
      _isLoading = false;
      _saveStatus = 'Changes saved successfully';
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
      _saveStatus = 'Failed to save changes';
    });

    debugPrint("Update error: $e");
  }

  Future.delayed(const Duration(seconds: 2), () {
    if (mounted) {
      setState(() => _saveStatus = '');
    }
  });
}




  @override
  Widget build(BuildContext context) {
    
    final theme = Theme.of(context);
    final navVariant = bottomBarVariantFromRole(
      SessionService.instance.currentUser?['role']?.toString(),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Profile & Settings',
        variant: AppBarVariant.standard,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  ProfileHeaderWidget(
                    userData: _userData,
                    onPhotoTap: _showPhotoOptions,
                  ),
                  SizedBox(height: 2.h),
                  PersonalInformationWidget(
                    userData: _userData,
                    onSave: (data) => _handleSave('personal', data),
                  ),
                  SizedBox(height: 2.h),
AcademicDetailsWidget(
  userData: _userData,
  role: _role,
  onSave: (data) => _handleSave('academic', data),
),
//                   SizedBox(height: 2.h),
//                   NotificationPreferencesWidget(
// preferences: Map<String, dynamic>.from(
//   _userData["notificationPreferences"] ?? {},
// ),
//                     onSave: (data) => _handleSave('notifications', {
//                       "notificationPreferences": data,
//                     }),
//                   ),
//                   SizedBox(height: 2.h),
//                   PrivacySettingsWidget(
// settings: Map<String, dynamic>.from(
//   _userData["privacySettings"] ?? {},
// ),
//                     onSave: (data) =>
//                         _handleSave('privacy', {"privacySettings": data}),
//                   ),
                  SizedBox(height: 2.h),
                  AppPreferencesWidget(
preferences: Map<String, dynamic>.from(
  _userData["appPreferences"] ?? {},
),
                    onSave: (data) =>
                        _handleSave('appPreferences', {"appPreferences": data}),
                  ),
                  SizedBox(height: 2.h),
                  SecuritySettingsWidget(
security: Map<String, dynamic>.from(
  _userData["security"] ?? {},
),
                    onSave: (data) =>
                        _handleSave('security', {"security": data}),
                    onPasswordChange: () {
                      // Navigate to password change screen
                    },
                  ),
                  SizedBox(height: 3.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                        ),
                        child: Text(
                          'Logout',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onError,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
          if (_saveStatus.isNotEmpty)
            Positioned(
              top: 2.h,
              left: 4.w,
              right: 4.w,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.primary,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'check_circle',
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          _saveStatus,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        variant: navVariant,
      ),





    );
  }
}

