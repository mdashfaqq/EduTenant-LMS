import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class InstitutionLogoService {
  static Future<String> uploadLogo(
    String institutionCode,
    File logoFile,
  ) async {
final uri = Uri.parse(
  'https://unreadymades.com/LMS/edutenant_lms_backend/api/institutions_logo.php',
);

    final request = http.MultipartRequest('POST', uri)
      ..fields['institution_code'] = institutionCode
      ..files.add(
        await http.MultipartFile.fromPath('logo', logoFile.path),
      )
      ..headers['Accept'] = 'application/json';

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Logo upload failed (${response.statusCode}): $body');
    }

    final decoded = jsonDecode(body);
    return decoded['data']['logo'];
  }
}
