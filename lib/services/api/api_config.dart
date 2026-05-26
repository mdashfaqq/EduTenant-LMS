import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _envBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    return 'https://unreadymades.com/LMS/edutenant_lms_backend/api';
  }

  /// 🔥 Public base URL (without /api)
  static String get publicBaseUrl {
    final api = baseUrl;

    if (api.endsWith('/api')) {
      return api.substring(0, api.length - 4);
    }

    return api;
  }
}