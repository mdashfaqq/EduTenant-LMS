import 'package:flutter/material.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class EmptyStateWidget extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onBrowseCatalog;
  final VoidCallback onClearFilters;

  const EmptyStateWidget({
    super.key,
    required this.hasActiveFilters,
    required this.onBrowseCatalog,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state illustration
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.2,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: hasActiveFilters ? 'filter_list_off' : 'school',
                  color: theme.colorScheme.primary,
                  size: 80,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              hasActiveFilters ? 'No Courses Found' : 'No Courses Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              hasActiveFilters
                  ? 'Try adjusting your filters or search terms to find courses.'
                  : 'You haven\'t enrolled in any courses yet. Browse the course catalog to get started.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action buttons
            hasActiveFilters
                ? Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: onClearFilters,
                        icon: CustomIconWidget(
                          iconName: 'clear',
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                        label: const Text('Clear Filters'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          minimumSize: const Size(200, 48),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: onBrowseCatalog,
                        icon: CustomIconWidget(
                          iconName: 'explore',
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        label: const Text('Browse Catalog'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          minimumSize: const Size(200, 48),
                        ),
                      ),
                    ],
                  )
                : ElevatedButton.icon(
                    onPressed: onBrowseCatalog,
                    icon: CustomIconWidget(
                      iconName: 'explore',
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
                    label: const Text('Browse Course Catalog'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      minimumSize: const Size(220, 48),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
