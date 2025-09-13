import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/contractor_models.dart';

class ContractorService {
  // Adjust to your environment
  static String get _baseUrl => 'http://10.4.64.23:8521'; // your host
  static const _registerPath = '/api/Contractor/register';
  static const _typesPath    = '/api/Contractor/contractor-types';
  static const _emiratesPath = '/api/Contractor/emirates-list';

  static Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Dropdowns
  static Future<List<String>> getContractorTypes() async {
    final uri = Uri.parse('$_baseUrl$_typesPath');
    final res = await http.get(uri, headers: _jsonHeaders);
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final list = (body['data'] as List?)?.map((e) => e.toString()).toList() ?? const [];
      return list;
    }
    throw Exception('Failed to load contractor types (${res.statusCode})');
  }

  static Future<List<String>> getEmiratesList() async {
    final uri = Uri.parse('$_baseUrl$_emiratesPath');
    final res = await http.get(uri, headers: _jsonHeaders);
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final list = (body['data'] as List?)?.map((e) => e.toString()).toList() ?? const [];
      return list;
    }
    throw Exception('Failed to load emirates list (${res.statusCode})');
  }

  // Register
  static Future<ContractorRegistrationResponse> registerContractor(
      ContractorRegistrationRequest req) async {
    final uri = Uri.parse('$_baseUrl$_registerPath');
    final payload = json.encode(req.toJson());

    final res = await http.post(uri, headers: _jsonHeaders, body: payload);

    if (res.statusCode == 200) {
      final jsonBody = json.decode(res.body) as Map<String, dynamic>;
      return ContractorRegistrationResponse.fromJson(jsonBody);
    } else {
      try {
        final jsonBody = json.decode(res.body) as Map<String, dynamic>;
        return ContractorRegistrationResponse(
          success: false,
          message: (jsonBody['message'] ?? 'Registration failed').toString(),
          contractorId: jsonBody['contractorId']?.toString(),
          influencerCode: jsonBody['influencerCode']?.toString(),
        );
      } catch (_) {
        return ContractorRegistrationResponse(
          success: false,
          message: 'Registration failed (${res.statusCode})',
        );
      }
    }
  }

  // Utilities you referenced in validators
  static String? validateMobileNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Mobile is required';
    final v = value.replaceAll(RegExp(r'\s+'), '');
    if (v.length < 10) return 'Enter a valid mobile';
    return null;
  }

  static String? validateIban(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    // Minimal check; customize for UAE if needed
    if (value.trim().length < 8) return 'Invalid IBAN';
    return null;
  }

  static String? formatMobileNumber(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'\s+'), '');
  }

  static String? formatIban(String? value) {
    if (value == null) return '';
    return value.replaceAll(' ', '').toUpperCase();
  }
}
