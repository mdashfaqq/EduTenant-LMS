import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class InstitutionLogoWidget extends StatelessWidget {
  final String? institutionName;
  final String? logoUrl;

  const InstitutionLogoWidget({
    super.key,
    this.institutionName,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 30.w,
      height: 30.w,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ 1. Show logo if available
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          'https://unreadymades.com/LMS/edutenant_lms_backend$logoUrl',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(context),
        ),
      );
    }

    // ✅ 2. Show initials if name exists
    if (institutionName != null && institutionName!.isNotEmpty) {
      return _buildInitials(context);
    }

    // ✅ 3. Placeholder
    return _buildPlaceholder(context);
  }

  Widget _buildInitials(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _getInitials(institutionName!);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          initials,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 1.h),
        CustomIconWidget(
          iconName: 'verified',
          size: 24,
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomIconWidget(
          iconName: 'school',
          size: 48,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        SizedBox(height: 1.h),
        Text(
          'Institution',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
}

