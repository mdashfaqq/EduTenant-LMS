// import 'package:flutter/material.dart';
// import 'package:sizer/sizer.dart';
// import 'package:intl/intl.dart';

// class PendingDuesWidget extends StatelessWidget {
//   final List<Map<String, dynamic>> feeBreakdown;

//   const PendingDuesWidget({
//     super.key,
//     required this.feeBreakdown,
//   });

//   double _safeAmount(dynamic value) {
//     if (value == null) return 0.0;
//     if (value is num) return value.toDouble();
//     return double.tryParse(value.toString()) ?? 0.0;
//   }

//   List<Map<String, dynamic>> get _pendingFees =>
//       feeBreakdown
//           .where((f) => _safeAmount(f['amountPending']) > 0)
//           .map((f) => Map<String, dynamic>.from(f))
//           .toList();

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     if (_pendingFees.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.check_circle_outline,
//               size: 64,
//               color: theme.colorScheme.primary,
//             ),
//             SizedBox(height: 2.h),
//             Text(
//               'No Pending Dues',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             SizedBox(height: 1.h),
//             Text(
//               'All fees are paid up to date',
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.builder(
//       padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
//       itemCount: _pendingFees.length,
//       itemBuilder: (context, index) {
//         final fee = _pendingFees[index];
//         final dueDate = DateFormat('MMM dd, yyyy')
//             .format(DateTime.parse(fee['dueDate']));
//         final amount = _safeAmount(fee['amountPending']);

//         return Container(
//           margin: EdgeInsets.only(bottom: 2.h),
//           padding: EdgeInsets.all(4.w),
//           decoration: BoxDecoration(
//             color: theme.colorScheme.surface,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: theme.colorScheme.outline),
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       fee['category'],
//                       style: theme.textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     SizedBox(height: 0.5.h),
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.calendar_today,
//                           size: 14,
//                           color: theme.colorScheme.onSurfaceVariant,
//                         ),
//                         SizedBox(width: 1.w),
//                         Text(
//                           'Due: $dueDate',
//                           style: theme.textTheme.bodySmall?.copyWith(
//                             color: theme.colorScheme.onSurfaceVariant,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               Text(
//                 '₹${amount.toStringAsFixed(2)}',
//                 style: theme.textTheme.titleLarge?.copyWith(
//                   color: theme.colorScheme.primary,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class PendingDuesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> feeBreakdown;

  const PendingDuesWidget({
    super.key,
    required this.feeBreakdown,
  });

  double _safeAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // ✅ Indian compact currency formatter
  String _formatIndianCurrency(num amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

List<Map<String, dynamic>> get _pendingFees =>
    feeBreakdown
        .where((f) =>
            _safeAmount(f['amountPending']) > 0 ||
            f['status'] == 'cancelled')
        .map((f) => Map<String, dynamic>.from(f))
        .toList();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_pendingFees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 2.h),
            Text(
              'No Pending Dues',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'All fees are paid up to date',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      itemCount: _pendingFees.length,
itemBuilder: (context, index) {
  final fee = _pendingFees[index];

  final dueDate = DateFormat('MMM dd, yyyy')
      .format(DateTime.parse(fee['dueDate'] ?? fee['due_date']));

  final bool cancelled = fee['status'] == 'cancelled';

double amount;

if (fee['status'] == 'cancelled') {
  amount = _safeAmount(
      fee['finalAmount'] ??
      fee['final_amount'] ??
      fee['amount'] ??
      fee['amount_due']);
} else {
  amount = _safeAmount(
      fee['amountPending'] ??
      fee['amount_pending']);
}

  return Container(
    margin: EdgeInsets.only(bottom: 2.h),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: cancelled
          ? theme.colorScheme.surfaceVariant
          : theme.colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: Row(
      children: [

        /// LEFT STATUS BAR
        Container(
          width: 5,
          height: 11.h,
          decoration: BoxDecoration(
            color: cancelled
                ? Colors.grey
                : theme.colorScheme.primary,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(14),
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// TITLE + STATUS
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fee['fee_name'] ?? fee['category'] ?? "Fee",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    if (cancelled)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 3.w, vertical: 0.4.h),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "CANCELLED",
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 1.h),

                /// DUE DATE
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 1.5.w),
                    Text(
                      "Due $dueDate",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 1.3.h),

                /// AMOUNT
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formatIndianCurrency(amount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cancelled
                          ? Colors.grey
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
    },
  );
}
}