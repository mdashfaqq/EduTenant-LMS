import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:sizer/sizer.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Grading tools bottom sheet widget
class GradingToolsSheet extends StatefulWidget {
  final Map<String, dynamic> submission;
  final Function(Map<String, dynamic>) onGradeSubmit;

  const GradingToolsSheet({
    super.key,
    required this.submission,
    required this.onGradeSubmit,
  });

  @override
  State<GradingToolsSheet> createState() => _GradingToolsSheetState();
}

class _GradingToolsSheetState extends State<GradingToolsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();

  String _selectedGrade = 'A';
  bool _isListening = false;
  bool _isRecording = false;
  String? _audioPath;
  List<String> _selectedRubricItems = [];

  final List<String> _grades = [
    'A+',
    'A',
    'A-',
    'B+',
    'B',
    'B-',
    'C+',
    'C',
    'C-',
    'D',
    'F',
  ];
  final List<String> _quickPhrases = [
    'Excellent work!',
    'Good effort',
    'Needs improvement',
    'Well done',
    'Please revise',
  ];
  final List<String> _rubricItems = [
    'Content Quality',
    'Organization',
    'Grammar & Spelling',
    'Citations',
    'Creativity',
  ];

  @override
  void initState() {
    super.initState();
    _initializeSpeechToText();
  }

  Future<void> _initializeSpeechToText() async {
    await _speechToText.initialize();
  }

  Future<void> _startListening() async {
    if (await Permission.microphone.request().isGranted) {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _commentController.text = result.recognizedWords;
          });
        },
      );
      setState(() => _isListening = true);
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  Future<void> _startRecording() async {
    if (await Permission.microphone.request().isGranted) {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(const RecordConfig(), path: 'feedback.m4a');
        setState(() => _isRecording = true);
      }
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _audioPath = path;
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGradePicker(theme),
                  SizedBox(height: 3.h),
                  _buildRubricSection(theme),
                  SizedBox(height: 3.h),
                  _buildCommentSection(theme),
                  SizedBox(height: 3.h),
                  _buildQuickPhrases(theme),
                  SizedBox(height: 3.h),
                  _buildAudioFeedback(theme),
                ],
              ),
            ),
          ),
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'close',
              size: 24,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grade Submission',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.submission['studentName'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Grade',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          height: 15.h,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 50,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() => _selectedGrade = _grades[index]);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final isSelected = _grades[index] == _selectedGrade;
                return Center(
                  child: Text(
                    _grades[index],
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
              childCount: _grades.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRubricSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rubric Checklist',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _rubricItems.map((item) {
            final isSelected = _selectedRubricItems.contains(item);
            return FilterChip(
              label: Text(item),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedRubricItems.add(item);
                  } else {
                    _selectedRubricItems.remove(item);
                  }
                });
              },
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommentSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Comments',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: _isListening ? 'mic' : 'mic_none',
                size: 24,
                color: _isListening
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              onPressed: _isListening ? _stopListening : _startListening,
            ),
          ],
        ),
        SizedBox(height: 2.h),
        TextField(
          controller: _commentController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Enter your feedback here...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPhrases(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Phrases',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _quickPhrases.map((phrase) {
            return ActionChip(
              label: Text(phrase),
              onPressed: () {
                setState(() {
                  _commentController.text +=
                      (_commentController.text.isEmpty ? '' : ' ') + phrase;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAudioFeedback(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audio Feedback',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: CustomIconWidget(
                iconName: _isRecording ? 'stop' : 'mic',
                size: 20,
                color: theme.colorScheme.onPrimary,
              ),
              label: Text(_isRecording ? 'Stop Recording' : 'Record Audio'),
            ),
            if (_audioPath != null) ...[
              SizedBox(width: 2.w),
              CustomIconWidget(
                iconName: 'check_circle',
                size: 24,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                widget.onGradeSubmit({
                  'grade': _selectedGrade,
                  'comment': _commentController.text,
                  'rubricItems': _selectedRubricItems,
                  'audioPath': _audioPath,
                  'status': 'needs_revision',
                });
                Navigator.pop(context);
              },
              child: const Text('Request Revision'),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                widget.onGradeSubmit({
                  'grade': _selectedGrade,
                  'comment': _commentController.text,
                  'rubricItems': _selectedRubricItems,
                  'audioPath': _audioPath,
                  'status': 'graded',
                });
                Navigator.pop(context);
              },
              child: const Text('Submit Grade'),
            ),
          ),
        ],
      ),
    );
  }
}
