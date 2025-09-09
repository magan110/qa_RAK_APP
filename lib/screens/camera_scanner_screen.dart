import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import 'dart:async';
import 'dart:ui_web' as ui_web;
import 'dart:js_util' as jsu;

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _scanLineController;
  late AnimationController _cornerPulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _cornerPulseAnimation;

  bool isScanning = false;
  bool _isProcessingQR = false;

  web.HTMLVideoElement? _videoElement;
  web.HTMLCanvasElement? _canvasElement;
  Timer? _scanTimer;
  Timer? _initTimer;
  String _videoElementId = 'camera-video-element';
  bool _cameraInitialized = false;
  web.MediaStream? _currentStream;
  bool _viewFactoryRegistered = false;

  final List<Map<String, dynamic>> _scannedQRCodes = [];

  @override
  void initState() {
    super.initState();

    _videoElementId =
        'camera-video-element-${DateTime.now().millisecondsSinceEpoch}';

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _cornerPulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6),
      ),
    );
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
    _cornerPulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _cornerPulseController, curve: Curves.easeInOut),
    );

    _initializeCamera();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scanLineController.dispose();
    _cornerPulseController.dispose();
    _stopCamera();
    _initTimer?.cancel();
    super.dispose();
  }

  // ---------------- JS bridge helpers ----------------

  bool get _hasNativePerms =>
      jsu.hasProperty(web.window, 'NativePerms') &&
      jsu.hasProperty(
        jsu.getProperty(web.window, 'NativePerms') as Object,
        'request',
      );

  Future<Map<String, dynamic>?> _requestCameraPermissionViaBridge() async {
    try {
      if (!_hasNativePerms) return null;
      final nativePerms = jsu.getProperty(web.window, 'NativePerms');
      final promise = jsu.callMethod(nativePerms, 'request', [
        'camera',
        'This app needs camera access to scan QR codes.',
      ]);
      final result = await jsu.promiseToFuture<Object?>(promise);
      final map = jsu.dartify(result) as Map?;
      return map?.map((k, v) => MapEntry(k.toString(), v));
    } catch (e) {
      // fallback to direct getUserMedia
      return null;
    }
  }

  String? _detectQrViaJs(web.ImageData imageData, int w, int h) {
    try {
      if (jsu.hasProperty(web.window, 'detectQRCode')) {
        final res = jsu.callMethod(web.window, 'detectQRCode', [
          imageData.data, // Uint8ClampedArray
          w,
          h,
        ]);
        if (res == null) return null;
        final s = res.toString();
        return (s.isNotEmpty && s != 'null') ? s : null;
      }
    } catch (_) {}
    return null;
  }

  // ---------------- Camera lifecycle ----------------

  void _initializeCamera() {
    _initTimer?.cancel();
    if (!_viewFactoryRegistered) {
      ui_web.platformViewRegistry.registerViewFactory(_videoElementId, (int _) {
        _videoElement = web.HTMLVideoElement()
          ..id = _videoElementId
          ..autoplay = true
          ..muted = true
          ..setAttribute('playsinline', 'true')
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.border = 'none'
          ..style.backgroundColor = '#000';
        // Ensure element is attached before starting camera
        Future.delayed(const Duration(milliseconds: 100), _startCamera);
        return _videoElement!;
      });
      _viewFactoryRegistered = true;
    }
    setState(() => _cameraInitialized = true);

    _initTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !isScanning && _cameraInitialized) _restartCamera();
    });
  }

  Future<void> _startCamera() async {
    try {
      setState(() => _isProcessingQR = false);

      if (web.window.isSecureContext != true) {
        _showError('Camera access requires a secure context (HTTPS).');
        return;
      }

      // 1) Ask native (via index.html bridge). Non-blocking if missing.
      final bridgeResult = await _requestCameraPermissionViaBridge();
      if (bridgeResult != null && bridgeResult['ok'] == false) {
        _showError(
          'Camera permission denied: ${bridgeResult['error'] ?? 'Permission not granted'}',
        );
        return;
      }
      if (bridgeResult != null && bridgeResult.containsKey('webError')) {
        // Native granted but browser warm-up had an issue – log & continue.
        // ignore: avoid_print
        print('Browser warm-up error: ${bridgeResult['webError']}');
      }

      // 3) Try multiple constraints; convert to JS objects with jsify
      final strategies = <Map<String, Object>>[
        {
          'video': {
            'facingMode': 'environment',
            'width': {'ideal': 1280, 'max': 1920},
            'height': {'ideal': 720, 'max': 1080},
            'frameRate': {'ideal': 30, 'max': 60},
          },
          'audio': false,
        },
        {
          'video': {'facingMode': 'environment'},
          'audio': false,
        },
        {'video': true},
      ];

      web.MediaStream? stream;
      Object? lastErr;
      for (var i = 0; i < strategies.length; i++) {
        try {
          final jsConstraints = jsu.jsify(strategies[i]);
          final promise = web.window.navigator.mediaDevices.getUserMedia(
            jsConstraints,
          );
          stream = await jsu.promiseToFuture<web.MediaStream>(promise);
          break;
        } catch (e) {
          lastErr = e;
          if (i == strategies.length - 1) {
            // ignore: only_throw_errors
            throw lastErr;
          }
        }
      }

      if (stream == null) {
        // ignore: only_throw_errors
        throw lastErr ?? Exception('Failed to obtain camera stream');
      }

      if (_videoElement != null) {
        _currentStream = stream;
        _videoElement!.srcObject = stream;

        _videoElement!.onLoadedMetadata.listen((_) {
          _initTimer?.cancel();
          if (!mounted) return;
          setState(() => isScanning = true);
          _startQRDetection();
        });

        _videoElement!.onCanPlay.listen((_) {
          if (!mounted || isScanning) return;
          setState(() => isScanning = true);
          _startQRDetection();
        });

        _videoElement!.onError.listen((_) {
          _showError('Video playback error occurred.');
        });
      }
    } catch (e) {
      _handleCameraError(e);
    }
  }

  void _handleCameraError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('notallowederror') || s.contains('permission')) {
      _showError('Camera permission is required to scan QR codes.');
    } else if (s.contains('notfounderror')) {
      _showError('No camera found on this device.');
    } else if (s.contains('notreadableerror')) {
      _showError('Camera is already in use by another application.');
    } else if (s.contains('overconstrainederror')) {
      _showError(
        'Requested camera constraints are not supported on this device.',
      );
    } else {
      _showError('Unable to access camera: ${e.toString()}');
    }
  }

  void _startQRDetection() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!_isProcessingQR && _videoElement != null && isScanning) {
        _processVideoFrame();
      }
    });
  }

  void _processVideoFrame() {
    if (_videoElement == null || _isProcessingQR) return;
    try {
      _canvasElement ??= web.HTMLCanvasElement()
        ..width = 640
        ..height = 480;

      final ctx = _canvasElement!.context2D;
      ctx.drawImageScaled(_videoElement!, 0, 0, 640, 480);
      final imageData = ctx.getImageData(0, 0, 640, 480);

      final code = _detectQrViaJs(imageData, 640, 480);
      if (code != null) {
        _isProcessingQR = true;
        _handleQRCode(code);
      }
    } catch (e) {
      // ignore frame errors, continue scanning
    }
  }

  void _stopCamera() {
    _scanTimer?.cancel();
    _scanTimer = null;

    if (_currentStream != null) {
      final tracks = _currentStream!.getTracks(); // JSArray
      for (var i = 0; i < tracks.length; i++) {
        tracks[i].stop();
      }
      _currentStream = null;
    }

    if (_videoElement != null) {
      _videoElement!.srcObject = null;
      _videoElement = null;
    }

    setState(() {
      isScanning = false;
      _isProcessingQR = false;
      _cameraInitialized = false;
    });
  }

  void _resumeScanning() {
    if (!mounted || _videoElement == null || _currentStream == null) return;
    _scanTimer?.cancel();
    setState(() {
      _isProcessingQR = false;
      isScanning = true;
    });
    _startQRDetection();
  }

  void _restartCamera() {
    if (!mounted) return;
    setState(() {
      _cameraInitialized = false;
      _isProcessingQR = false;
      isScanning = false;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _initializeCamera();
    });
  }

  void _handleQRCode(String code) {
    HapticFeedback.heavyImpact();
    final type = _detectQRType(code);

    setState(() {
      _scannedQRCodes.insert(0, {
        'data': code,
        'type': type,
        'timestamp': DateTime.now(),
      });
      _isProcessingQR = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('QR Code scanned'),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 800), _resumeScanning);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _detectQRType(String code) {
    if (code.startsWith('http://') || code.startsWith('https://')) return 'URL';
    if (code.startsWith('mailto:')) return 'Email';
    if (code.startsWith('tel:')) return 'Phone';
    if (code.startsWith('WIFI:')) return 'WiFi';
    if (code.startsWith('BEGIN:VCARD')) return 'Contact';
    if (code.contains('\n') &&
        (code.contains('Name:') || code.contains('ID:'))) {
      return 'Product Info';
    }
    return 'Text';
  }

  IconData _getQRIcon(String type) {
    switch (type) {
      case 'URL':
        return Icons.link;
      case 'Email':
        return Icons.email;
      case 'Phone':
        return Icons.phone;
      case 'WiFi':
        return Icons.wifi;
      case 'Contact':
        return Icons.contact_page;
      case 'Product Info':
        return Icons.inventory;
      default:
        return Icons.text_fields;
    }
  }

  void _processQRData(String code, String type) {
    try {
      switch (type) {
        case 'URL':
        case 'Email':
        case 'Phone':
          web.window.open(code, '_blank');
          break;
        default:
          _showError('QR code processed successfully');
      }
    } catch (_) {
      _showError('Unable to process QR code');
    }
  }

  void _clearScannedList() => setState(() => _scannedQRCodes.clear());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Scanner section
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade800,
                    Colors.blue.shade600,
                    Colors.blue.shade400,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _cameraInitialized
                        ? HtmlElementView(viewType: _videoElementId)
                        : _buildInitializing(),
                  ),
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildOverlay(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Scanned list section
          Expanded(flex: 1, child: _buildScannedList()),
        ],
      ),
    );
  }

  Widget _buildInitializing() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Initializing camera...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _restartCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Restart Camera'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.6),
          ],
        ),
      ),
      child: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        _stopCamera();
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'QR Code Scanner',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    // Corners
                    ...List.generate(4, (index) {
                      final alignments = [
                        Alignment.topLeft,
                        Alignment.topRight,
                        Alignment.bottomLeft,
                        Alignment.bottomRight,
                      ];
                      return Align(
                        alignment: alignments[index],
                        child: AnimatedBuilder(
                          animation: _cornerPulseAnimation,
                          builder: (_, __) {
                            return Transform.scale(
                              scale: _cornerPulseAnimation.value,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: index < 2
                                        ? const BorderSide(
                                            color: Colors.white,
                                            width: 4,
                                          )
                                        : BorderSide.none,
                                    bottom: index >= 2
                                        ? const BorderSide(
                                            color: Colors.white,
                                            width: 4,
                                          )
                                        : BorderSide.none,
                                    left: index % 2 == 0
                                        ? const BorderSide(
                                            color: Colors.white,
                                            width: 4,
                                          )
                                        : BorderSide.none,
                                    right: index % 2 == 1
                                        ? const BorderSide(
                                            color: Colors.white,
                                            width: 4,
                                          )
                                        : BorderSide.none,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                    // Scan line
                    if (isScanning)
                      AnimatedBuilder(
                        animation: _scanLineAnimation,
                        builder: (_, __) {
                          return Positioned(
                            top: 280 * _scanLineAnimation.value - 1,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    // Center icon
                    if (isScanning)
                      Center(
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _cameraInitialized && isScanning
                      ? 'Position QR code within the frame'
                      : _cameraInitialized
                      ? 'Camera ready - scan QR code'
                      : 'Starting camera...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedList() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Scanned QR Codes',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                if (_scannedQRCodes.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton.icon(
                      onPressed: _clearScannedList,
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                      label: Text(
                        'Clear All',
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _scannedQRCodes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.qr_code_scanner_outlined,
                            color: Colors.blue.shade300,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No QR codes scanned yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scan a QR code to see it here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _scannedQRCodes.length,
                    itemBuilder: (context, index) {
                      final qr = _scannedQRCodes[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 3,
                          shadowColor: Colors.blue.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () => _processQRData(qr['data'], qr['type']),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          _getQRIcon(qr['type']),
                                          color: Colors.blue.shade600,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              qr['type'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatTime(qr['timestamp']),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      qr['data'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF2C3E50),
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(text: qr['data']),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Row(
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Copied to clipboard'),
                                                ],
                                              ),
                                              backgroundColor:
                                                  Colors.green.shade600,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: Icon(
                                          Icons.copy,
                                          size: 18,
                                          color: Colors.blue.shade600,
                                        ),
                                        label: Text(
                                          'Copy',
                                          style: TextStyle(
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            side: BorderSide(
                                              color: Colors.blue.shade200,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _processQRData(
                                          qr['data'],
                                          qr['type'],
                                        ),
                                        icon: const Icon(
                                          Icons.open_in_new,
                                          size: 18,
                                        ),
                                        label: const Text('Open'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade600,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
