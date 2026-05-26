import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class StudentAttendanceCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final Function(String) onStatusChange;

  const StudentAttendanceCard({
    super.key,
    required this.student,
    required this.onStatusChange,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.schedule;
      case 'excused':
        return Icons.info;
      default:
        return Icons.help;
    }
  }

  void _showStatusOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mark Attendance',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            _buildStatusOption(
              context,
              'Present',
              'present',
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatusOption(
              context,
              'Absent',
              'absent',
              Icons.cancel,
              Colors.red,
            ),
            _buildStatusOption(
              context,
              'Late',
              'late',
              Icons.schedule,
              Colors.orange,
            ),
            _buildStatusOption(
              context,
              'Excused',
              'excused',
              Icons.info,
              Colors.blue,
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext context,
    String label,
    String status,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        onStatusChange(status);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = student['status'] as String;
    final statusColor = _getStatusColor(status);

    return Slidable(
      key: ValueKey(student['id']),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.mediumImpact();
              onStatusChange('present');
            },
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.check_circle,
            label: 'Present',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.mediumImpact();
              onStatusChange('absent');
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.cancel,
            label: 'Absent',
          ),
        ],
      ),
      child: InkWell(
        onLongPress: () => _showStatusOptions(context),
        child: Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Student Avatar
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(student['avatar']),
              ),

              SizedBox(width: 3.w),

              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      student['rollNumber'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (status == 'late' && student['lateArrivalTime'] != null)
                      Padding(
                        padding: EdgeInsets.only(top: 0.5.h),
                        child: Text(
                          'Arrived: ${student['lateArrivalTime']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (status == 'excused' && student['excuseNote'] != null)
                      Padding(
                        padding: EdgeInsets.only(top: 0.5.h),
                        child: Text(
                          student['excuseNote'],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),

              // Attendance Pattern
              Column(
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      final pattern = student['attendancePattern'] as List;
                      final isPresent = pattern[index] as bool;
                      return Container(
                        margin: EdgeInsets.only(left: 1.w),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isPresent ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '${student['attendanceRate'].toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              SizedBox(width: 3.w),

              // Status Toggle
              InkWell(
                onTap: () => _showStatusOptions(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: statusColor,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
