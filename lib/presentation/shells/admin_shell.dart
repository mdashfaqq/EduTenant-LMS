// import 'package:edutenant_lms/presentation/profile_settings/profile_settings.dart';
// import 'package:flutter/material.dart';
// import '/widgets/custom_bottom_bar.dart';
// import '/presentation/admin_dashboard/admin_dashboard_page.dart';
// import '/presentation/admin_course_management/admin_course_management.dart';
// import '/presentation/user_management/user_management.dart';
// import '/presentation/fees_management/fees_management.dart';
// import '/presentation/profile_settings/profile_settings.dart';
// class AdminShell extends StatefulWidget {
//   const AdminShell({super.key});
//
//   @override
//   State<AdminShell> createState() => _AdminShellState();
// }
//
// class _AdminShellState extends State<AdminShell> {
//   int _currentIndex = 0;
//
//   late final List<Widget> _pages = [
//     AdminDashboardPage(),
//     AdminCourseManagement(),
//     UserManagement(),
//     FeesManagement(),
//     ProfileSettings(),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: IndexedStack(
//           index: _currentIndex,
//           children: _pages,
//         ),
//       ),
//       bottomNavigationBar: CustomBottomBar(
//         currentIndex: _currentIndex,
//         variant: BottomBarVariant.admin,
//         onTap: (index) {
//           if (index >= _pages.length) return;
//           setState(() => _currentIndex = index);
//         },
//       ),
//     );
//   }
// }
