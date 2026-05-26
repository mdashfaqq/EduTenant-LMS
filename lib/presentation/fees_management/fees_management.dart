import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/sync_status_badge.dart';

import '../../services/api/fees_service.dart';
import '../../services/api/session_service.dart';
import './widgets/fee_overview_card.dart';
import './widgets/payment_history_widget.dart';
import './widgets/pending_dues_widget.dart';
import './widgets/payment_method_selector.dart';
import 'package:intl/intl.dart';

/// Fees Management Screen
/// Provides comprehensive financial tracking and payment processing
class FeesManagement extends StatefulWidget {
  const FeesManagement({super.key});

  @override
  State<FeesManagement> createState() => _FeesManagementState();
}

class _FeesManagementState extends State<FeesManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _loadError;
String formatIndianCurrency(double amount) {
  if (amount >= 10000000) {
    return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
  } else if (amount >= 100000) {
    return '₹${(amount / 100000).toStringAsFixed(1)}L';
  } else if (amount >= 1000) {
    return '₹${(amount / 1000).toStringAsFixed(1)}K';
  } else {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);
  }
}




  // Mock data for fees
  final Map<String, dynamic> _feesData = {
    "studentInfo": {
      "name": "Sarah Johnson",
      "studentId": "STU2025001",
      "semester": "Fall 2025",
      "program": "Computer Science",
    },
    "feeBreakdown": [
      {
        "id": 1,
        "category": "Tuition Fee",
        "amount": 5000.00,
        "dueDate": "2025-01-15",
        "status": "paid",
        "paidDate": "2025-01-10",
      },
      {
        "id": 2,
        "category": "Library Fee",
        "amount": 200.00,
        "dueDate": "2025-01-15",
        "status": "paid",
        "paidDate": "2025-01-10",
      },
      {
        "id": 3,
        "category": "Lab Fee",
        "amount": 500.00,
        "dueDate": "2025-02-15",
        "status": "pending",
      },
      {
        "id": 4,
        "category": "Sports Fee",
        "amount": 150.00,
        "dueDate": "2025-02-15",
        "status": "pending",
      },
      {
        "id": 5,
        "category": "Examination Fee",
        "amount": 300.00,
        "dueDate": "2025-03-15",
        "status": "upcoming",
      },
    ],
    "paymentHistory": [
      {
        "id": 1,
        "transactionId": "TXN20250110001",
        "amount": 5200.00,
        "date": "2025-01-10",
        "method": "Credit Card",
        "status": "success",
        "description": "Tuition Fee + Library Fee",
        "receiptUrl": "https://example.com/receipt/001",
      },
      {
        "id": 2,
        "transactionId": "TXN20241215001",
        "amount": 5000.00,
        "date": "2024-12-15",
        "method": "Bank Transfer",
        "status": "success",
        "description": "Semester Fee",
        "receiptUrl": "https://example.com/receipt/002",
      },
      {
        "id": 3,
        "transactionId": "TXN20241120001",
        "amount": 500.00,
        "date": "2024-11-20",
        "method": "Digital Wallet",
        "status": "success",
        "description": "Lab Fee",
        "receiptUrl": "https://example.com/receipt/003",
      },
    ],
    "summary": {
      "totalFees": 6150.00,
      "totalPaid": 5200.00,
      "pendingDues": 650.00,
      "upcomingDues": 300.00,
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFeesData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

Future<void> _loadFeesData() async {
  setState(() {
    _isLoading = true;
    _loadError = null;
  });

  try {
    final rawId = SessionService.instance.currentUser?['id'];
final int? studentId =
    rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    if (studentId == null) {
      throw Exception('Student not logged in');
    }

    final fees = await FeesService.instance.listFees(
      studentId: studentId,
    );

    final summary = _buildSummary(fees);

    final paymentHistory = fees
        .where((f) => (f['amountPaid'] ?? 0) > 0)
        .map((f) => {
              'transactionId': 'PAY-${f['id']}',
              'amount': f['amountPaid'],
              'date': f['paidDate'] ?? '—',
              'method': 'Offline / Admin',
              'status': 'success',
              'description': f['category'],
              'logo': SessionService.instance.currentUser?['institution_logo'],
            })
        .toList();

    setState(() {
      _feesData['feeBreakdown'] = fees;
      _feesData['summary'] = summary;
      _feesData['paymentHistory'] = paymentHistory;
    });
  } catch (e) {
    setState(() => _loadError = e.toString());
  } finally {
    setState(() => _isLoading = false);
  }
}

List<Map<String, dynamic>> _fees = [];

Map<String, dynamic> _buildSummary(List<Map<String, dynamic>> fees) {
  double totalFees = 0;
  double totalPaid = 0;
  double pendingDues = 0;
  double cancelled = 0;

  for (final fee in fees) {

    final amount =
        (fee['final_amount'] ?? fee['finalAmount'] ?? fee['amount'] ?? 0)
            .toDouble();

    final paid =
        (fee['amount_paid'] ?? fee['amountPaid'] ?? 0).toDouble();

    final pending =
        (fee['amount_pending'] ?? fee['amountPending'] ?? 0).toDouble();

    totalFees += amount;
    totalPaid += paid;
    pendingDues += pending;

    if (fee['status'] == 'cancelled') {
      cancelled += amount;
    }
  }

  return {
    'totalFees': totalFees,
    'totalPaid': totalPaid,
    'pendingDues': pendingDues,
    'cancelled': cancelled,
    'upcomingDues': 0.0,
  };
}

  void _handlePayNow(List<Map<String, dynamic>> selectedFees) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          PaymentMethodSelector(
            totalAmount: selectedFees.fold(
              0.0,
                  (sum, fee) => sum + (fee['amount'] as double),
            ),
            onPaymentComplete: (method) {
              Navigator.pop(context);
              _processPayment(selectedFees, method);
            },
          ),
    );
  }

  void _processPayment(List<Map<String, dynamic>> fees, String method) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            title: const Text('Processing Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: 2.h),
                Text('Processing your payment via $method...'),
              ],
            ),
          ),
    );

    _submitPayments(fees, method);
  }
Future<void> _submitPayments(
  List<Map<String, dynamic>> fees,
  String method,
) async {
  final currentUser = SessionService.instance.currentUser;
  final processedBy = currentUser?['id'];

  try {
    await Future.wait(
      fees.map(
        (fee) => FeesService.instance.recordPayment({
          'student_id': fee['studentId'] as int,
          'student_fee_id': fee['id'],
          'amount': (fee['amountPending'] ?? 0).toDouble(),
          'payment_method': method,
          'processed_by': processedBy,
          'transaction_id':
              'APP_${DateTime.now().millisecondsSinceEpoch}',
        }),
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);
    await _loadFeesData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful!'),
        backgroundColor: Color(0xFF059669),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: $e'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

  void _updateSummary() {
    final breakdown = _feesData['feeBreakdown'] as List;
    final totalPaid = breakdown
        .where((f) => f['status'] == 'paid')
        .fold(0.0, (sum, f) => sum + (f['amount'] as double));
    final pendingDues = breakdown
       .where((f) =>
    f['status'] == 'pending' ||
    f['status'] == 'partial')

        .fold(0.0, (sum, f) => sum + (f['amount'] as double));
    final upcomingDues = breakdown
        .where((f) => f['status'] == 'upcoming')
        .fold(0.0, (sum, f) => sum + (f['amount'] as double));

    setState(() {
      _feesData['summary']['totalPaid'] = totalPaid;
      _feesData['summary']['pendingDues'] = pendingDues;
      _feesData['summary']['upcomingDues'] = upcomingDues;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Fees Tracker',
        variant: AppBarVariant.standard,
      ),
      // ✅ ADD BOTTOM BAR HERE
      bottomNavigationBar: const CustomBottomBar(
        variant: BottomBarVariant.student,
      ),

      body: Column(
        children: [
          // const SyncStatusBadge(showTimestamp: true, compact: false),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  _loadError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : Column(
              children: [
                FeeOverviewCard(
                  summary:
                  _feesData['summary'] as Map<String, dynamic>,
                ),

                // ✅ TabBar must be inside Material
               Padding(
  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
  child: Material(
    color: theme.colorScheme.surface,
    borderRadius: BorderRadius.circular(10),
    child: TabBar(
      controller: _tabController,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      labelColor: theme.colorScheme.onPrimary,
      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
      labelPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      tabs: const [
        Tab(height: 36, text: 'Pending Dues'),
        Tab(height: 36, text: 'Payment History'),
      ],
    ),
  ),
),

                Expanded(
  child: TabBarView(
    controller: _tabController,
    children: [
PendingDuesWidget(
  
  feeBreakdown: (_feesData['feeBreakdown'] as List)
      .where((f) =>
    (f['amountPending'] ?? 0) > 0 ||
    f['status'] == 'cancelled')
      .map((f) => Map<String, dynamic>.from(f))
      .toList(),
  
),


      PaymentHistoryWidget(
        
        paymentHistory:
        _feesData['paymentHistory'] as List,
      ),
    ],
  ),
),

              
              ],
            ),
          ),
        ],
      ),
    );
  }
}