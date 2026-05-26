import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'session_service.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
onRequest: (options, handler) async {
  await SessionService.instance.init();

  final instituteCode = SessionService.instance.institutionCode;
  final token = SessionService.instance.authToken;

  final skip = options.extra['skipInstitutionInjection'] == true;

  // ✅ Inject institution only if NOT skipping
  if (!skip &&
      instituteCode != null &&
      instituteCode.isNotEmpty) {
    options.queryParameters ??= {};
    options.queryParameters!['institution_code'] = instituteCode;
  }

  // ✅ Inject token only if NOT skipping
  if (!skip &&
      token != null &&
      token.isNotEmpty) {
    options.headers['Authorization'] = 'Bearer $token';
  }

  debugPrint(
    '[ApiClient] ${options.method} ${options.path} '
    'query: ${options.queryParameters} '
    'headers: ${options.headers}',
  );

  handler.next(options);
},

      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

Future<dynamic> get(
  String path, {
  Map<String, dynamic>? queryParameters,
  bool skipInstitutionInjection = false,
}) async {
    debugPrint('FINAL QUERY → $queryParameters');
    try {
final response = await _dio.get(
  path,
  queryParameters: queryParameters,
  options: Options(
    extra: {
      'skipInstitutionInjection': skipInstitutionInjection,
    },
  ),
);
      return _unwrap(response);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

// Future<dynamic> post(
//   String path, {
//   Map<String, dynamic>? data,
//   Map<String, dynamic>? queryParameters,
// }) async {
//   try {
//     final response = await _dio.post(
//       path,
//       data: data,
//       queryParameters: queryParameters,
//     );

//     debugPrint("STATUS: ${response.statusCode}");
//     debugPrint("RAW RESPONSE: ${response.data}");

//     return _unwrap(response);
//   } on DioException catch (error) {
//     debugPrint("DIO ERROR STATUS: ${error.response?.statusCode}");
//     debugPrint("DIO ERROR BODY: ${error.response?.data}");
//     throw _mapDioError(error);
//   }
// }

Future<dynamic> post(
  String path, {
  Map<String, dynamic>? data,
  Map<String, dynamic>? queryParameters,
  bool skipInstitutionInjection = false,
}) async {
  try {
    final response = await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        extra: {
          'skipInstitutionInjection': skipInstitutionInjection,
        },
      ),
    );

    debugPrint("STATUS: ${response.statusCode}");
    debugPrint("RAW RESPONSE: ${response.data}");

    return _unwrap(response);
  } on DioException catch (error) {
    debugPrint("DIO ERROR STATUS: ${error.response?.statusCode}");
    debugPrint("DIO ERROR BODY: ${error.response?.data}");
    throw _mapDioError(error);
  }
}
  // Future<dynamic> put(
  //   String path, {
  //   Map<String, dynamic>? data,
  //   Map<String, dynamic>? queryParameters,
  // }) async {
  //   try {
  //     final response = await _dio.put(
  //       path,
  //       data: data,
  //       queryParameters: queryParameters,
  //     );
  //     return _unwrap(response);
  //   } on DioException catch (error) {
  //     throw _mapDioError(error);
  //   }
  // }

  Future<dynamic> put(
  String path, {
  Map<String, dynamic>? data,
  Map<String, dynamic>? queryParameters,
}) async {
  try {
    final response = await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
    );

    debugPrint("STATUS: ${response.statusCode}");
    debugPrint("RAW RESPONSE: ${response.data}");

    return _unwrap(response);
  } on DioException catch (error) {

    debugPrint("===== PUT ERROR =====");
    debugPrint("STATUS: ${error.response?.statusCode}");
    debugPrint("BODY: ${error.response?.data}");
    debugPrint("=====================");

    throw _mapDioError(error);
  }
}
// make sure this is added

Future<dynamic> postMultipart(
  String path, {
  required Map<String, dynamic> data,
  required List<MultipartFile> files,
}) async {
  final formData = FormData.fromMap({
    ...data,
    'attachments[]': files, // 🔥 important key
  });

  final response = await _dio.post(
    path,
    data: formData,
    options: Options(
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    ),
  );

  return response.data;
}

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _unwrap(response);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  dynamic _unwrap(Response response) {
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      if (payload.containsKey('success')) {
        final success = payload['success'] == true;
        if (!success) {
          throw ApiException(
            payload['message']?.toString() ?? 'Request failed',
            statusCode: response.statusCode,
          );
        }
        return payload['data'];
      }
    }
    return payload;
  }

ApiException _mapDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
      return ApiException(
        "Connection timeout. Please check your internet.",
        statusCode: error.response?.statusCode,
      );

    case DioExceptionType.receiveTimeout:
      return ApiException(
        "Server is taking too long to respond.",
        statusCode: error.response?.statusCode,
      );

    case DioExceptionType.connectionError:
      return ApiException(
        "No internet connection.",
        statusCode: error.response?.statusCode,
      );

    case DioExceptionType.badResponse:
      final message = error.response?.data is Map<String, dynamic>
          ? error.response?.data['message']?.toString()
          : "Server error occurred";
      return ApiException(
        message ?? "Server error occurred",
        statusCode: error.response?.statusCode,
      );

    default:
      return ApiException(
        error.message ?? "Unexpected error occurred",
        statusCode: error.response?.statusCode,
      );
  }
}

}
