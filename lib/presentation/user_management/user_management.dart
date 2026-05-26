import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/sync_status_badge.dart';
import '../../services/api/users_service.dart';
import '../../services/api/session_service.dart';
import '../../utils/role_utils.dart';
import './widgets/user_card_widget.dart';
import './widgets/add_user_dialog.dart';
import './widgets/edit_user_dialog.dart';
import './widgets/user_detail_view.dart';
import './widgets/bulk_operations_sheet.dart';
import '../../services/api/institution_service.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'all';
  String _selectedStatus = 'all';
  String _selectedDepartment = 'all';
  bool _isMultiSelectMode = false;
  final Set<int> _selectedUsers = {};
  List<Map<String, dynamic>> _filteredUsers = [];
Map<String, String> _institutionMap = {};
  bool _isLoading = false;
  String? _loadError;

  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterUsers);
    _loadUsers();
      _loadInstitutions(); 
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


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final users = await UsersService.instance.listUsers();

      final currentRole =
      SessionService.instance.currentUser?['role']?.toString();

      final filtered = currentRole == 'platform_admin'
          ? users // platform admin can see everyone
          : users.where((u) => u['role'] != 'platform_admin').toList();

      if (!mounted) return;
      setState(() {
        _users = filtered;
        _filteredUsers = List.from(filtered);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

Future<void> _loadInstitutions() async {
  try {
    final institutions =
        await InstitutionService.instance.listInstitutions();

    final map = <String, String>{};
debugPrint("Institutions API response: $institutions");
    for (var inst in institutions) {
      map[inst['institution_code'].toString()] = inst['name'].toString();
    }

    if (!mounted) return;

    setState(() {
      _institutionMap = map;
    });

    debugPrint("Institution map: $map");
  } catch (e) {
    debugPrint("Institution load failed: $e");
  }
}
  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch =
            user['name'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            user['email'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
        final matchesRole =
            _selectedRole == 'all' ||
            normalizeRoleValue(user['role']?.toString()) ==
                normalizeRoleValue(_selectedRole);
        final matchesStatus =
            _selectedStatus == 'all' || user['status'] == _selectedStatus;
        final matchesDepartment =
            _selectedDepartment == 'all' ||
            user['department'] == _selectedDepartment;
        return matchesSearch &&
            matchesRole &&
            matchesStatus &&
            matchesDepartment;
      }).toList();
    });
  }

  void _showAddUserDialog() {
    HapticFeedback.mediumImpact();
    final scaffoldContext = context; 
    showDialog(
      context: context,
      builder: (context) => AddUserDialog(
        onAdd: (userData) async {
          try {
final payload = {
  'name': userData['name'],
  'email': userData['email'],
  'password': userData['password'],
  'role': userData['role'],
  'department': userData['department'],
  'status': userData['status'],

  // 🔥 ADD THESE
  'discount_type': userData['discount_type'] ?? 'none',
  'discount_value': userData['discount_value'] ?? 0,
  'discount_reason': userData['discount_reason'] ?? '',
};
if (userData['course_ids'] != null) {
  payload['course_ids'] = userData['course_ids'];
}

if (userData['instructor_map'] != null) {
  payload['instructor_map'] =
      (userData['instructor_map'] as Map).map(
        (k, v) => MapEntry(k.toString(), v),
      );
}

if (userData['institution_code'] != null) {
  payload['institution_code'] = userData['institution_code'];
}
debugPrint("CREATE USER PAYLOAD:");
debugPrint(payload.toString());
            final created = await UsersService.instance.createUser(payload);
            if (!mounted) return;
            setState(() {
              _users.add(created);
              _filterUsers();
            });
ScaffoldMessenger.of(scaffoldContext).showSnackBar(
  const SnackBar(content: Text('User added successfully')),
);
          } catch (e) {
            if (!mounted) return;
ScaffoldMessenger.of(scaffoldContext).showSnackBar(
  SnackBar(content: Text('Failed to add user: $e')),
);
          }
        },
      ),
    );
  }

 void _showEditUserDialog(Map<String, dynamic> user) async {
  HapticFeedback.mediumImpact();

  try {
    // 🔥 FETCH FULL USER (WITH DISCOUNT)
    final fullUser =
        await UsersService.instance.getUserById(user['id']);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => EditUserDialog(
        user: fullUser,   // ✅ FIXED
        currentUserRole:
            SessionService.instance.currentUser?['role']?.toString() ?? '',
        onUpdate: (updatedData) async {
          try {
            final updated = await UsersService.instance.updateUser(
              user['id'] as int,
              updatedData,
            );
            if (!mounted) return;
            setState(() {
              final index = _users.indexWhere((u) => u['id'] == user['id']);
              if (index != -1) {
                _users[index] = updated;
                _filterUsers();
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User updated successfully')),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update user: $e')),
            );
          }
        },
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load user: $e')),
    );
  }
}

  void _showUserDetail(Map<String, dynamic> user) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserDetailView(
        user: user,
        onEdit: () {
          Navigator.pop(context);
          _showEditUserDialog(user);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteUser(user['id']);
        },
        onResetPassword: () {
          Navigator.pop(context);
          _resetPassword(user);
        },
      ),
    );
  }

  void _deleteUser(int userId) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDeleteUser(userId);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteUser(int userId) async {
    try {
      await UsersService.instance.deleteUser(userId);
      if (!mounted) return;
      setState(() {
        _users.removeWhere((u) => u['id'] == userId);
        _filterUsers();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    }
  }

  void _resetPassword(Map<String, dynamic> user) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password reset link sent to ${user['email']}'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleMultiSelect() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedUsers.clear();
      }
    });
    HapticFeedback.selectionClick();
  }

  void _toggleUserSelection(int userId) {
    setState(() {
      if (_selectedUsers.contains(userId)) {
        _selectedUsers.remove(userId);
      } else {
        _selectedUsers.add(userId);
      }
    });
    HapticFeedback.selectionClick();
  }

  void _showBulkOperations() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BulkOperationsSheet(
        selectedCount: _selectedUsers.length,
        onBulkImport: _handleBulkImport,
        onBulkStatusChange: _handleBulkStatusChange,
        onBulkRoleChange: _handleBulkRoleChange,
        onBulkDelete: _handleBulkDelete,
      ),
    );
  }

  Future<void> _handleBulkImport() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'CSV file imported successfully. Processing users...',
            ),
            duration: Duration(seconds: 2),
          ),
        );
        // In production, parse CSV and add users
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import CSV: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleBulkStatusChange(String status) async {
    final selectedIds = _selectedUsers.toList();
    Navigator.pop(context);

    try {
      await Future.wait(
        selectedIds.map(
          (id) => UsersService.instance.updateUser(id, {'status': status}),
        ),
      );
      if (!mounted) return;
      setState(() {
        for (var userId in selectedIds) {
          final index = _users.indexWhere((u) => u['id'] == userId);
          if (index != -1) {
            _users[index]['status'] = status;
          }
        }
        _filterUsers();
        _selectedUsers.clear();
        _isMultiSelectMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedIds.length} users updated to $status'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bulk update failed: $e')),
      );
    }
  }

  Future<void> _handleBulkRoleChange(String role) async {
    final selectedIds = _selectedUsers.toList();
    Navigator.pop(context);

    try {
      await Future.wait(
        selectedIds.map(
          (id) => UsersService.instance.updateUser(id, {'role': role}),
        ),
      );
      if (!mounted) return;
      setState(() {
        for (var userId in selectedIds) {
          final index = _users.indexWhere((u) => u['id'] == userId);
          if (index != -1) {
            _users[index]['role'] = role;
          }
        }
        _filterUsers();
        _selectedUsers.clear();
        _isMultiSelectMode = false;
      });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${selectedIds.length} users role changed to ${roleLabel(role)}',
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bulk update failed: $e')),
      );
    }
  }

  void _handleBulkDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Users'),
        content: Text(
          'Are you sure you want to delete ${_selectedUsers.length} users?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final selectedIds = _selectedUsers.toList();
              Navigator.pop(context);
              _performBulkDelete(selectedIds);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkDelete(List<int> selectedIds) async {
    try {
      await Future.wait(
        selectedIds.map((id) => UsersService.instance.deleteUser(id)),
      );
      if (!mounted) return;
      setState(() {
        _users.removeWhere((u) => selectedIds.contains(u['id']));
        _filterUsers();
        _selectedUsers.clear();
        _isMultiSelectMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected users deleted successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bulk delete failed: $e')),
      );
    }
  }

  void _showFilterSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filter Users',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text('Role', style: theme.textTheme.titleSmall),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            children: [
              'all',
              'student',
              'instructor',
              'admin',
              'platform_admin',
              'parent',
            ]
                .map(
                  (role) => FilterChip(
                    label: Text(role == 'all' ? 'All' : roleLabel(role)),
                    selected: _selectedRole == role,
                    onSelected: (selected) {
                      setState(() => _selectedRole = role);
                      _filterUsers();
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 2.h),
          Text('Status', style: theme.textTheme.titleSmall),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            children: ['all', 'active', 'inactive']
                .map(
                  (status) => FilterChip(
                    label: Text(status == 'all' ? 'All' : status.toUpperCase()),
                    selected: _selectedStatus == status,
                    onSelected: (selected) {
                      setState(() => _selectedStatus = status);
                      _filterUsers();
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 2.h),
        ],
      ),
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
        title: 'User Management',
        variant: AppBarVariant.standard,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddUserDialog,
            tooltip: 'Add User',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterUsers();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Active Filters
          if (_selectedRole != 'all' || _selectedStatus != 'all')
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  Text(
                    'Filters:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  if (_selectedRole != 'all')
                    Chip(
                      label: Text(_selectedRole),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() => _selectedRole = 'all');
                        _filterUsers();
                      },
                    ),
                  SizedBox(width: 2.w),
                  if (_selectedStatus != 'all')
                    Chip(
                      label: Text(_selectedStatus.toUpperCase()),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() => _selectedStatus = 'all');
                        _filterUsers();
                      },
                    ),
                ],
              ),
            ),

          // User List
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
                : _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No users found',
                          style: theme.textTheme.titleMedium,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Try adjusting your filters',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _filteredUsers.length,
itemBuilder: (context, index) {
  final user = _filteredUsers[index];
  final isSelected = _selectedUsers.contains(user['id']);

  return UserCardWidget(
    user: user,
    institutionMap: _institutionMap,
    isMultiSelectMode: _isMultiSelectMode,
    isSelected: isSelected,
    onTap: () {
      if (_isMultiSelectMode) {
        _toggleUserSelection(user['id']);
      } else {
        _showUserDetail(user);
      }
    },
    onLongPress: () {
      if (!_isMultiSelectMode) {
        _toggleMultiSelect();
        _toggleUserSelection(user['id']);
      }
    },
    onEdit: () => _showEditUserDialog(user),
    onDelete: () => _deleteUser(user['id']),
  );
}
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
      bottomNavigationBar: CustomBottomBar(
        variant: navVariant,
      ),



    );
  }
}
