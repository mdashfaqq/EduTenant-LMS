import 'package:flutter/material.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../services/api/student_service.dart';
import '../../services/api/courses_service.dart';
import '../../services/api/fees_service.dart';
import '../../widgets/main_drawer.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/api/session_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _loading = true;
  String? _error;
bool get _showHighPendingAlert => _pendingAmount > 200;
  int _studentsCount = 0;
  int _coursesCount = 0;
  double _revenue = 0;
  double _pendingAmount = 0;
  double _unpaidPercentage = 0;
  
  String _formatRevenue(double value) {
  if (value >= 10000000) {
    return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
  } else if (value >= 100000) {
    return '₹${(value / 100000).toStringAsFixed(1)}L';
  } else if (value >= 1000) {
    return '₹${(value / 1000).toStringAsFixed(1)}K';
  } else {
    return '₹${value.toStringAsFixed(0)}';
  }

}


  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final students = await StudentsService.instance.listStudents();
      final courses = await CoursesService.instance.listCourses();
      final fees = await FeesService.instance.listFees();

      double revenue = 0;
      double pendingAmount = 0;
for (final f in fees) {
  revenue += (f['amountPaid'] ?? 0).toDouble();
  pendingAmount += (f['amountPending'] ?? 0).toDouble();
}


      final activities = <Map<String, dynamic>>[];

      // recent students
      for (final s in students.take(3)) {
        activities.add({
          'title': 'New student registered',
          'subtitle': s['name'],
          'type': 'student',
        });
      }

      // recent payments
      for (final f in fees.take(3)) {
        if ((f['amountPaid'] ?? 0) > 0) {
          activities.add({
            'title': 'Fee payment received',
            'subtitle': '₹${f['amountPaid']}',
            'type': 'payment',
          });
        }
      }

int unpaidStudents = 0;

for (final f in fees) {
  if ((f['amountPending'] ?? 0).toDouble() > 0) {
    unpaidStudents++;
  }
}

final totalStudents = students.length;

final unpaidPercentage = totalStudents == 0
    ? 0.0
    : (unpaidStudents / totalStudents * 100);
      if (!mounted) return;
      setState(() {
        _studentsCount = students.length;
        _coursesCount = courses.length;
        _revenue = revenue;
        _pendingAmount = pendingAmount; 
        _activities = activities;
        _loading = false;
        _unpaidPercentage = unpaidPercentage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

return Scaffold(
  drawer: const MainDrawer(
    currentRoute: '/admin-dashboard',
    variant: BottomBarVariant.admin,
  ),

  appBar: const CustomAppBar(
    title: 'Admin Dashboard',
    variant: AppBarVariant.dashboard,
  ),

  body: SafeArea(
    child: _loading
        ? const Center(child: CircularProgressIndicator())
: _error != null
    ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadDashboard,
              child: const Text("Retry"),
            ),
          ],
        ),
      )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        // // ================= HEADER =================
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     Text(
                        //       'Admin Dashboard',
                        //       style: theme.textTheme.headlineSmall
                        //           ?.copyWith(fontWeight: FontWeight.w600),
                        //     ),
                        //     const CircleAvatar(
                        //       child: Icon(Icons.admin_panel_settings),
                        //     ),
                        //   ],
                        // ),

if (_showHighPendingAlert)
GestureDetector(
  onTap: () {
    Navigator.pushNamed(context, '/cash-payment-management');
  },
  child: Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.red),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "High pending fees — ${_formatRevenue(_pendingAmount)}",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        ),
        const Icon(Icons.arrow_forward_ios, size: 16),
      ],
    ),
  ),
),
                        const SizedBox(height: 5),

                        if (_unpaidPercentage > 0)
  Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      "${_unpaidPercentage.toStringAsFixed(1)}% students have pending fees",
      style: const TextStyle(fontWeight: FontWeight.w500),
    ),
  ),
const SizedBox(height: 5),
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    gradient: LinearGradient(
      colors: [
        Colors.blue.withOpacity(0.2),
        Colors.blue.withOpacity(0.05),
      ],
    ),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        "Total Revenue",
        style: theme.textTheme.titleMedium,
      ),
      Text(
        _formatRevenue(_revenue),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
),


const SizedBox(height: 20),
                        // ================= STATS =================
GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 220, // max width per card
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.2,
  ),
  itemCount: 4,
  itemBuilder: (context, index) {
    final items = [
      _StatCard(
        title: 'Students',
        value: _studentsCount.toString(),
        icon: Icons.people,
        color: Colors.blue,
      ),
      _StatCard(
        title: 'Courses',
        value: _coursesCount.toString(),
        icon: Icons.school,
        color: Colors.green,
      ),
      _StatCard(
        title: 'Revenue',
        value: _formatRevenue(_revenue),
        icon: Icons.payments,
        color: Colors.orange,
      ),
_StatCard(
  title: 'Pending Fees',
  value: _formatRevenue(_pendingAmount),
  icon: Icons.account_balance_wallet,
  color: Colors.red,
),
    ];

    return items[index];
  },
),

                        const SizedBox(height: 24),

                        // ================= QUICK ACTIONS =================
                        Text(
                          'Quick Actions',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),LayoutBuilder(
  builder: (context, constraints) {
    final width = constraints.maxWidth;

    final crossAxisCount = width > 600
        ? 3
        : width > 400
            ? 3
            : 2;

    final itemWidth =
        (width - (12 * (crossAxisCount - 1))) / crossAxisCount;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: itemWidth,
          child: _QuickActionButton(
            icon: Icons.add_circle,
            label: 'Add Course',
            onTap: () =>
                Navigator.pushNamed(context, '/admin-course-management'),
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: _QuickActionButton(
            icon: Icons.person_add,
            label: 'Add User',
            onTap: () =>
                Navigator.pushNamed(context, '/user-management'),
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: _QuickActionButton(
            icon: Icons.payments,
            label: 'Collect Fees',
            onTap: () =>
                Navigator.pushNamed(context, '/cash-payment-management'),
          ),
        ),
        SizedBox(
  width: itemWidth,
  child: _QuickActionButton(
    icon: Icons.forum,
    label: 'Forum',
    onTap: () =>
        Navigator.pushNamed(context, '/discussion-forum'),
  ),
),
      ],
    );
  },
),
                        const SizedBox(height: 24),

                        // ================= RECENT ACTIVITY =================
                        Text(
                          'Recent Activity',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),

                        Card(
                          child: _activities.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No recent activity'),
                                )
                              : Column(
                                  children: _activities.map((a) {
                                    return ListTile(
                                      leading: CircleAvatar(
                                        child: Icon(
                                          a['type'] == 'student'
                                              ? Icons.person
                                              : Icons.payments,
                                        ),
                                      ),
                                      title: Text(a['title']),
                                      subtitle: Text(a['subtitle']),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar:
          const CustomBottomBar(variant: BottomBarVariant.admin),
    );
  }
}

/// ================= STAT CARD =================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              value,
style: title == 'Revenue'
    ? theme.textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.bold)
    : theme.textTheme.headlineSmall
        ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(title),
          ],
        ),
      ),
    );
    
  }
  
}


/// ================= QUICK ACTION =================
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
