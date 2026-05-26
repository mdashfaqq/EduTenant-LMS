import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Submission bottom sheet with upload options
class SubmissionBottomSheet extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onSubmit;

  const SubmissionBottomSheet({super.key, required this.onSubmit});

  @override
  State<SubmissionBottomSheet> createState() => _SubmissionBottomSheetState();
}

class _SubmissionBottomSheetState extends State<SubmissionBottomSheet> {
  final List<Map<String, dynamic>> _selectedFiles = [];
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Handle camera capture
  Future<void> _handleCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedFiles.add({
            "name": image.name,
            "path": image.path,
            "size": "Unknown",
            "type": "image",
          });
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      _showError('Failed to capture image');
    }
  }

  /// Handle photo library selection
  Future<void> _handlePhotoLibrary() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            _selectedFiles.add({
              "name": image.name,
              "path": image.path,
              "size": "Unknown",
              "type": "image",
            });
          }
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      _showError('Failed to select images');
    }
  }

  /// Handle file browser selection
  Future<void> _handleFileBrowser() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'zip'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            _selectedFiles.add({
              "name": file.name,
              "path": file.path ?? '',
              "size": _formatFileSize(file.size),
              "type": _getFileType(file.extension ?? ''),
            });
          }
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      _showError('Failed to select files');
    }
  }

  /// Remove selected file
  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
    HapticFeedback.selectionClick();
  }

  /// Handle submission
  Future<void> _handleSubmit() async {
    if (_selectedFiles.isEmpty && _textController.text.trim().isEmpty) {
      _showError('Please add files or text before submitting');
      return;
    }

    setState(() => _isUploading = true);

    // Add text entry if provided
    final List<Map<String, dynamic>> allFiles = List.from(_selectedFiles);
    if (_textController.text.trim().isNotEmpty) {
      allFiles.add({
        "name": "text_submission.txt",
        "content": _textController.text.trim(),
        "type": "text",
      });
    }

    // Simulate upload delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pop(context);
      widget.onSubmit(allFiles);
    }
  }

  /// Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get file type from extension
  String _getFileType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'pdf';
      case 'doc':
      case 'docx':
        return 'document';
      case 'zip':
        return 'archive';
      default:
        return 'file';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 1.h),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Submit Assignment',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      size: 24,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upload options
                    Text(
                      'Upload Options',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Option buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildOptionButton(
                            context: context,
                            icon: 'camera_alt',
                            label: 'Camera',
                            onTap: _handleCamera,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: _buildOptionButton(
                            context: context,
                            icon: 'photo_library',
                            label: 'Gallery',
                            onTap: _handlePhotoLibrary,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 2.h),

                    Row(
                      children: [
                        Expanded(
                          child: _buildOptionButton(
                            context: context,
                            icon: 'folder_open',
                            label: 'Files',
                            onTap: _handleFileBrowser,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: _buildOptionButton(
                            context: context,
                            icon: 'text_fields',
                            label: 'Text',
                            onTap: () {
                              // Scroll to text field
                            },
                          ),
                        ),
                      ],
                    ),

                    // Selected files
                    if (_selectedFiles.isNotEmpty) ...[
                      SizedBox(height: 3.h),
                      Text(
                        'Selected Files (${_selectedFiles.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      ..._selectedFiles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;

                        return Container(
                          margin: EdgeInsets.only(bottom: 1.h),
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              CustomIconWidget(
                                iconName: _getFileIcon(file["type"] as String),
                                size: 24,
                                color: theme.colorScheme.primary,
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file["name"] as String,
                                      style: theme.textTheme.bodyMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (file["size"] != null)
                                      Text(
                                        file["size"] as String,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: CustomIconWidget(
                                  iconName: 'close',
                                  size: 20,
                                  color: theme.colorScheme.error,
                                ),
                                onPressed: () => _removeFile(index),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],

                    // Text entry
                    SizedBox(height: 3.h),
                    Text(
                      'Text Submission (Optional)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextField(
                      controller: _textController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Enter your submission text here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.8.h),
                        ),
                        child: _isUploading
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
                                'Submit Assignment',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build option button
  Widget _buildOptionButton({
    required BuildContext context,
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: icon,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get file icon
  String _getFileIcon(String type) {
    switch (type) {
      case 'image':
        return 'image';
      case 'pdf':
        return 'picture_as_pdf';
      case 'document':
        return 'description';
      case 'archive':
        return 'folder_zip';
      default:
        return 'insert_drive_file';
    }
  }
}
