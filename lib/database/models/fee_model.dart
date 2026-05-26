/// Student Fee Model for SQLite database
class StudentFeeModel {
  final int? id;
  final String institutionCode;
  final int studentId;
  final int feeId;
  final double amountDue;
  final double amountPaid;
  final double? amountPending;
  final String? dueDate;
  final String status;
  final String? lastPaymentDate;
  final int syncStatus;
  final String? lastSync;

  StudentFeeModel({
    this.id,
    required this.institutionCode,
    required this.studentId,
    required this.feeId,
    required this.amountDue,
    this.amountPaid = 0.0,
    this.amountPending,
    this.dueDate,
    this.status = 'pending',
    this.lastPaymentDate,
    this.syncStatus = 0,
    this.lastSync,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institution_code': institutionCode,
      'student_id': studentId,
      'fee_id': feeId,
      'amount_due': amountDue,
      'amount_paid': amountPaid,
      'amount_pending': amountPending,
      'due_date': dueDate,
      'status': status,
      'last_payment_date': lastPaymentDate,
      'sync_status': syncStatus,
      'last_sync': lastSync,
    };
  }

  factory StudentFeeModel.fromMap(Map<String, dynamic> map) {
    return StudentFeeModel(
      id: map['id'] as int?,
      institutionCode: map['institution_code'] as String,
      studentId: map['student_id'] as int,
      feeId: map['fee_id'] as int,
      amountDue: map['amount_due'] as double,
      amountPaid: map['amount_paid'] as double? ?? 0.0,
      amountPending: map['amount_pending'] as double?,
      dueDate: map['due_date'] as String?,
      status: map['status'] as String? ?? 'pending',
      lastPaymentDate: map['last_payment_date'] as String?,
      syncStatus: map['sync_status'] as int? ?? 0,
      lastSync: map['last_sync'] as String?,
    );
  }
}
