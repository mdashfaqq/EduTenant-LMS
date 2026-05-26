import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class PaymentStatusDialog extends StatefulWidget {
  final Map<String, dynamic> student;
  final Function(Map<String, dynamic>) onUpdate;

  const PaymentStatusDialog({
    super.key,
    required this.student,
    required this.onUpdate,
  });

  @override
  State<PaymentStatusDialog> createState() => _PaymentStatusDialogState();
  
}

class _PaymentStatusDialogState extends State<PaymentStatusDialog> {
  double get pendingAmount {
  final value = widget.student['pendingAmount'];
  if (value is num) return value.toDouble();
  return 0.0;
}

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _receiptController = TextEditingController();
  String _selectedMethod = 'Cash';
  bool _isFullPayment = false;

  @override
  void initState() {
    super.initState();
    _receiptController.text =
        'RCP-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  void _handleFullPayment() {
    setState(() {
      _isFullPayment = !_isFullPayment;
      if (_isFullPayment) {
_amountController.text = pendingAmount.toStringAsFixed(2);

      } else {
        _amountController.clear();
      }
    });
    HapticFeedback.selectionClick();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      if (amount > pendingAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Amount cannot exceed pending amount'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      widget.onUpdate({
        'amount': amount,
        'method': _selectedMethod,
        'receiptNumber': _receiptController.text.trim(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Record Payment',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.student['name'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        widget.student['studentId'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pending Amount:',
                            style: theme.textTheme.bodyMedium,
                          ),
Text(
  '₹${pendingAmount.toStringAsFixed(2)}',

                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFFDC2626),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),

                CheckboxListTile(
                  value: _isFullPayment,
                  onChanged: (value) => _handleFullPayment(),
                  title: const Text('Full Payment'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                SizedBox(height: 1.h),

                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  enabled: !_isFullPayment,
                  decoration: const InputDecoration(
                    labelText: 'Payment Amount',
                    hintText: 'Enter amount',
                    prefixIcon: Icon(Icons.currency_rupee_sharp),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 2.h),

                DropdownButtonFormField<String>(
                  value: _selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: ['Cash', 'Check', 'Money Order']
                      .map(
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedMethod = value!);
                  },
                ),
                SizedBox(height: 2.h),

                TextFormField(
                  controller: _receiptController,
                  decoration: const InputDecoration(
                    labelText: 'Receipt Number',
                    hintText: 'Enter receipt number',
                    prefixIcon: Icon(Icons.receipt_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter receipt number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 3.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    SizedBox(width: 2.w),
                    ElevatedButton(
                      onPressed: _handleSubmit,
                      child: const Text('Record Payment'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
