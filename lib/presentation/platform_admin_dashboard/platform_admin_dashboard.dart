import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/main_drawer.dart';
import '../../widgets/sync_status_badge.dart';
import '../../services/api/institution_service.dart';
import '../../services/api/session_service.dart';
import '../../utils/role_utils.dart';

class PlatformAdminDashboard extends StatefulWidget {
  const PlatformAdminDashboard({super.key});

  @override
  State<PlatformAdminDashboard> createState() => _PlatformAdminDashboardState();
}

class _PlatformAdminDashboardState extends State<PlatformAdminDashboard> {


  int _currentBottomNavIndex = 0;
  bool _isLoading = false;
  String? _loadError;

  int _institutionCount = 0;
  int _activeSubscriptions = 0;
  int _suspendedSubscriptions = 0;
List<Map<String, dynamic>> _insights = [];
  @override
  void initState() {
    super.initState();
    _loadSummary();
  }
Future<void> _loadSummary() async {
  setState(() {
    _isLoading = true;
    _loadError = null;
  });

  try {
    final institutions =
        await InstitutionService.instance.listInstitutions();

    final List<Map<String, dynamic>> insightsData = [];

    for (final inst in institutions.take(5)) {
      insightsData.add({
        'title': inst['name'],
        'subtitle': inst['subscription_status'] == 'active'
            ? 'Subscription activated'
            : 'Subscription suspended',
        'icon': inst['subscription_status'] == 'active'
            ? Icons.check_circle
            : Icons.pause_circle,
        'color': inst['subscription_status'] == 'active'
            ? Colors.green
            : Colors.orange,
        'time': inst['created_at'] ?? 'Recently',
      });
    }

    final active = institutions
        .where((i) => i['subscription_status'] == 'active')
        .length;

    final suspended = institutions
        .where((i) => i['subscription_status'] == 'suspended')
        .length;

    if (!mounted) return;

    setState(() {
      _institutionCount = institutions.length;
      _activeSubscriptions = active;
      _suspendedSubscriptions = suspended;

      // ✅ CORRECT ASSIGNMENT
      _insights = insightsData;

      _isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _loadError = e.toString();
      _isLoading = false;
    });
  }
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
        title: 'Platform Admin Dashboard',
        variant: AppBarVariant.dashboard,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummary,
          ),
        ],
      ),
      drawer: MainDrawer(
        currentRoute: '/platform-admin-dashboard',
        variant: navVariant,
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
                    : SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 3.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overview',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            GridView.count(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  crossAxisCount: 2,
  crossAxisSpacing: 0,
  mainAxisSpacing: 5.h,
  childAspectRatio: 1.8, // adjust height/width feel
  children: [
    _buildStatCard(
      theme,
      title: 'Institutions',
      value: _institutionCount.toString(),
      icon: Icons.account_balance,
      color: theme.colorScheme.primary,
    ),
    _buildStatCard(
      theme,
      title: 'Active',
      value: _activeSubscriptions.toString(),
      icon: Icons.verified,
      color: Colors.green,
    ),
    _buildStatCard(
      theme,
      title: 'Suspended',
      value: _suspendedSubscriptions.toString(),
      icon: Icons.warning_amber,
      color: Colors.orange,
    ),
  ],
),

                            SizedBox(height: 3.h),
                            Text(
                              'Actions',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 1.5.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    context,
                                    label: 'Manage Institutions',
                                    icon: Icons.manage_accounts,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/institution-management',
                                    ),
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: _buildActionButton(
                                    context,
                                    label: 'Role Access',
                                    icon: Icons.admin_panel_settings,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/role-access-management',
                                    ),
                                  ),
                                ),
                              ],
                            ),

SizedBox(height: 3.h),

Text(
  'Insights',
  style: theme.textTheme.titleLarge?.copyWith(
    fontWeight: FontWeight.bold,
  ),
),

SizedBox(height: 1.h),

Card(
  elevation: 2,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  child: _insights.isEmpty
      ? Padding(
          padding: EdgeInsets.all(4.w),
          child: Text(
            'No recent activity',
            style: theme.textTheme.bodyMedium,
          ),
        )
      : ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _insights.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = _insights[index];

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: item['color'].withOpacity(0.15),
                child: Icon(
                  item['icon'],
                  color: item['color'],
                ),
              ),
              title: Text(
                item['title'],
                style: theme.textTheme.labelLarge,
              ),
              subtitle: Text(item['subtitle']),
              trailing: Text(
                item['time'],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
),

                          ],
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        variant: BottomBarVariant.platformAdmin,
      ),

    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
Widget _buildActionButton(
  BuildContext context, {
  required String label,
  required IconData icon,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      height: 56, // consistent touch target
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.primary,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),

          // ✅ THIS PREVENTS OVERFLOW
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


}