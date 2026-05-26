import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  SessionService._internal();
  String? _institutionLogo;

  String? get institutionLogo => _institutionLogo;
  static final SessionService instance = SessionService._internal();

  static const String _institutionCodeKey = 'institution_code';
  static const String _institutionNameKey = 'institution_name';
  static const String _authTokenKey = 'auth_token';
  static const String _currentUserKey = 'current_user';
 static const String _biometricEnabledKey = 'biometric_enabled';
 static const String _institutionLogoKey = 'institution_logo';
  SharedPreferences? _prefs;
  

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
      _institutionLogo = _prefs!.getString(_institutionLogoKey);
  }

Future<void> setInstitution({
  required String code,
  String? name,
  String? logo,
}) async {
  await init();

  await _prefs!.setString(_institutionCodeKey, code);

  if (name != null) {
    await _prefs!.setString(_institutionNameKey, name);
  }

  if (logo != null) {
    await _prefs!.setString(_institutionLogoKey, logo);
    _institutionLogo = logo; // store in memory too
  }
}
// String? get institutionCode {
//   if (_prefs == null) {
//     throw Exception("SessionService not initialized");
//   }
//   return _prefs!.getString(_institutionCodeKey);
// }
String? get institutionCode {
  return _prefs?.getString(_institutionCodeKey);
}

  String? get institutionName {
    return _prefs?.getString(_institutionNameKey);
  }

  Future<void> setAuthToken(String token) async {
    await init();
    await _prefs!.setString(_authTokenKey, token);
  }

  String? get authToken {
    return _prefs?.getString(_authTokenKey);
  }
 
 Future<void> clearInstitution() async {
  await init();

  await _prefs!.remove(_institutionCodeKey);
  await _prefs!.remove(_institutionNameKey);
  await _prefs!.remove(_institutionLogoKey);

  _institutionLogo = null;
}

Future<void> setBiometricEnabled(bool value) async {
  await init();
  await _prefs!.setBool(_biometricEnabledKey, value);
}

bool get biometricEnabled {
  return _prefs?.getBool(_biometricEnabledKey) ?? false;
}


  Future<void> setCurrentUser(Map<String, dynamic> user) async {
    await init();
    await _prefs!.setString(_currentUserKey, jsonEncode(user));
  }

  Map<String, dynamic>? get currentUser {
    final raw = _prefs?.getString(_currentUserKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clearSession() async {
    await init();
    await _prefs!.remove(_authTokenKey);
    await _prefs!.remove(_currentUserKey);
  }
}
