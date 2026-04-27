import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Sends OTP codes via EmailJS (https://www.emailjs.com).
///
/// Template variables expected on the EmailJS template:
///   {{to_email}} — recipient address
///   {{code}}     — the 4-digit verification code
class EmailOtpService {
  EmailOtpService._();

  static const _serviceId  = 'service_bcef5el';
  static const _templateId = 'template_t8kcckn';
  static const _publicKey  = 'kR6IKxVw7eNevwFaV';
  static const _endpoint   = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Returns a fresh 4-digit code as a zero-padded string.
  static String generateCode() {
    final n = Random.secure().nextInt(10000);
    return n.toString().padLeft(4, '0');
  }

  /// Sends [code] to [toEmail]. Returns true on HTTP 200.
  static Future<bool> sendCode({required String toEmail, required String code}) async {
    final res = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json', 'Origin': 'http://localhost'},
      body: jsonEncode({
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'template_params': {
          'to_email': toEmail,
          'code': code,
        },
      }),
    );
    return res.statusCode == 200;
  }
}
