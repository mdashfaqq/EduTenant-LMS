// import 'package:flutter/material.dart';
// import '../../widgets/custom_app_bar.dart';
// import '../../widgets/sync_status_badge.dart';
// import '../../services/api/api_client.dart';
// import '../../services/api/session_service.dart';
// import '../../routes/app_routes.dart';

// class CourseDetailPage extends StatelessWidget {
  
//   const CourseDetailPage({super.key});

//   bool get _isInstructor {
//     final role =
//         SessionService.instance.currentUser?['role']?.toLowerCase();
//     return role == 'admin' || role == 'instructor';
//   }
  

//   @override
//   Widget build(BuildContext context) {
//     final course =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

//     debugPrint('[CourseDetailPage] course args: $course');

//     if (course == null) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
// final GlobalKey<_AnnouncementFeedState> _feedKey =
//     GlobalKey<_AnnouncementFeedState>();

//     return Scaffold(
//       appBar: CustomAppBar(
//         title: course['title'],
//         variant: AppBarVariant.standard,
//       ),
//       body: Column(
//         children: [
//           const SyncStatusBadge(showTimestamp: true),

//           if (_isInstructor)
//             _PostAnnouncementCard(courseId: course['id']),
            
// Expanded(
//   child: AnnouncementFeed(
//     key: _feedKey,
//     courseId: course['id'], // ✅ INT
//   ),
// ),



//         ],
//       ),
//     );
//   }
// }

// /* --------------------------------------------------------
//    POST ANNOUNCEMENT CTA
// --------------------------------------------------------- */

// class _PostAnnouncementCard extends StatelessWidget {
//   final int courseId;

//   const _PostAnnouncementCard({required this.courseId});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.all(12),
//       color: Theme.of(context).colorScheme.primaryContainer,
//       child: ListTile(
//         leading: const Icon(Icons.campaign),
//         title: const Text('Post an announcement'),
//         subtitle: const Text('Share updates with your class'),
//         trailing: const Icon(Icons.arrow_forward),
// onTap: () async {
//   final result = await Navigator.pushNamed(
//     context,
//     AppRoutes.createAnnouncement,
//     arguments: {'courseId': courseId},
//   );

//   // ✅ refresh feed only if post succeeded

// },


//       ),
//     );
//   }
// }

// /* --------------------------------------------------------
//    ANNOUNCEMENT FEED
// --------------------------------------------------------- */

// class AnnouncementFeed extends StatefulWidget {
//   final int courseId;

//   const AnnouncementFeed({
//     super.key,
//     required this.courseId,
//   });


//   @override
//   State<AnnouncementFeed> createState() => _AnnouncementFeedState();
// }


// class _AnnouncementFeedState extends State<AnnouncementFeed> {
//   bool _loading = true;
//   List<Map<String, dynamic>> _announcements = [];

//   @override
//   void initState() {
//     super.initState();
//     debugPrint('[AnnouncementFeed] initState → loading announcements');
//     _loadAnnouncements();
//   }


//   Future<void> _loadAnnouncements() async {
//   try {
//     debugPrint('[AnnouncementFeed] Starting API call');

//     // 🔥 FRONTEND GUARANTEE FOR institution_code
//     final session = SessionService.instance;
//     final institutionCode =
//         session.institutionCode ??
//         session.currentUser?['institution_code']?.toString();

//     if (institutionCode == null || institutionCode.isEmpty) {
//       throw Exception('institution_code missing in session');
//     }

//     debugPrint(
//       '[AnnouncementFeed] Using institution_code=$institutionCode',
//     );

// final res = await ApiClient.instance.get(
//   '/announcements.php',
//   queryParameters: {
//     'course_id': widget.courseId, // ✅ INT
//   },
// );


//     debugPrint('[AnnouncementFeed] Raw API response: $res');
//     debugPrint('[AnnouncementFeed] Response type: ${res.runtimeType}');

//     if (res is List) {
//       _announcements =
//           res.map((e) => Map<String, dynamic>.from(e)).toList();
//     } else {
//       _announcements = [];
//     }

//     debugPrint(
//       '[AnnouncementFeed] Parsed announcements count: ${_announcements.length}',
//     );

//     setState(() => _loading = false);
//   } catch (e, st) {
//     debugPrint('[AnnouncementFeed] ERROR loading announcements: $e');
//     debugPrintStack(stackTrace: st);

//     setState(() => _loading = false);

//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to load announcements'),
//         ),
//       );
//     }
//   }
// }

//  @override
//   Widget build(BuildContext context) {
//     debugPrint(
//       '[AnnouncementFeed] build → loading=$_loading, count=${_announcements.length}',
//     );

//     if (_loading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (_announcements.isEmpty) {
//       return const _EmptyAnnouncementState();
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: _announcements.length,
//       itemBuilder: (context, index) {
//         final a = _announcements[index];

//         debugPrint('[AnnouncementFeed] Rendering item $index: $a');

//         return AnnouncementCard(
//           title: a['title']?.toString() ?? '',
//           body: a['content']?.toString() ?? '',
//          author: a['created_name'] ??
//     (a['created_role']?.toString().toUpperCase() ?? 'STAFF'),

//           createdAt: a['created_date']?.toString(),
//         );
//       },
//     );
//   }
// }

// /* --------------------------------------------------------
//    ANNOUNCEMENT CARD
// --------------------------------------------------------- */

// class AnnouncementCard extends StatelessWidget {
//   final String title;
//   final String body;
//   final String author;
//   final String? createdAt;

//   const AnnouncementCard({
//     super.key,
//     required this.title,
//     required this.body,
//     required this.author,
//     this.createdAt,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(author,
//                 style: Theme.of(context).textTheme.labelMedium),
//             if (createdAt != null)
//               Padding(
//                 padding: const EdgeInsets.only(top: 2),
//                 child: Text(
//                   createdAt!,
//                   style: Theme.of(context).textTheme.labelSmall,
//                 ),
//               ),
//             const SizedBox(height: 8),
//             Text(
//               title,
//               style: Theme.of(context).textTheme.titleMedium,
//             ),
//             const SizedBox(height: 8),
//             Text(body),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /* --------------------------------------------------------
//    EMPTY STATE
// --------------------------------------------------------- */

// class _EmptyAnnouncementState extends StatelessWidget {
//   const _EmptyAnnouncementState();

//   @override
//   Widget build(BuildContext context) {
//     debugPrint('[AnnouncementFeed] Showing empty state');
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: const [
//           Icon(Icons.campaign_outlined,
//               size: 64, color: Colors.grey),
//           SizedBox(height: 12),
//           Text(
//             'No announcements yet',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           SizedBox(height: 6),
//           Text(
//             'Updates from your teacher will appear here',
//             style: TextStyle(color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/sync_status_badge.dart';
import '../../services/api/api_client.dart';
import '../../services/api/session_service.dart';
import '../../routes/app_routes.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../services/api/announcements_service.dart';

/* ========================================================
   COURSE DETAIL PAGE
======================================================== */

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({super.key});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final GlobalKey<_AnnouncementFeedState> _feedKey =
      GlobalKey<_AnnouncementFeedState>();

  bool get _isInstructor {
    final role =
        SessionService.instance.currentUser?['role']?.toLowerCase();
    return role == 'admin' || role == 'instructor';
  }

  @override
  Widget build(BuildContext context) {
    final course =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    debugPrint('[CourseDetailPage] course args: $course');

    if (course == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: course['title'],
        variant: AppBarVariant.standard,
      ),
      body: Column(
        children: [

          
          // const SyncStatusBadge(showTimestamp: true),

          if (_isInstructor)
            _PostAnnouncementCard(
              courseId: course['id'],
              onPosted: () {
                _feedKey.currentState?.reload();
              },
            ),

          Expanded(
            child: AnnouncementFeed(
              key: _feedKey,
              courseId: course['id'],
            ),
          ),
        ],
      ),
    );
  }
}

/* ========================================================
   POST ANNOUNCEMENT CTA
======================================================== */

class _PostAnnouncementCard extends StatelessWidget {
  final int courseId;
  final VoidCallback onPosted;

  const _PostAnnouncementCard({
    required this.courseId,
    required this.onPosted,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        leading: const Icon(Icons.campaign),
        title: const Text('Post an announcement'),
        subtitle: const Text('Share updates with your class'),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () async {
          final result = await Navigator.pushNamed(
            context,
            AppRoutes.createAnnouncement,
            arguments: {'courseId': courseId},
          );

          if (result == true) {
            onPosted(); // ✅ refresh feed
          }
        },
      ),
    );
  }
}

/* ========================================================
   ANNOUNCEMENT FEED
======================================================== */

class AnnouncementFeed extends StatefulWidget {
  final int courseId;

  const AnnouncementFeed({
    super.key,
    required this.courseId,
  });

  @override
  State<AnnouncementFeed> createState() => _AnnouncementFeedState();
}

class _AnnouncementFeedState extends State<AnnouncementFeed> {
  bool get _isInstructor {
  final role =
      SessionService.instance.currentUser?['role']?.toLowerCase();
  return role == 'admin' || role == 'instructor';
}
  bool _loading = true;
  List<Map<String, dynamic>> _announcements = [];
int? get _currentUserId {
  return SessionService.instance.currentUser?['id'];
}
  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  /// ✅ PUBLIC METHOD CALLED BY PARENT
  void reload() {
    debugPrint('[AnnouncementFeed] reload() called');
    setState(() => _loading = true);
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final res = await ApiClient.instance.get(
        '/announcements.php',
        queryParameters: {
          'course_id': widget.courseId,
        },
      );

      if (res is List) {
        _announcements =
            res.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _announcements = [];
      }

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[AnnouncementFeed] ERROR: $e');
      setState(() => _loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load announcements')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_announcements.isEmpty) {
      return const _EmptyAnnouncementState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        final a = _announcements[index];
        final isOwner =
    _currentUserId?.toString() == a['created_by']?.toString();
final role =
    SessionService.instance.currentUser?['role']?.toLowerCase();

final canManage = role == 'admin' || isOwner;
final card = AnnouncementCard(
  title: a['title']?.toString() ?? '',
  body: a['content']?.toString() ?? '',
  author: a['created_name'] ??
      (a['created_role']?.toString().toUpperCase() ?? 'STAFF'),
  createdAt: a['created_date']?.toString(),
  canManage: false,
  onUpdated: reload,
);

if (!canManage) {
  return card;
}

return canManage
    ? Slidable(
        key: ValueKey(a['announcement_id']),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (context) async {
                final result = await Navigator.pushNamed(
                  context,
                  AppRoutes.createAnnouncement,
                  arguments: {
                    'courseId': widget.courseId,
                    'announcement': a,
                    'isEdit': true,
                  },
                );

                if (result == true) {
                  reload();
                }
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (context) async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Delete Announcement'),
                      content: const Text(
                          'Are you sure you want to delete this announcement?'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  await AnnouncementsService.instance
                      .delete(a['announcement_id']);
                  reload();
                }
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: card,
      )
    : card;
      },
    );
  }
}
/* ========================================================
   ANNOUNCEMENT CARD
======================================================== */

class AnnouncementCard extends StatelessWidget {
  final String title;
  final String body;
  final String author;
  final String? createdAt;
    final bool canManage;
  final VoidCallback onUpdated;

  const AnnouncementCard({
    super.key,
    required this.title,
    required this.body,
    required this.author,
    this.createdAt,
        required this.canManage,
    required this.onUpdated,

  });

@override
Widget build(BuildContext context) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 TOP ROW (Author + Icons)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    if (createdAt != null)
                      Text(
                        createdAt!,
                        style:
                            Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),

              /// ✅ EDIT & DELETE ICONS
              if (canManage)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: 'Edit',
                      onPressed: () {
                        // TODO: implement edit navigation
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          size: 20, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () {
                        // TODO: implement delete API
                      },
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 8),

          Text(body),
        ],
      ),
    ),
  );
}
}

/* ========================================================
   EMPTY STATE
======================================================== */

class _EmptyAnnouncementState extends StatelessWidget {
  const _EmptyAnnouncementState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.campaign_outlined,
              size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No announcements yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Updates from your teacher will appear here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
