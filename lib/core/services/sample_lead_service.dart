import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sample_lead_request.dart';

class SampleLeadService {
  static const String baseUrl = 'http://10.4.64.23:8521';
  static const String registerEndpoint = '/api/SampleLead/register';

  static Future<SampleLeadResponse> registerSampleLead(SampleLeadRequest request) async {
    try {
      final url = Uri.parse('$baseUrl$registerEndpoint');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return SampleLeadResponse.fromJson(responseData);
      } else {
        return SampleLeadResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to register sample lead',
          error: responseData['error'] ?? 'HTTP ${response.statusCode}',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      return SampleLeadResponse(
        success: false,
        message: 'Network error occurred',
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }
}
