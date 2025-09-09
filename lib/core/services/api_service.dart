import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;
import '../utils/app_logger.dart';

class ApiService {
  static final AppLogger _logger = AppLogger();
  static const Duration _defaultTimeout = Duration(seconds: 30);

  // Base URL configuration with fallback options
  static String get baseUrl {
    return 'http://10.166.220.122';
  }

  static List<String> get fallbackUrls => [
    'http://10.166.220.122',
    'http://[::1]',
    'http://localhost',
    'http://127.0.0.1',
  ];

  static bool get _isInAppWebView {
    if (kIsWeb) {
      try {
        final ua = web.window.navigator.userAgent.toLowerCase();
        final vendor = web.window.navigator.vendor.toLowerCase();
        final loc = web.window.location;

        return ua.contains('inapp') ||
            ua.contains('webview') ||
            ua.contains('inappbrowser') ||
            ua.contains('capacitor') ||
            ua.contains('cordova') ||
            ua.contains('phonegap') ||
            vendor.contains('inapp') ||
            loc.protocol == 'file:' ||
            loc.protocol == 'capacitor:' ||
            loc.protocol == 'ionic:' ||
            (loc.hostname == 'localhost' && loc.port.isEmpty) ||
            (ua.contains('mobile') && !ua.contains('chrome'));
      } catch (_) {
        return true;
      }
    }
    return false;
  }

  // Remove duplicate - using the new fallbackUrls getter above

  // Generic HTTP methods
  static Future<Map<String, dynamic>> _makeRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      _logger.info('Making $method request to $endpoint');

      final uri = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?headers,
      };

      http.Response response;
      final timeoutDuration = timeout ?? _defaultTimeout;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(uri, headers: requestHeaders)
              .timeout(timeoutDuration);
          break;
        case 'POST':
          response = await http
              .post(
                uri,
                headers: requestHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(timeoutDuration);
          break;
        case 'PUT':
          response = await http
              .put(
                uri,
                headers: requestHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(timeoutDuration);
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: requestHeaders)
              .timeout(timeoutDuration);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      _logger.debug('Response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _safeJson(response.body);
        return {
          'success': true,
          'data': data,
          'statusCode': response.statusCode,
        };
      } else {
        final error = _safeJson(response.body);
        return {
          'success': false,
          'error': error['message'] ?? 'Request failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      _logger.error('Request failed', e);
      return {'success': false, 'error': 'Network error: $e', 'statusCode': 0};
    }
  }

  // Authentication APIs
  static Future<Map<String, dynamic>> login(
    String userId,
    String password,
  ) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate delay

    if (userId.isNotEmpty && password.isNotEmpty) {
      return {
        'success': true,
        'data': {
          'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'id': userId,
            'name': 'User Name',
            'email': '$userId@example.com',
          },
        },
      };
    }

    return {'success': false, 'error': 'Invalid credentials'};
  }

  static Future<Map<String, dynamic>> loginWithOtp(
    String mobile,
    String otp,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    if (mobile.isNotEmpty && otp.isNotEmpty) {
      return {
        'success': true,
        'data': {
          'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {'id': mobile, 'name': 'Mobile User', 'phone': mobile},
        },
      };
    }

    return {'success': false, 'error': 'Invalid OTP'};
  }

  static Future<Map<String, dynamic>> sendOtp(String mobile) async {
    await Future.delayed(const Duration(seconds: 1));

    if (mobile.isNotEmpty) {
      return {
        'success': true,
        'data': {
          'message': 'OTP sent successfully',
          'otpId': 'otp_${DateTime.now().millisecondsSinceEpoch}',
        },
      };
    }

    return {'success': false, 'error': 'Invalid mobile number'};
  }

  static Future<Map<String, dynamic>> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'success': true,
      'data': {'message': 'Logged out successfully'},
    };
  }

  // File Upload APIs
  static Future<Map<String, dynamic>> uploadFile(
    String filePath, {
    String? originalName,
  }) async {
    return await _uploadWithFallback(filePath, originalName: originalName);
  }

  static Future<Map<String, dynamic>> _uploadWithFallback(
    String filePath, {
    String? originalName,
  }) async {
    var result = await _uploadToUrl(
      baseUrl,
      filePath,
      originalName: originalName,
    );
    if (result['success'] == true) return result;

    for (final url in fallbackUrls) {
      result = await _uploadToUrl(url, filePath, originalName: originalName);
      if (result['success'] == true) return result;
    }

    return result;
  }

  static Future<Map<String, dynamic>> _uploadToUrl(
    String baseUrl,
    String filePath, {
    String? originalName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/upload');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';

      if (kIsWeb) {
        if (filePath.startsWith('data:')) {
          final parts = filePath.split(',');
          if (parts.length != 2) {
            throw Exception('Invalid data URL format');
          }
          final header = parts[0];
          final mimeType = header.split(':')[1].split(';')[0];
          final bytes = base64Decode(parts[1]);

          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: originalName ?? 'upload.${_extFromMime(mimeType)}',
            ),
          );
        } else {
          throw Exception(
            'Unsupported web file path format (expected data: URL)',
          );
        }
      } else {
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('File does not exist: $filePath');
        }
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            filePath,
            filename: originalName ?? file.path.split('/').last,
          ),
        );
      }

      final timeout = _isInAppWebView
          ? const Duration(seconds: 20)
          : const Duration(seconds: 30);

      final streamed = await request.send().timeout(
        timeout,
        onTimeout: () {
          throw Exception('Upload timed out after ${timeout.inSeconds}s');
        },
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = _safeJson(response.body);
        return {'success': true, 'data': data};
      } else {
        final err = _safeJson(response.body);
        final msg = (err['error'] ?? 'Upload failed').toString();
        return {
          'success': false,
          'error': _isInAppWebView ? 'InAppWebView upload error: $msg' : msg,
        };
      }
    } catch (e) {
      String msg = 'Upload failed: $e';
      if (_isInAppWebView) {
        if (e.toString().contains('timed out')) {
          msg =
              'Upload timed out in InAppWebView. Please check your connection and try again.';
        } else if (e.toString().contains('SocketException') ||
            e.toString().contains('Connection')) {
          msg =
              'Network connection failed in InAppWebView. Ensure the server is reachable.';
        } else {
          msg = 'InAppWebView upload error: $e';
        }
      }
      return {'success': false, 'error': msg};
    }
  }

  // OCR Processing APIs
  static Future<Map<String, dynamic>> processUAEId(String imagePath) async {
    try {
      _logger.info('Processing UAE ID via API');

      // For now, return mock data - in real implementation, this would call OCR service
      await Future.delayed(const Duration(seconds: 2));

      return {
        'success': true,
        'data': {
          'name': 'Sample Name',
          'idNumber': '784-1234-1234567-1',
          'dateOfBirth': '01/01/1990',
          'nationality': 'UAE',
          'issuingDate': '01/01/2020',
          'expiryDate': '01/01/2030',
          'sex': 'M',
          'isValid': true,
        },
      };
    } catch (e) {
      _logger.error('UAE ID processing failed', e);
      return {'success': false, 'error': 'Failed to process UAE ID: $e'};
    }
  }

  static Future<Map<String, dynamic>> processBankDetails(
    String imagePath,
  ) async {
    try {
      _logger.info('Processing bank details via API');

      // For now, return mock data - in real implementation, this would call OCR service
      await Future.delayed(const Duration(seconds: 2));

      return {
        'success': true,
        'data': {
          'accountHolderName': 'Sample Account Holder',
          'accountNumber': '1234567890',
          'ibanNumber': 'AE12345678901234567890123',
          'bankName': 'Emirates NBD',
          'branchName': 'Dubai Main Branch',
          'swiftCode': 'EBILAEAD',
          'isValid': true,
        },
      };
    } catch (e) {
      _logger.error('Bank details processing failed', e);
      return {'success': false, 'error': 'Failed to process bank details: $e'};
    }
  }

  // QR Code APIs
  static Future<Map<String, dynamic>> processQRCode(String qrData) async {
    try {
      _logger.info('Processing QR code via API');

      await Future.delayed(const Duration(milliseconds: 500));

      return {
        'success': true,
        'data': {
          'qrData': qrData,
          'productInfo': {
            'name': 'Sample Product',
            'code': qrData,
            'points': 50,
            'category': 'Construction Material',
          },
          'points': 50,
        },
      };
    } catch (e) {
      _logger.error('QR code processing failed', e);
      return {'success': false, 'error': 'Failed to process QR code: $e'};
    }
  }

  // Analytics APIs
  static Future<Map<String, dynamic>> getBusinessMetrics() async {
    try {
      _logger.info('Fetching business metrics via API');

      await Future.delayed(const Duration(milliseconds: 500));

      return {
        'success': true,
        'data': {
          'totalScans': 1234,
          'redeemedPoints': 856,
          'activeCampaigns': 5,
          'monthlyTargetProgress': 78.0,
          'totalPoints': 2450,
          'monthlyScans': 124,
          'rewardsEarned': 18,
        },
      };
    } catch (e) {
      _logger.error('Failed to fetch business metrics', e);
      return {
        'success': false,
        'error': 'Failed to fetch business metrics: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getRecentActivities({
    int limit = 10,
  }) async {
    try {
      _logger.info('Fetching recent activities via API');

      await Future.delayed(const Duration(milliseconds: 300));

      return {
        'success': true,
        'data': {
          'activities': [
            {
              'id': '1',
              'title': 'QR Code Scanned',
              'subtitle': 'Birla White Primacoat Primer - +70 points',
              'timestamp': DateTime.now()
                  .subtract(const Duration(hours: 2))
                  .toIso8601String(),
              'iconName': 'qr_code_scanner',
              'colorName': 'successGreen',
              'points': 70,
            },
            {
              'id': '2',
              'title': 'Reward Redeemed',
              'subtitle': 'Amazon Gift Card - 500 points',
              'timestamp': DateTime.now()
                  .subtract(const Duration(days: 1))
                  .toIso8601String(),
              'iconName': 'card_giftcard',
              'colorName': 'warningAmber',
              'points': -500,
            },
            {
              'id': '3',
              'title': 'Level Up',
              'subtitle': 'Reached Gold Member Status',
              'timestamp': DateTime.now()
                  .subtract(const Duration(days: 3))
                  .toIso8601String(),
              'iconName': 'emoji_events',
              'colorName': 'accentBlue',
              'points': 100,
            },
          ],
        },
      };
    } catch (e) {
      _logger.error('Failed to fetch recent activities', e);
      return {
        'success': false,
        'error': 'Failed to fetch recent activities: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> trackQRScan(
    String qrCode, {
    int pointsEarned = 0,
  }) async {
    try {
      _logger.info('Tracking QR scan via API');

      final body = {
        'qrCode': qrCode,
        'pointsEarned': pointsEarned,
        'timestamp': DateTime.now().toIso8601String(),
      };

      return await _makeRequest(
        method: 'POST',
        endpoint: '/analytics/track/qr-scan',
        body: body,
      );
    } catch (e) {
      _logger.error('Failed to track QR scan', e);
      return {'success': false, 'error': 'Failed to track QR scan: $e'};
    }
  }

  static Future<Map<String, dynamic>> trackRewardRedemption(
    String rewardName,
    int pointsSpent,
  ) async {
    try {
      _logger.info('Tracking reward redemption via API');

      final body = {
        'rewardName': rewardName,
        'pointsSpent': pointsSpent,
        'timestamp': DateTime.now().toIso8601String(),
      };

      return await _makeRequest(
        method: 'POST',
        endpoint: '/analytics/track/reward-redemption',
        body: body,
      );
    } catch (e) {
      _logger.error('Failed to track reward redemption', e);
      return {
        'success': false,
        'error': 'Failed to track reward redemption: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> trackUserInteraction(
    String action, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.info('Tracking user interaction via API');

      final body = {
        'action': action,
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
      };

      return await _makeRequest(
        method: 'POST',
        endpoint: '/analytics/track/user-interaction',
        body: body,
      );
    } catch (e) {
      _logger.error('Failed to track user interaction', e);
      return {
        'success': false,
        'error': 'Failed to track user interaction: $e',
      };
    }
  }

  // Product APIs
  static Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> productData,
  ) async {
    try {
      _logger.info('Creating product via API');

      return await _makeRequest(
        method: 'POST',
        endpoint: '/products',
        body: productData,
      );
    } catch (e) {
      _logger.error('Failed to create product', e);
      return {'success': false, 'error': 'Failed to create product: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    try {
      _logger.info('Updating product via API');

      return await _makeRequest(
        method: 'PUT',
        endpoint: '/products/$productId',
        body: productData,
      );
    } catch (e) {
      _logger.error('Failed to update product', e);
      return {'success': false, 'error': 'Failed to update product: $e'};
    }
  }

  static Future<Map<String, dynamic>> getProducts({
    int? limit,
    int? offset,
  }) async {
    try {
      _logger.info('Fetching products via API');

      var endpoint = '/products';
      if (limit != null || offset != null) {
        endpoint += '?';
        if (limit != null) endpoint += 'limit=$limit&';
        if (offset != null) endpoint += 'offset=$offset&';
        endpoint = endpoint.substring(0, endpoint.length - 1);
      }

      return await _makeRequest(method: 'GET', endpoint: endpoint);
    } catch (e) {
      _logger.error('Failed to fetch products', e);
      return {'success': false, 'error': 'Failed to fetch products: $e'};
    }
  }

  // Registration APIs
  static Future<Map<String, dynamic>> registerUser(
    Map<String, dynamic> userData,
  ) async {
    try {
      _logger.info('Registering user via API');

      return await _makeRequest(
        method: 'POST',
        endpoint: '/auth/register',
        body: userData,
      );
    } catch (e) {
      _logger.error('Failed to register user', e);
      return {'success': false, 'error': 'Failed to register user: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      _logger.info('Updating user profile via API');

      return await _makeRequest(
        method: 'PUT',
        endpoint: '/users/$userId/profile',
        body: profileData,
      );
    } catch (e) {
      _logger.error('Failed to update user profile', e);
      return {'success': false, 'error': 'Failed to update user profile: $e'};
    }
  }

  // Quality Control APIs
  static Future<Map<String, dynamic>> submitQualityReport(
    Map<String, dynamic> reportData,
  ) async {
    try {
      _logger.info('Submitting quality report via API');

      return await _makeRequest(
        method: 'POST',
        endpoint: '/quality-control/reports',
        body: reportData,
      );
    } catch (e) {
      _logger.error('Failed to submit quality report', e);
      return {'success': false, 'error': 'Failed to submit quality report: $e'};
    }
  }

  static Future<Map<String, dynamic>> getQualityReports({
    String? status,
    int? limit,
  }) async {
    try {
      _logger.info('Fetching quality reports via API');

      var endpoint = '/quality-control/reports';
      if (status != null || limit != null) {
        endpoint += '?';
        if (status != null) endpoint += 'status=$status&';
        if (limit != null) endpoint += 'limit=$limit&';
        endpoint = endpoint.substring(0, endpoint.length - 1);
      }

      return await _makeRequest(method: 'GET', endpoint: endpoint);
    } catch (e) {
      _logger.error('Failed to fetch quality reports', e);
      return {'success': false, 'error': 'Failed to fetch quality reports: $e'};
    }
  }

  // Retail APIs
  static Future<Map<String, dynamic>> registerRetailer(
    Map<String, dynamic> retailerData,
  ) async {
    try {
      _logger.info('Registering retailer via API');

      return await _makeRequest(
        method: 'POST',
        endpoint: '/retail/register',
        body: retailerData,
      );
    } catch (e) {
      _logger.error('Failed to register retailer', e);
      return {'success': false, 'error': 'Failed to register retailer: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitRetailEntry(
    Map<String, dynamic> entryData,
  ) async {
    try {
      _logger.info('Submitting retail entry via API');

      return await _makeRequest(
        method: 'POST',
        endpoint: '/retail/entries',
        body: entryData,
      );
    } catch (e) {
      _logger.error('Failed to submit retail entry', e);
      return {'success': false, 'error': 'Failed to submit retail entry: $e'};
    }
  }

  // Contractor Registration APIs
  static Future<Map<String, dynamic>> registerContractor(
    Map<String, dynamic> contractorData,
  ) async {
    try {
      _logger.info('Registering contractor via API');

      return await _makeRequest(
        method: 'POST',
        endpoint: '/api/Contractor/register',
        body: contractorData,
      );
    } catch (e) {
      _logger.error('Failed to register contractor', e);
      return {'success': false, 'error': 'Failed to register contractor: $e'};
    }
  }

  static Future<Map<String, dynamic>> uploadContractorDocument({
    required String filePath,
    required String documentType,
    String? originalName,
  }) async {
    try {
      _logger.info('Uploading contractor document via API');

      final uri = Uri.parse('$baseUrl/api/Contractor/upload-document');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';
      request.fields['documentType'] = documentType;

      if (kIsWeb) {
        if (filePath.startsWith('data:')) {
          final parts = filePath.split(',');
          if (parts.length != 2) {
            throw Exception('Invalid data URL format');
          }
          final header = parts[0];
          final mimeType = header.split(':')[1].split(';')[0];
          final bytes = base64Decode(parts[1]);

          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: originalName ?? 'document.${_extFromMime(mimeType)}',
            ),
          );
        } else {
          throw Exception(
            'Unsupported web file path format (expected data: URL)',
          );
        }
      } else {
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('File does not exist: $filePath');
        }
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            filePath,
            filename: originalName ?? file.path.split('/').last,
          ),
        );
      }

      final timeout = _isInAppWebView
          ? const Duration(seconds: 20)
          : const Duration(seconds: 30);

      final streamed = await request.send().timeout(
        timeout,
        onTimeout: () {
          throw Exception('Upload timed out after ${timeout.inSeconds}s');
        },
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = _safeJson(response.body);
        return {'success': true, 'data': data};
      } else {
        final err = _safeJson(response.body);
        final msg = (err['error'] ?? 'Upload failed').toString();
        return {
          'success': false,
          'error': _isInAppWebView ? 'InAppWebView upload error: $msg' : msg,
        };
      }
    } catch (e) {
      _logger.error('Failed to upload contractor document', e);
      String msg = 'Upload failed: $e';
      if (_isInAppWebView) {
        if (e.toString().contains('timed out')) {
          msg =
              'Upload timed out in InAppWebView. Please check your connection and try again.';
        } else if (e.toString().contains('SocketException') ||
            e.toString().contains('Connection')) {
          msg =
              'Network connection failed in InAppWebView. Ensure the server is reachable.';
        } else {
          msg = 'InAppWebView upload error: $e';
        }
      }
      return {'success': false, 'error': msg};
    }
  }

  static Future<Map<String, dynamic>> getContractorTypes() async {
    try {
      _logger.info('Fetching contractor types via API');

      return await _makeRequest(
        method: 'GET',
        endpoint: '/api/Contractor/contractor-types',
      );
    } catch (e) {
      _logger.error('Failed to fetch contractor types', e);
      return {
        'success': false,
        'error': 'Failed to fetch contractor types: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getEmiratesList() async {
    try {
      _logger.info('Fetching emirates list via API');

      return await _makeRequest(
        method: 'GET',
        endpoint: '/api/Contractor/emirates-list',
      );
    } catch (e) {
      _logger.error('Failed to fetch emirates list', e);
      return {'success': false, 'error': 'Failed to fetch emirates list: $e'};
    }
  }

  // Health Check
  static Future<Map<String, dynamic>> testConnectivity() async {
    try {
      final resp = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout'),
          );

      return {
        'success': resp.statusCode == 200,
        'statusCode': resp.statusCode,
        'data': _safeJson(resp.body),
      };
    } catch (e) {
      _logger.error('Connectivity test failed', e);
      return {'success': false, 'error': 'Connectivity test failed: $e'};
    }
  }

  // Utility methods
  static String _extFromMime(String mime) {
    switch (mime) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/gif':
        return 'gif';
      case 'image/webp':
        return 'webp';
      case 'application/pdf':
        return 'pdf';
      case 'text/plain':
        return 'txt';
      default:
        return 'bin';
    }
  }

  static Map<String, dynamic> _safeJson(String body) {
    try {
      final parsed = json.decode(body);
      return parsed is Map<String, dynamic>
          ? parsed
          : <String, dynamic>{'raw': parsed};
    } catch (_) {
      return <String, dynamic>{'raw': body};
    }
  }
}
