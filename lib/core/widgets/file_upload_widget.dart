// file_upload_widget.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' show File; // OK on mobile; guarded by kIsWeb checks
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

// Web-only libs (guarded by kIsWeb)
import 'package:web/web.dart' as web;
// ignore: deprecated_member_use
import 'dart:js' as js;
import 'dart:js_util' as js_util;

import '../services/upload_service.dart';

// PDF viewer
import 'package:pdfx/pdfx.dart';

/// Detect if running inside an InAppWebView-like environment
bool get _isInAppWebView {
  if (kIsWeb) {
    try {
      final userAgent = web.window.navigator.userAgent.toLowerCase();
      final location = web.window.location;

      final isStandardBrowser =
          (userAgent.contains('chrome') &&
              userAgent.contains('chrome/') &&
              !userAgent.contains('webview')) ||
          userAgent.contains('firefox') ||
          (userAgent.contains('safari') &&
              !userAgent.contains('webview') &&
              !userAgent.contains('mobile')) ||
          userAgent.contains('edge');

      if (isStandardBrowser &&
          location.protocol.startsWith('http') &&
          location.hostname != 'localhost') {
        // Standard browser → NOT InAppWebView
        return false;
      }

      // Assume InAppWebView in all other web cases (safer for camera)
      return true;
    } catch (_) {
      return true; // Fail-safe: treat as InAppWebView
    }
  }
  return false;
}

class FileUploadWidget extends StatefulWidget {
  final String label;
  final IconData icon;
  final Function(String?) onFileSelected;
  final Duration delay;
  final bool isRequired;
  final List<String> allowedExtensions;
  final double maxSizeInMB;
  final String? currentFilePath;
  final String? formType; // 'contractor' or 'painter' get a simplified picker

  const FileUploadWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.onFileSelected,
    this.delay = Duration.zero,
    this.isRequired = true,
    this.allowedExtensions = const ['*'],
    this.maxSizeInMB = 15.0,
    this.currentFilePath,
    this.formType,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  String? _selectedFilePath;
  String? _originalFileName;
  String? _fileType; // captured type hint for UI (does NOT control detection)
  bool _isVisible = false;
  bool _isUploading = false;
  bool _isUploaded = false;
  String? _uploadError;

  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();

    _selectedFilePath = widget.currentFilePath;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _isVisible = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void didUpdateWidget(FileUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentFilePath != oldWidget.currentFilePath) {
      setState(() {
        _selectedFilePath = widget.currentFilePath;
        if (_selectedFilePath != null && _selectedFilePath!.isNotEmpty) {
          _isUploading = false;
          _isUploaded = true;
          _uploadError = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _scaffoldMessenger = null;
    super.dispose();
  }

  bool _isContractorOrPainterForm() =>
      widget.formType == 'contractor' || widget.formType == 'painter';

  void _safeShowSnackBar(SnackBar bar) {
    if (mounted && _scaffoldMessenger != null) {
      _scaffoldMessenger!.showSnackBar(bar);
    }
  }

  void _safeHideCurrentSnackBar() {
    if (mounted && _scaffoldMessenger != null) {
      _scaffoldMessenger!.hideCurrentSnackBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(_isVisible ? 0 : 20, 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isRequired ? '${widget.label} *' : widget.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ScaleTransition(
              scale: _scaleAnimation ?? const AlwaysStoppedAnimation(1.0),
              child: GestureDetector(
                onTapDown: (_) => _animationController?.forward(),
                onTapUp: (_) => _animationController?.reverse(),
                onTapCancel: () => _animationController?.reverse(),
                onTap: _selectedFilePath == null
                    ? () => _showUploadOptions(context)
                    : () => _showFileActions(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedFilePath != null
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedFilePath != null
                        ? Colors.white
                        : Colors.grey.shade50,
                  ),
                  child: _selectedFilePath != null
                      ? _buildUploadedFileDisplay()
                      : _buildUploadPrompt(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPrompt() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue.shade200, width: 2),
          ),
          child: Icon(widget.icon, size: 28, color: Colors.blue.shade600),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to upload ${widget.label.toLowerCase()}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _isContractorOrPainterForm()
                ? (_isInAppWebView
                      ? '🖼️ Gallery Recommended • 📷 Camera (Limited) • 📁 Browse Files'
                      : '📷 Camera • 🖼️ Gallery • 📁 Browse Files')
                : '📷 Camera • 🖼️ Gallery • 📁 Files',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadedFileDisplay() {
    final isImage = _isImageFileLocal(_selectedFilePath!);

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isImage
                ? (kIsWeb
                      ? (_selectedFilePath!.startsWith('data:')
                            ? Builder(
                                builder: (context) {
                                  try {
                                    final parts = _selectedFilePath!.split(',');
                                    if (parts.length != 2)
                                      return _buildFileIconForUploadArea();
                                    final imageBytes = base64Decode(parts[1]);
                                    return Image.memory(
                                      imageBytes,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildFileIconForUploadArea(),
                                    );
                                  } catch (_) {
                                    return _buildFileIconForUploadArea();
                                  }
                                },
                              )
                            : Image.network(
                                _selectedFilePath!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildFileIconForUploadArea(),
                              ))
                      : Image.file(
                          File(_selectedFilePath!),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildFileIconForUploadArea(),
                        ))
                : _buildFileIconForUploadArea(),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Row(
            children: [
              if (_isUploading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else if (_uploadError != null)
                const Icon(Icons.error, size: 16, color: Colors.red)
              else if (_isUploaded)
                const Icon(Icons.check_circle, size: 16, color: Colors.white)
              else
                const Icon(Icons.file_present, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _isUploading
                      ? 'Uploading...'
                      : _uploadError != null
                      ? 'Upload failed'
                      : _getFileNameLocal(_selectedFilePath!),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            radius: 12,
            backgroundColor: Colors.black54,
            child: Icon(Icons.more_vert, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildFileIconForUploadArea() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getFileIconLocal(_selectedFilePath!),
              size: 32,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 6),
            Text(
              _getFileExtensionLocal(_selectedFilePath!).toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getFileNameLocal(_selectedFilePath!),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose an action for this file',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  _buildActionOption(
                    icon: Icons.visibility_rounded,
                    title: 'View File',
                    subtitle: 'Preview the uploaded file',
                    onTap: () {
                      Navigator.pop(context);
                      _showFilePreview();
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_uploadError != null) ...[
                    _buildActionOption(
                      icon: Icons.refresh_rounded,
                      title: 'Retry Upload',
                      subtitle: 'Try uploading the file again',
                      onTap: () {
                        Navigator.pop(context);
                        _retryUpload();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildActionOption(
                    icon: Icons.edit_rounded,
                    title: 'Change File',
                    subtitle: 'Upload a different file',
                    onTap: () {
                      Navigator.pop(context);
                      _showUploadOptions(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildActionOption(
                    icon: Icons.delete_rounded,
                    title: 'Remove File',
                    subtitle: 'Delete this uploaded file',
                    onTap: () {
                      Navigator.pop(context);
                      _removeFile();
                    },
                    isDestructive: true,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDestructive ? Colors.red.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? Colors.red.shade600
                    : Colors.blue.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? Colors.red.shade700
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload ${widget.label}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how you want to upload your file',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  if (_isContractorOrPainterForm()) ...[
                    _buildUploadOption(
                      icon: Icons.camera_alt_rounded,
                      title: _isInAppWebView
                          ? 'Take Photo (Limited)'
                          : 'Take Photo',
                      subtitle: _isInAppWebView
                          ? 'Camera access may be restricted'
                          : 'Use camera to capture',
                      onTap: () => _pickFromCamera(context),
                      warning: _isInAppWebView
                          ? 'Camera may not work in this environment'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildUploadOption(
                      icon: Icons.photo_library_rounded,
                      title: 'Choose from Gallery',
                      subtitle: 'Select from photo library (Recommended)',
                      onTap: () => _pickFromGallery(context),
                      isRecommended: _isInAppWebView,
                    ),
                    const SizedBox(height: 16),
                    _buildUploadOption(
                      icon: Icons.folder_rounded,
                      title: 'Browse Files',
                      subtitle: 'Select PDF or other files from device',
                      onTap: () => _pickFromFiles(context),
                    ),
                  ] else ...[
                    _buildUploadOption(
                      icon: Icons.camera_alt_rounded,
                      title: 'Take Photo',
                      subtitle: 'Use camera to capture',
                      onTap: () => _pickFromCamera(context),
                    ),
                    const SizedBox(height: 16),
                    _buildUploadOption(
                      icon: Icons.photo_library_rounded,
                      title: 'Choose from Gallery',
                      subtitle: 'Select from photo library',
                      onTap: () => _pickFromGallery(context),
                    ),
                    const SizedBox(height: 16),
                    _buildUploadOption(
                      icon: Icons.folder_rounded,
                      title: 'Choose from Files',
                      subtitle: 'Select from device storage',
                      onTap: () => _pickFromFiles(context),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'File Requirements',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Supported: ${widget.allowedExtensions.contains('*') ? 'All file types' : widget.allowedExtensions.join(', ').toUpperCase()}\n'
                          'Max size: ${widget.maxSizeInMB}MB',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? warning,
    bool isRecommended = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isRecommended
                ? Colors.green.shade300
                : warning != null
                ? Colors.orange.shade300
                : Colors.grey.shade200,
            width: isRecommended ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isRecommended
              ? Colors.green.shade50
              : warning != null
              ? Colors.orange.shade50
              : Colors.white,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isRecommended
                        ? Colors.green.shade50
                        : warning != null
                        ? Colors.orange.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isRecommended
                        ? Colors.green.shade600
                        : warning != null
                        ? Colors.orange.shade600
                        : Colors.blue.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: warning != null
                                    ? Colors.orange.shade800
                                    : null,
                              ),
                            ),
                          ),
                          if (isRecommended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade600,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'RECOMMENDED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: warning != null
                              ? Colors.orange.shade700
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            if (warning != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      size: 14,
                      color: Colors.orange.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        warning,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    Navigator.pop(context);

    _safeShowSnackBar(
      SnackBar(
        content: const Text('Opening camera...'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );

    // Try simple hidden input for InAppWebView first (better compatibility)
    if (_isInAppWebView && kIsWeb) {
      try {
        final completer = Completer<String?>();
        final inputId = 'camera_input_${DateTime.now().millisecondsSinceEpoch}';

        js.context.callMethod('eval', [
          '''
          (function() {
            const existing = document.getElementById('$inputId');
            if (existing) existing.remove();
            const input = document.createElement('input');
            input.type = 'file';
            input.accept = 'image/*';
            input.capture = 'environment';
            input.id = '$inputId';
            input.style.position = 'fixed';
            input.style.left = '-9999px';
            input.style.opacity = '0';
            document.body.appendChild(input);
            input.onchange = function(e) {
              const file = e.target.files && e.target.files[0];
              if (!file) { window.dartCameraResult_$inputId({success:false}); return; }
              const reader = new FileReader();
              reader.onload = function(e) {
                window.dartCameraResult_$inputId({
                  success: true,
                  base64: e.target.result,
                  fileName: file.name,
                  mimeType: file.type
                });
              };
              reader.onerror = function() { window.dartCameraResult_$inputId({success:false}); };
              reader.readAsDataURL(file);
            };
            input.click();
          })();
          ''',
        ]);

        js.context['dartCameraResult_$inputId'] = js.allowInterop((result) {
          try {
            final ok = js_util.getProperty(result, 'success') == true;
            if (ok) {
              final base64 = js_util.getProperty(result, 'base64')?.toString();
              completer.complete(base64);
            } else {
              completer.complete(null);
            }
          } catch (_) {
            completer.complete(null);
          }
        });

        final base64Result = await completer.future.timeout(
          const Duration(seconds: 60),
          onTimeout: () => null,
        );

        try {
          js.context.deleteProperty('dartCameraResult_$inputId');
          js.context.callMethod('eval', [
            'document.getElementById("$inputId")?.remove()',
          ]);
        } catch (_) {}

        if (base64Result != null && base64Result.isNotEmpty) {
          _safeHideCurrentSnackBar();
          _showSuccessSnackBar('📷 Photo captured successfully!');
          await _handleSelectedFile(
            base64Result,
            fileType: 'image',
            originalName: 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          return;
        } else if (_isInAppWebView) {
          _safeHideCurrentSnackBar();
          _showInAppWebViewCameraHint();
          return;
        }
      } catch (_) {
        // continue to ImagePicker fallback
      }
    }

    // Fallback (and primary on mobile): ImagePicker
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: _isInAppWebView ? 1920 : 1280,
        maxHeight: _isInAppWebView ? 1080 : 720,
        imageQuality: _isInAppWebView ? 85 : 70,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) {
        _safeHideCurrentSnackBar();
        if (_isInAppWebView) {
          _showInAppWebViewCameraHint();
        } else {
          _showErrorSnackBar('Camera cancelled.');
        }
        return;
      }

      _safeHideCurrentSnackBar();

      String imagePath = image.path;
      if (kIsWeb || _isInAppWebView) {
        final bytes = await image.readAsBytes();
        final b64 = base64Encode(bytes);
        imagePath = 'data:image/jpeg;base64,$b64';
      }

      await _handleSelectedFile(
        imagePath,
        fileType: 'image',
        originalName: image.name,
      );
    } catch (e) {
      _safeHideCurrentSnackBar();
      _showErrorSnackBar(
        _isInAppWebView
            ? 'Camera failed in InAppWebView. Use "Choose from Gallery".'
            : 'Failed to capture image: $e',
      );
      if (_isInAppWebView && mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _showInAppWebViewCameraHelpDialog();
        });
      }
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    Navigator.pop(context);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image == null) return;

      String path = image.path;
      if (kIsWeb) {
        final b = await image.readAsBytes();
        path = 'data:image/jpeg;base64,${base64Encode(b)}';
      }

      await _handleSelectedFile(
        path,
        fileType: 'image',
        originalName: image.name,
      );
    } catch (e) {
      _showErrorSnackBar('Failed to select image: $e');
    }
  }

  Future<void> _pickFromFiles(BuildContext context) async {
    Navigator.pop(context);
    try {
      FilePickerResult? result;

      if (kIsWeb || _isInAppWebView) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: true,
        );
      } else {
        if (widget.allowedExtensions.contains('*') ||
            widget.allowedExtensions.isEmpty) {
          result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: false,
          );
        } else {
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: widget.allowedExtensions,
            allowMultiple: false,
          );
        }
      }

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        String fileType = 'document';
        final ext = (file.extension ?? '').toLowerCase();

        if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext))
          fileType = 'image';
        else if (ext == 'pdf')
          fileType = 'pdf';
        else if (ext == 'txt')
          fileType = 'text';
        else if (['doc', 'docx'].contains(ext))
          fileType = 'word';
        else if (['xls', 'xlsx'].contains(ext))
          fileType = 'excel';
        else if (['ppt', 'pptx'].contains(ext))
          fileType = 'powerpoint';

        String pathForState;
        if (kIsWeb && file.bytes != null && file.bytes!.isNotEmpty) {
          final mime = _mimeFromExtensionLocal(ext.isEmpty ? 'bin' : ext);
          pathForState = 'data:$mime;base64,${base64Encode(file.bytes!)}';
        } else if (!kIsWeb && file.path != null) {
          pathForState = file.path!;
        } else {
          _showErrorSnackBar('Unable to access selected file');
          return;
        }

        await _handleSelectedFile(
          pathForState,
          fileType: fileType,
          originalName: file.name,
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select file: $e');
    }
  }

  Future<void> _handleSelectedFile(
    String filePath, {
    String? fileType,
    String? originalName,
  }) async {
    // Lenient validation in web/InApp when the context implies images
    bool skipValidation = false;
    if (kIsWeb || _isInAppWebView) {
      final isImageContext =
          fileType == 'image' ||
          widget.allowedExtensions.any(
            (e) => [
              'jpg',
              'jpeg',
              'png',
              'gif',
              'webp',
              'bmp',
            ].contains(e.toLowerCase()),
          ) ||
          widget.label.toLowerCase().contains('emirates') ||
          widget.label.toLowerCase().contains('id') ||
          widget.label.toLowerCase().contains('photo');
      if (isImageContext) skipValidation = true;
    }

    String extension = '';
    if (filePath.contains('.')) {
      extension = filePath.split('.').last.toLowerCase();
    } else if (originalName != null && originalName.contains('.')) {
      extension = originalName.split('.').last.toLowerCase();
    }

    if (!skipValidation &&
        widget.allowedExtensions.isNotEmpty &&
        !widget.allowedExtensions.contains('*') &&
        extension.isNotEmpty) {
      final normalized = widget.allowedExtensions
          .map((e) => e.toLowerCase())
          .toList();
      final imageAliases = {'jpeg': 'jpg', 'jfif': 'jpg', 'webp': 'jpg'};
      bool isAllowed = normalized.contains(extension);
      if (!isAllowed && imageAliases.containsKey(extension)) {
        isAllowed = normalized.contains(imageAliases[extension]!);
      }
      if (!isAllowed && extension.isEmpty && fileType == 'image') {
        isAllowed = normalized.any((e) => ['jpg', 'jpeg', 'png'].contains(e));
      }
      if (!isAllowed) {
        _showErrorSnackBar(
          'Invalid file type. Allowed: ${widget.allowedExtensions.join(', ').toUpperCase()}',
        );
        return;
      }
    }

    // Check file size for both web and mobile
    double fileSizeInMB = 0;
    if (kIsWeb && filePath.startsWith('data:')) {
      // For web data URLs, calculate size from base64
      try {
        final parts = filePath.split(',');
        if (parts.length == 2) {
          final base64Data = parts[1];
          final bytes = base64Decode(base64Data);
          fileSizeInMB = bytes.length / (1024 * 1024);
        }
      } catch (_) {}
    } else if (!kIsWeb && !filePath.startsWith('data:')) {
      // For mobile files
      try {
        final file = File(filePath);
        final sizeInBytes = await file.length();
        fileSizeInMB = sizeInBytes / (1024 * 1024);
      } catch (_) {}
    }

    if (fileSizeInMB > widget.maxSizeInMB) {
      _showFileSizeErrorSnackBar(fileSizeInMB, widget.maxSizeInMB);
      return;
    }

    setState(() {
      _selectedFilePath = filePath;
      _fileType = fileType;
      _originalFileName = originalName;
      _isUploading = true;
      _isUploaded = false;
      _uploadError = null;
    });

    widget.onFileSelected(filePath);

    // Force immediate visual refresh
    if (mounted) setState(() {});

    try {
      // Try real network first (even in InAppWebView); UploadService handles fallback
      final uploadResult = await UploadService.uploadFile(
        filePath,
        originalName: originalName,
      );

      if (uploadResult['success'] == true) {
        setState(() {
          _isUploading = false;
          _isUploaded = true;
        });

        if (_isContractorOrPainterForm()) {
          String msg = _isInAppWebView
              ? '✅ ${widget.label} uploaded successfully in app!'
              : '✅ ${widget.label} uploaded successfully!';
          _showEnhancedSuccessSnackBar(msg);
        }
      } else {
        setState(() {
          _isUploading = false;
          _isUploaded = false;
          _uploadError = (uploadResult['error'] ?? 'Unknown error').toString();
        });

        var message = 'Upload failed: $_uploadError';
        if (_isInAppWebView) {
          message = 'Upload failed in InAppWebView: $_uploadError';
          if (_uploadError!.contains('Network') ||
              _uploadError!.contains('Connection')) {
            message +=
                '\n\nTip: Check connectivity and whether the server is reachable from the app.';
          }
        }
        _showErrorSnackBar(message);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isUploaded = false;
        _uploadError = e.toString();
      });

      String message = 'Upload failed: $e';
      if (_isInAppWebView) {
        if (e.toString().contains('XMLHttpRequest')) {
          message =
              'InAppWebView upload failed: Network request blocked/failed. Server may not be accessible.';
        } else if (e.toString().contains('CORS')) {
          message =
              'InAppWebView upload failed: CORS blocked the request. Configure your server to allow your origin.';
        } else {
          message = 'InAppWebView upload failed: $e';
        }
      }
      _showErrorSnackBar(message);
    }
  }

  Future<void> _retryUpload() async {
    if (_selectedFilePath == null) return;
    await _handleSelectedFile(
      _selectedFilePath!,
      fileType: _fileType,
      originalName: _originalFileName,
    );
  }

  void _removeFile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Remove File'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${_getFileNameLocal(_selectedFilePath!)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedFilePath = null;
                _isUploading = false;
                _isUploaded = false;
                _uploadError = null;
              });
              widget.onFileSelected(null);
              _showSuccessSnackBar('File removed successfully');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    _safeShowSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEnhancedSuccessSnackBar(String message) {
    _safeShowSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Complete!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(message, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    _safeShowSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 5),
        action: message.toLowerCase().contains('camera')
            ? SnackBarAction(
                label: 'Try Gallery',
                textColor: Colors.white,
                onPressed: () {
                  _safeHideCurrentSnackBar();
                  _pickFromGallery(context);
                },
              )
            : null,
      ),
    );
  }

  void _showFileSizeErrorSnackBar(double actualSize, double maxSize) {
    _safeShowSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'File too large! Size: ${actualSize.toStringAsFixed(1)}MB (Max: ${maxSize}MB)\nPlease select a smaller file.',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Choose Different File',
          textColor: Colors.white,
          onPressed: () {
            _safeHideCurrentSnackBar();
            _showUploadOptions(context);
          },
        ),
      ),
    );
  }

  void _showInAppWebViewCameraHint() {
    _safeShowSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Camera access is limited. Try "Choose from Gallery" instead.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Use Gallery',
          textColor: Colors.white,
          onPressed: () {
            _safeHideCurrentSnackBar();
            _pickFromGallery(context);
          },
        ),
      ),
    );
  }

  void _showInAppWebViewCameraHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.orange),
            SizedBox(width: 8),
            Text('Camera Issue'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Camera access is limited in InAppWebView environments.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'InAppWebView apps often restrict direct camera access for security reasons.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, size: 20, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Use "Choose from Gallery" to select photos from your device.',
                      style: TextStyle(fontSize: 12),
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
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showUploadOptions(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Use Gallery',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilePreview() {
    if (_selectedFilePath == null) return;

    final isImage = _isImageFileLocal(_selectedFilePath!);
    if (isImage) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(widget.label),
              actions: [
                IconButton(
                  onPressed: _showFileDetails,
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
            body: Center(
              child: InteractiveViewer(
                child: kIsWeb
                    ? (_selectedFilePath!.startsWith('data:')
                          ? Image.memory(
                              base64Decode(_selectedFilePath!.split(',')[1]),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _imageError(),
                            )
                          : Image.network(
                              _selectedFilePath!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _imageError(),
                            ))
                    : Image.file(
                        File(_selectedFilePath!),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _imageError(),
                      ),
              ),
            ),
          ),
        ),
      );
    } else {
      _showDocumentViewer();
    }
  }

  Widget _imageError() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error, size: 64, color: Colors.white),
        SizedBox(height: 16),
        Text('Unable to load image', style: TextStyle(color: Colors.white)),
      ],
    ),
  );

  void _showDocumentViewer() {
    if (_selectedFilePath == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(widget.label),
            actions: [
              IconButton(
                onPressed: _showFileDetails,
                icon: const Icon(Icons.info_outline),
              ),
            ],
          ),
          body: _buildDocumentContent(),
        ),
      ),
    );
  }

  Widget _buildDocumentContent() {
    String fileType = _fileType ?? 'unknown';

    if (fileType == 'unknown') {
      final extension = _getFileExtensionLocal(_selectedFilePath!);
      if (['pdf'].contains(extension))
        fileType = 'pdf';
      else if (['txt'].contains(extension))
        fileType = 'text';
      else if (['doc', 'docx'].contains(extension))
        fileType = 'word';
      else if (['xls', 'xlsx'].contains(extension))
        fileType = 'excel';
      else if (['ppt', 'pptx'].contains(extension))
        fileType = 'powerpoint';
      else if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension))
        fileType = 'image';
    }

    switch (fileType) {
      case 'pdf':
        return _buildPdfViewer();
      case 'text':
        return _buildTextViewer();
      case 'word':
        return _buildDocumentPlaceholder('Word Document');
      case 'excel':
        return _buildDocumentPlaceholder('Excel Spreadsheet');
      case 'powerpoint':
        return _buildDocumentPlaceholder('PowerPoint Presentation');
      case 'image':
        return _buildImagePlaceholder();
      default:
        return _buildUnsupportedDocument();
    }
  }

  Widget _buildPdfViewer() {
    return FutureBuilder<PdfDocument?>(
      future: _loadPdfDocument(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading PDF...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 80, color: Colors.red.shade600),
                const SizedBox(height: 16),
                Text(
                  'Failed to load PDF',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _openExternalViewer,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Externally'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final pdfDocument = snapshot.data;
        if (pdfDocument == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  size: 80,
                  color: Colors.red.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'PDF Document',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getFileNameLocal(_selectedFilePath!),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _openExternalViewer,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Externally'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // PDF Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFileNameLocal(_selectedFilePath!),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${pdfDocument.pagesCount} pages',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _openExternalViewer,
                    icon: const Icon(Icons.open_in_new),
                    tooltip: 'Open externally',
                  ),
                ],
              ),
            ),
            // PDF Viewer
            Expanded(
              child: PdfView(
                controller: PdfController(document: Future.value(pdfDocument)),
                scrollDirection: Axis.vertical,
                pageSnapping: false,
                physics: const BouncingScrollPhysics(),
                renderer: (PdfPage page) => page.render(
                  width: page.width * 2,
                  height: page.height * 2,
                  format: PdfPageImageFormat.jpeg,
                  backgroundColor: '#FFFFFF',
                ),
                onDocumentLoaded: (document) {
                  // PDF loaded successfully
                },
                onPageChanged: (page) {
                  // Page changed
                },
                onDocumentError: (error) {
                  // Handle PDF error
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<PdfDocument?> _loadPdfDocument() async {
    try {
      if (_selectedFilePath == null) return null;

      if (_selectedFilePath!.startsWith('data:')) {
        // Handle base64 data URL
        final parts = _selectedFilePath!.split(',');
        if (parts.length == 2) {
          final base64Data = parts[1];
          final bytes = base64Decode(base64Data);
          return PdfDocument.openData(bytes);
        }
      } else if (_selectedFilePath!.startsWith('http')) {
        // Handle URL
        return PdfDocument.openFile(_selectedFilePath!);
      } else if (!kIsWeb) {
        // Handle local file path (mobile)
        return PdfDocument.openFile(_selectedFilePath!);
      }

      return null;
    } catch (e) {
      print('Error loading PDF: $e');
      return null;
    }
  }

  Widget _buildTextViewer() {
    return FutureBuilder<String>(
      future: _readTextFile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading file: ${snapshot.error}'),
              ],
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              snapshot.data ?? 'Empty file',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentPlaceholder(String documentType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileIconLocal(_selectedFilePath!),
            size: 80,
            color: Colors.blue.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            documentType,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getFileNameLocal(_selectedFilePath!),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Ready to View',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade300, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 80, color: Colors.green.shade600),
                const SizedBox(height: 16),
                Text(
                  'Image File',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _originalFileName ?? _getFileNameLocal(_selectedFilePath!),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  _isUploaded
                      ? 'Image Uploaded Successfully'
                      : (_isUploading ? 'Uploading...' : 'Ready to Upload'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _uploadError == null
                      ? (_isUploaded
                            ? 'Your image has been uploaded and is ready for processing.'
                            : 'We will upload your image now.')
                      : 'Upload failed: $_uploadError',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedDocument() {
    final ext = _getFileExtensionLocal(_selectedFilePath!).toUpperCase();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, size: 80, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            'Unsupported File Type',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _originalFileName ?? _getFileNameLocal(_selectedFilePath!),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$ext files cannot be previewed',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600, size: 18),
                const SizedBox(width: 8),
                Text(
                  'File Type Not Supported',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _readTextFile() async {
    try {
      final file = File(_selectedFilePath!);
      return await file.readAsString();
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }

  void _openExternalViewer() {
    if (_selectedFilePath == null) return;

    if (kIsWeb) {
      _openFileOnWeb();
    } else {
      _openFileOnMobile();
    }
  }

  void _openFileOnWeb() {
    if (_selectedFilePath!.startsWith('data:')) {
      // For base64 data URLs, create a download link
      try {
        final parts = _selectedFilePath!.split(',');
        if (parts.length == 2) {
          final mimeType = parts[0].split(':')[1].split(';')[0];
          final base64Data = parts[1];
          final bytes = base64Decode(base64Data);

          // Create a blob URL for download using JavaScript interop
          final blob = js_util.callConstructor(
            js_util.getProperty(web.window, 'Blob'),
            [
              js_util.jsify([bytes]),
              js_util.jsify({'type': mimeType}),
            ],
          );
          final url = web.URL.createObjectURL(blob as web.Blob);

          // Create and trigger download
          final anchor = web.HTMLAnchorElement()
            ..href = url
            ..download = _getFileNameLocal(_selectedFilePath!)
            ..style.display = 'none';

          web.document.body!.append(anchor);
          anchor.click();
          anchor.remove();

          // Clean up the blob URL
          web.URL.revokeObjectURL(url);

          _safeShowSnackBar(
            SnackBar(
              content: Text(
                'File downloaded: ${_getFileNameLocal(_selectedFilePath!)}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        _safeShowSnackBar(
          SnackBar(
            content: const Text('Failed to download file'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // For regular URLs, try to open in new tab
      try {
        final isPdf = _getFileExtensionLocal(_selectedFilePath!) == 'pdf';
        if (isPdf) {
          // Try to open PDF in new tab
          js.context.callMethod('open', [_selectedFilePath!, '_blank']);
        } else {
          // For other files, download
          final anchor = web.HTMLAnchorElement()
            ..href = _selectedFilePath!
            ..download = _getFileNameLocal(_selectedFilePath!)
            ..target = '_blank'
            ..style.display = 'none';

          web.document.body!.append(anchor);
          anchor.click();
          anchor.remove();
        }

        _safeShowSnackBar(
          SnackBar(
            content: Text(
              'Opening ${_getFileNameLocal(_selectedFilePath!)}...',
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        _safeShowSnackBar(
          SnackBar(
            content: const Text('Failed to open file'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openFileOnMobile() {
    // For mobile, we can't directly open files in external apps from Flutter
    // The best we can do is show a helpful message
    _safeShowSnackBar(
      SnackBar(
        content: Text(
          'File "${_getFileNameLocal(_selectedFilePath!)}" is ready. '
          'You can find it in your downloads or use a file manager to open it.',
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showFileDetails() {
    if (_selectedFilePath == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_getFileIconLocal(_selectedFilePath!), color: Colors.blue),
            const SizedBox(width: 8),
            const Text('File Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Label', widget.label),
            _buildDetailRow('Name', _getFileNameLocal(_selectedFilePath!)),
            _buildDetailRow(
              'Type',
              _getFileExtensionLocal(_selectedFilePath!).toUpperCase(),
            ),
            _buildDetailRow('Path', _getUserFriendlyPath(_selectedFilePath!)),
            if (!kIsWeb) ...[
              const SizedBox(height: 8),
              FutureBuilder<int>(
                future: File(_selectedFilePath!).length(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final bytes = snapshot.data!;
                    String size;
                    if (bytes < 1024) {
                      size = '$bytes B';
                    } else if (bytes < 1024 * 1024) {
                      size = '${(bytes / 1024).toStringAsFixed(1)} KB';
                    } else {
                      size = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
                    }
                    return _buildDetailRow('Size', size);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (_isImageFileLocal(_selectedFilePath!) && !kIsWeb)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showFilePreview();
              },
              child: const Text('View Full Size'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  // -------- Local helper methods (no globals!) --------

  String _getFileNameLocal(String path) {
    if (path.startsWith('data:')) {
      // For base64 data URLs, extract filename from original name if available
      if (_originalFileName != null && _originalFileName!.isNotEmpty) {
        return _originalFileName!;
      }
      // Fallback: extract mime type and create a generic name
      final mimeType = path.split(',')[0].split(':')[1].split(';')[0];
      final ext = mimeType.split('/').last;
      return 'uploaded_file.$ext';
    }
    return path.split('/').last;
  }

  String _getUserFriendlyPath(String path) {
    if (path.startsWith('data:')) {
      // For base64 data URLs, show a user-friendly message instead of the raw data
      final mimeType = path.split(',')[0].split(':')[1].split(';')[0];
      return 'Data URL (${mimeType})';
    }
    // For regular file paths, show the path but truncate if too long
    if (path.length > 50) {
      return '${path.substring(0, 20)}...${path.substring(path.length - 20)}';
    }
    return path;
  }

  String _getFileExtensionLocal(String path) {
    if (!path.contains('.')) return 'jpg'; // sensible default for camera photos
    return path.split('.').last.toLowerCase();
  }

  bool _isImageFileLocal(String path) {
    final lower = path.toLowerCase();

    if (lower.startsWith('data:')) {
      final comma = lower.indexOf(',');
      final header = lower.substring(5, comma == -1 ? lower.length : comma);
      final mime = header.split(';').first;
      return mime.startsWith('image/');
    }

    final ext = _getFileExtensionLocal(path);
    const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'};
    return imageExts.contains(ext);
  }

  IconData _getFileIconLocal(String path) {
    final extension = _getFileExtensionLocal(path);
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _mimeFromExtensionLocal(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      default:
        return 'application/octet-stream';
    }
  }
}
