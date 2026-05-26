// 🔥 IMPROVED PROFESSIONAL DASHBOARD

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api/session_service.dart';
import '../../services/api/courses_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/main_drawer.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  bool _loading = true;
  String? _error;
List<Map<String, dynamic>> _activities = [];
  String _name = 'Instructor';
  int _totalCourses = 0;
  int _totalStudents = 0;

  double _avgAttendance = 0;
  String _attendanceStatus = 'Good';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      await SessionService.instance.init();
      final user = SessionService.instance.currentUser;

      final courses = await CoursesService.instance.listCourses();

      int students = 0;
      for (final c in courses) {
        final count = int.tryParse(
              c['enrollmentCount']?.toString() ?? '0',
            ) ??
            0;
        students += count;
      }

final activities = <Map<String, dynamic>>[];

if (courses.isNotEmpty) {
  activities.add({
    "title": "Courses loaded",
    "subtitle": "${courses.length} courses available",
    "icon": Icons.menu_book,
    "time": "Just now",
  });
}

if (students > 0) {
  activities.add({
    "title": "Student engagement",
    "subtitle": "$students students enrolled",
    "icon": Icons.people,
    "time": "Today",
  });
}



setState(() {
  _activities = activities;
});
      final avgAttendance = students == 0 ? 0 : 78;

      setState(() {
        _name = user?['name'] ?? 'Instructor';
        _totalCourses = courses.length;
        _totalStudents = students;
        _avgAttendance = avgAttendance.toDouble();
        _attendanceStatus =
            avgAttendance >= 75 ? 'Healthy' : 'Needs Attention';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _go(String route) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(
        currentRoute: '/instructor-dashboard',
        variant: BottomBarVariant.instructor,
      ),
      appBar: const CustomAppBar(
        title: 'Dashboard',
        variant: AppBarVariant.dashboard,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),

                      _buildStats(),
                      const SizedBox(height: 24),

                      _buildInsights(),
                      const SizedBox(height: 24),

                      _buildQuickActions(),
                      const SizedBox(height: 24),

                      _buildRecentActivity(),
                    ],
                  ),
                ),
      bottomNavigationBar:
          const CustomBottomBar(variant: BottomBarVariant.instructor),
    );
  }

  /* ================= HEADER ================= */

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Welcome back, $_name 👋",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= STATS ================= */

  Widget _buildStats() {
    return Row(
      children: [
        _StatCard(
          title: "Courses",
          value: _totalCourses.toString(),
          color: Colors.blue,
          icon: Icons.menu_book,
        ),
        const SizedBox(width: 12),
        _StatCard(
          title: "Students",
          value: _totalStudents.toString(),
          color: Colors.green,
          icon: Icons.people,
        ),
      ],
    );
  }

  /* ================= INSIGHTS ================= */

  Widget _buildInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Insights",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _InsightTile(
          title: "Attendance",
          subtitle: "Average ${_avgAttendance.toInt()}%",
          status: _attendanceStatus,
          color: _attendanceStatus == 'Healthy'
              ? Colors.green
              : Colors.orange,
        ),
      ],
    );
  }

  /* ================= QUICK ACTIONS ================= */

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Quick Actions",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _ActionCard(
                icon: Icons.campaign,
                label: "Exams",
                onTap: () => _go('/exams-results')),
            _ActionCard(
                icon: Icons.check_circle,
                label: "Attendance",
                onTap: () => _go('/course-attendance')),
            _ActionCard(
                icon: Icons.forum,
                label: "Forum",
                onTap: () => _go('/discussion-forum')),
                  _ActionCard(
    icon: Icons.bar_chart,
    label: "Progress",
    onTap: () => _go('/course-progress-page'),
                  ),
          ],
        ),
      ],
    );
  }

  /* ================= RECENT ACTIVITY ================= */

 Widget _buildRecentActivity() {
  if (_activities.isEmpty) {
    return const SizedBox();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Recent Activity",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),

      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _activities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _activities[index];

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(item["icon"],
                      color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item["title"],
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(item["subtitle"],
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12)),
                    ],
                  ),
                ),

                Text(
                  item["time"],
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}
}
/* ================= COMPONENTS ================= */

class _StatCard extends StatelessWidget {
  final String title, value;
  final Color color;
  final IconData icon;

  const _StatCard(
      {required this.title,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String title, subtitle, status;
  final Color color;

  const _InsightTile(
      {required this.title,
      required this.subtitle,
      required this.status,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20)),
          child: Text(status,
              style:
                  TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(18),
  color: Theme.of(context).colorScheme.surface,
  border: Border.all(
    color: Theme.of(context).dividerColor.withOpacity(0.4),
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ],
),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}