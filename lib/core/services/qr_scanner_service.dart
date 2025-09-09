import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../utils/app_logger.dart';

/// Custom exceptions for QR scanner operations
class QRScannerException implements Exception {
  final String message;
  final String? code;

  QRScannerException(this.message, {this.code});

  @override
  String toString() =>
      'QRScannerException: $message${code != null ? ' (Code: $code)' : ''}';
}

class CameraPermissionDeniedException extends QRScannerException {
  CameraPermissionDeniedException(String message)
    : super(message, code: 'PERMISSION_DENIED');
}

class CameraNotFoundException extends QRScannerException {
  CameraNotFoundException(String message)
    : super(message, code: 'CAMERA_NOT_FOUND');
}

class CameraInUseException extends QRScannerException {
  CameraInUseException(String message) : super(message, code: 'CAMERA_IN_USE');
}

class SecureContextRequiredException extends QRScannerException {
  SecureContextRequiredException(String message)
    : super(message, code: 'SECURE_CONTEXT_REQUIRED');
}

/// Service for handling QR code scanning operations
class QRScannerService {
  web.HTMLVideoElement? _videoElement;
  web.HTMLCanvasElement? _canvasElement;
  Timer? _scanTimer;
  bool _isProcessingQR = false;
  bool _isScanning = false;

  final AppLogger _logger = AppLogger();

  /// Check if camera is currently scanning
  bool get isScanning => _isScanning;

  /// Start camera scanning for QR codes
  Future<void> startScanning() async {
    try {
      _logger.info('Starting QR scanner service');

      setState(() {
        _isProcessingQR = false;
      });

      // Enhanced InAppWebView detection and debugging
      final userAgent = web.window.navigator.userAgent.toLowerCase();
      final isInAppWebView =
          userAgent.contains('inappwebview') ||
          userAgent.contains('webview') ||
          (web.window.name?.contains('webview') ?? false);

      _logger.debug('WebView detection', {
        'userAgent': userAgent,
        'isInAppWebView': isInAppWebView,
        'isSecureContext': web.window.isSecureContext,
        'mediaDevicesAvailable': web.window.navigator.mediaDevices != null,
        'location': web.window.location.href,
        'protocol': web.window.location.protocol,
      });

      // Check for secure context (required for camera access)
      if (web.window.isSecureContext != true) {
        throw SecureContextRequiredException(
          'Camera access requires a secure context (HTTPS).',
        );
      }

      // For WebView, try to bypass some restrictions
      if (web.window.navigator.mediaDevices == null) {
        throw QRScannerException(
          'Camera access is not available in this WebView environment.',
        );
      }

      // Get environment info
      final envInfo = await _callJavaScriptMethod('getEnvironmentInfo');
      _logger.debug('Environment info', envInfo);

      // Get available devices
      final deviceInfo = await _callJavaScriptMethod('getAvailableDevices');
      _logger.debug('Device info', deviceInfo);

      // For InAppWebView, try JavaScript helper first
      if (isInAppWebView) {
        try {
          // Call the JavaScript helper with a timeout
          final jsResult = await _callJavaScriptMethod(
            'requestCameraPermission',
          );
          _logger.debug('JavaScript helper result', jsResult);

          // If JS helper indicates permission denied, throw exception
          if (jsResult != null &&
              jsResult.toString().contains('permission-denied')) {
            throw CameraPermissionDeniedException(
              'Camera permission denied by user.',
            );
          }
        } catch (e) {
          _logger.warning(
            'JavaScript helper failed, continuing with fallback',
            e,
          );
        }
      }

      // Try multiple camera access approaches with InAppWebView specific constraints
      web.MediaStream? stream;

      // Multiple fallback strategies for camera access
      final strategies = <Map<String, dynamic>>[
        // Strategy 1: InAppWebView optimized
        if (isInAppWebView)
          {
            'video': {
              'facingMode': 'environment',
              'width': {'ideal': 640, 'max': 1280},
              'height': {'ideal': 480, 'max': 720},
              'frameRate': {'ideal': 15, 'max': 30},
            },
            'audio': false,
          },
        // Strategy 2: Simple environment camera
        {
          'video': {'facingMode': 'environment'},
          'audio': false,
        },
        // Strategy 3: Any video device
        {'video': true},
        // Strategy 4: Minimal constraints
        {
          'video': {'width': 320, 'height': 240},
        },
      ];

      Exception? lastError;
      for (int i = 0; i < strategies.length; i++) {
        try {
          _logger.debug('Trying camera strategy ${i + 1}/${strategies.length}');
          final result = web.window.navigator.mediaDevices!.getUserMedia(
            strategies[i].jsify()! as web.MediaStreamConstraints,
          );
          stream = await result.toDart;
          _logger.info('Camera strategy ${i + 1} successful');
          break;
        } catch (e) {
          _logger.warning('Camera strategy ${i + 1} failed', e);
          lastError = e as Exception;
          if (i == strategies.length - 1) {
            throw lastError;
          }
        }
      }

      if (stream == null) {
        throw lastError ?? QRScannerException('Failed to obtain camera stream');
      }

      _videoElement = web.HTMLVideoElement()
        ..srcObject = stream
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true') // Important for mobile WebViews
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      web.document.body!.append(_videoElement!);
      _videoElement!.style.display = 'none';

      setState(() {
        _isScanning = true;
      });

      _startQRDetection();

      _logger.info(
        'Camera started successfully in ${isInAppWebView ? 'InAppWebView' : 'browser'} mode',
      );
    } catch (e) {
      _logger.error('Camera error', e);
      _handleCameraError(e);
      rethrow;
    }
  }

  /// Stop camera scanning
  void stopScanning() {
    _scanTimer?.cancel();
    _scanTimer = null;

    if (_videoElement?.srcObject != null) {
      final stream = _videoElement!.srcObject as web.MediaStream;
      for (int i = 0; i < stream.getTracks().length; i++) {
        stream.getTracks()[i].stop();
      }
    }

    _videoElement = null;

    setState(() {
      _isScanning = false;
      _isProcessingQR = false;
    });

    _logger.info('Camera scanning stopped');
  }

  /// Start QR detection on video frames
  void _startQRDetection() {
    _scanTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isProcessingQR && _videoElement != null) {
        _processVideoFrame();
      }
    });
  }

  /// Process video frame for QR detection
  void _processVideoFrame() async {
    if (_videoElement == null || _isProcessingQR) return;

    try {
      _canvasElement ??= web.HTMLCanvasElement();
      _canvasElement!.width = 640;
      _canvasElement!.height = 480;
      final context = _canvasElement!.context2D;
      context.drawImage(_videoElement!, 0, 0, 640, 480);
      final imageData = context.getImageData(0, 0, 640, 480);

      // Simulate QR detection - in a real app, you'd use a QR detection library
      await _simulateQRDetection(imageData);
    } catch (e) {
      // Ignore processing errors
      _logger.debug('Video frame processing error', e);
    }
  }

  /// Simulate QR detection (placeholder for real QR detection library)
  Future<void> _simulateQRDetection(web.ImageData imageData) async {
    // QR detection would go here with a proper QR detection library
    // For now, this is a placeholder for real QR code detection
    if (isScanning && !_isProcessingQR) {
      await Future.delayed(const Duration(milliseconds: 100));
      // Real QR detection implementation would go here
    }
  }

  /// Handle camera errors and throw appropriate exceptions
  void _handleCameraError(dynamic e) {
    final errorStr = e.toString().toLowerCase();
    _logger.error('Handling camera error', errorStr);

    if (errorStr.contains('notallowederror') ||
        errorStr.contains('permission')) {
      throw CameraPermissionDeniedException('Camera permission denied');
    } else if (errorStr.contains('notfounderror')) {
      throw CameraNotFoundException('No camera found on this device');
    } else if (errorStr.contains('notreadableerror')) {
      throw CameraInUseException('Camera is already in use');
    } else if (errorStr.contains('notsupported') ||
        errorStr.contains('not supported')) {
      throw QRScannerException('Camera not supported in this environment');
    } else {
      throw QRScannerException('Unknown camera error: $errorStr');
    }
  }

  /// Call JavaScript helper methods for camera access
  Future<dynamic> _callJavaScriptMethod(String method) async {
    try {
      // Use dart:js for proper JavaScript interop
      final cameraHelper = web.window['cameraHelper'];
      if (cameraHelper == null) {
        _logger.warning('CameraHelper JavaScript object not found');
        return null;
      }

      if (method.contains('requestCameraPermission')) {
        // For permission requests, we just call the method and return immediately
        try {
          final result = (cameraHelper as dynamic).callMethod(
            'requestCameraPermission',
            [],
          );
          return result;
        } catch (e) {
          return {
            'success': false,
            'error': 'js-call-failed',
            'details': e.toString(),
          };
        }
      } else if (method.contains('getEnvironmentInfo')) {
        return (cameraHelper as dynamic).callMethod('getEnvironmentInfo', []);
      } else if (method.contains('getAvailableDevices')) {
        final result = (cameraHelper as dynamic).callMethod(
          'getAvailableDevices',
          [],
        );
        return result;
      }
      return null;
    } catch (e) {
      _logger.error('JavaScript method call failed', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Dispose of resources
  void dispose() {
    stopScanning();
    _videoElement?.remove();
    _logger.info('QRScannerService disposed');
  }

  /// Set state callback for UI updates
  late void Function(VoidCallback) setState;

  /// Initialize with setState callback
  void initialize(void Function(VoidCallback) setStateCallback) {
    setState = setStateCallback;
  }
}
