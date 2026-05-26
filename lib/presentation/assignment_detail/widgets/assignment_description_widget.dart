import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Assignment description widget with rich text content
class AssignmentDescriptionWidget extends StatelessWidget {
  final String description;

  const AssignmentDescriptionWidget({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'description',
                size: 20,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Text(
                'Assignment Description',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Description content
          _buildRichText(context, description),
        ],
      ),
    );
  }

  /// Build rich text from markdown-like content
  Widget _buildRichText(BuildContext context, String content) {
    final theme = Theme.of(context);
    final lines = content.trim().split('\n');
    final widgets = <Widget>[];

    for (var line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(SizedBox(height: 1.h));
        continue;
      }

      // Heading 1
      if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: 1.h, bottom: 0.5.h),
            child: Text(
              line.substring(2),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
      // Heading 2
      else if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: 1.h, bottom: 0.5.h),
            child: Text(
              line.substring(3),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
      // Numbered list
      else if (RegExp(r'^\d+\.').hasMatch(line)) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 0.5.h),
            child: Text(line, style: theme.textTheme.bodyMedium),
          ),
        );
      }
      // Regular paragraph
      else {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 0.5.h),
            child: Text(
              line,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
