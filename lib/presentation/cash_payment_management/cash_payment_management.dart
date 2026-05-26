import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/sync_status_badge.dart';
import '../../services/api/fees_service.dart';
import '../../services/api/session_service.dart';
import '../../services/api/student_service.dart';
import './widgets/payment_status_dialog.dart';
import './widgets/student_fee_card.dart';
import './widgets/fee_management_card.dart';
import 'package:intl/intl.dart';

/// Cash Payment Management Screen
/// Enables administrators to process and track offline fee payments
class CashPaymentManagement extends StatefulWidget {
  const CashPaymentManagement({super.key});



  @override
  State<CashPaymentManagement> createState() => _CashPaymentManagementState();
}


class _CashPaymentManagementState extends State<CashPaymentManagement> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  List<Map<String, dynamic>> _filteredStudents = [];
  // int _currentBottomNavIndex = 3;
  
  bool _isLoading = false;
  String? _loadError;
  List<Map<String, dynamic>> _studentFees = [];
  List<Map<String, dynamic>> _feeStructures = [];
bool _isLoadingFees = false;
  List<Map<String, dynamic>> _students = [];
  final NumberFormat _rupeeFormat =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹');

String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterStudents);
    FeesService.instance.generateMonthlyFees();
    _loadStudents();
    _loadFeeStructures();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  

Future<void> _loadFeeStructures() async {
  setState(() => _isLoadingFees = true);

  try {
    final fees = await FeesService.instance.listFeeStructure();

    print("FEE STRUCTURE RESPONSE:");
    print(fees);

    if (!mounted) return;
    setState(() => _feeStructures = fees);
  } catch (e) {
    print("FEE STRUCTURE ERROR: $e");
    if (!mounted) return;
    setState(() => _loadError = e.toString());
  } finally {
    if (!mounted) return;
    setState(() => _isLoadingFees = false);
  }
}

Future<void> _cancelStudentFee(Map<String, dynamic> student) async {
final fees = _studentFees
    .where((f) =>
        f['studentId'] == student['id'] &&
        (f['amountPending'] ?? 0) > 0)
    .toList();

  if (fees.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No pending fee to cancel')),
    );
    return;
  }

  final fee = fees.first;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Cancel Fee'),
      content: const Text(
          'Are you sure you want to cancel the remaining fee for this student?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Yes, Cancel'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    await FeesService.instance.cancelFee(fee['id']);

    if (!mounted) return;

    await _loadStudents();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fee cancelled successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cancel failed: $e')),
    );
  }
}

Future<void> _loadStudents() async {
  setState(() {
    _isLoading = true;
    _loadError = null;
  });

  try {
    final fees = await FeesService.instance.listFees();
    final students = await StudentsService.instance.listStudents();

    final Map<int, Map<String, dynamic>> grouped = {};

    // 1️⃣ Start with ALL students
    for (final s in students) {
      final id = s['id'] as int;
      grouped[id] = {
        'id': id,
        'name': s['name'],
        'studentId': 'STU$id',
        'avatar':
            'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png',
        'totalFees': 0.0,
        'paidAmount': 0.0,
        'pendingAmount': 0.0,
        'status': 'pending',
        'lastPaymentDate': null,
      };
    }

    // 2️⃣ Merge fees into students
// 2️⃣ Merge fees into students (USE UI MAPPED KEYS)
for (final fee in fees) {
final studentId = fee['studentId'];
  if (studentId == null) continue;

  final student = grouped[studentId];
  if (student == null) continue;

final total = fee['finalAmount'] ?? fee['amount'] ?? 0.0;
final paid = fee['amountPaid'] ?? 0.0;
final pending = fee['amountPending'] ?? 0.0;

student['totalFees'] += total;
student['paidAmount'] += paid;
student['pendingAmount'] += (total - paid);

  student['lastPaymentDate'] = fee['last_payment_date'];
}

    // 3️⃣ Compute status
for (final student in grouped.values) {

  final studentFees = fees.where((f) => f['studentId'] == student['id']);

  // If any fee is cancelled → cancelled
  if (studentFees.any((f) => f['status'] == 'cancelled')) {
    student['status'] = 'cancelled';
    continue;
  }

  final pending = (student['pendingAmount'] ?? 0).toDouble();
  final paid = (student['paidAmount'] ?? 0).toDouble();

  if (pending <= 0 && paid > 0) {
    student['status'] = 'paid';
  } else if (paid > 0) {
    student['status'] = 'partial';
  } else {
    student['status'] = 'pending';
  }
}

    if (!mounted) return;
    setState(() {
      _studentFees = fees;
      _students = grouped.values.toList();
      _filteredStudents = List.from(_students);
    });
  } catch (e) {
    if (!mounted) return;
    setState(() => _loadError = e.toString());
  } finally {
    if (!mounted) return;
    setState(() => _isLoading = false);
  }
}

  void _filterStudents() {
    setState(() {
      _filteredStudents = _students.where((student) {
        final matchesSearch =
            student['name'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            student['studentId'].toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
        final matchesStatus =
            _selectedStatus == 'all' || student['status'] == _selectedStatus;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _showPaymentStatusDialog(Map<String, dynamic> student) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => PaymentStatusDialog(
        student: student,
        onUpdate: (paymentData) {
          _recordCashPayment(student, paymentData);
        },
      ),
    );
  }
  
void _showAssignFeeDialog() async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _AssignFeeDialog(),
  );

  if (result == true) {
    await _loadStudents(); // 🔥 refresh UI
  }
}


  Future<void> _recordCashPayment(
    Map<String, dynamic> student,
    Map<String, dynamic> paymentData,
  ) async {
final fees = _studentFees
    .where((f) =>
        f['studentId'] == student['id'] &&
        f['status'] != 'cancelled' &&
        (f['amountPending'] ?? 0) > 0)
    .toList();

fees.sort((a, b) {
  final aDate = DateTime.tryParse(a['dueDate'] ?? '') ?? DateTime(2100);
  final bDate = DateTime.tryParse(b['dueDate'] ?? '') ?? DateTime(2100);
  return aDate.compareTo(bDate);
});

final fee = fees.isNotEmpty ? fees.first : {};



    if (fee.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fee record found for this student.')),
      );
      return;
    }

    final currentUser = SessionService.instance.currentUser;
    final processedBy = currentUser?['id'];

    try {
      await FeesService.instance.recordPayment({
       'student_id': fee['studentId'],
        'student_fee_id': fee['id'],
        'amount': paymentData['amount'],
        'payment_method': paymentData['method'],
        'processed_by': processedBy,
        'transaction_id': paymentData['receiptNumber'],
      });
      if (!mounted) return;
      await _loadStudents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

return DefaultTabController(
  length: 2,
  child: Scaffold(
    appBar: CustomAppBar(
      title: 'Cash Payment Management',
      variant: AppBarVariant.standard,
      bottom: const TabBar(
        tabs: [
          Tab(icon: Icon(Icons.people_outline), text: 'Students'),
          Tab(icon: Icon(Icons.account_balance_wallet), text: 'Fees'),
        ],
      ),
    ),
    body: TabBarView(
      children: [
        _buildStudentsTab(),
        _buildFeesTab(),
      ],
    ),
    bottomNavigationBar: CustomBottomBar(
      variant: BottomBarVariant.admin,
    ),
  ),
);
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: 35.w,
      margin: EdgeInsets.only(right: 3.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildStudentsTab() {
  final theme = Theme.of(context);

return Column(
  children: [
Padding(
  padding: EdgeInsets.all(4.w),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        "Students",
        style: Theme.of(context).textTheme.titleLarge,
      ),
      ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text("Assign Fee"),
        onPressed: _showAssignFeeDialog,

      ),
    ],
  ),
),
      Padding(
        padding: EdgeInsets.all(4.w),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search students...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      SizedBox(
        height: 12.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          children: [
            _buildSummaryCard(
              'Total Students',
              _students.length.toString(),
              Icons.people_outline,
              theme.colorScheme.primary,
            ),
            _buildSummaryCard(
              'Pending',
              _students.where((s) => s['status'] == 'pending').length.toString(),
              Icons.pending_outlined,
              const Color(0xFFD97706),
            ),
            _buildSummaryCard(
              'Partial',
              _students.where((s) => s['status'] == 'partial').length.toString(),
              Icons.hourglass_empty,
              const Color(0xFF059669),
            ),
            _buildSummaryCard(
              'Paid',
              _students.where((s) => s['status'] == 'paid').length.toString(),
              Icons.check_circle_outline,
              const Color(0xFF059669),
            ),
          ],
        ),
      ),

      SizedBox(height: 2.h),

      Expanded(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(child: Text(_loadError!))
                : _filteredStudents.isEmpty
                    ? const Center(child: Text('No students found'))
                    : ListView.builder(
                        padding: EdgeInsets.all(4.w),
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
return StudentFeeCard(
  student: student,
  onRecordPayment: () =>
      _showPaymentStatusDialog(student),
  onCancelFee: () => _cancelStudentFee(student),
);
                        },
                      ),
      ),
    ],
  );
}
Widget _buildFeesTab() {
  if (_isLoadingFees) {
    return const Center(child: CircularProgressIndicator());
  }

  return Column(
    children: [
      // 🔹 Header + Create Button
      Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fee Structures',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Fee'),
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (_) => const CreateFeeStructureDialog(),
                );

                if (result == true) {
                  await _loadFeeStructures();
                }
              },
            ),
          ],
        ),
      ),

      // 🔹 List
      Expanded(
        child: _feeStructures.isEmpty
            ? const Center(child: Text('No fee structures found'))
            : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: _feeStructures.length,
                itemBuilder: (context, index) {
                  final fee = _feeStructures[index];

                  return FeeManagementCard(
                    fee: fee,
                    onEdit: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (_) =>
                            CreateFeeStructureDialog(fee: fee),
                      );

                      if (result == true) {
                        await _loadFeeStructures();
                      }
                    },
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Fee'),
                          content: const Text(
                              'Are you sure you want to delete this fee structure?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await FeesService.instance
                            .deleteFeeStructure(fee['id']);
                        await _loadFeeStructures();
                      }
                    },
                  );
                },
              ),
      ),
    ],
  );
}



void _showEditFeeDialog(Map<String, dynamic> fee) async {
  final parentContext = context;

  final result = await showDialog<bool>(
    context: context,
    builder: (_) => CreateFeeStructureDialog(fee: fee),
  );

  if (result == true) {
    await _loadFeeStructures();

    if (!mounted) return;
    ScaffoldMessenger.of(parentContext).showSnackBar(
      const SnackBar(content: Text('Fee updated successfully')),
    );
  }
}


  void _showFilterSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Status',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All'),
              selected: _selectedStatus == 'all',
              onTap: () {
                setState(() {
                  _selectedStatus = 'all';
                  _filterStudents();
                });
                Navigator.pop(context, true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pending_outlined),
              title: const Text('Pending'),
              selected: _selectedStatus == 'pending',
              onTap: () {
                setState(() {
                  _selectedStatus = 'pending';
                  _filterStudents();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.hourglass_empty),
              title: const Text('Partial'),
              selected: _selectedStatus == 'partial',
              onTap: () {
                setState(() {
                  _selectedStatus = 'partial';
                  _filterStudents();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Paid'),
              selected: _selectedStatus == 'paid',
              onTap: () {
                setState(() {
                  _selectedStatus = 'paid';
                  _filterStudents();
                });
                Navigator.pop(context);
              },
              
            ),
            ListTile(
              leading: const Icon(Icons.warning_outlined),
              title: const Text('Overdue'),
              selected: _selectedStatus == 'overdue',
              onTap: () {
                setState(() {
                  _selectedStatus = 'overdue';
                  _filterStudents();
                });
                Navigator.pop(context);
              },
              
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}

// ===============================
// Assign Fee Dialog (ADMIN)
// ===============================

class _AssignFeeDialog extends StatefulWidget {
  const _AssignFeeDialog();

  @override
  State<_AssignFeeDialog> createState() => _AssignFeeDialogState();
}


class _AssignFeeDialogState extends State<_AssignFeeDialog> {
  bool _loading = true;
  String? _error;
String _discountType = 'none'; // none, percentage, fixed
final TextEditingController _discountController = TextEditingController();
final TextEditingController _reasonController = TextEditingController();
bool _generateInstallments = true;

double _calculatedFinalAmount = 0;
  List<Map<String, dynamic>> _fees = [];
  List<Map<String, dynamic>> _students = [];

  int? selectedStudentId;
  int? selectedFeeId;
  DateTime? dueDate;
  String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final fees = await FeesService.instance.listFeeStructure();
 final students = await StudentsService.instance.listStudents();
      if (!mounted) return;
      setState(() {
        _fees = fees;
        _students = students;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        content: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(_error!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Assign Fee'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
           DropdownButtonFormField<int>(
  decoration: const InputDecoration(labelText: 'Select Student'),
  items: _students.map<DropdownMenuItem<int>>((s) {
    return DropdownMenuItem<int>(
      value: int.tryParse(s['id'].toString()),
      child: Text(s['name'].toString()),
    );
  }).toList(),
  onChanged: (v) => selectedStudentId = v,
),

const SizedBox(height: 16),

           DropdownButtonFormField<int>(
             isExpanded: true,
  decoration: const InputDecoration(labelText: 'Select Fee'),
items: _fees
    .where((f) =>
        f['status'] == 'active' && f['frequency'] != 'monthly')
    .map<DropdownMenuItem<int>>((f) {
    return DropdownMenuItem<int>(
      value: f['id'] as int, // 👈 CAST IS REQUIRED
      child: Text(
  '${f['name']} – ${formatCurrency(double.parse(f['amount'].toString()))}',
),
    );
  }).toList(),
  onChanged: (v) => selectedFeeId = v,
),

const SizedBox(height: 16),

// DropdownButtonFormField<String>(
//   value: _discountType,
//   decoration: const InputDecoration(
//     labelText: 'Discount Type',
//     border: OutlineInputBorder(),
//   ),
//   items: const [
//     DropdownMenuItem(value: 'none', child: Text('No Discount')),
//     DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
//     DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (₹)')),
//   ],
//   onChanged: (v) {
//     setState(() => _discountType = v!);
//   },
// ),

// const SizedBox(height: 16),

// if (_discountType != 'none')
//   TextField(
//     controller: _discountController,
//     keyboardType: TextInputType.number,
//     decoration: const InputDecoration(
//       labelText: 'Discount Value',
//       border: OutlineInputBorder(),
//     ),
//   ),

// const SizedBox(height: 16),

// if (_discountType != 'none')
//   TextField(
//     controller: _reasonController,
//     decoration: const InputDecoration(
//       labelText: 'Reason (Widow / Divorced / Scholarship)',
//       border: OutlineInputBorder(),
//     ),
//   ),
            TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                dueDate == null
                    ? 'Select Due Date'
                    : dueDate!.toIso8601String().split('T').first,
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  initialDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => dueDate = picked);
                }
                final fee = _fees.firstWhere((f) => f['id'] == selectedFeeId);

// 🚫 BLOCK monthly fees
if (fee['frequency'] == 'monthly') {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Monthly fees are auto-generated'),
    ),
  );
  return;
}
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
if (selectedStudentId == null || selectedFeeId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Please select student, fee and due date'),
                ),
              );
              return;
            }
            

            
    

            final fee =
                _fees.firstWhere((f) => f['id'] == selectedFeeId);

final now = DateTime.now();



await FeesService.instance.assignFee(
  studentId: selectedStudentId!,
  feeStructureId: selectedFeeId!,
  billingYear: now.year,
  billingMonth: now.month,
  discountType: _discountType,
  discountValue: _discountType == 'none'
      ? 0
      : double.tryParse(_discountController.text) ?? 0,
  generateInstallments: _generateInstallments,
);

// 🔥 IMPORTANT: refresh parent UI
if (mounted) {
  Navigator.pop(context, true); // return success
}
          },
          child: const Text('Assign'),
        ),
      ],
    );
  }
}
class CreateFeeStructureDialog extends StatefulWidget {
  final Map<String, dynamic>? fee;

  const CreateFeeStructureDialog({super.key, this.fee});

  @override
  State<CreateFeeStructureDialog> createState() =>
      _CreateFeeStructureDialogState();
}

class _CreateFeeStructureDialogState
    extends State<CreateFeeStructureDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  String _frequency = 'one_time';
  String _status = 'active';
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();

    if (widget.fee != null) {
      _isEdit = true;
      _nameController.text = widget.fee!['name'] ?? '';
      _amountController.text =
          widget.fee!['amount']?.toString() ?? '';
      _frequency = widget.fee!['frequency'] ?? 'one_time';
      _status = widget.fee!['status'] ?? 'active';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Fee Structure' : 'Create Fee Structure'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Fee Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'one_time', child: Text('One Time')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'semester', child: Text('Semester')),
                DropdownMenuItem(value: 'annual', child: Text('Annual')),
              ],
              onChanged: (v) => setState(() => _frequency = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context,true),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final payload = {
              'name': _nameController.text.trim(),
              'amount': _amountController.text.trim(),
              'frequency': _frequency,
              'status': _status,
            };

            if (_isEdit) {
              await FeesService.instance.updateFeeStructure(
                id: widget.fee!['id'],
                payload: payload,
              );
            } else {
              await FeesService.instance.createFeeStructure(payload);
            }

            Navigator.pop(context, true);
          },
          child: Text(_isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
