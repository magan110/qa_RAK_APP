// upload_service.dart
import 'dart:convert';
import 'dart:io' show File; // used only on mobile paths
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// Web-only
import 'package:web/web.dart' as web;

class UploadService {
  // Detect webview-ish contexts (wider net than widget side)
  static bool get _isInAppWebView {
    if (kIsWeb) {
      try {
        final ua = web.window.navigator.userAgent.toLowerCase();
        final vendor = web.window.navigator.vendor.toLowerCase();
        final loc = web.window.location;

        final isInAppWebView =
            ua.contains('inapp') ||
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

        return isInAppWebView;
      } catch (_) {
        return true;
      }
    }
    return false;
  }

  static List<String> get _fallbackUrls => <String>[
    'https://10.166.220.182:8521/api', // Direct IP (HTTPS)
    'http://10.166.220.182:8520/api', // HTTP variant
    'http://localhost:8520/api',
    'http://localhost:8080/api',
  ];

  static String get baseUrl {
    if (kIsWeb) {
      if (_isInAppWebView) {
        try {
          final host = web.window.location.hostname;
          final port = web.window.location.port;
          final protocol = web
              .window
              .location
              .protocol; // keep same scheme to avoid mixed content
          if (host.isNotEmpty && host != 'localhost') {
            final portPart = (port.isNotEmpty && port != '80' && port != '443')
                ? ':$port'
                : '';
            return '$protocol//$host$portPart/api';
          }
        } catch (_) {}
        // Fallback for in-app
        return 'https://10.166.220.182:8521/api';
      } else {
        // Browser dev default; change to your served origin if needed
        return 'http://localhost:8080/api';
      }
    } else {
      // Mobile builds – hit your server
      return 'https://10.166.220.182:8520/api';
    }
  }

  /// Upload file to server only - no local storage fallback
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
    // Try primary URL first
    var result = await _uploadToUrl(
      baseUrl,
      filePath,
      originalName: originalName,
    );
    if (result['success'] == true) return result;

    // Try fallbacks
    for (final url in _fallbackUrls) {
      result = await _uploadToUrl(url, filePath, originalName: originalName);
      if (result['success'] == true) return result;
    }

    // Give up; caller may choose local fallback
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

      // Helpful (but CORS must be on server)
      request.headers['Accept'] = 'application/json';

      if (kIsWeb) {
        if (filePath.startsWith('data:')) {
          final parts = filePath.split(',');
          if (parts.length != 2) {
            throw Exception('Invalid data URL format');
          }
          final header = parts[0]; // data:<mime>;base64
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
          // If you support blob: or object URLs, you’d need to fetch them first in JS and pass data:
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

      // Reasonable timeouts
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

  static Future<bool> testConnectivity() async {
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
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // -------- helpers --------

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
