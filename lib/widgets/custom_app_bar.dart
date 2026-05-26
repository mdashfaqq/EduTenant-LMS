import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom app bar widget for the educational LMS application.
/// Implements clean professional header with contextual actions.
///
/// Features:
/// - Role-aware title and actions
/// - Optional search functionality
/// - Notification badge support
/// - Back navigation with proper context
/// - Minimum 44pt touch targets
/// - Platform-adaptive styling
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title to display in the app bar
  final String title;

  /// Optional subtitle for additional context
  final String? subtitle;

  /// Leading widget (typically back button or menu)
  final Widget? leading;

  /// Action widgets displayed on the right side
  final List<Widget>? actions;

  /// Whether to show the back button automatically
  final bool automaticallyImplyLeading;

  /// Whether to center the title
  final bool centerTitle;

  /// Callback when search icon is tapped
  final VoidCallback? onSearchTap;

  /// Callback when notification icon is tapped
  final VoidCallback? onNotificationTap;

  /// Number of unread notifications
  final int? notificationCount;

  /// App bar variant to determine styling and actions
  final AppBarVariant variant;

/// Optional widget shown at the bottom (e.g. TabBar)
final PreferredSizeWidget? bottom;

  /// Background color override
  final Color? backgroundColor;

  /// Elevation override
  final double? elevation;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
    this.onSearchTap,
    this.onNotificationTap,
    this.notificationCount,
    this.variant = AppBarVariant.standard,
    this.backgroundColor,
    this.elevation,
    this.bottom,
  });

@override
Size get preferredSize {
  final bottomHeight = bottom?.preferredSize.height ?? 0;
  return Size.fromHeight(kToolbarHeight + bottomHeight);
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      title: _buildTitle(context),
      leading:
          leading ??
          (automaticallyImplyLeading ? _buildLeading(context) : null),
      actions: _buildActions(context),
      centerTitle: centerTitle,
      bottom: bottom,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      elevation: elevation ?? theme.appBarTheme.elevation,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: theme.brightness,
      ),
    );
  }

  /// Build the title widget with optional subtitle
  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);

    if (subtitle != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: centerTitle
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.appBarTheme.titleTextStyle,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return Text(
      title,
      style: theme.appBarTheme.titleTextStyle,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Build the leading widget (back button or menu)
  Widget? _buildLeading(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    if (!canPop && variant == AppBarVariant.dashboard) {
      // Show menu icon for dashboard
      return IconButton(
        icon: const Icon(Icons.menu),
        tooltip: 'Menu',
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      );
    }

    if (canPop) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).pop();
        },
      );
    }

    return null;
  }

  /// Build action widgets based on variant and provided actions
  List<Widget>? _buildActions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final List<Widget> actionWidgets = [];

    // Add search action if callback is provided
    if (onSearchTap != null) {
      actionWidgets.add(
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search',
          onPressed: () {
            HapticFeedback.selectionClick();
            onSearchTap?.call();
          },
        ),
      );
    }

    // Add notification action if callback is provided
    if (onNotificationTap != null) {
      actionWidgets.add(
        IconButton(
          icon: _buildNotificationIcon(context),
          tooltip: 'Notifications',
          onPressed: () {
            HapticFeedback.selectionClick();
            onNotificationTap?.call();
          },
        ),
      );
    }

    // Add custom actions
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    // Add variant-specific actions
    switch (variant) {
      case AppBarVariant.dashboard:
        // Dashboard already has menu in leading
        break;

      case AppBarVariant.course:
        if (!actionWidgets.any(
          (w) => w is IconButton && (w.icon as Icon?)?.icon == Icons.more_vert,
        )) {
          actionWidgets.add(
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
              onPressed: () {
                HapticFeedback.selectionClick();
                _showCourseOptions(context);
              },
            ),
          );
        }
        break;

      case AppBarVariant.assignment:
        if (!actionWidgets.any(
          (w) => w is IconButton && (w.icon as Icon?)?.icon == Icons.more_vert,
        )) {
          actionWidgets.add(
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
              onPressed: () {
                HapticFeedback.selectionClick();
                _showAssignmentOptions(context);
              },
            ),
          );
        }
        break;

      case AppBarVariant.discussion:
        if (!actionWidgets.any(
          (w) =>
              w is IconButton && (w.icon as Icon?)?.icon == Icons.filter_list,
        )) {
          actionWidgets.add(
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter',
              onPressed: () {
                HapticFeedback.selectionClick();
                _showDiscussionFilters(context);
              },
            ),
          );
        }
        break;

      case AppBarVariant.profile:
        if (!actionWidgets.any(
          (w) => w is IconButton && (w.icon as Icon?)?.icon == Icons.edit,
        )) {
          actionWidgets.add(
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit profile',
              onPressed: () {
                HapticFeedback.selectionClick();
                // Navigate to edit profile
              },
            ),
          );
        }
        break;

      case AppBarVariant.standard:
        // No additional actions for standard variant
        break;
    }

    return actionWidgets.isEmpty ? null : actionWidgets;
  }

  /// Build notification icon with badge
  Widget _buildNotificationIcon(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (notificationCount == null || notificationCount == 0) {
      return const Icon(Icons.notifications_outlined);
    }

    return Badge(
      label: Text(
        notificationCount! > 99 ? '99+' : notificationCount.toString(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onError,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: colorScheme.error,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: const Icon(Icons.notifications_outlined),
    );
  }

  /// Show course options bottom sheet
  void _showCourseOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Course'),
              onTap: () {
                Navigator.pop(context);
                // Handle share
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Bookmark'),
              onTap: () {
                Navigator.pop(context);
                // Handle bookmark
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Course Info'),
              onTap: () {
                Navigator.pop(context);
                // Handle info
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show assignment options bottom sheet
  void _showAssignmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(context);
                // Handle download
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // Handle share
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Add to Calendar'),
              onTap: () {
                Navigator.pop(context);
                // Handle calendar
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show discussion filters bottom sheet
  void _showDiscussionFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Discussions'),
              onTap: () {
                Navigator.pop(context);
                // Handle filter
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Unread'),
              onTap: () {
                Navigator.pop(context);
                // Handle filter
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('My Posts'),
              onTap: () {
                Navigator.pop(context);
                // Handle filter
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Variants of the app bar for different screen contexts
enum AppBarVariant {
  /// Standard app bar with basic functionality
  standard,

  /// Dashboard app bar with menu icon
  dashboard,

  /// Course detail app bar with course-specific actions
  course,

  /// Assignment detail app bar with assignment-specific actions
  assignment,

  /// Discussion forum app bar with filter options
  discussion,

  /// Profile app bar with edit action
  profile,
}
