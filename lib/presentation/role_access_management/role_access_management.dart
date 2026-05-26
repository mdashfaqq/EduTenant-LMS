import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/sync_status_badge.dart';
import '../../services/api/role_access_service.dart';
import '../../services/api/session_service.dart';
import '../../utils/role_utils.dart';

class RoleAccessManagement extends StatefulWidget {
  const RoleAccessManagement({super.key});

  @override
  State<RoleAccessManagement> createState() => _RoleAccessManagementState();
}

class _RoleAccessManagementState extends State<RoleAccessManagement> {
  final List<String> _roles = const [
    'platform_admin',
    'admin',
    'instructor',
    'student',
    'parent',
  ];

  final Map<String, List<String>> _permissions = {};
  bool _isLoading = false;
  String? _loadError;


  final List<Map<String, String>> _screens = const [
    {'id': '/admin-course-management', 'label': 'Admin Dashboard'},
    {'id': '/user-management', 'label': 'User Management'},
    {'id': '/course-list', 'label': 'Courses'},
    {'id': '/attendance-management', 'label': 'Attendance'},
    {'id': '/bulk-attendance-dashboard', 'label': 'Bulk Attendance'},
    {'id': '/exams-results', 'label': 'Exams & Results'},
    {'id': '/discussion-forum', 'label': 'Discussions'},
    {'id': '/profile-settings', 'label': 'Profile Settings'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }
  List<CustomBottomBarItem> _platformAdminItems() {
    return const [
        CustomBottomBarItem(
          icon: Icons.dashboard,
          label: 'Dashboard',
          route: '/platform-admin-dashboard',
        ),
      CustomBottomBarItem(
        icon: Icons.business,
        label: 'Institutions',
        route: '/institution-management',
      ),
      CustomBottomBarItem(
        icon: Icons.security,
        label: 'Roles',
        route: '/role-access-management',
      ),
      CustomBottomBarItem(
        icon: Icons.people_outline,
        label: 'Users',
        route: '/user-management',
      ),
      CustomBottomBarItem(
        icon: Icons.settings,
        label: 'Settings',
        route: '/profile-settings',
      ),
    ];
  }

Future<void> _loadPermissions() async {
  setState(() {
    _isLoading = true;
    _loadError = null;
  });

  try {
    await SessionService.instance.init();

    final currentRole = normalizeRoleValue(
      SessionService.instance.currentUser?['role']?.toString(),
    );

    if (currentRole != 'platform_admin') {
      throw Exception('Access denied: Platform Admin only');
    }

    final institutionCode =
        SessionService.instance.currentUser?['institution_code'];

final items = await RoleAccessService.instance.listPermissions();

    final Map<String, List<String>> perms = {};

    for (final item in items) {
      final role = normalizeRoleValue(item['role']?.toString());

      final routes =
          (item['permissions'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList();

      perms[role] = routes;
    }

    setState(() {
      _permissions
        ..clear()
        ..addAll(perms);
    });
  } catch (e) {
    setState(() {
      _loadError = e.toString();
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> _togglePermission(String role, String screenId, bool enabled) async {
    final normalizedRole = normalizeRoleValue(role);
    final current = List<String>.from(_permissions[normalizedRole] ?? []);
    if (enabled) {
      if (!current.contains(screenId)) current.add(screenId);
    } else {
      current.remove(screenId);
    }
    setState(() {
      _permissions[normalizedRole] = current;
    });
    await RoleAccessService.instance.updatePermissions(
      role: normalizedRole,
      permissions: current,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated $role access')),
    );
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
        title: 'Role Access Management',
        variant: AppBarVariant.standard,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPermissions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Text(
                            _loadError!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(4.w),
                        itemCount: _roles.length,
                        itemBuilder: (context, index) {
                          final role = _roles[index];
                          final perms = _permissions[role] ?? [];
                          return Card(
                            margin: EdgeInsets.only(bottom: 2.h),
                            child: Padding(
                              padding: EdgeInsets.all(3.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    roleLabel(role),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _screens.map((screen) {
                                      final enabled = perms.contains(screen['id']);
                                      return FilterChip(
                                        label: Text(screen['label'] ?? ''),
                                        selected: enabled,
                                        onSelected: (value) {
                                          _togglePermission(
                                            role,
                                            screen['id'] ?? '',
                                            value,
                                          );
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        variant: BottomBarVariant.platformAdmin,
      ),


    );
  }
}
