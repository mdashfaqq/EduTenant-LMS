import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class StudentFeeCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onRecordPayment;
    final VoidCallback? onCancelFee;
  

  StudentFeeCard({
    super.key,
    required this.student,
    required this.onRecordPayment,
     this.onCancelFee,
    
  });

  double numValue(String key) {
    final v = student[key];
    if (v is num) return v.toDouble();
    return 0.0;
  }

  String stringValue(String key) {
    final v = student[key];
    if (v is String) return v;
    return '';
  }


  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return const Color(0xFF059669);
      case 'partial':
        return const Color(0xFFD97706);
      case 'pending':
        return const Color(0xFFDC2626);
      case 'overdue':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

String _getStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return 'PAID';
    case 'partial':
      return 'PARTIAL';
    case 'pending':
      return 'PENDING';
    case 'overdue':
      return 'OVERDUE';
    case 'cancelled':
      return 'CANCELLED';
    default:
      return 'UNKNOWN';
  }
}
  final NumberFormat _rupeeFormat =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

String formatCurrency(double amount) {
  return _rupeeFormat.format(amount);
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(student['status']);
    final status = student['status'];
final isPaid = status == 'paid';
final isCancelled = status == 'cancelled';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(student['avatar']),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.3.h),
                      Text(
                        student['studentId'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    _getStatusLabel(student['status']),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Fees', style: theme.textTheme.bodyMedium),
                      Text(
                        formatCurrency(numValue('totalFees')),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paid Amount',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF059669),
                        ),
                      ),
                      Text(
                     formatCurrency(numValue('paidAmount')),

                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF059669),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pending Amount',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                      Text(
                 formatCurrency(numValue('pendingAmount')),

                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (student['lastPaymentDate'] != null) ...[
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(
                    Icons.receipt_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child:Text(
'Last Payment: ${formatCurrency(numValue('lastPaymentAmount'))} '
  'on ${DateFormat('MMM dd, yyyy').format(DateTime.parse(student['lastPaymentDate']))}',
  style: theme.textTheme.bodySmall?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  ),
),

                  ),
                ],
              ),
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Receipt: ${stringValue('receiptNumber')}',

                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],

if (!isPaid && !isCancelled) ...[
  SizedBox(height: 2.h),

  Row(
    children: [

      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            onRecordPayment();
          },
          icon: const Icon(Icons.payment),
          label: const Text('Record Payment'),
        ),
      ),

      SizedBox(width: 3.w),

      Expanded(
        child: ElevatedButton.icon(
          onPressed: onCancelFee == null ? null : () {
  HapticFeedback.mediumImpact();
  onCancelFee!();
},
          icon: const Icon(Icons.cancel),
          label: const Text('Cancel Fee'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
        ),
      ),
    ],
  ),
],
          ],
        ),
      ),
    );
  }
}
