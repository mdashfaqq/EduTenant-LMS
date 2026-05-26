import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class QuickMarkActionsWidget extends StatelessWidget {
  final Function(String) onMarkAll;
  final Function(String)? onBulkMarkByPeriod;

  const QuickMarkActionsWidget({
    super.key,
    required this.onMarkAll,
    this.onBulkMarkByPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  'Mark All Present',
                  Icons.check_circle_outline,
                  Colors.green,
                  () {
                    HapticFeedback.mediumImpact();
                    onMarkAll('present');
                  },
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildActionButton(
                  context,
                  'Mark All Absent',
                  Icons.cancel_outlined,
                  Colors.red,
                  () {
                    HapticFeedback.mediumImpact();
                    onMarkAll('absent');
                  },
                ),
              ),
            ],
          ),
          if (onBulkMarkByPeriod != null) ...[
            SizedBox(height: 1.h),
            _buildActionButton(
              context,
              'Bulk Mark by Period',
              Icons.calendar_view_week,
              theme.colorScheme.primary,
              () {
                HapticFeedback.mediumImpact();
                _showBulkPeriodDialog(context);
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showBulkPeriodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Mark by Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Daily'),
              onTap: () {
                Navigator.pop(context);
                onBulkMarkByPeriod!('daily');
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_week),
              title: const Text('Weekly'),
              onTap: () {
                Navigator.pop(context);
                onBulkMarkByPeriod!('weekly');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Monthly'),
              onTap: () {
                Navigator.pop(context);
                onBulkMarkByPeriod!('monthly');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 2.w),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
