import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/sync_status_badge.dart';
import '../../services/api/courses_service.dart';
import '../../services/api/session_service.dart';
import './widgets/course_card_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_chips_widget.dart';

class CourseList extends StatefulWidget {
  const CourseList({super.key});

  @override
  State<CourseList> createState() => _CourseListState();
}

class _CourseListState extends State<CourseList>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _activeFilters = [];
  bool _isLoading = false;
  bool _isOffline = false;
  String _lastSyncTime = '2 hours ago';
  int _currentBottomNavIndex = 1;
  bool _isSearching = false;

  List<Map<String, dynamic>> _allCourses = [];

  List<Map<String, dynamic>> _filteredCourses = [];

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _loadCourses();
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _isOffline = false;
    });

    try {
      final courses = await CoursesService.instance.listCourses();
      if (!mounted) return;
      setState(() {
        _allCourses = courses;
        _applyFilters();
        _lastSyncTime = 'Just now';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isOffline = true;
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredCourses = _allCourses.where((course) {
        // Apply active filters
        bool matchesFilters = true;
        final status = (course['status'] ?? '').toString().toLowerCase();

        if (_activeFilters.contains('Current Semester')) {
          matchesFilters =
              matchesFilters &&
              (course['semester'] as String) == 'Current Semester';
        }

        if (_activeFilters.contains('Completed')) {
          matchesFilters =
              matchesFilters && status == 'completed';
        }

        if (_activeFilters.contains('Archived')) {
          matchesFilters =
              matchesFilters && (status == 'archived' || status == 'inactive');
        }

        // Apply search filter
        if (_searchController.text.isNotEmpty) {
          final searchLower = _searchController.text.toLowerCase();
          matchesFilters =
              matchesFilters &&
              ((course['title'] as String).toLowerCase().contains(
                    searchLower,
                  ) ||
                  (course['instructor'] as String).toLowerCase().contains(
                    searchLower,
                  ) ||
                  (course['courseCode'] as String).toLowerCase().contains(
                    searchLower,
                  ));
        }

        return matchesFilters;
      }).toList();

      // Sort: pinned courses first
      _filteredCourses.sort((a, b) {
        if ((a['isPinned'] as bool) && !(b['isPinned'] as bool)) return -1;
        if (!(a['isPinned'] as bool) && (b['isPinned'] as bool)) return 1;
        return 0;
      });
    });
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_activeFilters.contains(filter)) {
        _activeFilters.remove(filter);
      } else {
        _activeFilters.add(filter);
      }
      _applyFilters();
    });
  }

  void _onSearchChanged(String value) {
    _applyFilters();
  }

  Future<void> _onRefresh() async {
    await _loadCourses();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Courses updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Filter Courses',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'calendar_today',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Current Semester'),
                trailing: _activeFilters.contains('Current Semester')
                    ? CustomIconWidget(
                        iconName: 'check',
                        color: theme.colorScheme.primary,
                        size: 24,
                      )
                    : null,
                onTap: () {
                  _toggleFilter('Current Semester');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'check_circle',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Completed'),
                trailing: _activeFilters.contains('Completed')
                    ? CustomIconWidget(
                        iconName: 'check',
                        color: theme.colorScheme.primary,
                        size: 24,
                      )
                    : null,
                onTap: () {
                  _toggleFilter('Completed');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'archive',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Archived'),
                trailing: _activeFilters.contains('Archived')
                    ? CustomIconWidget(
                        iconName: 'check',
                        color: theme.colorScheme.primary,
                        size: 24,
                      )
                    : null,
                onTap: () {
                  _toggleFilter('Archived');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _onCourseCardTap(Map<String, dynamic> course) {
    HapticFeedback.selectionClick();
    // Navigate to course detail screen
    Navigator.pushNamed(context, '/course-detail', arguments: course);
  }

  void _onCourseCardLongPress(Map<String, dynamic> course) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  course['title'] as String,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CustomIconWidget(
                  iconName: (course['isPinned'] as bool)
                      ? 'push_pin'
                      : 'push_pin',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text(
                  (course['isPinned'] as bool)
                      ? 'Unpin from Top'
                      : 'Pin to Top',
                ),
                onTap: () {
                  setState(() {
                    course['isPinned'] = !(course['isPinned'] as bool);
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'mark_email_read',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Mark All Read'),
                onTap: () {
                  setState(() {
                    course['unreadCount'] = 0;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'download',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Download for Offline'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Downloading course content...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'settings',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Course Settings'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _onQuickAction(Map<String, dynamic> course, String action) {
    HapticFeedback.selectionClick();
    switch (action) {
      case 'assignments':
        Navigator.pushNamed(
          context,
          '/assignment-detail',
          arguments: {
            'courseId': course['id'],
            'courseTitle': course['title'],
          },
        );
        break;
      case 'grades':
        Navigator.pushNamed(context, '/grade-management');
        break;
      case 'discussions':
        Navigator.pushNamed(context, '/discussion-forum');
        break;
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
        title: 'My Courses',
        variant: AppBarVariant.standard,
        onSearchTap: () {
          setState(() => _isSearching = !_isSearching);
        },
      ),
      body: Column(
        children: [
  
          if (_isSearching)
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search courses, instructors, or codes',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: CustomIconWidget(
                            iconName: 'search',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: CustomIconWidget(
                                  iconName: 'clear',
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 24,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'filter_list',
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    onPressed: _showFilterOptions,
                    tooltip: 'Filter courses',
                  ),
                ],
              ),
            )
          else
            const SizedBox.shrink(),

          // Filter chips
          FilterChipsWidget(
            activeFilters: _activeFilters,
            onFilterToggle: _toggleFilter,
          ),

          // Offline indicator
          _isOffline
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: theme.colorScheme.errorContainer,
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'cloud_off',
                        color: theme.colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Offline mode - Last synced $_lastSyncTime',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),

          // Course list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCourses.isEmpty
                ? EmptyStateWidget(
              hasActiveFilters:
              _activeFilters.isNotEmpty ||
                  _searchController.text.isNotEmpty,
              onBrowseCatalog: () {},
              onClearFilters: () {
                setState(() {
                  _activeFilters.clear();
                  _searchController.clear();
                  _applyFilters();
                });
              },
            )
                : RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredCourses.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final course = _filteredCourses[index];
                  return CourseCardWidget(
                    course: course,
                    onTap: () => _onCourseCardTap(course),
                    onLongPress: () => _onCourseCardLongPress(course),
                    onQuickAction: (action) =>
                        _onQuickAction(course, action),
                  );
                },
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        variant: navVariant,
      ),


    );
  }
}
