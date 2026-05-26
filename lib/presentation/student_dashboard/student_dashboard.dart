import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../services/api/courses_service.dart';
import '../../core/app_export.dart';
import '../../services/api/session_service.dart';
import '../../services/api/attendance_service.dart';
import '../../services/api/fees_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/main_drawer.dart';
import '../../widgets/sync_status_badge.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}


class _StudentDashboardState extends State<StudentDashboard> {
  bool _isRefreshing = false;
  int _notificationCount = 0;
int _coursesCount = 0;
double _attendance = 0;
String _feesStatus = "N/A";
bool _loadingStats = true;
String? _errorMessage;
String _getFormattedDate() {
  final now = DateTime.now();
  return "${_getMonth(now.month)} ${now.day}";
}

double _pendingAmount = 0;
String _getFormattedTime() {
  final now = DateTime.now();
  final hour = now.hour > 12 ? now.hour - 12 : now.hour;
  final period = now.hour >= 12 ? "PM" : "AM";
  return "${hour == 0 ? 12 : hour}:${now.minute.toString().padLeft(2, '0')} $period";
}

String _getMonth(int month) {
  const months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];
  return months[month - 1];
}
@override
void initState() {
  super.initState();
  _loadDashboardStats();
}


Future<void> _loadDashboardStats() async {
  setState(() {
    _loadingStats = true;
    _errorMessage = null;
  });

  try {
    final courses = await CoursesService.instance.listCourses();

    final courseCount = courses.length;

   final attendance =
    await AttendanceService.instance.getDashboardAttendance();
final feesData = await FeesService.instance.getDashboardFees();

final feesStatus = feesData['fees_status'] ?? "N/A";
final pendingAmount = (feesData['pending_amount'] ?? 0).toDouble();

setState(() {
  _coursesCount = courseCount;
  _attendance = attendance;
  _feesStatus = feesStatus;
  _pendingAmount = pendingAmount;
  _loadingStats = false;
});
  } catch (e) {
    setState(() {
      _loadingStats = false;
      _errorMessage = "Failed to load dashboard";
    });
  }
}
  @override
Future<void> _handleRefresh() async {
  HapticFeedback.mediumImpact();

  await _loadDashboardStats();

  if (!mounted) return;
  HapticFeedback.lightImpact();
}
  Widget _statItem(String title, String value, IconData icon) {
  final theme = Theme.of(context);

  return Column(
    children: [
      Icon(icon, color: theme.colorScheme.primary),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      Text(
        title,
        style: const TextStyle(fontSize: 12),
      ),
    ],
  );
}

Widget _buildSection(String title, List<Widget> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 10),

      GridView.count(
        shrinkWrap: true,
        crossAxisCount: 4,
        physics: const NeverScrollableScrollPhysics(),
        children: items,
        childAspectRatio: 0.85,
      ),

      const SizedBox(height: 20),
    ],
  );
}

Widget _menuItem(String label, IconData icon, String route) {
  final theme = Theme.of(context);

  return InkWell(
onTap: () {
  if (label == "Courses" && _coursesCount == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No courses available")),
    );
    return;
  }

  Navigator.pushNamed(context, route);
},
    borderRadius: BorderRadius.circular(14),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
  colors: [
    theme.colorScheme.primary.withOpacity(0.25),
    theme.colorScheme.primary.withOpacity(0.1),
  ],
),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 6),
Text(
  label,
  style: const TextStyle(fontSize: 12),
  textAlign: TextAlign.center,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    
    final theme = Theme.of(context);
    final user = SessionService.instance.currentUser;
    final institution = SessionService.instance.institutionName;
    final role = user?['role']?.toString();
    final navVariant = bottomBarVariantFromRole(role);

    final studentName = user?['name']?.toString() ?? 'Student';
    final email = user?['email']?.toString() ?? '';
if (user == null) {
  return const Scaffold(
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );
}
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: MainDrawer(
        currentRoute: '/student-dashboard',
        variant: navVariant,
      ),
      appBar: CustomAppBar(
        title: 'Dashboard',
        variant: AppBarVariant.dashboard,
        notificationCount: _notificationCount,
        onNotificationTap: () {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No new notifications')),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
child: Column(
          children: [
            // const SyncStatusBadge(showTimestamp: true, compact: false),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= WELCOME =================
                    Text(
                      'Welcome back,',
                      style: theme.textTheme.bodyMedium,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      studentName,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),

                    if (email.isNotEmpty) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        email,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],

                    SizedBox(height: 3.h),
Container(
  width: double.infinity,
  padding: EdgeInsets.all(4.w),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    gradient: LinearGradient(
      colors: [
        theme.colorScheme.primary.withOpacity(0.35),
        theme.colorScheme.primary.withOpacity(0.15),
      ],
    ),
  ),
child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // 🔥 DATE HEADER
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Today • ${_getFormattedDate()}",
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          _getFormattedTime(),
          style: theme.textTheme.bodySmall,
        ),
      ],
    ),

    SizedBox(height: 2.h),

    // 🔥 CONTENT
    _loadingStats
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
            ? Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(_errorMessage!),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadDashboardStats,
                    child: const Text("Retry"),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statItem("Courses", _coursesCount.toString(), Icons.menu_book),
                  _statItem("Attendance", "${_attendance.toStringAsFixed(1)}%", Icons.bar_chart),
_statItem(
  "Fees",
  _pendingAmount == 0
      ? "Paid"
      : "₹${_pendingAmount.toInt()} Due",
  Icons.currency_rupee,
),
                ],
              ),
  ],
),
),

if (!_loadingStats && _coursesCount == 0)
  Container(
    width: double.infinity,
    margin: EdgeInsets.only(top: 2.h),
    padding: EdgeInsets.all(4.w),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: theme.colorScheme.surface,
      border: Border.all(
        color: theme.dividerColor.withOpacity(0.3),
      ),
    ),
    child: Column(
      children: [
        Icon(Icons.info_outline, color: theme.colorScheme.primary),
        SizedBox(height: 1.h),
        Text(
          "No courses available",
          style: theme.textTheme.titleSmall,
        ),
        SizedBox(height: 0.5.h),
        Text(
          "Contact your instructor or admin",
          style: theme.textTheme.bodySmall,
        ),
      ],
    ),
  ),

SizedBox(height: 3.h),
                    // ================= INSIGHTS =================
                    Row(
                      children: [
                        _InsightCard(
                          title: 'Institution',
                          value: institution ?? 'Connected',
                          icon: Icons.school,
                        ),
                        SizedBox(width: 3.w),
                        const _InsightCard(
                          title: 'Status',
                          value: 'Active',
                          icon: Icons.verified,
                        ),
                      ],
                    ),

SizedBox(height: 3.h),


_buildSection("Academics", [
  _menuItem("Courses", Icons.menu_book, '/course-list'),
  _menuItem("Attendance", Icons.check_circle, '/student-attendance-page'),
  _menuItem("Results", Icons.bar_chart, '/student-full-report-screen'),
  _menuItem("Forum", Icons.forum, '/discussion-forum'), // moved here
]),


const SizedBox(height: 10),

_buildSection("Services", [
  _menuItem("Fees", Icons.currency_rupee, '/fees-management'),
]),

                    SizedBox(height: 5.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const CustomBottomBar(variant: BottomBarVariant.student),
    );
  
  }
}

/// ================= INSIGHT CARD =================
class _InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

   return Expanded(
  child: Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: theme.colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              SizedBox(height: 1.h),
              Text(
                title,
                style: theme.textTheme.bodySmall,
              ),
              SizedBox(height: 0.5.h),
              Text(
                value,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
}
