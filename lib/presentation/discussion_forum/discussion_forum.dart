import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../services/api/courses_service.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/sync_status_badge.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/api/discussions_service.dart';
import '../../services/api/session_service.dart';
import './widgets/discussion_post_card.dart';
import './widgets/filter_chips_row.dart';
import './widgets/new_post_dialog.dart';
import './widgets/post_detail_view.dart';
import 'dart:async';

class DiscussionForum extends StatefulWidget {
  const DiscussionForum({super.key});

  @override
  State<DiscussionForum> createState() => _DiscussionForumState();
}

class _DiscussionForumState extends State<DiscussionForum> {
  int _currentBottomIndex = 3;
  String _selectedSort = 'Recent';
  String _selectedFilter = 'All';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _filteredDiscussions = [];
  bool _isLoading = false;
  String? _loadError;
  List<String> _filters = ['All'];
  List<Map<String, dynamic>> _courses = [];

  int _page = 1;
bool _hasMore = true;
bool _isFetchingMore = false;
  List<Map<String, dynamic>> _discussions = [];

Future<void> _loadCourses() async {
  final courses = await CoursesService.instance.listCourses();

  setState(() {
    _courses = courses;

    _filters = [
      'All',
      ...courses.map((c) => c['title'] as String),
    ];
  });
}
  @override
  void initState() {
    super.initState();
      _loadCourses();
    _loadDiscussions();
    _scrollController.addListener(() {
  if (_scrollController.position.pixels >=
      _scrollController.position.maxScrollExtent - 200) {
    _loadDiscussions(loadMore: true);
  }
});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Future<void> _loadDiscussions() async {
  //   setState(() {
  //     _isLoading = true;
  //     _loadError = null;
  //   });

  //   try {
  //     final posts = await DiscussionsService.instance.listPosts(
  //       category: _selectedFilter,
  //     );
  //     if (!mounted) return;
  //     setState(() {
  //       _discussions = posts;
  //       _filteredDiscussions = List.from(posts);
  //     });
  //     _filterDiscussions();
  //   } catch (e) {
  //     if (!mounted) return;
  //     setState(() {
  //       _loadError = e.toString();
  //     });
  //   } finally {
  //     if (!mounted) return;
  //     setState(() => _isLoading = false);
  //   }
  // }


Future<void> _loadDiscussions({bool loadMore = false}) async {
  if (loadMore && (_isFetchingMore || !_hasMore)) return;

  if (loadMore) {
    setState(() => _isFetchingMore = true);
  } else {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _page = 1;
      _hasMore = true;
       _discussions.clear();
    });
  }

  try {
    final posts = await DiscussionsService.instance.listPosts(
      category: _selectedFilter,
      limit: 10,
      offset: (_page - 1) * 10,
    );

    if (!mounted) return;

    setState(() {
      if (loadMore) {
        _discussions.addAll(posts);
      } else {
        _discussions = posts;
      }

      _filteredDiscussions = List.from(_discussions);

      _hasMore = posts.length == 10;
      if (_hasMore) _page++;
    });

    _filterDiscussions();

  } catch (e) {
    if (!mounted) return;

    setState(() {
      _loadError = "Failed to load discussions";
    });
  } finally {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isFetchingMore = false;
    });
  }
}

  void _filterDiscussions() {
    setState(() {
      _filteredDiscussions = _discussions.where((discussion) {
        final matchesSearch =
            _searchController.text.isEmpty ||
            (discussion["title"] as String).toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            (discussion["content"] ?? "").toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );

final matchesFilter =
    _selectedFilter == 'All' ||
    discussion["courseTitle"] == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();

      // Apply sorting
      if (_selectedSort == 'Recent') {
        _filteredDiscussions.sort(
          (a, b) => (b["timestamp"] as DateTime).compareTo(
            a["timestamp"] as DateTime,
          ),
        );
      } else if (_selectedSort == 'Popular') {
        _filteredDiscussions.sort(
          (a, b) => (b["likeCount"] as int).compareTo(a["likeCount"] as int),
        );
      } else if (_selectedSort == 'Unanswered') {
        _filteredDiscussions = _filteredDiscussions
            .where((d) => (d["replyCount"] as int) == 0)
            .toList();
      }
    });
  }


void _showNewPostDialog() {
  if (_courses.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Courses are still loading")),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (context) => NewPostDialog(
      categories: _courses
          .map((c) => c['title'] as String)
          .toList(),
      onPostCreated: (title, content, selectedCourseTitle) async {
        final currentUser = SessionService.instance.currentUser;
        final authorId = currentUser?['id'];

        if (authorId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in again.')),
          );
          return;
        }

        final selectedCourse = _courses.firstWhere(
          (c) => c['title'] == selectedCourseTitle,
        );

        final courseId = selectedCourse['id'];

        try {
          final created = await DiscussionsService.instance.createPost({
            'title': title,
            'content': content,
            'course_id': courseId,
            'author_id': authorId,
          });

          if (!mounted) return;

          setState(() {
            _discussions.insert(0, created);
            _filterDiscussions();
          });

        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create post: $e')),
          );
        }
      },
    ),
  );
}

  Future<void> _showPostDetail(Map<String, dynamic> discussion) async {
    final postId = discussion['id'] as int;
    try {
      final replies = await DiscussionsService.instance.listReplies(postId);
      discussion['replies'] = replies;
    } catch (_) {}

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailView(
          discussion: discussion,
          onReplyAdded: (reply) async {
            final currentUser = SessionService.instance.currentUser;
            final authorId = currentUser?['id'];

            if (authorId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please sign in again.')),
              );
              return;
            }

            try {
              final created = await DiscussionsService.instance.addReply(
                postId,
                {
                  'content': reply['content'],
                  'author_id': authorId,
                },
              );
              if (!mounted) return;
await _loadDiscussions(loadMore: false);

            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to add reply: $e')),
              );
            }
          },
          onLikeToggled: () {
            setState(() {
              final index = _discussions.indexWhere(
                (d) => d["id"] == discussion["id"],
              );
              if (index != -1) {
                final isLiked = _discussions[index]["isLiked"] as bool;
                _discussions[index]["isLiked"] = !isLiked;
                _discussions[index]["likeCount"] =
                    ((_discussions[index]["likeCount"] as int) +
                    (isLiked ? -1 : 1));
                _filterDiscussions();
              }
            });
          },
          onBookmarkToggled: () {
            setState(() {
              final index = _discussions.indexWhere(
                (d) => d["id"] == discussion["id"],
              );
              if (index != -1) {
                _discussions[index]["isBookmarked"] =
                    !(_discussions[index]["isBookmarked"] as bool);
                _filterDiscussions();
              }
            });
          },
        ),
      ),
    );
  }

Future<void> _editPost(Map<String, dynamic> discussion) async {
  if (_courses.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Courses are still loading")),
    );
    return;
  }

  final titleController =
      TextEditingController(text: discussion['title']);
  final contentController =
      TextEditingController(text: discussion['content']);

  // 🔥 Get current course title from discussion
String selectedCourseTitle =
    _courses.any((c) => c['title'] == discussion['course_title'])
        ? discussion['course_title']
        : _courses.first['title'];

  final updated = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Edit Post"),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ Course Dropdown
SizedBox(
  width: double.infinity,
  child: DropdownButtonFormField<String>(
    isExpanded: true,
    value: selectedCourseTitle,
    items: _courses
        .map((course) => DropdownMenuItem<String>(
              value: course['title'],
              child: Text(
                course['title'],
                overflow: TextOverflow.ellipsis,
              ),
            ))
        .toList(),
    onChanged: (value) {
      if (value != null) {
        setStateDialog(() {
          selectedCourseTitle = value;
        });
      }
    },
    decoration: const InputDecoration(
      labelText: "Course",
      isDense: true,
      contentPadding:
          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  ),
),
                  const SizedBox(height: 12),

                  TextField(
                    controller: titleController,
                    decoration:
                        const InputDecoration(labelText: "Title"),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: contentController,
                    decoration:
                        const InputDecoration(labelText: "Content"),
                    maxLines: 3,
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Update"),
          ),
        ],
      );
    },
  );

  if (updated != true) return;

  // 🔥 Get selected course ID
  final selectedCourse = _courses.firstWhere(
    (c) => c['title'] == selectedCourseTitle,
  );

  final courseId = selectedCourse['id'];

  try {
    await DiscussionsService.instance.updatePost(
      discussion['id'],
      {
        "title": titleController.text,
        "content": contentController.text,
        "course_id": courseId,
      },
    );

    setState(() {
      discussion['title'] = titleController.text;
      discussion['content'] = contentController.text;
      discussion['courseTitle'] = selectedCourseTitle;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Post updated successfully")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to update post: $e")),
    );
  }
}


Future<void> _deletePost(Map<String, dynamic> discussion) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Delete Post"),
      content: const Text("Are you sure you want to delete this post?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            "Delete",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    await DiscussionsService.instance.deletePost(discussion['id']);

    setState(() {
      _discussions.removeWhere((d) => d["id"] == discussion["id"]);
      _filterDiscussions();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Post deleted")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to delete post: $e")),
    );
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
        title: 'Discussion Forum',
        variant: AppBarVariant.standard,
      ),
floatingActionButton: FloatingActionButton(
  onPressed: _showNewPostDialog,
  child: const Icon(Icons.add),
),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Expanded(
                    //   child: ElevatedButton.icon(
                    //     onPressed: _showNewPostDialog,
                    //     icon: CustomIconWidget(
                    //       iconName: 'add',
                    //       color: theme.colorScheme.onPrimary,
                    //       size: 20,
                    //     ),
                    //     label: Text('New Post'),
                    //     style: ElevatedButton.styleFrom(
                    //       padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    //     ),
                    //   ),
                    // ),
                    // SizedBox(width: 2.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
  value: _selectedSort,
  underline: const SizedBox(),
  isDense: true,
  items: ['Recent', 'Popular', 'Unanswered']
      .map((sort) => DropdownMenuItem(
            value: sort,
            child: Text(sort),
          ))
      .toList(),
  onChanged: (value) {
    if (value != null) {
      setState(() {
        _selectedSort = value;
        _filterDiscussions();
      });
    }
  },
)
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
FilterChipsRow(
  filters: _filters,
  selectedFilter: _selectedFilter,
  onFilterChanged: (filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadDiscussions();
  },
),
              ],
            ),
          ),
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
                : RefreshIndicator(
                    onRefresh: _loadDiscussions,
                    child: _filteredDiscussions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomIconWidget(
                                  iconName: 'forum',
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 64,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'No discussions found',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  'Try adjusting your filters or search',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            itemCount: _filteredDiscussions.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 2.h),
itemBuilder: (context, index) {
  final discussion = _filteredDiscussions[index];

  final currentUser = SessionService.instance.currentUser;

    print("Post author: ${discussion["author_id"]}");
  print("Current user: ${currentUser?["id"]}");
  final isOwner =
      discussion["author_id"] == currentUser?["id"];

  return DiscussionPostCard(
    discussion: discussion,
    onTap: () => _showPostDetail(discussion),
onLike: () async {
  HapticFeedback.lightImpact();

  final originalLiked = discussion["isLiked"] as bool;

  setState(() {
    discussion["isLiked"] = !originalLiked;
    discussion["likeCount"] =
        (discussion["likeCount"] as int) + (originalLiked ? -1 : 1);
  });

  try {
    await DiscussionsService.instance.toggleLike(discussion["id"]);
  } catch (e) {
    // rollback if failed
    setState(() {
      discussion["isLiked"] = originalLiked;
      discussion["likeCount"] =
          (discussion["likeCount"] as int) + (originalLiked ? 1 : -1);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to update like")),
    );
  }
},
    onBookmark: () {
      HapticFeedback.lightImpact();
      setState(() {
        discussion["isBookmarked"] =
            !(discussion["isBookmarked"] as bool);
      });
    },
    onShare: () {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share functionality coming soon'),
          duration: Duration(seconds: 2),
        ),
      );
    },
    onReport: () {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post reported'),
          duration: Duration(seconds: 2),
        ),
      );
    },

    /// 🔥 IMPORTANT
    isOwner: isOwner,
    onEdit: isOwner ? () => _editPost(discussion) : null,
    onDelete: isOwner ? () => _deletePost(discussion) : null,
  );
},
                          ),
                  ),
          ),
        ],
      ),
bottomNavigationBar: CustomBottomBar(
  variant: navVariant,
),

    );
  }
}
