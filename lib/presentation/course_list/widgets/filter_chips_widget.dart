import 'package:flutter/material.dart';

class FilterChipsWidget extends StatelessWidget {
  final List<String> activeFilters;
  final Function(String) onFilterToggle;

  const FilterChipsWidget({
    super.key,
    required this.activeFilters,
    required this.onFilterToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableFilters = ['Current Semester', 'Completed', 'Archived'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: availableFilters.map((filter) {
            final isActive = activeFilters.contains(filter);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isActive,
                onSelected: (selected) => onFilterToggle(filter),
                backgroundColor: theme.colorScheme.surface,
                selectedColor: theme.colorScheme.primaryContainer,
                checkmarkColor: theme.colorScheme.primary,
                labelStyle: theme.textTheme.bodySmall?.copyWith(
                  color: isActive
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
