import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/sync_status_badge.dart';
import './widgets/grade_distribution_chart.dart';
import './widgets/grading_progress_indicator.dart';
import './widgets/grading_tools_sheet.dart';
import './widgets/student_submission_card.dart';

class GradeManagement extends StatefulWidget {
  const GradeManagement({super.key});

  @override
  State<GradeManagement> createState() => _GradeManagementState();
}

class _GradeManagementState extends State<GradeManagement> {
  bool _isMultiSelectMode = false;
  final Set<int> _selectedSubmissions = {};
  String _filterStatus = 'all';

  final List<Map<String, dynamic>> _submissions = [
    {
      "id": 1,
      "studentName": "Emily Rodriguez",
      "studentAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1d99ce68c-1763293773878.png",
      "studentAvatarLabel":
          "Professional headshot of a young woman with long brown hair wearing a blue blazer",
      "submittedTime": "2 hours ago",
      "status": "pending",
      "type": "document",
      "fileName": "Research_Paper_Final.pdf",
      "fileSize": "2.4 MB",
      "grade": null,
    },
    {
      "id": 2,
      "studentName": "Michael Chen",
      "studentAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1ffeb43ad-1763298672388.png",
      "studentAvatarLabel":
          "Professional headshot of an Asian man with short black hair wearing glasses and a white shirt",
      "submittedTime": "5 hours ago",
      "status": "graded",
      "type": "document",
      "fileName": "Assignment_3_Submission.docx",
      "fileSize": "1.8 MB",
      "grade": "A",
    },
    {
      "id": 3,
      "studentName": "Sarah Johnson",
      "studentAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_11c812e67-1763301664668.png",
      "studentAvatarLabel":
          "Professional headshot of a blonde woman with shoulder-length hair wearing a gray sweater",
      "submittedTime": "1 day ago",
      "status": "needs_revision",
      "type": "document",
      "fileName": "Essay_Draft_v2.pdf",
      "fileSize": "1.2 MB",
      "grade": "B-",
    },
    {
      "id": 4,
      "studentName": "David Martinez",
      "studentAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1c13bd7bb-1763296465559.png",
      "studentAvatarLabel":
          "Professional headshot of a Hispanic man with short dark hair wearing a navy suit",
      "submittedTime": "1 day ago",
      "status": "graded",
      "type": "image",
      "fileName": "Project_Presentation.png",
      "fileSize": "3.5 MB",
      "grade": "A-",
    },
    {
      "id": 5,
      "studentName": "Jessica Taylor",
      "studentAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1c56710a9-1763300346689.png",
      "studentAvatarLabel":
          "Professional headshot of a young woman with curly red hair wearing a green blouse",
      "submittedTime": "2 days ago",
      "status": "pending",
      "type": "video",
      "fileName": "Video_Assignment.mp4",
      "fileSize": "45.2 MB",
      "grade": null,
    },
    {
      "id": 6,
      "studentName": "James Wilson",
      "studentAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1946b52b1-1763296100404.png",
      "studentAvatarLabel":
          "Professional headshot of a man with short brown hair and beard wearing a black t-shirt",
      "submittedTime": "2 days ago",
      "status": "graded",
      "type": "document",
      "fileName": "Final_Report.pdf",
      "fileSize": "2.1 MB",
      "grade": "B+",
    },
  ];

  final Map<String, int> _gradeDistribution = {
    'A+': 2,
    'A': 5,
    'A-': 3,
    'B+': 4,
    'B': 6,
    'B-': 2,
    'C+': 1,
    'C': 0,
    'F': 0,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Grade Management',
        variant: AppBarVariant.standard,
      ),
      body: Column(
        children: [
          const SyncStatusBadge(showTimestamp: true, compact: false),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: GradingProgressIndicator(
              totalSubmissions: _submissions.length,
              gradedSubmissions: _submissions
                  .where((s) => s['status'] == 'graded')
                  .length,
            ),
          ),
          Expanded(
            child: _getFilteredSubmissions().isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    itemCount: _getFilteredSubmissions().length,
                    itemBuilder: (context, index) {
                      final submission = _getFilteredSubmissions()[index];
                      final isSelected = _selectedSubmissions.contains(
                        submission['id'],
                      );

                      return _isMultiSelectMode
                          ? _buildMultiSelectCard(submission, isSelected, theme)
                          : StudentSubmissionCard(
                              submission: submission,
                              onTap: () => _openGradingSheet(submission),
                              onSwipeRight: () => _quickApprove(submission),
                              onSwipeLeft: () => _requestRevision(submission),
                            );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton:
          _isMultiSelectMode && _selectedSubmissions.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBulkActions,
              icon: CustomIconWidget(
                iconName: 'done_all',
                size: 24,
                color: theme.colorScheme.onPrimary,
              ),
              label: Text('Bulk Actions (${_selectedSubmissions.length})'),
            )
          : null,
    );
  }

  Widget _buildMultiSelectCard(
    Map<String, dynamic> submission,
    bool isSelected,
    ThemeData theme,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedSubmissions.add(submission['id'] as int);
            } else {
              _selectedSubmissions.remove(submission['id']);
            }
          });
        },
        title: Text(
          submission['studentName'] as String,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Submitted ${submission['submittedTime']}',
          style: theme.textTheme.bodySmall,
        ),
        secondary: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: CustomImageWidget(
            imageUrl: submission['studentAvatar'] as String,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            semanticLabel: submission['studentAvatarLabel'] as String,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'assignment_turned_in',
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: 2.h),
          Text(
            'No submissions found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Try adjusting your filters',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredSubmissions() {
    if (_filterStatus == 'all') {
      return _submissions;
    }
    return _submissions.where((s) => s['status'] == _filterStatus).toList();
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
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'all_inclusive',
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('All Submissions'),
                trailing: _filterStatus == 'all'
                    ? CustomIconWidget(
                        iconName: 'check',
                        size: 24,
                        color: theme.colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() => _filterStatus = 'all');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'pending',
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('Pending'),
                trailing: _filterStatus == 'pending'
                    ? CustomIconWidget(
                        iconName: 'check',
                        size: 24,
                        color: theme.colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() => _filterStatus = 'pending');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'check_circle',
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('Graded'),
                trailing: _filterStatus == 'graded'
                    ? CustomIconWidget(
                        iconName: 'check',
                        size: 24,
                        color: theme.colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() => _filterStatus = 'graded');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'refresh',
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('Needs Revision'),
                trailing: _filterStatus == 'needs_revision'
                    ? CustomIconWidget(
                        iconName: 'check',
                        size: 24,
                        color: theme.colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() => _filterStatus = 'needs_revision');
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: 2.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showGradeDistribution();
                  },
                  child: const Text('View Grade Distribution'),
                ),
              ),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  void _showGradeDistribution() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: 70.h,
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Class Performance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      size: 24,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Expanded(
                child: GradeDistributionChart(
                  gradeDistribution: _gradeDistribution,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openGradingSheet(Map<String, dynamic> submission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return GradingToolsSheet(
          submission: submission,
          onGradeSubmit: (gradeData) {
            _submitGrade(submission, gradeData);
          },
        );
      },
    );
  }

  void _submitGrade(
    Map<String, dynamic> submission,
    Map<String, dynamic> gradeData,
  ) {
    HapticFeedback.mediumImpact();
    setState(() {
      final index = _submissions.indexWhere((s) => s['id'] == submission['id']);
      if (index != -1) {
        _submissions[index]['grade'] = gradeData['grade'];
        _submissions[index]['status'] = gradeData['status'];
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          gradeData['status'] == 'graded'
              ? 'Grade submitted successfully'
              : 'Revision requested',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              final index = _submissions.indexWhere(
                (s) => s['id'] == submission['id'],
              );
              if (index != -1) {
                _submissions[index]['grade'] = null;
                _submissions[index]['status'] = 'pending';
              }
            });
          },
        ),
      ),
    );
  }

  void _quickApprove(Map<String, dynamic> submission) {
    HapticFeedback.lightImpact();
    _submitGrade(submission, {
      'grade': 'A',
      'status': 'graded',
      'comment': 'Approved',
    });
  }

  void _requestRevision(Map<String, dynamic> submission) {
    HapticFeedback.lightImpact();
    _submitGrade(submission, {
      'grade': submission['grade'],
      'status': 'needs_revision',
      'comment': 'Needs revision',
    });
  }

  void _showBulkActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'check_circle',
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('Approve All'),
                onTap: () {
                  Navigator.pop(context);
                  _bulkApprove();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'refresh',
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('Request Revisions'),
                onTap: () {
                  Navigator.pop(context);
                  _bulkRequestRevision();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'download',
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('Download Selected'),
                onTap: () {
                  Navigator.pop(context);
                  _bulkDownload();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _bulkApprove() {
    HapticFeedback.mediumImpact();
    setState(() {
      for (final id in _selectedSubmissions) {
        final index = _submissions.indexWhere((s) => s['id'] == id);
        if (index != -1) {
          _submissions[index]['grade'] = 'A';
          _submissions[index]['status'] = 'graded';
        }
      }
      _selectedSubmissions.clear();
      _isMultiSelectMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All selected submissions approved')),
    );
  }

  void _bulkRequestRevision() {
    HapticFeedback.mediumImpact();
    setState(() {
      for (final id in _selectedSubmissions) {
        final index = _submissions.indexWhere((s) => s['id'] == id);
        if (index != -1) {
          _submissions[index]['status'] = 'needs_revision';
        }
      }
      _selectedSubmissions.clear();
      _isMultiSelectMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Revision requested for selected submissions'),
      ),
    );
  }

  void _bulkDownload() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Downloading ${_selectedSubmissions.length} submissions...',
        ),
      ),
    );

    setState(() {
      _selectedSubmissions.clear();
      _isMultiSelectMode = false;
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportGrades();
        break;
      case 'analytics':
        _showGradeDistribution();
        break;
      case 'settings':
        _showGradingSettings();
        break;
    }
  }

  void _exportGrades() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting grades...')));
  }

  void _showGradingSettings() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Grading Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Enable rubric grading'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Allow late submissions'),
                value: false,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Send grade notifications'),
                value: true,
                onChanged: (value) {},
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Settings saved')));
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
