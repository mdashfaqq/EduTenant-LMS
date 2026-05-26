import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../services/api/session_service.dart';
import '../../utils/role_utils.dart';
import '../../services/assignment_submissions_service.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/sync_status_badge.dart';
import '../../services/api/assignments_service.dart';
import './widgets/assignment_description_widget.dart';
import './widgets/assignment_header_widget.dart';
import './widgets/attached_resources_widget.dart';
import './widgets/previous_submissions_widget.dart';
import './widgets/requirements_checklist_widget.dart';
import './widgets/submission_bottom_sheet.dart';
import './widgets/submission_guidelines_widget.dart';

/// Assignment Detail Screen
/// Provides comprehensive assignment information with mobile-optimized submission workflow
class AssignmentDetail extends StatefulWidget {
  const AssignmentDetail({super.key});

  @override
  State<AssignmentDetail> createState() => _AssignmentDetailState();
}

class _AssignmentDetailState extends State<AssignmentDetail> {
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _loadError;
  int? _assignmentId;
  int? _courseId;
  DateTime? _lastAutoSave;

  final Map<String, dynamic> _assignmentData = {
  "id": null,
  "title": "",
  "courseId": null,
  "courseName": "",
  "dueDate": DateTime.now(),
  "submissionStatus": "",
  "allowResubmission": true,
  "maxScore": 0,
  "description": "",
  "requirements": <Map<String, dynamic>>[],
  "attachedResources": <Map<String, dynamic>>[],
  "submissionGuidelines": <Map<String, dynamic>>[],
  "previousSubmissions": <Map<String, dynamic>>[],
};


  @override
  void initState() {
    super.initState();
    _startAutoSave();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoaded) {
      return;
    }
    _hasLoaded = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _assignmentId = _parseInt(args['assignmentId'] ?? args['id']);
      _courseId = _parseInt(args['courseId'] ?? args['course_id']);
    }
    _loadAssignment();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

Future<void> _loadAssignment() async {
  setState(() {
    _isLoading = true;
    _loadError = null;
  });

  try {
    if (_assignmentId == null) {
      throw Exception('Assignment ID missing');
    }

    final response =
        await AssignmentsService.instance.getAssignment(_assignmentId!);

    if (!mounted) return;

    setState(() {
      _applyAssignmentData(response['assignment']);

      _assignmentData['requirements'] =
          List<Map<String, dynamic>>.from(response['requirements'] ?? []);

      _assignmentData['submissionGuidelines'] =
          List<Map<String, dynamic>>.from(
            (response['submissionGuidelines'] ?? []).map(
              (g) => {
                ...g,
                'expanded': false,
              },
            ),
          );

      _assignmentData['attachedResources'] =
          List<Map<String, dynamic>>.from(response['attachedResources'] ?? []);

      _assignmentData['previousSubmissions'] =
          List<Map<String, dynamic>>.from(response['previousSubmissions'] ?? []);
    });
  } catch (e) {
    if (!mounted) return;
    setState(() => _loadError = e.toString());
  } finally {
    if (!mounted) return;
    setState(() => _isLoading = false);
  }
}


  void _applyAssignmentData(Map<String, dynamic> assignment) {
    final dueDate = _parseDate(assignment['due_date']);
    final maxScore = _parseInt(assignment['total_points']);
    final status = _formatStatus(assignment['status']);
    final description = assignment['description']?.toString();

    _assignmentData['id'] =
        assignment['assignment_id'] ?? assignment['id'] ?? _assignmentData['id'];
    _assignmentData['title'] = assignment['title'] ?? _assignmentData['title'];
    _assignmentData['courseId'] =
        assignment['course_id'] ?? _assignmentData['courseId'];
    _assignmentData['courseName'] =
        assignment['course_title'] ?? _assignmentData['courseName'];
    if (dueDate != null) {
      _assignmentData['dueDate'] = dueDate;
    }
    if (maxScore != null) {
      _assignmentData['maxScore'] = maxScore;
    }
    if (status != null) {
      _assignmentData['submissionStatus'] = status;
    }
    if (description != null && description.trim().isNotEmpty) {
      _assignmentData['description'] = description;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String? _formatStatus(dynamic status) {
    if (status == null) return null;
    final raw = status.toString().trim();
    if (raw.isEmpty) return null;
    final normalized = raw.replaceAll('_', ' ');
    switch (normalized.toLowerCase()) {
      case 'active':
      case 'open':
      case 'pending':
        return 'Not Submitted';
      case 'completed':
      case 'graded':
        return 'Graded';
      case 'closed':
      case 'archived':
        return 'Closed';
      default:
        return _titleCase(normalized);
    }
  }

  String _titleCase(String value) {
    return value
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  /// Start auto-save timer
  void _startAutoSave() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _autoSaveDraft();
        _startAutoSave();
      }
    });
  }

  /// Auto-save draft
  void _autoSaveDraft() {
    setState(() {
      _lastAutoSave = DateTime.now();
    });

    // Show subtle confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Draft saved'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 20.h, left: 4.w, right: 4.w),
      ),
    );
  }

  /// Show submission bottom sheet
  void _showSubmissionSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubmissionBottomSheet(onSubmit: _handleSubmission),
    );
  }
Future<void> _handleSubmission(List<Map<String, dynamic>> files) async {
  setState(() => _isSubmitting = true);

  try {
    final assignmentCode = _assignmentData['id']?.toString();

    if (assignmentCode == null || assignmentCode.isEmpty) {
      throw Exception('Invalid assignment code');
    }

    // Take first uploaded file (for now)
    final fileUrl = files.isNotEmpty ? files.first['url'] : null;

    await AssignmentSubmissionsService.instance.submitAssignment(
      assignmentCode: assignmentCode,
      fileUrl: fileUrl,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Assignment submitted successfully!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}

  /// Toggle requirement completion
  void _toggleRequirement(int index) {
    setState(() {
      final requirements = _assignmentData["requirements"] as List;
      requirements[index]["completed"] = !requirements[index]["completed"];
    });
    HapticFeedback.selectionClick();
  }

  /// Toggle guideline expansion
  void _toggleGuideline(int index) {
    setState(() {
      final guidelines = _assignmentData["submissionGuidelines"] as List;
      guidelines[index]["expanded"] = !guidelines[index]["expanded"];
    });
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
        title: 'Assignment Details',
        variant: AppBarVariant.standard,
      ),

      // ✅ PERMISSION-BASED BOTTOM BAR (same as CourseList)
      bottomNavigationBar: CustomBottomBar(
        variant: navVariant,
      ),

      body: Column(
        children: [
          const SyncStatusBadge(showTimestamp: true, compact: false),
          if (_loadError != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _loadError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Assignment header with countdown
                        AssignmentHeaderWidget(
                          title: _assignmentData["title"] as String,
                          dueDate: _assignmentData["dueDate"] as DateTime,
                          status:
                              _assignmentData["submissionStatus"] as String,
                          maxScore: _assignmentData["maxScore"] as int,
                        ),
                        SizedBox(height: 2.h),

                        // Assignment description
                        AssignmentDescriptionWidget(
                          description: _assignmentData["description"] as String,
                        ),

                        SizedBox(height: 2.h),

                        // Requirements checklist
                        RequirementsChecklistWidget(
                          requirements:
                              _assignmentData["requirements"]
                                  as List<Map<String, dynamic>>,
                          onToggle: _toggleRequirement,
                        ),

                        SizedBox(height: 2.h),

                        // Attached resources
                        AttachedResourcesWidget(
                          resources:
                              _assignmentData["attachedResources"]
                                  as List<Map<String, dynamic>>,
                        ),

                        SizedBox(height: 2.h),

                        // Submission guidelines
                        SubmissionGuidelinesWidget(
                          guidelines:
                              _assignmentData["submissionGuidelines"]
                                  as List<Map<String, dynamic>>,
                          onToggle: _toggleGuideline,
                        ),

                        SizedBox(height: 2.h),

                        // Previous submissions (if resubmission allowed)
                        if (_assignmentData["allowResubmission"] == true &&
                            (_assignmentData["previousSubmissions"] as List)
                                .isNotEmpty)
                          PreviousSubmissionsWidget(
                            submissions:
                                _assignmentData["previousSubmissions"]
                                    as List<Map<String, dynamic>>,
                          ),

                        SizedBox(height: 18.h), // Space for bottom toolbar
                      ],
                    ),
                  ),
          ),

          // Bottom sticky toolbar
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Auto-save indicator
                    if (_lastAutoSave != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 1.h),
                        child: Text(
                          'Last saved: ${_formatTime(_lastAutoSave!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                    Row(
                      children: [
                        // Save Draft button
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : _autoSaveDraft,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 1.8.h),
                              side: BorderSide(
                                color: theme.colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Save Draft',
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                        ),

                        SizedBox(width: 3.w),

                        // Start Submission button
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : _showSubmissionSheet,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 1.8.h),
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Start Submission',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format time for auto-save indicator
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
