import 'api_client.dart';
import 'session_service.dart';

class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();


  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  String? institutionCode,
  }) async {
final requestBody = {
  'email': email,
  'password': password,
};


if (institutionCode != null && institutionCode.isNotEmpty) {
  requestBody['institution_code'] = institutionCode;
}
print("LOGIN REQUEST BODY: $requestBody");
final data = await ApiClient.instance.post(
  '/auth.php',
  data: requestBody,
  skipInstitutionInjection: true,   // 🔥 THIS IS THE KEY
);

    // ✅ HANDLE STRING RESPONSE
    if (data is String) {
      throw Exception(data); // shown in UI error box
    }

    // ✅ HANDLE INVALID STRUCTURE
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response from server');
    }

    final payload = data;

    final user = payload['user'];
    if (user is! Map<String, dynamic>) {
      throw Exception('Login failed: user data missing');
    }

    final token = payload['token']?.toString() ?? '';

    // await SessionService.instance.setInstitution(
    //   code: institutionCode ?? null,
    //   name: user['institution_name']?.toString(),
    // );

    if (token.isNotEmpty) {
      await SessionService.instance.setAuthToken(token);
    }

    await SessionService.instance.setCurrentUser(user);

    return payload;
  }

Future<bool> verifyPassword({
  required String password,
}) async {
  try {
    // Make sure session is initialized
    await SessionService.instance.init();

    final user = SessionService.instance.currentUser;
    final institutionCode = SessionService.instance.institutionCode;

    if (user == null || institutionCode == null) {
      return false;
    }

    final email = user['email']?.toString();
    if (email == null || email.isEmpty) {
      return false;
    }

    // Try login again with entered password
    await login(
      email: email,
      password: password,
      institutionCode: institutionCode,
    );

    return true; // password correct
  } catch (e) {
    return false; // password wrong
  }
}

Future<bool> changePassword({
  required String currentPassword,
  required String newPassword,
}) async {
  try {
    await SessionService.instance.init();
    final user = SessionService.instance.currentUser;

    if (user == null) return false;

    final response = await ApiClient.instance.post(
      '/auth.php',
      data: {
        'action': 'change_password',
        'current_password': currentPassword,
        'new_password': newPassword,
        'user_id': user['id'],
      },
    );

    print("Change password response: $response");

    // 🔥 Your ApiClient already unwraps "data"
    if (response is Map<String, dynamic> &&
        response.containsKey('user')) {

      final updatedUser = response['user'];

      await SessionService.instance.setCurrentUser(updatedUser);

      return true;
    }

    return false;
  } catch (e) {
    print("Error: $e");
    return false;
  }
}

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String institutionCode,
    String? department,
  }) async {
    final data = await ApiClient.instance.post(
      '/auth.php',
      data: {
        'action': 'register',
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'institution_code': institutionCode,
        'department': department,
      },
    );

    final payload = (data as Map<String, dynamic>);
    final user = (payload['user'] as Map<String, dynamic>?) ?? {};
    final token = payload['token']?.toString() ?? '';

    await SessionService.instance.setInstitution(code: institutionCode);
    if (token.isNotEmpty) {
      await SessionService.instance.setAuthToken(token);
    }
    if (user.isNotEmpty) {
      await SessionService.instance.setCurrentUser(user);
    }

    return payload;
  }
}
