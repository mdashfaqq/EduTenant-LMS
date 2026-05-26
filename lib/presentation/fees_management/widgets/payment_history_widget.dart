// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:sizer/sizer.dart';
// import 'package:intl/intl.dart';

// class PaymentHistoryWidget extends StatelessWidget {
//   final List<dynamic> paymentHistory;

//   const PaymentHistoryWidget({super.key, required this.paymentHistory});

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'success':
//         return Colors.green;
//       case 'pending':
//         return Colors.orange;
//       case 'failed':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData _getPaymentMethodIcon(String method) {
//     switch (method.toLowerCase()) {
//       case 'credit card':
//         return Icons.credit_card;
//       case 'bank transfer':
//         return Icons.account_balance;
//       case 'digital wallet':
//         return Icons.account_balance_wallet;
//       default:
//         return Icons.payment;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     if (paymentHistory.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.receipt_long_outlined,
//               size: 64,
//               color: theme.colorScheme.onSurfaceVariant,
//             ),
//             SizedBox(height: 2.h),
//             Text(
//               'No Payment History',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             SizedBox(height: 1.h),
//             Text(
//               'Your payment transactions will appear here',
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
//       itemCount: paymentHistory.length,
//       itemBuilder: (context, index) {
//         final payment = paymentHistory[index];
//         final paymentDate = DateFormat(
//           'MMM dd, yyyy',
//         ).format(DateTime.parse(payment['date']));
//         final statusColor = _getStatusColor(payment['status']);

//         return Container(
//           margin: EdgeInsets.only(bottom: 2.h),
//           padding: EdgeInsets.all(4.w),
//           decoration: BoxDecoration(
//             color: theme.colorScheme.surface,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: theme.colorScheme.outline),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: EdgeInsets.all(2.w),
//                     decoration: BoxDecoration(
//                       color: theme.colorScheme.primary.withValues(alpha: 0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Icon(
//                       _getPaymentMethodIcon(payment['method']),
//                       color: theme.colorScheme.primary,
//                       size: 24,
//                     ),
//                   ),
//                   SizedBox(width: 3.w),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           payment['description'],
//                           style: theme.textTheme.titleMedium?.copyWith(
//                             fontWeight: FontWeight.w600,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         SizedBox(height: 0.3.h),
//                         Text(
//                           payment['transactionId'],
//                           style: theme.textTheme.bodySmall?.copyWith(
//                             color: theme.colorScheme.onSurfaceVariant,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         '\$${payment['amount'].toStringAsFixed(2)}',
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           color: theme.colorScheme.primary,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       SizedBox(height: 0.3.h),
//                       Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 2.w,
//                           vertical: 0.3.h,
//                         ),
//                         decoration: BoxDecoration(
//                           color: statusColor.withValues(alpha: 0.1),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: Text(
//                           payment['status'].toUpperCase(),
//                           style: theme.textTheme.bodySmall?.copyWith(
//                             color: statusColor,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 10,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               SizedBox(height: 2.h),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.calendar_today,
//                         size: 14,
//                         color: theme.colorScheme.onSurfaceVariant,
//                       ),
//                       SizedBox(width: 1.w),
//                       Text(
//                         paymentDate,
//                         style: theme.textTheme.bodySmall?.copyWith(
//                           color: theme.colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                       SizedBox(width: 3.w),
//                       Icon(
//                         Icons.payment,
//                         size: 14,
//                         color: theme.colorScheme.onSurfaceVariant,
//                       ),
//                       SizedBox(width: 1.w),
//                       Text(
//                         payment['method'],
//                         style: theme.textTheme.bodySmall?.copyWith(
//                           color: theme.colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                     ],
//                   ),
//                   TextButton.icon(
//                     onPressed: () {
//                       HapticFeedback.selectionClick();
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text(
//                             'Downloading receipt for ${payment['transactionId']}',
//                           ),
//                         ),
//                       );
//                     },
//                     icon: const Icon(Icons.download, size: 16),
//                     label: const Text('Receipt'),
//                     style: TextButton.styleFrom(
//                       padding: EdgeInsets.symmetric(horizontal: 2.w),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../../../services/api/receipt_service.dart';
import '../../../../services/api/session_service.dart';

class PaymentHistoryWidget extends StatelessWidget {
  final List<dynamic> paymentHistory;

  const PaymentHistoryWidget({
    super.key,
    required this.paymentHistory,
  });

  // ✅ Indian compact formatter
  String formatIndianCurrency(num amount) {
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'credit card':
        return Icons.credit_card;
      case 'bank transfer':
        return Icons.account_balance;
      case 'digital wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (paymentHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text(
              'No Payment History',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Your payment transactions will appear here',
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
      itemCount: paymentHistory.length,
      itemBuilder: (context, index) {
        final payment = paymentHistory[index];
        final paymentDate = DateFormat('MMM dd, yyyy')
            .format(DateTime.parse(payment['date']));
        final statusColor = _getStatusColor(payment['status']);

        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPaymentMethodIcon(payment['method']),
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment['description'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.3.h),
                        Text(
                          payment['transactionId'],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // ✅ Currency fixed here
                      Text(
                        formatIndianCurrency(payment['amount']),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 0.3.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.3.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          payment['status'].toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        paymentDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Icon(
                        Icons.payment,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        payment['method'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
TextButton.icon(
  onPressed: () async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Downloading receipt...")),
  );

  try {
    await ReceiptService.downloadReceipt(
  payment,
  instituteName: SessionService.instance.currentUser?['institution_name'] ?? "Institute",
  studentName: SessionService.instance.currentUser?['name'] ?? "Student",
  studentId: SessionService.instance.currentUser?['id']?.toString() ?? "N/A",
  logoUrl: SessionService.instance.currentUser?['institution_logo'],
);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Receipt opened")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed: $e")),
    );
  }
},
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Receipt'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}