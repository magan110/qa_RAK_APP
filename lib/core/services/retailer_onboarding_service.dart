import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/retailer_onboarding_models.dart';
import '../utils/app_logger.dart';

class RetailerOnboardingService {
  static final AppLogger _logger = AppLogger();
  static const String _baseUrl = 'http://10.4.64.23:8521';
  static const Duration _timeout = Duration(seconds: 30);

  static Future<RetailerOnboardingResponse> registerRetailer(
    RetailerOnboardingRequest request,
  ) async {
    try {
      _logger.info('Registering retailer via API');

      final uri = Uri.parse('$_baseUrl/api/RetailerOnboarding/register');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Convert to JSON and log for debugging
      final requestData = request.toJson();
      final requestBody = jsonEncode(requestData);
      
      _logger.debug('Request URL: $uri');
      _logger.debug('Request headers: $headers');
      _logger.debug('Request body: $requestBody');

      final response = await http
          .post(
            uri,
            headers: headers,
            body: requestBody,
          )
          .timeout(_timeout);

      _logger.debug('Response status: ${response.statusCode}');
      _logger.debug('Response body: ${response.body}');

      // Parse response with error handling
      Map<String, dynamic> responseData = {};
      try {
        if (response.body.isNotEmpty) {
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        _logger.error('Failed to parse response JSON', e);
        return RetailerOnboardingResponse(
          success: false,
          message: 'Failed to parse server response',
          error: 'JSON parsing error: $e',
          timestamp: DateTime.now(),
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return RetailerOnboardingResponse.fromJson(responseData);
      } else {
        // Handle error response
        return RetailerOnboardingResponse(
          success: false,
          message: responseData['message']?.toString() ?? 'Registration failed',
          error: responseData['error']?.toString() ?? 
                 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      _logger.error('Retailer registration failed', e);
      return RetailerOnboardingResponse(
        success: false,
        message: 'Registration failed',
        error: 'Network error: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  static Future<Map<String, dynamic>> testConnection() async {
    try {
      _logger.info('Testing connection to retailer onboarding API');

      final uri = Uri.parse('$_baseUrl/api/RetailerOnboarding');
      final response = await http
          .get(
            uri,
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      return {
        'success': response.statusCode == 200 || response.statusCode == 404,
        'statusCode': response.statusCode,
        'message': response.statusCode == 404
            ? 'API endpoint reachable but GET not supported'
            : 'Connection successful',
      };
    } catch (e) {
      _logger.error('Connection test failed', e);
      return {
        'success': false,
        'error': 'Connection failed: $e',
      };
    }
  }
}