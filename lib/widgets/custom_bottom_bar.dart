import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/role_utils.dart';

/// Navigation item configuration for the bottom navigation bar
class CustomBottomBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String route;
  final int? badgeCount;

  const CustomBottomBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.route,
    this.badgeCount,
  });
}

/// Custom bottom navigation bar widget for the educational LMS application.
/// Implements bottom-heavy interaction design with role-aware navigation.
///
/// Features:
/// - Badge notifications for pending items
/// - Smooth 200ms tab switching animations
/// - Minimum 48dp touch targets for accessibility
/// - Platform-adaptive Material 3 design
/// - Haptic feedback on selection
class CustomBottomBarItems {
  static const List<CustomBottomBarItem> _instructorAllItems = [
    CustomBottomBarItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      route: '/instructor-dashboard',
    ),
    CustomBottomBarItem(
      icon: Icons.school_outlined,
      activeIcon: Icons.school,
      label: 'Courses',
      route: '/course-list',
    ),
    CustomBottomBarItem(
      icon: Icons.how_to_reg_outlined,
      activeIcon: Icons.how_to_reg,
      label: 'Attendance',
      route: '/bulk-attendance-dashboard',
    ),
    CustomBottomBarItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Exams',
      route: '/exams-results',
    ),
    CustomBottomBarItem(
      icon: Icons.forum_outlined,
      activeIcon: Icons.forum,
      label: 'Discussions',
      route: '/discussion-forum',
    ),
    CustomBottomBarItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Users',
      route: '/user-management',
    ),
    CustomBottomBarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      route: '/profile-settings',
    ),
  ];

  static List<CustomBottomBarItem> forVariant(
      BottomBarVariant variant, {
        List<int?>? badgeCounts,
        List<String>? permissions,
      }) {

    switch (variant) {
      case BottomBarVariant.platformAdmin:
        return const [
          CustomBottomBarItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
            route: '/platform-admin-dashboard',
          ),
          CustomBottomBarItem(
            icon: Icons.business_outlined,
            activeIcon: Icons.business,
            label: 'Institutions',
            route: '/institution-management',
          ),
          CustomBottomBarItem(
            icon: Icons.security_outlined,
            activeIcon: Icons.security,
            label: 'Roles',
            route: '/role-access-management',
          ),
          CustomBottomBarItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: 'Users',
            route: '/user-management',
          ),
          CustomBottomBarItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Settings',
            route: '/profile-settings',
          ),
        ];

      case BottomBarVariant.admin:
        return const [
          CustomBottomBarItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
            route: '/admin-dashboard',
          ),
          CustomBottomBarItem(
            icon: Icons.school_outlined,
            activeIcon: Icons.school,
            label: 'Courses',
            route: '/admin-course-management',
          ),
          CustomBottomBarItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: 'Users',
            route: '/user-management',
          ),

                    CustomBottomBarItem(
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment,
            label: 'Exams',
            route: '/exams-results',
          ),
          CustomBottomBarItem(
            icon: Icons.payments_outlined,
            activeIcon: Icons.payments,
            label: 'Payments',
            route: '/cash-payment-management',
          ),
          CustomBottomBarItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            route: '/profile-settings',
          ),
        ];

      case BottomBarVariant.instructor:
        return const [
          CustomBottomBarItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
            route: '/instructor-dashboard',
          ),
          CustomBottomBarItem(
            icon: Icons.school_outlined,
            activeIcon: Icons.school,
            label: 'Courses',
            route: '/course-list',
          ),
          CustomBottomBarItem(
            icon: Icons.how_to_reg_outlined,
            activeIcon: Icons.how_to_reg,
            label: 'Attendance',
            route: '/course-attendance',
          ),
          CustomBottomBarItem(
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment,
            label: 'Exams',
            route: '/exams-results',
          ),

                    CustomBottomBarItem(
            icon: Icons.grade_outlined,
            activeIcon: Icons.grade,
            label: 'Progress',
            route: '/course-progress-page',
          ),


          CustomBottomBarItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            route: '/profile-settings',
          ),
        ];

      case BottomBarVariant.student:
      default:
        return const [
          CustomBottomBarItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
            route: '/student-dashboard',
          ),
          CustomBottomBarItem(
            icon: Icons.school_outlined,
            activeIcon: Icons.school,
            label: 'Courses',
            route: '/course-list',
          ),

          CustomBottomBarItem(
            icon: Icons.assessment_outlined,
            activeIcon: Icons.assessment,
            label: 'My Exams',
            route: '/student-full-report-screen',
          ),

          CustomBottomBarItem(
            icon: Icons.forum_outlined,
            activeIcon: Icons.forum,
            label: 'Discussions',
            route: '/discussion-forum',
          ),

          CustomBottomBarItem(
            icon: Icons.payment_rounded,
            activeIcon: Icons.payment_rounded,
            label: 'Fees',
            route: '/fees-management',
          ),
          CustomBottomBarItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            route: '/profile-settings',
          ),
        ];
    }
  }
}
class CustomBottomBar extends StatelessWidget {
  /// Navigation variant to determine which items to show
  final BottomBarVariant variant;

  /// Optional badge counts for each navigation item
  final List<int?>? badgeCounts;

  const CustomBottomBar({
    super.key,
    required this.variant,
    this.badgeCounts,
  });

  @override
  Widget build(BuildContext context) {
    final items = CustomBottomBarItems.forVariant(
      variant,
      badgeCounts: badgeCounts,
    );

    final currentRoute = ModalRoute.of(context)?.settings.name;

    final currentIndex = items.indexWhere(
          (item) => item.route == currentRoute,
    );

    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        color: Theme.of(context).colorScheme.surface,
        // child: NavigationBar(
        //   selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        //   onDestinationSelected: (index) {
        //     final targetRoute = items[index].route;

        //     if (targetRoute != currentRoute) {
        //       HapticFeedback.selectionClick();
        //       Navigator.pushReplacementNamed(context, targetRoute);
        //     }
        //   },
        //   destinations: items.map((item) {
        //     return NavigationDestination(
        //       icon: Icon(item.icon),
        //       selectedIcon: Icon(item.activeIcon ?? item.icon),
        //       label: item.label,
        //     );
        //   }).toList(),
        // ),
        child: BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  currentIndex: currentIndex < 0 ? 0 : currentIndex,
  selectedLabelStyle: const TextStyle(fontSize: 11),
unselectedLabelStyle: const TextStyle(fontSize: 11),
  onTap: (index) {
    final targetRoute = items[index].route;

    if (targetRoute != currentRoute) {
      HapticFeedback.selectionClick();
      Navigator.pushReplacementNamed(context, targetRoute);
    }
  },
  items: items.map((item) {
    return BottomNavigationBarItem(
      icon: Icon(item.icon),
      activeIcon: Icon(item.activeIcon ?? item.icon),
      label: item.label,
    );
  }).toList(),
),
      ),
    );
  }
}


  // /// Build icon with optional badge
  // Widget _buildIcon({
  //   required BuildContext context,
  //   required IconData icon,
  //   int? badgeCount,
  //   required bool isSelected,
  // }) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;
  //
  //   if (badgeCount == null || badgeCount == 0) {
  //     return Icon(icon);
  //   }
  //
  //   return Badge(
  //     label: Text(
  //       badgeCount > 99 ? '99+' : badgeCount.toString(),
  //       style: theme.textTheme.labelSmall?.copyWith(
  //         color: colorScheme.onError,
  //         fontSize: 10,
  //         fontWeight: FontWeight.w600,
  //       ),
  //     ),
  //     backgroundColor: colorScheme.error,
  //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  //     child: Icon(icon),
  //   );
  // }


/// Variants of the bottom navigation bar for different user roles
enum BottomBarVariant {
  /// Student navigation with dashboard, courses, assignments, discussions, and profile
  student,

  /// Instructor navigation with dashboard, courses, grades, discussions, and profile
  instructor,

  /// Admin navigation with dashboard, users, courses, and settings
  admin,

  platformAdmin
}

BottomBarVariant bottomBarVariantFromRole(String? role) {
  final normalized = normalizeRoleValue(role);
  switch (normalized) {
    case 'platform_admin':
      return BottomBarVariant.platformAdmin;
    case 'admin':
      return BottomBarVariant.admin;
    case 'instructor':
      return BottomBarVariant.instructor;
    default:
      return BottomBarVariant.student;
  }
}

/// Extension to safely get element at index or return null
extension SafeListAccess<T> on List<T> {
  T? elementAtOrNull(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }
}
