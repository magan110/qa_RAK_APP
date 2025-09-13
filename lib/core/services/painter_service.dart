import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/painter_models.dart';

class PainterService {
  // Change to your own base URL
  static String get _baseUrl => 'http://10.4.64.23:8521';

  static const _registerPath = '/api/Painter/register';

  static Map<String, String> get _jsonHeaders => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Register Painter
  static Future<PainterRegistrationResponse> registerPainter(
      PainterRegistrationRequest req) async {
    final uri = Uri.parse('$_baseUrl$_registerPath');
    final payload = json.encode(req.toJson());

    final res = await http.post(uri, headers: _jsonHeaders, body: payload);

    // Success
    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return PainterRegistrationResponse.fromJson(body);
    }

    // Error body from API
    try {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return PainterRegistrationResponse(
        success: false,
        message: (body['message'] ?? 'Registration failed').toString(),
        influencerCode: body['influencerCode']?.toString(),
      );
    } catch (_) {
      // Generic fallback
      return PainterRegistrationResponse(
        success: false,
        message: 'Registration failed (${res.statusCode})',
      );
    }
  }

  // ---------- helpers you can reuse in UI validators ----------

  /// Keep digits only; return empty string for null
  static String formatMobileUae(String? value) {
    if (value == null) return '';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 11) return digits;
    // keep last 11 (matches server expectation)
    return digits.substring(digits.length - 11);
  }

  /// IBAN -> remove spaces, uppercase
  static String formatIban(String? value) {
    if (value == null) return '';
    return value.replaceAll(' ', '').toUpperCase();
  }

  /// Very light validation (optional)
  static String? validateIban(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final noSpace = value.replaceAll(' ', '');
    if (noSpace.length < 8) return 'Invalid IBAN';
    return null;
  }

  /// Very light UAE mobile validation (optional)
  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile is required';
    }
    // You can sync this with your UI validator pattern if needed
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) return 'Enter a valid mobile';
    return null;
    }
}
