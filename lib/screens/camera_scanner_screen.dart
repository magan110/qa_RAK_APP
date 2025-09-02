import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:async';
import 'dart:ui_web' as ui_web;

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool isScanning = false;
  bool _isProcessingQR = false;
  html.VideoElement? _videoElement;
  html.CanvasElement? _canvasElement;
  Timer? _scanTimer;
  Timer? _cornerTimer;
  Timer? _initTimer;
  double _cornerOpacity = 1.0;
  String _videoElementId = 'camera-video-element';
  bool _cameraInitialized = false;
  bool _flashEnabled = false;
  bool _hasFlashSupport = false;
  html.MediaStream? _currentStream;
  bool _viewFactoryRegistered = false;

  @override
  void initState() {
    super.initState();
    // Generate unique ID for this instance
    _videoElementId = 'camera-video-element-${DateTime.now().millisecondsSinceEpoch}';
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
    _initializeCamera();
    _startCornerAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    
    // Stop torch maintenance and ensure flash is turned off
    try {
      js.context.callMethod('stopTorchMaintenance');
      
      // Try to turn off flash before disposing
      if (_flashEnabled && _currentStream != null) {
        final videoTracks = _currentStream!.getVideoTracks();
        if (videoTracks.isNotEmpty) {
          final track = videoTracks.first;
          js.JsObject.fromBrowserObject(track).callMethod('applyConstraints', [
            js.JsObject.jsify({'advanced': [{'torch': false}]})
          ]);
        }
      }
    } catch (e) {
      print('Error stopping torch maintenance in dispose: $e');
    }
    
    _stopCamera();
    _cornerTimer?.cancel();
    _initTimer?.cancel();
    super.dispose();
  }

  void _startCornerAnimation() {
    _cornerTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (mounted) {
        setState(() {
          _cornerOpacity = _cornerOpacity == 1.0 ? 0.3 : 1.0;
        });
      }
    });
  }

  void _initializeCamera() {
    // Cancel any existing initialization timer
    _initTimer?.cancel();
    
    if (!_viewFactoryRegistered) {
      // Register the video element for Flutter web
      ui_web.platformViewRegistry.registerViewFactory(
        _videoElementId,
        (int viewId) {
          _videoElement = html.VideoElement()
            ..id = _videoElementId
            ..autoplay = true
            ..muted = true
            ..setAttribute('playsinline', 'true')
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'cover'
            ..style.border = 'none'
            ..style.backgroundColor = '#000000';

          // Start camera after a short delay to ensure element is ready
          Future.delayed(const Duration(milliseconds: 100), () {
            _startCamera();
          });
          
          return _videoElement!;
        },
      );
      _viewFactoryRegistered = true;
    }
    
    // Set camera initialized to true so the HtmlElementView shows
    setState(() {
      _cameraInitialized = true;
    });

    // Set up timeout to restart camera if initialization takes too long
    _initTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !isScanning && _cameraInitialized) {
        print('Camera initialization timeout - attempting restart');
        _restartCamera();
      }
    });
  }

  void _startCamera() async {
    try {
      print('Starting camera initialization...');
      setState(() {
        _isProcessingQR = false;
      });

      // Check for secure context (required for camera access)
      if (html.window.isSecureContext != true) {
        print('Error: Not a secure context');
        _showError('Camera access requires a secure context (HTTPS).');
        return;
      }

      // Check if mediaDevices is available
      if (html.window.navigator.mediaDevices == null) {
        print('Error: MediaDevices not available');
        _showError('Camera access is not available in this environment.');
        return;
      }
      
      print('Security checks passed, requesting camera...');

      // Try multiple camera access approaches
      html.MediaStream? stream;
      final strategies = <Map<String, dynamic>>[
        // Strategy 1: Environment camera with full torch capabilities
        {
          'video': {
            'facingMode': 'environment',
            'width': {'ideal': 1280, 'max': 1920},
            'height': {'ideal': 720, 'max': 1080},
            'frameRate': {'ideal': 30, 'max': 60},
            'torch': false,
          },
          'audio': false,
        },
        // Strategy 2: Environment camera with torch in advanced constraints
        {
          'video': {
            'facingMode': 'environment',
            'advanced': [
              {'torch': false}
            ]
          },
          'audio': false,
        },
        // Strategy 3: Simple environment camera
        {
          'video': {'facingMode': 'environment'},
          'audio': false,
        },
        // Strategy 4: Any video device
        {'video': true},
      ];

      Exception? lastError;

      for (int i = 0; i < strategies.length; i++) {
        try {
          print('Trying camera strategy ${i + 1}/${strategies.length}');
          stream = await html.window.navigator.mediaDevices!.getUserMedia(
            strategies[i],
          );
          print('Camera strategy ${i + 1} successful!');
          break;
        } catch (e) {
          print('Camera strategy ${i + 1} failed: $e');
          lastError = e as Exception;
          if (i == strategies.length - 1) {
            throw lastError;
          }
        }
      }

      if (stream == null) {
        print('All camera strategies failed');
        throw lastError ?? Exception('Failed to obtain camera stream');
      }

      print('Got camera stream, setting up video element...');
      if (_videoElement != null) {
        _currentStream = stream;
        _videoElement!.srcObject = stream;
        print('Stream assigned to video element');
        
        _videoElement!.onLoadedMetadata.listen((_) {
          print('Video metadata loaded - camera ready!');
          _initTimer?.cancel(); // Cancel timeout since camera is working
          _checkFlashCapability(); // Check if flash is available
          if (mounted) {
            setState(() {
              isScanning = true;
            });
            _startQRDetection();
          }
        });
        
        // Also try onCanPlay as a fallback
        _videoElement!.onCanPlay.listen((_) {
          print('Video can play event triggered');
          _initTimer?.cancel(); // Cancel timeout since camera is working
          if (mounted && !isScanning) {
            setState(() {
              isScanning = true;
            });
            _startQRDetection();
          }
        });
        
        // Add onError listener
        _videoElement!.onError.listen((error) {
          print('Video element error: $error');
          _showError('Video playback error occurred');
        });
      } else {
        print('Error: Video element is null');
        _showError('Video element not initialized');
      }
    } catch (e) {
      _handleCameraError(e);
    }
  }

  void _handleCameraError(dynamic e) {
    print('Camera error occurred: $e');
    final errorStr = e.toString().toLowerCase();

    if (errorStr.contains('notallowederror') ||
        errorStr.contains('permission')) {
      print('Permission error detected');
      _showError('Camera permission is required to scan QR codes.');
    } else if (errorStr.contains('notfounderror')) {
      print('No camera found error');
      _showError('No camera found on this device.');
    } else if (errorStr.contains('notreadableerror')) {
      print('Camera in use error');
      _showError('Camera is already in use by another application.');
    } else {
      print('Generic camera error: $errorStr');
      _showError('Unable to access camera: ${e.toString()}');
    }
  }

  void _startQRDetection() {
    _scanTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!_isProcessingQR && _videoElement != null && isScanning) {
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

      // Try to use jsQR library for real QR detection
      try {
        final result = js.context.callMethod('detectQRCode', [
          imageData.data,
          640,
          480,
        ]);
        if (result != null && result.toString().isNotEmpty && result.toString() != 'null') {
          _isProcessingQR = true;
          _handleQRCode(result.toString());
          return;
        }
      } catch (e) {
        print('QR detection error: $e');
      }

      // No QR code detected - continue scanning
      // Remove simulation call to only detect real QR codes
    } catch (e) {
      // Ignore processing errors
    }
  }

  Future<void> _simulateQRDetection(html.ImageData imageData) async {
    // Real QR detection implementation - no simulation
    // This method is only called as fallback when jsQR is not available
    // In production, ensure jsQR library is loaded for real QR detection
  }

  void _stopCamera() {
    _scanTimer?.cancel();
    _scanTimer = null;
    
    // Stop torch maintenance before stopping camera
    try {
      js.context.callMethod('stopTorchMaintenance');
    } catch (e) {
      print('Error stopping torch maintenance: $e');
    }
    
    // Turn off flash before stopping camera
    if (_flashEnabled && _currentStream != null) {
      try {
        final videoTracks = _currentStream!.getVideoTracks();
        if (videoTracks.isNotEmpty) {
          final track = videoTracks.first;
          js.JsObject.fromBrowserObject(track).callMethod('applyConstraints', [
            js.JsObject.jsify({'advanced': [{'torch': false}]})
          ]);
          print('Flash turned off before stopping camera');
        }
      } catch (e) {
        print('Error turning off flash before stopping camera: $e');
      }
    }
    
    if (_currentStream != null) {
      _currentStream!.getTracks().forEach((track) => track.stop());
      _currentStream = null;
    }
    if (_videoElement != null) {
      _videoElement!.srcObject = null;
      _videoElement = null;
    }
    setState(() {
      isScanning = false;
      _isProcessingQR = false;
      _flashEnabled = false;
      _hasFlashSupport = false;
      _cameraInitialized = false;
    });
  }

  void _toggleFlash() async {
    if (_currentStream == null) {
      _showError('Camera not available');
      return;
    }
    
    try {
      final videoTracks = _currentStream!.getVideoTracks();
      if (videoTracks.isEmpty) {
        _showError('No video track available');
        return;
      }

      final track = videoTracks.first;
      final newFlashState = !_flashEnabled;
      
      print('Toggling flash from $_flashEnabled to $newFlashState');
      
      bool success = false;
      String lastError = '';
      
      // Method 1: Use the enhanced JavaScript helper
      if (!success) {
        try {
          print('Trying JavaScript helper...');
          final result = await js.context.callMethod('toggleFlashlight', [track, newFlashState]);
          
          if (result == true) {
            success = true;
            print('Flash toggled successfully via JavaScript helper');
          } else {
            print('JavaScript helper returned false');
          }
        } catch (e) {
          lastError = 'JavaScript helper failed: $e';
          print(lastError);
        }
      }
      
      // Method 2: Direct advanced constraint
      if (!success) {
        try {
          print('Trying direct advanced constraint...');
          await js.JsObject.fromBrowserObject(track).callMethod('applyConstraints', [
            js.JsObject.jsify({'advanced': [{'torch': newFlashState}]})
          ]);
          success = true;
          print('Flash toggled via direct advanced constraint');
        } catch (e) {
          lastError = 'Advanced constraint failed: $e';
          print(lastError);
        }
      }
      
      // Method 3: Simple torch constraint
      if (!success) {
        try {
          print('Trying simple torch constraint...');
          await js.JsObject.fromBrowserObject(track).callMethod('applyConstraints', [
            js.JsObject.jsify({'torch': newFlashState})
          ]);
          success = true;
          print('Flash toggled via simple torch constraint');
        } catch (e) {
          lastError = 'Simple constraint failed: $e';
          print(lastError);
        }
      }
      
      // Method 4: Video object constraint
      if (!success) {
        try {
          print('Trying video object constraint...');
          await js.JsObject.fromBrowserObject(track).callMethod('applyConstraints', [
            js.JsObject.jsify({'video': {'torch': newFlashState}})
          ]);
          success = true;
          print('Flash toggled via video object constraint');
        } catch (e) {
          lastError = 'Video constraint failed: $e';
          print(lastError);
        }
      }
      
      // Method 5: Force retry with delay (for enable only)
      if (!success && newFlashState) {
        try {
          print('Trying force retry with delay...');
          await Future.delayed(const Duration(milliseconds: 300));
          await js.JsObject.fromBrowserObject(track).callMethod('applyConstraints', [
            js.JsObject.jsify({'advanced': [{'torch': true}]})
          ]);
          success = true;
          print('Flash enabled via force retry');
        } catch (e) {
          lastError = 'Force retry failed: $e';
          print(lastError);
        }
      }
      
      if (success) {
        setState(() {
          _flashEnabled = newFlashState;
        });
        
        HapticFeedback.lightImpact();
        print('Flash toggled successfully to: $newFlashState');
        
        // Start maintenance for enabled torch
        if (newFlashState) {
          try {
            js.context.callMethod('toggleFlashlight', [track, true]);
          } catch (e) {
            print('Could not start torch maintenance: $e');
          }
        }
      } else {
        // Even if all methods failed, still toggle the UI state and show a warning
        // Some devices might work even though they throw errors
        setState(() {
          _flashEnabled = newFlashState;
        });
        
        HapticFeedback.lightImpact();
        print('Flash constraints failed but toggling UI anyway - device may still work');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Flash may not be fully supported. Last error: ${lastError.split(':').first}'),
            backgroundColor: Colors.orange.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      print('Flash toggle error: $e');
      
      // Fallback: still toggle UI state
      setState(() {
        _flashEnabled = !_flashEnabled;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Flash toggle attempted - may not work on this device'),
          backgroundColor: Colors.orange.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _resumeScanning() {
    if (mounted && _videoElement != null && _currentStream != null) {
      // Cancel any existing scan timer before starting a new one
      _scanTimer?.cancel();
      setState(() {
        _isProcessingQR = false;
        isScanning = true;
      });
      _startQRDetection();
    }
  }

  void _checkFlashCapability() {
    try {
      if (_currentStream == null) return;
      
      final videoTracks = _currentStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        final track = videoTracks.first;
        
        bool hasFlashSupport = false;
        
        // Check track capabilities first
        try {
          final capabilities = js.JsObject.fromBrowserObject(track).callMethod('getCapabilities');
          if (capabilities != null && capabilities['torch'] == true) {
            print('Flash/torch capability detected in track capabilities');
            hasFlashSupport = true;
          }
        } catch (e) {
          print('Could not check track torch capabilities: $e');
        }
        
        // Check browser support as alternative method
        if (!hasFlashSupport) {
          try {
            final supportedConstraints = js.context['navigator']['mediaDevices'].callMethod('getSupportedConstraints');
            if (supportedConstraints != null && supportedConstraints['torch'] == true) {
              print('Browser supports torch constraints');
              hasFlashSupport = true;
            }
          } catch (e) {
            print('Could not check browser torch support: $e');
          }
        }
        
        // Final fallback: assume flash support on mobile devices with environment camera
        if (!hasFlashSupport) {
          try {
            final settings = js.JsObject.fromBrowserObject(track).callMethod('getSettings');
            if (settings != null && settings['facingMode'] == 'environment') {
              print('Environment camera detected - assuming flash support');
              hasFlashSupport = true;
            }
          } catch (e) {
            print('Could not check track settings: $e');
          }
        }
        
        // Ultimate fallback: assume flash support if we have a video track
        // This is because many mobile devices support flash but don't report it properly
        if (!hasFlashSupport) {
          print('Enabling flash support as fallback - will test during toggle');
          hasFlashSupport = true;
        }
        
        // Test flash functionality by attempting to apply torch constraint
        if (hasFlashSupport) {
          _testFlashFunctionality(track);
        }
        
        // Update UI based on flash support
        if (mounted) {
          setState(() {
            _hasFlashSupport = hasFlashSupport;
          });
        }
        
        if (!hasFlashSupport) {
          print('Flash/torch not supported on this device/browser');
        } else {
          print('Flash/torch is available and supported');
        }
      }
    } catch (e) {
      print('Error checking flash capability: $e');
      if (mounted) {
        setState(() {
          _hasFlashSupport = false;
        });
      }
    }
  }

  void _testFlashFunctionality(dynamic track) async {
    try {
      print('Testing flash functionality...');
      // Try to apply torch constraint briefly to test if it works
      await js.JsObject.fromBrowserObject(track).callMethod('applyConstraints', [
        js.JsObject.jsify({
          'advanced': [{'torch': true}]
        })
      ]);
      
      // Wait briefly and then turn it off
      await Future.delayed(const Duration(milliseconds: 100));
      
      await js.JsObject.fromBrowserObject(track).callMethod('applyConstraints', [
        js.JsObject.jsify({
          'advanced': [{'torch': false}]
        })
      ]);
      
      print('Flash test successful - functionality confirmed');
    } catch (e) {
      print('Flash test failed: $e');
      // Don't disable flash support based on test failure - it might still work
    }
  }

  void _restartCamera() {
    if (mounted) {
      setState(() {
        _cameraInitialized = false;
        _isProcessingQR = false;
        isScanning = false;
      });
      
      // Reinitialize camera after a short delay
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _initializeCamera();
        }
      });
    }
  }

  void _restartCameraWithTorch(bool enableTorch) async {
    if (!mounted) return;
    
    print('Restarting camera with torch: $enableTorch');
    
    // Stop torch maintenance before restarting
    try {
      js.context.callMethod('stopTorchMaintenance');
    } catch (e) {
      print('Error stopping torch maintenance before restart: $e');
    }
    
    // Stop current camera
    _stopCamera();
    
    // Wait a moment for cleanup
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    try {
      // Register video element if needed
      if (!_viewFactoryRegistered) {
        ui_web.platformViewRegistry.registerViewFactory(
          _videoElementId,
          (int viewId) {
            _videoElement = html.VideoElement()
              ..id = _videoElementId
              ..autoplay = true
              ..muted = true
              ..setAttribute('playsinline', 'true')
              ..style.width = '100%'
              ..style.height = '100%'
              ..style.objectFit = 'cover'
              ..style.border = 'none'
              ..style.backgroundColor = '#000000';
            return _videoElement!;
          },
        );
        _viewFactoryRegistered = true;
      }
      
      setState(() {
        _cameraInitialized = true;
      });

      // Request camera with torch constraint from the start
      final strategies = <Map<String, dynamic>>[
        // Strategy 1: Environment camera with torch in main constraints
        {
          'video': {
            'facingMode': 'environment',
            'torch': enableTorch,
            'width': {'ideal': 1280, 'max': 1920},
            'height': {'ideal': 720, 'max': 1080},
            'frameRate': {'ideal': 30, 'max': 60},
          },
          'audio': false,
        },
        // Strategy 2: Environment camera with torch in advanced constraints
        {
          'video': {
            'facingMode': 'environment',
            'advanced': [{'torch': enableTorch}],
            'width': {'ideal': 1280},
            'height': {'ideal': 720},
          },
          'audio': false,
        },
        // Strategy 3: Simple environment with torch
        {
          'video': {
            'facingMode': 'environment',
            'torch': enableTorch
          },
          'audio': false,
        },
        // Strategy 4: Fallback to environment without torch
        {
          'video': {'facingMode': 'environment'},
          'audio': false,
        },
      ];

      html.MediaStream? stream;
      Exception? lastError;

      for (int i = 0; i < strategies.length; i++) {
        try {
          print('Trying camera strategy with torch ${i + 1}/${strategies.length}');
          stream = await html.window.navigator.mediaDevices!.getUserMedia(
            strategies[i],
          );
          print('Camera strategy with torch ${i + 1} successful!');
          break;
        } catch (e) {
          print('Camera strategy with torch ${i + 1} failed: $e');
          lastError = e as Exception;
        }
      }

      if (stream == null) {
        throw lastError ?? Exception('Failed to obtain camera stream with torch');
      }

      if (_videoElement != null) {
        _currentStream = stream;
        _videoElement!.srcObject = stream;
        
        // Set initial flash state
        setState(() {
          _flashEnabled = enableTorch;
        });
        
        _videoElement!.onLoadedMetadata.listen((_) {
          print('Video metadata loaded - camera with torch ready!');
          if (mounted) {
            setState(() {
              isScanning = true;
            });
            _startQRDetection();
            
            // Verify torch is working by checking track settings
            _verifyTorchState();
          }
        });
        
        _videoElement!.onCanPlay.listen((_) {
          if (mounted && !isScanning) {
            setState(() {
              isScanning = true;
            });
            _startQRDetection();
          }
        });
      }
      
    } catch (e) {
      print('Failed to restart camera with torch: $e');
      _showError('Unable to restart camera with flash');
      // Fallback to regular camera restart
      _restartCamera();
    }
  }

  void _verifyTorchState() {
    try {
      if (_currentStream != null) {
        final videoTracks = _currentStream!.getVideoTracks();
        if (videoTracks.isNotEmpty) {
          final track = videoTracks.first;
          final settings = js.JsObject.fromBrowserObject(track).callMethod('getSettings');
          print('Torch verification - settings: $settings');
          
          if (settings != null && settings['torch'] != null) {
            final actualTorchState = settings['torch'] as bool;
            if (actualTorchState != _flashEnabled) {
              print('Torch state mismatch. Expected: $_flashEnabled, Actual: $actualTorchState');
              setState(() {
                _flashEnabled = actualTorchState;
              });
            } else {
              print('Torch state verified successfully: $actualTorchState');
            }
          }
        }
      }
    } catch (e) {
      print('Torch state verification failed: $e');
    }
  }

  void _handleQRCode(String code) {
    HapticFeedback.heavyImpact();
    // Pause scanning but keep camera running
    setState(() {
      _isProcessingQR = true;
      isScanning = false;
    });
    _scanTimer?.cancel();

    showDialog(
      context: context,
      builder: (context) => _buildQRResultDialog(code),
    ).then((_) {
      // Resume scanning when dialog is dismissed
      _resumeScanning();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showFlashUnsupportedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.flash_off_outlined, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Flash Not Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Flash/torch functionality is not supported on this device or browser.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'Possible reasons:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Device doesn\'t have a flash/torch'),
            const Text('• Browser doesn\'t support torch control'),
            const Text('• Running on desktop without flash hardware'),
            const Text('• Camera permissions are limited'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Try using the scanner in good lighting conditions instead.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showManualEntry() {
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

  Widget _buildQRResultDialog(String code) {
    final qrType = _detectQRType(code);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.green.shade500],
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
              child: Icon(
                _getQRIcon(qrType),
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'QR Code Detected!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type: $qrType',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  code,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QR data copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _processQRData(code, qrType);
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Dialog will resume scanning automatically
                    },
                    child: const Text(
                      'Scan Another',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      _stopCamera(); // Stop camera before closing
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Close Scanner',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _detectQRType(String code) {
    if (code.startsWith('http://') || code.startsWith('https://')) {
      return 'URL';
    } else if (code.startsWith('mailto:')) {
      return 'Email';
    } else if (code.startsWith('tel:')) {
      return 'Phone';
    } else if (code.startsWith('WIFI:')) {
      return 'WiFi';
    } else if (code.startsWith('BEGIN:VCARD')) {
      return 'Contact';
    } else if (code.contains('\n') && (code.contains('Name:') || code.contains('ID:'))) {
      return 'Product Info';
    } else {
      return 'Text';
    }
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
          html.window.open(code, '_blank');
          break;
        case 'Email':
          html.window.open(code, '_blank');
          break;
        case 'Phone':
          html.window.open(code, '_blank');
          break;
        default:
          _showError('QR code processed successfully');
      }
    } catch (e) {
      _showError('Unable to process QR code');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera view container
          Positioned.fill(
            child: _cameraInitialized
                ? HtmlElementView(viewType: _videoElementId)
                : Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Initializing camera...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _restartCamera,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Restart Camera'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Scanner overlay
          FadeTransition(
            opacity: _opacityAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Top section with back button and title
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(24),
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
                            const Text(
                              'Scan QR Code',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Center scanning area
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              // Corner indicators
                              ...List.generate(4, (index) {
                                return Positioned(
                                  top: index < 2 ? 0 : null,
                                  bottom: index >= 2 ? 0 : null,
                                  left: index % 2 == 0 ? 0 : null,
                                  right: index % 2 == 1 ? 0 : null,
                                  child: AnimatedOpacity(
                                    opacity: _cornerOpacity,
                                    duration: const Duration(milliseconds: 1000),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: index < 2
                                              ? const BorderSide(
                                                  color: Colors.green,
                                                  width: 4,
                                                )
                                              : BorderSide.none,
                                          bottom: index >= 2
                                              ? const BorderSide(
                                                  color: Colors.green,
                                                  width: 4,
                                                )
                                              : BorderSide.none,
                                          left: index % 2 == 0
                                              ? const BorderSide(
                                                  color: Colors.green,
                                                  width: 4,
                                                )
                                              : BorderSide.none,
                                          right: index % 2 == 1
                                              ? const BorderSide(
                                                  color: Colors.green,
                                                  width: 4,
                                                )
                                              : BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              // Center scanning indicator
                              if (isScanning)
                                Center(
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_scanner_rounded,
                                      color: Colors.green,
                                      size: 30,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom instructions and controls
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(25),
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
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Manual entry button
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: _showManualEntry,
                                    icon: const Icon(
                                      Icons.keyboard_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),

                                // Flashlight button - always show, but with different styling based on support
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: _hasFlashSupport
                                        ? (_flashEnabled 
                                            ? Colors.yellow.withOpacity(0.3)
                                            : Colors.black.withOpacity(0.5))
                                        : Colors.grey.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: _hasFlashSupport
                                          ? (_flashEnabled 
                                              ? Colors.yellow.withOpacity(0.8)
                                              : Colors.white.withOpacity(0.3))
                                          : Colors.grey.withOpacity(0.5),
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: _hasFlashSupport ? _toggleFlash : _showFlashUnsupportedDialog,
                                    icon: Icon(
                                      _hasFlashSupport
                                          ? (_flashEnabled 
                                              ? Icons.flash_on_rounded
                                              : Icons.flash_off_rounded)
                                          : Icons.flash_off_outlined,
                                      color: _hasFlashSupport
                                          ? (_flashEnabled 
                                              ? Colors.yellow
                                              : Colors.white)
                                          : Colors.grey,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}