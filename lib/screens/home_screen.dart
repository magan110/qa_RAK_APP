import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _mainController;
  late AnimationController _fabController;
  late AnimationController _navController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _navScaleAnimation;
  late Animation<double> _cardAnimation;
  bool isScanning = false;
  html.VideoElement? _videoElement;
  html.CanvasElement? _canvasElement;
  Timer? _scanTimer;
  bool _isProcessingQR = false;

  // Premium Business Color Palette
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkGray = Color(0xFF1F2937);
  static const Color mediumGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);

  // Image URLs
  final String logoUrl =
      'https://z-cdn-media.chatglm.cn/files/5415bb20-7f05-42cc-8dda-00ffeb0ae83b_logo3.png?auth_key=1788345874-e1b726547df64b29ac8bfe80df5589e1-0-cf9f2171c68dff55cba2de104da05218';
  final String buildingImageUrl =
      'https://z-cdn-media.chatglm.cn/files/d1b234c5-0eed-48ab-95e6-6749d83c5b38_RWC-Product-Usage6.jpeg?auth_key=1788345874-34325868650e4db982da81858eb73b3-0-f40ed5550ea3eb0639b02a321dd1f4ac';
  final String promotionalBannerUrl =
      'https://z-cdn-media.chatglm.cn/files/8a27d90f-fb96-42a9-855e-092491f0a1b6_WhatsApp%20Image%202025-09-02%20at%2015.57.46_2b714552.jpg?auth_key=1788345873-0acfc7ff363b438eb8867891626439ce-0-415e90947b55273e7e5e4460e05ab8fd';

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _navController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _navScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _navController, curve: Curves.elasticOut),
    );
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );
    _mainController.forward();
    _fabController.forward();
    _navController.forward();
    _cardController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _fabController.dispose();
    _navController.dispose();
    _cardController.dispose();
    _stopCamera();
    _videoElement?.remove();
    super.dispose();
  }

  // Camera and QR Scanning Methods
  void _startCamera() async {
    try {
      setState(() {
        _isProcessingQR = false;
      });
      // Enhanced InAppWebView detection and debugging
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      final isInAppWebView =
          userAgent.contains('inappwebview') ||
          userAgent.contains('webview') ||
          (html.window.name?.contains('webview') ?? false);
      print('WebView Debug: User Agent = $userAgent');
      print('WebView Debug: Is InAppWebView = $isInAppWebView');
      print('WebView Debug: isSecureContext = ${html.window.isSecureContext}');
      print(
        'WebView Debug: mediaDevices available = ${html.window.navigator.mediaDevices != null}',
      );
      print('WebView Debug: location = ${html.window.location.href}');
      print('WebView Debug: protocol = ${html.window.location.protocol}');
      // Check for secure context (required for camera access)
      if (html.window.isSecureContext != true) {
        _showSecureContextError();
        return;
      }
      // For WebView, try to bypass some restrictions
      if (html.window.navigator.mediaDevices == null) {
        _showWebViewError();
        return;
      }
      // Use JavaScript helper for comprehensive camera access attempt
      try {
        // Get environment info
        final envInfo = _callJavaScriptMethod('getEnvironmentInfo');
        print('WebView Debug: Environment info = $envInfo');
        // Get available devices
        final deviceInfo = _callJavaScriptMethod('getAvailableDevices');
        print('WebView Debug: Device info = $deviceInfo');
        // For InAppWebView, try JavaScript helper first
        if (isInAppWebView) {
          try {
            // Call the JavaScript helper with a timeout
            final jsResult = _callJavaScriptMethod('requestCameraPermission');
            print('WebView Debug: JavaScript helper result = $jsResult');
            // If JS helper indicates permission denied, show error
            if (jsResult != null &&
                jsResult.toString().contains('permission-denied')) {
              _showPermissionDeniedError();
              return;
            }
          } catch (e) {
            print(
              'WebView Debug: JavaScript helper failed, continuing with fallback: $e',
            );
          }
        }
      } catch (e) {
        print('WebView Debug: JavaScript helper failed: $e');
        // Fallback to original permission checking
        if (isInAppWebView) {
          try {
            final permission = await html.window.navigator.permissions!.query({
              'name': 'camera',
            });
            print(
              'WebView Debug: Camera permission state = ${permission.state}',
            );
            if (permission.state == 'denied') {
              return;
            }
          } catch (e) {
            print('WebView Debug: Permission query failed: $e');
          }
        }
      }
      // Try multiple camera access approaches with InAppWebView specific constraints
      html.MediaStream? stream;
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
          print(
            'WebView Debug: Trying camera strategy ${i + 1}/${strategies.length}',
          );
          stream = await html.window.navigator.mediaDevices!.getUserMedia(
            strategies[i],
          );
          print('WebView Debug: Camera strategy ${i + 1} successful');
          break;
        } catch (e) {
          print('WebView Debug: Camera strategy ${i + 1} failed: $e');
          lastError = e as Exception;
          if (i == strategies.length - 1) {
            throw lastError;
          }
        }
      }
      if (stream == null) {
        throw lastError ?? Exception('Failed to obtain camera stream');
      }
      _videoElement = html.VideoElement()
        ..srcObject = stream
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true') // Important for mobile WebViews
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      html.document.body!.append(_videoElement!);
      _videoElement!.style.display = 'none';
      setState(() {
        isScanning = true;
      });
      _startQRDetection();
      print(
        'WebView Debug: Camera started successfully in ${isInAppWebView ? 'InAppWebView' : 'browser'} mode',
      );
    } catch (e) {
      print('WebView Debug: Camera error: $e');
      _handleCameraError(e);
    }
  }

  void _handleCameraError(dynamic e) {
    final errorStr = e.toString().toLowerCase();
    print('WebView Debug: Handling camera error: $errorStr');
    if (errorStr.contains('notallowederror') ||
        errorStr.contains('permission')) {
      _showPermissionDeniedError();
    } else if (errorStr.contains('notfounderror')) {
      _showError('No camera found on this device.');
    } else if (errorStr.contains('notreadableerror')) {
      _showError('Camera is already in use.');
    } else if (errorStr.contains('notsupported') ||
        errorStr.contains('not supported')) {
      _showWebViewError();
    } else {
      // Show generic WebView error with debug info
      _showWebViewErrorWithDebug(e.toString());
    }
  }

  void _showWebViewErrorWithDebug(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: warningAmber),
            const SizedBox(width: 8),
            const Text('Camera Access Issue'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Camera access failed in WebView environment.'),
            const SizedBox(height: 12),
            const Text('This may be due to:'),
            const Text('• WebView security restrictions'),
            const Text('• App-level camera permissions'),
            const Text('• Device camera policies'),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('Debug Info', style: TextStyle(fontSize: 14)),
              children: [
                Text(
                  'Error: $error',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualQRInput();
            },
            child: const Text('Enter Code'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSecureContextError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.security, color: dangerRed),
            const SizedBox(width: 8),
            const Text('Security Context Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Camera access requires a secure context (HTTPS).'),
            const SizedBox(height: 12),
            const Text('Please ensure:'),
            const Text('• The app is served over HTTPS'),
            const Text('• localhost connections use proper certificates'),
            const Text('• InAppWebView has proper security settings'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualQRInput();
            },
            child: const Text('Enter Code'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWebViewError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: warningAmber),
            const SizedBox(width: 8),
            const Text('WebView Limitation'),
          ],
        ),
        content: const Text(
          'Camera access is not available in this WebView environment. Please open this page in a regular browser to use the QR scanner.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualQRInput();
            },
            child: const Text('Enter Code'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showManualQRInput() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter QR Code'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter QR code or text',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                _handleQRCode(controller.text);
              }
            },
            child: const Text('Process'),
          ),
        ],
      ),
    );
  }

  void _startQRDetection() {
    _scanTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isProcessingQR && _videoElement != null) {
        _processVideoFrame();
      }
    });
  }

  void _processVideoFrame() async {
    if (_videoElement == null || _isProcessingQR) return;
    try {
      _canvasElement ??= html.CanvasElement(width: 640, height: 480);
      final context = _canvasElement!.context2D;
      context.drawImageScaled(_videoElement!, 0, 0, 640, 480);
      final imageData = context.getImageData(0, 0, 640, 480);
      // Simulate QR detection - in a real app, you'd use a QR detection library
      await _simulateQRDetection(imageData);
    } catch (e) {
      // Ignore processing errors
    }
  }

  Future<void> _simulateQRDetection(html.ImageData imageData) async {
    // QR detection would go here with a proper QR detection library
    // For now, this is a placeholder for real QR code detection
    if (isScanning && !_isProcessingQR) {
      await Future.delayed(const Duration(milliseconds: 100));
      // Real QR detection implementation would go here
    }
  }

  void _stopCamera() {
    _scanTimer?.cancel();
    _scanTimer = null;
    if (_videoElement?.srcObject != null) {
      final stream = _videoElement!.srcObject as html.MediaStream;
      stream.getTracks().forEach((track) => track.stop());
    }
    _videoElement = null;
    setState(() {
      isScanning = false;
      _isProcessingQR = false;
    });
  }

  // JavaScript method caller for camera helper
  Future<dynamic> _callJavaScriptMethod(String method) async {
    try {
      // Use dart:js for proper JavaScript interop
      final cameraHelper = js.context['cameraHelper'];
      if (cameraHelper == null) {
        print('CameraHelper JavaScript object not found');
        return null;
      }
      if (method.contains('requestCameraPermission')) {
        // For permission requests, we just call the method and return immediately
        // The method itself will handle the async permission checking
        try {
          final result = cameraHelper.callMethod('requestCameraPermission', []);
          return result;
        } catch (e) {
          return {
            'success': false,
            'error': 'js-call-failed',
            'details': e.toString(),
          };
        }
      } else if (method.contains('getEnvironmentInfo')) {
        return cameraHelper.callMethod('getEnvironmentInfo', []);
      } else if (method.contains('getAvailableDevices')) {
        final result = cameraHelper.callMethod('getAvailableDevices', []);
        return result;
      }
      return null;
    } catch (e) {
      print('JavaScript method call failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  void _showPermissionDeniedError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.camera_alt_outlined, color: dangerRed),
            const SizedBox(width: 8),
            const Text('Camera Permission Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Camera access is required to scan QR codes.'),
            const SizedBox(height: 12),
            const Text('To enable camera access:'),
            const Text('• Allow camera permission when prompted'),
            const Text('• Check app permissions in device settings'),
            const Text('• Ensure the app has camera access'),
            const Text('• Try reloading the page after granting permission'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualQRInput();
            },
            child: const Text('Enter Code'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startCamera(); // Try again
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: dangerRed,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _handleQRCode(String code) {
    HapticFeedback.heavyImpact();
    _stopCamera();
    showDialog(
      context: context,
      builder: (context) => _buildQRResultDialog(code),
    );
  }

  // New scanning methods
  void _startCameraScanning() {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/camera-scanner');
  }

  void _showManualEntry() {
    Navigator.pushNamed(context, '/qr-input');
  }

  void _uploadQRImage() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.upload_file, color: warningAmber),
            const SizedBox(width: 8),
            const Text('Upload QR Image'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload a QR code image from your device gallery to extract the data.',
            ),
            const SizedBox(height: 16),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: warningAmber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: warningAmber.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(Icons.image, size: 60, color: warningAmber),
            ),
            const SizedBox(height: 16),
            const Text(
              'This feature will be available soon!',
              style: TextStyle(fontStyle: FontStyle.italic, color: mediumGray),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: warningAmber),
            child: const Text('Coming Soon'),
          ),
        ],
      ),
    );
  }

  void _startBatchScanning() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.qr_code_2, color: accentBlue),
            const SizedBox(width: 8),
            const Text('Batch Scanner'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Scan multiple QR codes in sequence for bulk processing.',
            ),
            const SizedBox(height: 16),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentBlue.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: accentBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: accentBlue.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 30,
                    left: 30,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: accentBlue.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This feature will be available soon!',
              style: TextStyle(fontStyle: FontStyle.italic, color: mediumGray),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: accentBlue),
            child: const Text('Coming Soon'),
          ),
        ],
      ),
    );
  }

  void _viewAllScans() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Scan History'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('View all your previous QR code scans and their results.'),
            SizedBox(height: 16),
            Text(
              'No scan history available yet.',
              style: TextStyle(fontStyle: FontStyle.italic, color: mediumGray),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildQRResultDialog(String code) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBlue, secondaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'QR Code Scanned!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 0);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryBlue,
                    ),
                    child: const Text('Process'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    return Scaffold(
      backgroundColor: lightGray,
      body: Stack(
        children: [_buildMainContent(), _buildPremiumBottomNavigation()],
      ),
    );
  }

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            ),
          ),
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeTab(),
              _buildQRScannerTab(),
              _buildProfileTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPremiumHeader(),
            const SizedBox(height: 24),
            _buildBusinessMetrics(),
            const SizedBox(height: 24),
            _buildQuickActionsGrid(),
            const SizedBox(height: 24),
            _buildLoyaltyProgramCard(),
            const SizedBox(height: 24),
            _buildPromotionalBanner(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
            const SizedBox(height: 24),
            _buildBusinessInsights(),
            const SizedBox(height: 100), // Space for bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'PREMIUM PARTNER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome, Magan',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'RAK White Cement & Construction Materials',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildHeaderStat('Points', '2,450', successGreen),
                        const SizedBox(width: 24),
                        _buildHeaderStat('Rank', 'Gold', warningAmber),
                        const SizedBox(width: 24),
                        _buildHeaderStat('Level', '12', accentBlue),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.network(
                    logoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 50,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Business Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkGray,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 14, color: secondaryBlue),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildMetricCard(
              'Total Scans',
              '1,234',
              '+12.5%',
              successGreen,
              Icons.qr_code_scanner,
              () {},
            ),
            _buildMetricCard(
              'Redeemed Points',
              '856',
              '+8.2%',
              accentBlue,
              Icons.redeem,
              () {},
            ),
            _buildMetricCard(
              'Active Campaigns',
              '5',
              '+2',
              warningAmber,
              Icons.campaign,
              () {},
            ),
            _buildMetricCard(
              'Monthly Target',
              '78%',
              '+15%',
              primaryBlue,
              Icons.trending_up,
              () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String change,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _cardAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _cardAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          change,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: mediumGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkGray,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkGray,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
          children: [
            _buildQuickActionCard(
              'Scan QR',
              Icons.qr_code_scanner,
              secondaryBlue,
              () => _startCameraScanning(),
            ),
            _buildQuickActionCard(
              'Products',
              Icons.inventory_2,
              successGreen,
              () {},
            ),
            _buildQuickActionCard(
              'Rewards',
              Icons.card_giftcard,
              warningAmber,
              () {},
            ),
            _buildQuickActionCard(
              'Reports',
              Icons.bar_chart,
              accentBlue,
              () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: darkGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyProgramCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Loyalty Program',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Gold Member',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildLoyaltyStat(
                  'Total Points',
                  '2,450',
                  Icons.star,
                  warningAmber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLoyaltyStat(
                  'Monthly Scans',
                  '124/200',
                  Icons.qr_code_scanner,
                  successGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLoyaltyStat(
                  'Rewards Earned',
                  '18',
                  Icons.card_giftcard,
                  accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.62,
              child: Container(
                decoration: BoxDecoration(
                  color: successGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '62% to next level',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              Text(
                '1,550 points needed',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildPromotionalBanner() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              promotionalBannerUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [warningAmber, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: warningAmber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LIMITED TIME OFFER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Fragrance Putty Bumper Prizes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Win amazing prizes with every purchase',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: warningAmber,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Learn More',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkGray,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final activities = [
                {
                  'title': 'QR Code Scanned',
                  'subtitle': 'Birla White Primacoat Primer - +70 points',
                  'time': '2 hours ago',
                  'icon': Icons.qr_code_scanner,
                  'color': successGreen,
                  'points': '+70',
                },
                {
                  'title': 'Reward Redeemed',
                  'subtitle': 'Amazon Gift Card - 500 points',
                  'time': '1 day ago',
                  'icon': Icons.card_giftcard,
                  'color': warningAmber,
                  'points': '-500',
                },
                {
                  'title': 'Level Up',
                  'subtitle': 'Reached Gold Member Status',
                  'time': '3 days ago',
                  'icon': Icons.emoji_events,
                  'color': accentBlue,
                  'points': '+100',
                },
              ];
              final activity = activities[index];
              return _buildActivityItem(activity);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['subtitle'] as String,
                  style: TextStyle(fontSize: 14, color: mediumGray),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                activity['points'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: activity['color'] as Color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activity['time'] as String,
                style: TextStyle(fontSize: 12, color: mediumGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInsights() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkGray,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  'Top Product',
                  'White Cement',
                  '45% of total scans',
                  Icons.trending_up,
                  successGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInsightCard(
                  'Peak Hours',
                  '10 AM - 2 PM',
                  'Highest activity',
                  Icons.access_time,
                  accentBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: mediumGray)),
        ],
      ),
    );
  }

  // QR Scanner Tab
  Widget _buildQRScannerTab() {
    return Container(
      decoration: const BoxDecoration(color: lightGray),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildScannerHeader(),
              const SizedBox(height: 30),
              Expanded(child: _buildScannerOptions()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'QR Scanner',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Scan or enter QR codes for quick processing',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOptions() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.1,
      children: [
        _buildScannerCard(
          'Camera Scan',
          Icons.camera_alt,
          successGreen,
          'Use device camera to scan QR codes',
          () => _startCameraScanning(),
        ),
        _buildScannerCard(
          'Manual Entry',
          Icons.keyboard,
          secondaryBlue,
          'Type or paste QR code content',
          () => _showManualEntry(),
        ),
      ],
    );
  }

  Widget _buildScannerCard(
    String title,
    IconData icon,
    Color color,
    String description,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: mediumGray),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Profile Tab
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryBlue, secondaryBlue]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person, size: 60, color: primaryBlue),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Magan Patel',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gold Member • Partner ID: RAK2024',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                const Text(
                  'magan@rakwhitecement.ae',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildProfileSection('Account Settings', [
            _buildProfileOption(
              'Personal Information',
              Icons.person,
              secondaryBlue,
              () {},
            ),
            const SizedBox(height: 16),
            _buildProfileOption(
              'Security',
              Icons.security,
              successGreen,
              () {},
            ),
            const SizedBox(height: 16),
            _buildProfileOption(
              'Notifications',
              Icons.notifications,
              warningAmber,
              () {},
            ),
          ]),
          const SizedBox(height: 32),
          _buildProfileSection('Support', [
            _buildProfileOption('Help Center', Icons.help, accentBlue, () {}),
            const SizedBox(height: 16),
            _buildProfileOption(
              'Contact Us',
              Icons.contact_support,
              primaryBlue,
              () {},
            ),
            const SizedBox(height: 16),
            _buildProfileOption('About', Icons.info, mediumGray, () {}),
          ]),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkGray,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildProfileOption(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: darkGray,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: mediumGray),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBottomNavigation() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPremiumNavItem(0, Icons.home, 'Home', primaryBlue),
                _buildPremiumNavItem(
                  1,
                  Icons.qr_code_scanner,
                  'Scan',
                  secondaryBlue,
                ),
                _buildPremiumNavItem(2, Icons.person, 'Profile', mediumGray),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumNavItem(
    int index,
    IconData icon,
    String label,
    Color color,
  ) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          setState(() => _currentIndex = index);
          _navController.reset();
          _navController.forward();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isSelected ? 56 : 40,
                height: isSelected ? 56 : 40,
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: isSelected ? 28 : 24,
                  color: isSelected ? Colors.white : mediumGray,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: isSelected ? 12 : 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : mediumGray,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
