import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UploadService {
  static const String baseUrl = kIsWeb
      ? '/api' // Use relative path for web
      : 'https://10.235.234.182:8520/api'; // Use full URL for mobile

  static Future<Map<String, dynamic>> uploadFile(
    String filePath, {
    String? originalName,
  }) async {
    try {
      print('Starting upload for file: $filePath');

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

      if (kIsWeb) {
        // Handle web uploads (data URLs or blob URLs)
        if (filePath.startsWith('data:')) {
          // Handle data URL (base64 encoded)
          final parts = filePath.split(',');
          if (parts.length == 2) {
            final bytes = base64Decode(parts[1]);
            final mimeType = parts[0].split(':')[1].split(';')[0];

            request.files.add(
              http.MultipartFile.fromBytes(
                'file',
                bytes,
                filename:
                    originalName ??
                    'upload.${_getExtensionFromMimeType(mimeType)}',
              ),
            );
          }
        } else {
          // Handle blob URL or other web paths
          throw Exception('Unsupported web file path format');
        }
      } else {
        // Handle mobile file uploads
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

      print('Sending upload request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Upload failed',
        };
      }
    } catch (e) {
      print('Upload error: $e');
      return {'success': false, 'error': 'Upload failed: $e'};
    }
  }

  static String _getExtensionFromMimeType(String mimeType) {
    switch (mimeType) {
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
}
