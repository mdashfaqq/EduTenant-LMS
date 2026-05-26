import 'api_client.dart';
import 'session_service.dart';

// class FeesService {
//   FeesService._internal();
//   static final FeesService instance = FeesService._internal();

//   /// ===============================
//   /// ASSIGN fee to student (ADMIN)
//   /// ===============================
//   Future<void> assignFee({
//     required int studentId,
//     required int feeId,
//     required double amount,
//     required String dueDate,
//   }) async {
//     final session = SessionService.instance;
//     await session.init();

//     await ApiClient.instance.post(
//       '/fees.php',
//       queryParameters: {
//         'assign': 1,
//         'institution_code': session.institutionCode,
//       },
//       data: {
//         'student_id': studentId,
//         'fee_id': feeId,
//         'amount_due': amount,
//         'due_date': dueDate,
//       },
//     );
//   }

//   /// ===============================
//   /// GET student fees
//   /// ===============================
// Future<List<Map<String, dynamic>>> listFees({
//   int? studentId,
//   String? status,
  
// }) async {
//   final session = SessionService.instance;
//   await session.init();

//   final params = <String, dynamic>{
//     'institution_code': session.institutionCode,
//   };

//   if (studentId != null) params['student_id'] = studentId;
//   if (status != null && status != 'all') params['status'] = status;

//   final dynamic response = await ApiClient.instance.get(
//     '/fees.php',
//     queryParameters: params,
//   );

//   // ✅ HANDLE BOTH API SHAPES
//   final List<dynamic> list =
//       response is List ? response : response['data'] ?? [];

//   return list
//       .map<Map<String, dynamic>>(
//         (e) => _toUiFee(Map<String, dynamic>.from(e)),
//       )
//       .toList();
// }


//   /// ===============================
//   /// GET fee structure
//   /// ===============================
// Future<List<Map<String, dynamic>>> listFeeStructure() async {
//   final session = SessionService.instance;
//   await session.init();

//   final List<dynamic> data =
//       await ApiClient.instance.get(
//         '/fees.php',
//         queryParameters: {
//           'structure': 1,
//           'institution_code': session.institutionCode,
//         },
//       );

//   return data
//       .map<Map<String, dynamic>>(
//         (e) => Map<String, dynamic>.from(e),
//       )
//       .toList();
// }

// /// ===============================
// /// CREATE fee structure (ADMIN)
// /// ===============================
// Future<void> createFeeStructure(Map<String, dynamic> payload) async {
//   final session = SessionService.instance;
//   await session.init();

//   await ApiClient.instance.post(
//     '/fees.php',
//     queryParameters: {
//       'structure': 1,
//       'institution_code': session.institutionCode,
//     },
//     data: payload,
//   );
// }

//   /// ===============================
//   /// POST payment
//   /// ===============================
//   Future<Map<String, dynamic>> recordPayment(
//     Map<String, dynamic> payload,
//   ) async {
//     final session = SessionService.instance;
//     await session.init();

//     final Map<String, dynamic> response =
//         await ApiClient.instance.post(
//           '/fees.php',
//           queryParameters: {
//             'payments': 1,
//             'institution_code': session.institutionCode,
//           },
//           data: payload,
//         );

//     return response['data'] ?? response;
//   }

//   /// ===============================
//   /// Backend → UI mapping
//   /// ===============================
//   Map<String, dynamic> _toUiFee(Map<String, dynamic> fee) {
    
//     return {
//       'id': fee['id'],
//       'category': fee['fee_name'] ?? fee['fee_type'] ?? 'Fee',
//       'amount': _toDouble(fee['amount_due']),
      
//       'dueDate': fee['due_date'],
//       'status': fee['status'],
//       'paidDate': fee['last_payment_date'],
//       'studentName': fee['student_name'],
//       'studentId': fee['student_id'],
//       'feeId': fee['fee_id'],
//       'amountPaid': _toDouble(fee['amount_paid']),
//       'amountPending': _toDouble(fee['amount_pending']),
//     };
//   }

//   double _toDouble(dynamic value) {
//     if (value == null) return 0.0;
//     if (value is num) return value.toDouble();
//     return double.tryParse(value.toString()) ?? 0.0;
//   }
// }
class FeesService {
  FeesService._internal();
  static final FeesService instance = FeesService._internal();

Future<void> assignFee({
  
  required int studentId,
  required int feeStructureId,
  required int billingYear,
  required int billingMonth,
  required String discountType,
  required double discountValue,
  required bool generateInstallments,
  String? dueDate,
}) async {
  final session = SessionService.instance;
  await session.init();
  print({
  'student_id': studentId,
  'fee_id': feeStructureId,
  'billing_year': billingYear,
  'billing_month': billingMonth,
  
});
print("ASSIGN URL:");
print('/fees.php?assign=1&institution_code=${session.institutionCode}');
  await ApiClient.instance.post(
    '/fees.php',
    queryParameters: {
      'assign': 1,
      'institution_code': session.institutionCode,
    },
    data: {
      'student_id': studentId,
      'fee_id': feeStructureId,
      'billing_year': billingYear,
      'billing_month': billingMonth,
      'discount_type': discountType,
      'discount_value': discountValue,
       'due_date': dueDate,
    },
  );
}

Future<void> generateMonthlyFees() async {
  final session = SessionService.instance;
  await session.init();

  final now = DateTime.now();

  final res = await ApiClient.instance.post(
    '/fees.php',
    queryParameters: {
      'generate_monthly': 1,
      'institution_code': session.institutionCode,
    },
    data: {
      'fee_id': 45,
      'billing_year': now.year,
      'billing_month': now.month,
    },
  );

  print("MONTHLY GENERATION RESPONSE:");
  print(res);
}


  Future<List<Map<String, dynamic>>> listFees({
    
    int? studentId,
    String? status,
  }) async {
    final session = SessionService.instance;
    await session.init();

    final params = <String, dynamic>{
      'institution_code': session.institutionCode,
    };

    if (studentId != null) params['student_id'] = studentId;
    if (status != null && status != 'all') params['status'] = status;

    final dynamic response =
        await ApiClient.instance.get('/fees.php', queryParameters: params);

    final List<dynamic> list =
        response is List ? response : response['data'] ?? [];

    return list
        .map((e) => _toUiFee(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listFeeStructure() async {
    final session = SessionService.instance;
    await session.init();

    final dynamic response = await ApiClient.instance.get(
      '/fees.php',
      queryParameters: {
        'structure': 1,
        'institution_code': session.institutionCode,
      },
    );

    final List<dynamic> list =
        response is List ? response : response['data'] ?? [];

    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }


  Future<Map<String, dynamic>> getDashboardFees() async {
    final res = await ApiClient.instance.get(
      '/fees.php?dashboard=1',
    );

    return res['data'] ?? res;
  }
Future<void> cancelFee(int studentFeeId) async {
  final session = SessionService.instance;
  await session.init();

  await ApiClient.instance.post(
    '/fees.php',
    queryParameters: {
      'cancel': 1,
      'institution_code': session.institutionCode,
    },
    data: {
      'student_fee_id': studentFeeId,
    },
  );
}
  Future<void> createFeeStructure(Map<String, dynamic> payload) async {
    final session = SessionService.instance;
    await session.init();

    await ApiClient.instance.post(
      '/fees.php',
      queryParameters: {
        'structure': 1,
        'institution_code': session.institutionCode,
      },
      data: payload,
    );
  }
  Future<void> updateFeeStructure({
  required int id,
  required Map<String, dynamic> payload,
}) async {
  await ApiClient.instance.post(
    '/fees.php',
    queryParameters: {
      'structure': 1,
      'update': 1,
      'id': id,
    },
    data: payload,
  );
}
Future<void> deleteFeeStructure(int id) async {
  await ApiClient.instance.post(
    '/fees.php',
    queryParameters: {
      'structure': 1,
      'delete': 1,
      'id': id,
    },
  );
}

  Future<Map<String, dynamic>> recordPayment(
    Map<String, dynamic> payload,
  ) async {
    final session = SessionService.instance;
    await session.init();

    final dynamic response = await ApiClient.instance.post(
      '/fees.php',
      queryParameters: {
        'payments': 1,
        'institution_code': session.institutionCode,
      },
      data: payload,
    );

    return response['data'] ?? response;
  }

Map<String, dynamic> _toUiFee(Map<String, dynamic> fee) {
     final finalAmount = _toDouble(fee['final_amount']);
final amountDue = _toDouble(fee['amount_due']);
  return {
    'id': fee['id'],
    'category': fee['fee_name'] ?? fee['fee_type'] ?? 'Fee',

    // 🔥 USE final_amount NOT amount_due


'amount': finalAmount > 0 ? finalAmount : amountDue,

    'dueDate': fee['due_date'],
    'status': fee['status'],
    'paidDate': fee['last_payment_date'],

    'studentName': fee['student_name'],
    'studentId': fee['student_id'],
    'feeStructureId': fee['fee_id'],

    'amountPaid': _toDouble(fee['amount_paid']),
    'amountPending': _toDouble(fee['amount_pending']),
  };
}

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}