// import 'package:flutter/material.dart';

// import '../services/api/session_service.dart';
// import 'custom_bottom_bar.dart';

// /// App-wide navigation drawer used on dashboard screens.
// class MainDrawer extends StatelessWidget {
//   final String currentRoute;
//   final BottomBarVariant variant;

//   const MainDrawer({
//     super.key,
//     required this.currentRoute,
//     required this.variant,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final user = SessionService.instance.currentUser;
//     final name = user?['name']?.toString() ?? 'User';
//     final role = user?['role']?.toString() ?? 'Student';
//     final avatar = user?['avatar']?.toString();

//     final items = _navItemsForVariant(variant);

//     return Drawer(
//       child: SafeArea(
//         child: Column(
//           children: [
//             UserAccountsDrawerHeader(
//               accountName: Text(name),
//               accountEmail: Text(role),
//               currentAccountPicture: CircleAvatar(
//                 backgroundColor: theme.colorScheme.primaryContainer,
//                 backgroundImage: avatar != null ? NetworkImage(avatar) : null,
//                 child: avatar == null
//                     ? Icon(
//                         Icons.person,
//                         color: theme.colorScheme.onPrimaryContainer,
//                       )
//                     : null,
//               ),
//               decoration: BoxDecoration(
//                 color: theme.colorScheme.primary,
//               ),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: items.length,
//                 itemBuilder: (context, index) {
//                   final item = items[index];
//                   final selected = currentRoute == item.route;
//                   return ListTile(
//                     leading: Icon(item.icon),
//                     title: Text(item.label),
//                     selected: selected,
//                     onTap: () {
//                       Navigator.pop(context);
//                       if (!selected) {
//                         Navigator.pushReplacementNamed(
//                           context,
//                           item.route,
//                         );
//                       }
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   List<_DrawerItem> _navItemsForVariant(BottomBarVariant variant) {
//     switch (variant) {
//       case BottomBarVariant.admin:
//         return const [
//           _DrawerItem(
//             icon: Icons.dashboard_outlined,
//             label: 'Dashboard',
//             route: '/admin-course-management',
//           ),
//           _DrawerItem(
//             icon: Icons.school_outlined,
//             label: 'Courses',
//             route: '/admin-course-management',
//           ),
//           _DrawerItem(
//             icon: Icons.people_outline,
//             label: 'Users',
//             route: '/user-management',
//           ),
//           _DrawerItem(
//             icon: Icons.person_outline,
//             label: 'Profile',
//             route: '/profile-settings',
//           ),
//         ];
//       case BottomBarVariant.instructor:
//         return const [
//           _DrawerItem(
//             icon: Icons.dashboard_outlined,
//             label: 'Dashboard',
//             route: '/instructor-dashboard',
//           ),
//           _DrawerItem(
//             icon: Icons.school_outlined,
//             label: 'Courses',
//             route: '/course-list',
//           ),
//           _DrawerItem(
//             icon: Icons.assignment_outlined,
//             label: 'Exams',
//             route: '/exams-results',
//           ),
//           _DrawerItem(
//             icon: Icons.person_outline,
//             label: 'Profile',
//             route: '/profile-settings',
//           ),
//         ];
//       case BottomBarVariant.student:
//       default:
//         return const [
//           _DrawerItem(
//             icon: Icons.dashboard_outlined,
//             label: 'Dashboard',
//             route: '/student-dashboard',
//           ),
//           _DrawerItem(
//             icon: Icons.school_outlined,
//             label: 'Courses',
//             route: '/course-list',
//           ),
//           _DrawerItem(
//             icon: Icons.forum_outlined,
//             label: 'Discussions',
//             route: '/discussion-forum',
//           ),
//           _DrawerItem(
//             icon: Icons.person_outline,
//             label: 'Profile',
//             route: '/profile-settings',
//           ),
//         ];
//     }
//   }
// }

// class _DrawerItem {
//   final IconData icon;
//   final String label;
//   final String route;

//   const _DrawerItem({
//     required this.icon,
//     required this.label,
//     required this.route,
//   });
// }


import 'package:flutter/material.dart';

import '../services/api/session_service.dart';
import 'custom_bottom_bar.dart';

class MainDrawer extends StatelessWidget {
  final String currentRoute;
  final BottomBarVariant variant;

  const MainDrawer({
    super.key,
    required this.currentRoute,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = SessionService.instance.currentUser;
    final name = user?['name']?.toString() ?? 'User';
    final role = user?['role']?.toString() ?? 'Student';
    final avatar = user?['avatar']?.toString();

    final items = _navItemsForVariant(variant);

return Drawer(
  child: SafeArea(
    child: Column(
      children: [
        UserAccountsDrawerHeader(
          accountName: Text(name),
          accountEmail: Text(role),
          currentAccountPicture: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage:
                avatar != null ? NetworkImage(avatar) : null,
            child: avatar == null
                ? Icon(
                    Icons.person,
                    color: theme.colorScheme.onPrimaryContainer,
                  )
                : null,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
          ),
        ),

        /// Navigation Items
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final selected = currentRoute == item.route;

              return ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                selected: selected,
                onTap: () {
                  Navigator.pop(context);
                  if (!selected) {
                    Navigator.pushReplacementNamed(
                      context,
                      item.route,
                    );
                  }
                },
              );
            },
          ),
        ),

        const Divider(),

        /// 🔴 LOGOUT BUTTON
        ListTile(
          leading: Icon(
            Icons.logout,
            color: theme.colorScheme.error,
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
onTap: () async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Logout'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await SessionService.instance.clearSession();

    if (!context.mounted) return;

    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil('/login-screen', (route) => false);
  }
},

        ),

        // SizedBox(height:),
      ],
    ),
  ),
);
  }

  List<_DrawerItem> _navItemsForVariant(BottomBarVariant variant) {
    switch (variant) {
      case BottomBarVariant.admin:
        return const [
          _DrawerItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: '/admin-course-management',
          ),
          _DrawerItem(
            icon: Icons.school_outlined,
            label: 'Courses',
            route: '/admin-course-management',
          ),
          _DrawerItem(
            icon: Icons.people_outline,
            label: 'Users',
            route: '/user-management',
          ),
          _DrawerItem(
            icon: Icons.person_outline,
            label: 'Profile',
            route: '/profile-settings',
          ),
        ];

      case BottomBarVariant.instructor:
        return const [
          _DrawerItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: '/instructor-dashboard',
          ),
          _DrawerItem(
            icon: Icons.school_outlined,
            label: 'Courses',
            route: '/course-list',
          ),
          _DrawerItem(
            icon: Icons.assignment_outlined,
            label: 'Exams',
            route: '/exams-results',
          ),
          _DrawerItem(
            icon: Icons.person_outline,
            label: 'Profile',
            route: '/profile-settings',
          ),
        ];

      case BottomBarVariant.student:
      default:
        return const [
          _DrawerItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: '/student-dashboard',
          ),
          _DrawerItem(
            icon: Icons.school_outlined,
            label: 'Courses',
            route: '/course-list',
          ),
          _DrawerItem(
            icon: Icons.forum_outlined,
            label: 'Discussions',
            route: '/discussion-forum',
          ),
          _DrawerItem(
            icon: Icons.person_outline,
            label: 'Profile',
            route: '/profile-settings',
          ),
        ];
    }
  }
}

class _DrawerItem {
  final IconData icon;
  final String label;
  final String route;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}