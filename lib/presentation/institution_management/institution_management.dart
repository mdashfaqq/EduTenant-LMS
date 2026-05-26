import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/custom_bottom_bar.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../widgets/custom_app_bar.dart';
import '../../widgets/sync_status_badge.dart';
import '../../services/api/institution_service.dart';
import '../../services/api/session_service.dart';
import '../../utils/role_utils.dart';
import './widgets/create_institution_dialog.dart';
import './widgets/edit_institution_dialog.dart';
import './widgets/institution_card_widget.dart';
import './widgets/institution_detail_view.dart';

class InstitutionManagement extends StatefulWidget {
  const InstitutionManagement({super.key});

  @override
  State<InstitutionManagement> createState() => _InstitutionManagementState();
}

class _InstitutionManagementState extends State<InstitutionManagement> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  List<Map<String, dynamic>> _filteredInstitutions = [];
  bool _isLoading = false;
  String? _loadError;
  bool _isPlatformAdmin = false;
  bool _roleChecked = false;
  File? _logoFile;
  bool _uploading = false;

  List<Map<String, dynamic>> _institutions = [];

  @override
  void initState() {
    super.initState();
    _initRole();
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
        route: '/platform-user-management',
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
  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _logoFile = File(image.path);
      });
    }
  }
Future<String?> _uploadLogo(String institutionCode) async {
  if (_logoFile == null) return null;

  final uri = Uri.parse(
    'https://unreadymades.com/LMS/edutenant_lms_backend/api/upload_institution_logo.php', // ← FIX THIS
  );

  final request = http.MultipartRequest('POST', uri)
    ..fields['institution_code'] = institutionCode
    ..files.add(
      await http.MultipartFile.fromPath('logo', _logoFile!.path),
    );

  final response = await request.send();
  final responseBody = await response.stream.bytesToString();

  if (response.statusCode != 200) {
    throw Exception(
      'Logo upload failed (${response.statusCode}): $responseBody',
    );
  }

  final decoded = jsonDecode(responseBody);

  if (decoded['success'] != true) {
    throw Exception(decoded['message'] ?? 'Upload failed');
  }

  return decoded['data']['logo'];
}
  Future<void> _initRole() async {
    await SessionService.instance.init();
    final role = normalizeRoleValue(
      SessionService.instance.currentUser?['role']?.toString(),
    );
    final isPlatformAdmin = role == 'platform_admin';
    if (mounted) {
      setState(() {
        _isPlatformAdmin = isPlatformAdmin;
        _roleChecked = true;
      });
    }
    if (isPlatformAdmin) {
      _searchController.addListener(_filterInstitutions);
      await _loadInstitutions();
    } else {
      setState(() {
        _loadError = 'Access denied: Platform Admin only';
      });
    }
  }

  Future<void> _loadInstitutions() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final institutions = await InstitutionService.instance.listInstitutions();
      if (!mounted) return;
      setState(() {
        _institutions = institutions.map(_toUiInstitution).toList();
        _filteredInstitutions = List.from(_institutions);
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

  Map<String, dynamic> _toUiInstitution(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'name': data['name'] ?? '',
      'code': data['institution_code'] ?? '',
      'logo': data['logo'] != null && data['logo'].toString().isNotEmpty
          ? 'https://unreadymades.com/LMS/edutenant_lms_backend${data['logo']}'
          : null,

      'semanticLabel': 'Institution logo',
      'address': data['address'] ?? '',
      'contactEmail': data['contact_email'] ?? '',
      'contactPhone': data['contact_phone'] ?? '',
      'subscriptionStatus': data['subscription_status'] ?? 'active',
      'subscriptionExpiry': data['subscription_expiry'] ?? '',
      'userCount': data['user_count'] ?? 0,
      'userLimit': data['user_limit'] ?? 0,
      'academicYear': data['academic_year'] ?? '',
      'primaryColor': data['primary_color'] ?? '',
      'modules': {
        'courses': data['modules_courses'] == 1 || data['modules_courses'] == true,
        'assignments':
            data['modules_assignments'] == 1 || data['modules_assignments'] == true,
        'grades': data['modules_grades'] == 1 || data['modules_grades'] == true,
        'attendance':
            data['modules_attendance'] == 1 || data['modules_attendance'] == true,
        'fees': data['modules_fees'] == 1 || data['modules_fees'] == true,
        'discussions':
            data['modules_discussions'] == 1 || data['modules_discussions'] == true,
        'exams': data['modules_exams'] == 1 || data['modules_exams'] == true,
      },
      'createdDate': data['created_date'] ?? '',
      'lastModified': data['last_modified'] ?? '',
    };
  }

  void _filterInstitutions() {
    setState(() {
      _filteredInstitutions = _institutions.where((institution) {
        final matchesSearch =
            institution['name'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            institution['code'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );

        final matchesStatus =
            _selectedStatus == 'all' ||
            institution['subscriptionStatus'] == _selectedStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  String _generateInstitutionCode() {
    final random = Random();
    String code;
    do {
      code = (100000 + random.nextInt(900000)).toString();
    } while (_institutions.any((inst) => inst['code'] == code));
    return code;
  }

 void _showCreateInstitutionDialog() {
  final generatedCode = _generateInstitutionCode();

  showDialog(
    context: context,
    builder: (context) => CreateInstitutionDialog(
      generatedCode: generatedCode,
      onAdd: (data, File? logoFile) async {
        try {
          // 1️⃣ CREATE institution FIRST
          final created =
              await InstitutionService.instance.createInstitution({
            'institution_code': data['code'],
            'name': data['name'],
            'user_limit': data['userLimit'],
            'modules_courses': data['modules']['courses'],
            'modules_assignments': data['modules']['assignments'],
            'modules_grades': data['modules']['grades'],
            'modules_attendance': data['modules']['attendance'],
            'modules_fees': data['modules']['fees'],
            'modules_discussions': data['modules']['discussions'],
            'modules_exams': data['modules']['exams'],
          });

          String? logoPath;

          // 2️⃣ UPLOAD logo ONLY AFTER creation
          if (logoFile != null) {
            logoPath =
                await InstitutionService.instance.uploadInstitutionLogo(
              data['code'],
              logoFile,
            );

            // 3️⃣ UPDATE institution with logo path
            await InstitutionService.instance.updateInstitution(
              data['code'],
              {'logo': logoPath},
            );
          }

          if (!mounted) return;

          setState(() {
            _institutions.add(
              _toUiInstitution({
                ...created,
                'logo': logoPath ?? created['logo'],
              }),
            );
            _filterInstitutions();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Institution "${data['name']}" created successfully'),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Creation failed: $e')),
          );
        }
      },
    ),
  );
}


void _showEditInstitutionDialog(Map<String, dynamic> institution) {
  showDialog(
    context: context,
    builder: (ctx) => EditInstitutionDialog(
      institution: institution,
      onUpdate: (payload, File? logoFile) async {
        try {
          debugPrint('🟣 [Parent] Payload: $payload');
          debugPrint('🟣 [Parent] Logo: ${logoFile?.path}');

          // 1️⃣ Upload logo if changed
          if (logoFile != null) {
            final logoPath =
                await InstitutionService.instance.uploadInstitutionLogo(
              institution['code'],
              logoFile,
            );
            payload['logo'] = logoPath;
          }

          // 2️⃣ Update institution
          final updated =
              await InstitutionService.instance.updateInstitution(
            institution['code'],
            payload,
          );

          if (!mounted) return;

          setState(() {
            final i = _institutions.indexWhere(
              (e) => e['id'] == institution['id'],
            );
            if (i != -1) {
              _institutions[i] = _toUiInstitution(updated);
              _filterInstitutions();
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Institution "${updated['name']}" updated successfully',
              ),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Update failed: $e')),
          );
        }
      },
    ),
  );
}

  void _showInstitutionDetail(Map<String, dynamic> institution) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstitutionDetailView(
          institution: institution,
          onEdit: () {
            Navigator.pop(context);
            _showEditInstitutionDialog(institution);
          },
          onDelete: () {
            Navigator.pop(context);
            _toggleSuspendInstitution(institution);
          },
        ),
      ),
    );
  }

void _toggleSuspendInstitution(Map<String, dynamic> institution) {
  final isSuspended =
      institution['subscriptionStatus'] == 'suspended';

  final newStatus = isSuspended ? 'active' : 'suspended';

  final scaffoldMessenger = ScaffoldMessenger.of(context); // ✅ capture safely

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        isSuspended ? 'Activate Institution' : 'Suspend Institution',
      ),
      content: Text(
        isSuspended
            ? 'Do you want to activate "${institution['name']}"?'
            : 'Do you want to suspend "${institution['name']}"?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(dialogContext); // ✅ close dialog

            try {
              await InstitutionService.instance
                  .updateSubscriptionStatus(
                institution['code'],
                newStatus,
              );

              if (!mounted) return;

              setState(() {
                institution['subscriptionStatus'] = newStatus;
                _filterInstitutions();
              });

              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Institution ${newStatus == 'suspended' ? 'suspended' : 'activated'} successfully',
                  ),
                ),
              );
            } catch (e) {
              if (!mounted) return;

              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('Operation failed: $e')),
              );
            }
          },
          child: Text(
            isSuspended ? 'Activate' : 'Suspend',
            style: TextStyle(
              color: isSuspended
                  ? Colors.green
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ),
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
        title: 'Institution Management',
        variant: AppBarVariant.standard,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _isPlatformAdmin ? _showCreateInstitutionDialog : null,
            tooltip: 'Add Institution',
          ),
          if (_isPlatformAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.pushNamed(context, '/role-access-management');
              },
              tooltip: 'Role Access',
            ),
        ],
      ),
      body: Column(
        children: [
          if (!_roleChecked)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (!_isPlatformAdmin)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                'Access denied: Platform Admin only',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or code...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterInstitutions();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  // Status Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        SizedBox(width: 2.w),
                        _buildFilterChip('Active', 'active'),
                        SizedBox(width: 2.w),
                        _buildFilterChip('Suspended', 'suspended'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Institution List
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
                : _filteredInstitutions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No institutions found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'Try adjusting your search'
                              : 'Create your first institution',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadInstitutions,
                    child: ListView.builder(
                      padding: EdgeInsets.all(4.w),
                      itemCount: _filteredInstitutions.length,
                      itemBuilder: (context, index) {
                        final institution = _filteredInstitutions[index];
                        return InstitutionCardWidget(
                          institution: institution,
                          onTap: () => _showInstitutionDetail(institution),
                          onEdit: () => _showEditInstitutionDialog(institution),
                          onDelete: () => _toggleSuspendInstitution(institution),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _isPlatformAdmin
          ? FloatingActionButton.extended(
              onPressed: _showCreateInstitutionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Institution'),
            )
          : null,
      bottomNavigationBar: CustomBottomBar(
        variant: navVariant,
      ),



    );
  }

  Widget _buildFilterChip(String label, String value) {
    final theme = Theme.of(context);
    final isSelected = _selectedStatus == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
          _filterInstitutions();
        });
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
