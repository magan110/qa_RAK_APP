import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/upload_service.dart';

// Check if running in InAppWebView context
bool get _isInAppWebView {
  if (kIsWeb) {
    try {
      // InAppWebView sets specific user agent or window properties
      return kIsWeb; // For now, assume all web is potentially InAppWebView
    } catch (e) {
      return false;
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
  final String? formType; // Add form type parameter

  const FileUploadWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.onFileSelected,
    this.delay = Duration.zero,
    this.isRequired = true,
    this.allowedExtensions = const ['*'], // Allow all file types by default
    this.maxSizeInMB = 15.0,
    this.currentFilePath,
    this.formType, // Add form type parameter
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  String? _selectedFilePath;
  String? _originalFileName;
  String? _fileType; // Store the actual file type
  bool _isVisible = false;
  bool _isUploading = false;
  bool _isUploaded = false;
  String? _uploadError;
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;

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
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  bool _isContractorOrPainterForm() {
    return widget.formType == 'contractor' || widget.formType == 'painter';
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
              scale: _scaleAnimation ?? AlwaysStoppedAnimation(1.0),
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
                      style: BorderStyle.solid,
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
                ? '🖼️ Gallery'
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

  Widget _buildSelectedFilePreview() {
    final isImage = _isImageFile(_selectedFilePath!);

    return Column(
      children: [
        // File preview area
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: isImage
                  ? GestureDetector(
                      onTap: () => _showFilePreview(),
                      child: Stack(
                        children: [
                          kIsWeb
                              ? (_selectedFilePath!.startsWith('data:')
                                    ? Image.memory(
                                        base64Decode(
                                          _selectedFilePath!.split(',')[1],
                                        ),
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildFileIconDisplay(),
                                      )
                                    : Image.network(
                                        _selectedFilePath!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildFileIconDisplay(),
                                      ))
                              : Image.file(
                                  File(_selectedFilePath!),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildFileIconDisplay(),
                                ),
                          // Overlay for tap indication
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                          // View icon overlay
                          const Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.black54,
                              child: Icon(
                                Icons.zoom_in,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : GestureDetector(
                      onTap: () => _showFilePreview(),
                      child: _buildFileIconDisplay(),
                    ),
            ),
          ),
        ),

        // File info and actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              // File name and success indicator
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _getFileName(_selectedFilePath!),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showFilePreview(),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showUploadOptions(context),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Change'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: BorderSide(color: Colors.orange.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _removeFile,
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    tooltip: 'Remove file',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileIcon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileIcon(_selectedFilePath!),
            size: 40,
            color: Colors.green.shade600,
          ),
          const SizedBox(height: 8),
          Text(
            _getFileName(_selectedFilePath!),
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFileIconDisplay() {
    return Container(
      color: Colors.grey.shade50,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getFileIcon(_selectedFilePath!),
                  size: 48,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(height: 8),
                Text(
                  _getFileExtension(_selectedFilePath!).toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getFileSize(_selectedFilePath!),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // View icon overlay
          const Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black54,
              child: Icon(Icons.info_outline, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedFileDisplay() {
    final isImage = _isImageFile(_selectedFilePath!);

    return Stack(
      children: [
        // Main file display
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isImage
                ? (kIsWeb
                      ? (_selectedFilePath!.startsWith('data:')
                            ? Image.memory(
                                base64Decode(_selectedFilePath!.split(',')[1]),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFileIconDisplay(),
                              )
                            : Image.network(
                                _selectedFilePath!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFileIconDisplay(),
                              ))
                      : Image.file(
                          File(_selectedFilePath!),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFileIconForUploadArea(),
                        ))
                : _buildFileIconForUploadArea(),
          ),
        ),

        // Overlay with file info and tap indication
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

        // File info overlay
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
              else
                const Icon(Icons.check_circle, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _isUploading
                      ? 'Uploading...'
                      : _uploadError != null
                      ? 'Upload failed'
                      : _getFileName(_selectedFilePath!),
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

        // Tap to view/change indicator
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
              _getFileIcon(_selectedFilePath!),
              size: 32,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 6),
            Text(
              _getFileExtension(_selectedFilePath!).toUpperCase(),
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
                    _getFileName(_selectedFilePath!),
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

                  // View option
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

                  // Retry option (only show if upload failed)
                  if (_uploadError != null) ...[
                    _buildActionOption(
                      icon: Icons.refresh_rounded,
                      title: 'Retry Upload',
                      subtitle: 'Try uploading the file again',
                      onTap: () {
                        Navigator.pop(context);
                        // _retryUpload();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Change option
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

                  // Remove option
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

                  // Show only gallery option for contractor and painter forms
                  if (_isContractorOrPainterForm()) ...[
                    _buildUploadOption(
                      icon: Icons.photo_library_rounded,
                      title: 'Choose from Gallery',
                      subtitle: 'Select from photo library',
                      onTap: () => _pickFromGallery(context),
                    ),
                  ] else ...[
                    // Camera option
                    _buildUploadOption(
                      icon: Icons.camera_alt_rounded,
                      title: 'Take Photo',
                      subtitle: 'Use camera to capture',
                      onTap: () => _pickFromCamera(context),
                    ),
                    const SizedBox(height: 16),

                    // Gallery option
                    _buildUploadOption(
                      icon: Icons.photo_library_rounded,
                      title: 'Choose from Gallery',
                      subtitle: 'Select from photo library',
                      onTap: () => _pickFromGallery(context),
                    ),

                    const SizedBox(height: 16),

                    // Files option
                    _buildUploadOption(
                      icon: Icons.folder_rounded,
                      title: 'Choose from Files',
                      subtitle: 'Select from device storage',
                      onTap: () => _pickFromFiles(context),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // File requirements
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.blue.shade600, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Future<void> _pickFromCamera(BuildContext context) async {
    Navigator.pop(context);

    try {
      // Add timeout for camera access to prevent hanging
      final XFile? image = await _picker
          .pickImage(
            source: ImageSource.camera,
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Camera access timed out. Please try again.');
            },
          );

      if (image != null) {
        print('Camera image captured: ${image.path}');
        print('Image name: ${image.name}');

        try {
          final length = await image.length();
          print('Image length: $length bytes');
        } catch (e) {
          print('Error getting image length: $e');
        }

        // For web, we might need to handle the path differently
        String imagePath = image.path;
        if (kIsWeb &&
            !imagePath.startsWith('blob:') &&
            !imagePath.startsWith('data:')) {
          // On web, image.path might not be a standard file path
          print('Web detected, image path: $imagePath');

          // Try to read the image as bytes and create a data URL
          try {
            final bytes = await image.readAsBytes();
            print('Image bytes length: ${bytes.length}');

            // Create a data URL for web
            final base64String = base64Encode(bytes);
            imagePath = 'data:image/jpeg;base64,$base64String';
            print('Created data URL path for web');
          } catch (e) {
            print('Error creating data URL: $e');
            // Fall back to original path
          }
        }

        await _handleSelectedFile(
          imagePath,
          fileType: 'image',
          originalName: image.name,
        );
      } else {
        print(
          'Camera capture returned null - user cancelled or permission denied',
        );
        // User cancelled or permission denied
        if (kIsWeb) {
          _showErrorSnackBar(
            'Camera access was cancelled. Please try again or use the gallery option.',
          );
        }
      }
    } catch (e) {
      String errorMessage = 'Failed to capture image';

      if (e.toString().contains('timed out')) {
        errorMessage =
            'Camera access timed out. Please try again or use the gallery option.';
      } else if (kIsWeb) {
        if (e.toString().contains('NotAllowedError') ||
            e.toString().contains('Permission denied')) {
          errorMessage =
              'Camera permission denied. Please allow camera access in your browser settings and try again.';
        } else if (e.toString().contains('NotFoundError') ||
            e.toString().contains('No camera found')) {
          errorMessage =
              'No camera found. Please ensure your device has a camera and it\'s not being used by another application.';
        } else if (e.toString().contains('NotSupportedError')) {
          errorMessage =
              'Camera not supported. Please try using the gallery option instead.';
        } else if (e.toString().contains('SecurityError')) {
          errorMessage =
              'Camera access blocked due to security restrictions. Please ensure you\'re using HTTPS and try again.';
        } else {
          errorMessage =
              'Camera access failed. Please try using the gallery option or check your browser permissions.';
        }
      }

      _showErrorSnackBar(errorMessage);

      // Show additional help dialog for web users
      if (kIsWeb && mounted) {
        _showWebCameraHelpDialog();
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

      if (image != null) {
        print('Gallery image selected: ${image.path}');
        print('Image name: ${image.name}');

        // Handle web paths consistently
        String imagePath = image.path;
        if (kIsWeb &&
            !imagePath.startsWith('blob:') &&
            !imagePath.startsWith('data:')) {
          try {
            final bytes = await image.readAsBytes();
            final base64String = base64Encode(bytes);
            imagePath = 'data:image/jpeg;base64,$base64String';
            print('Created data URL path for web gallery image');
          } catch (e) {
            print('Error creating data URL for gallery: $e');
          }
        }

        await _handleSelectedFile(
          imagePath,
          fileType: 'image',
          originalName: image.name,
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select image: $e');
    }
  }

  Future<void> _pickFromFiles(BuildContext context) async {
    Navigator.pop(context);
    try {
      FilePickerResult? result;

      // For web/InAppWebView, be more permissive with file picking
      if (kIsWeb || _isInAppWebView) {
        // Always use FileType.any for web to avoid browser restrictions
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
      } else {
        // For mobile, use the original logic
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

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        String fileType = 'document';

        // Determine file type based on extension
        if (file.extension != null) {
          final ext = file.extension!.toLowerCase();
          if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
            fileType = 'image';
          } else if (['pdf'].contains(ext)) {
            fileType = 'pdf';
          } else if (['txt'].contains(ext)) {
            fileType = 'text';
          } else if (['doc', 'docx'].contains(ext)) {
            fileType = 'word';
          } else if (['xls', 'xlsx'].contains(ext)) {
            fileType = 'excel';
          } else if (['ppt', 'pptx'].contains(ext)) {
            fileType = 'powerpoint';
          }
        }

        await _handleSelectedFile(
          file.path!,
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
    print('_handleSelectedFile called with:');
    print('  filePath: $filePath');
    print('  fileType: $fileType');
    print('  originalName: $originalName');

    // Get file extension (handle cases where there might be no extension)
    String extension = '';
    if (filePath.contains('.')) {
      extension = filePath.split('.').last.toLowerCase();
    } else if (originalName != null && originalName.contains('.')) {
      // Try to get extension from original name
      extension = originalName.split('.').last.toLowerCase();
    }

    print('  extension: $extension');
    print('  allowedExtensions: ${widget.allowedExtensions}');
    print('  originalName: $originalName');

    // Get MIME type for validation
    String mimeType = '';
    if (kIsWeb) {
      // For web, try to determine MIME type from file type or extension
      if (fileType == 'image') {
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          case 'webp':
            mimeType = 'image/webp';
            break;
          case 'bmp':
            mimeType = 'image/bmp';
            break;
        }
      }
    }

    print('  mimeType: $mimeType');

    // Skip validation entirely for web/InAppWebView when dealing with images
    bool skipValidation = false;

    if (kIsWeb || _isInAppWebView) {
      // For web, be very permissive with image uploads
      final isImageContext =
          fileType == 'image' ||
          widget.allowedExtensions.any(
            (ext) => [
              'jpg',
              'jpeg',
              'png',
              'gif',
              'webp',
              'bmp',
            ].contains(ext.toLowerCase()),
          ) ||
          widget.label.toLowerCase().contains('emirates') ||
          widget.label.toLowerCase().contains('id') ||
          widget.label.toLowerCase().contains('photo');

      if (isImageContext) {
        print(
          'Web/InAppWebView context detected - skipping strict validation for image upload',
        );
        print('Label context: ${widget.label}');
        skipValidation = true;
      }
    }

    // Emergency fallback - if we're in web and getting validation errors, skip validation entirely
    if (kIsWeb &&
        widget.allowedExtensions.isNotEmpty &&
        !widget.allowedExtensions.contains('*')) {
      final hasImageExtensions = widget.allowedExtensions.any(
        (ext) => [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'bmp',
        ].contains(ext.toLowerCase()),
      );

      if (hasImageExtensions) {
        print(
          'FALLBACK: Skipping validation for web image upload to prevent blocking',
        );
        skipValidation = true;
      }
    }

    // Only validate extension if allowedExtensions is not empty, doesn't contain '*', and we're not skipping validation
    if (!skipValidation &&
        widget.allowedExtensions.isNotEmpty &&
        !widget.allowedExtensions.contains('*') &&
        extension.isNotEmpty) {
      // Make extension validation case-insensitive and flexible
      final normalizedExtensions = widget.allowedExtensions
          .map((ext) => ext.toLowerCase())
          .toList();

      // Common image format aliases
      final imageAliases = {
        'jpeg': 'jpg',
        'jpg': 'jpeg',
        'jfif': 'jpg',
        'webp': 'jpg',
      };

      bool isAllowed = normalizedExtensions.contains(extension);

      // Check aliases
      if (!isAllowed && imageAliases.containsKey(extension)) {
        final alias = imageAliases[extension]!;
        isAllowed = normalizedExtensions.contains(alias);
      }

      // For camera-captured images without proper extensions, check if images are allowed
      if (!isAllowed && extension.isEmpty && fileType == 'image') {
        isAllowed = normalizedExtensions.any(
          (ext) => ['jpg', 'jpeg', 'png'].contains(ext),
        );
      }

      // Extra permissive check for web MIME types
      if (!isAllowed && kIsWeb && mimeType.isNotEmpty) {
        final imageMimeTypes = [
          'image/jpeg',
          'image/jpg',
          'image/png',
          'image/gif',
          'image/webp',
          'image/bmp',
        ];
        if (imageMimeTypes.contains(mimeType.toLowerCase()) &&
            normalizedExtensions.any(
              (ext) =>
                  ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext),
            )) {
          print('Allowing based on MIME type match: $mimeType');
          isAllowed = true;
        }
      }

      if (!isAllowed) {
        print(
          'Extension validation failed: $extension not in $normalizedExtensions',
        );
        print('MIME type: $mimeType');
        print('File type: $fileType');
        _showErrorSnackBar(
          'Invalid file type. Allowed: ${widget.allowedExtensions.join(', ').toUpperCase()}',
        );
        return;
      }
    }

    if (skipValidation) {
      print('Validation skipped for web/InAppWebView image upload');
    }

    // Validate file size
    if (!kIsWeb) {
      try {
        final file = File(filePath);
        final sizeInBytes = await file.length();
        final sizeInMB = sizeInBytes / (1024 * 1024);

        if (sizeInMB > widget.maxSizeInMB) {
          _showErrorSnackBar(
            'File too large. Maximum size: ${widget.maxSizeInMB}MB',
          );
          return;
        }
      } catch (e) {
        // Handle file size check error - continue anyway
        print('Error checking file size: $e');
      }
    }

    print('File validation passed, updating state...');

    setState(() {
      _selectedFilePath = filePath;
      _fileType = fileType;
      _originalFileName = originalName;
      _isUploading = false; // Don't show uploading indicator
      _isUploaded = true; // Mark as uploaded immediately
      _uploadError = null;
    });

    print('File selected successfully, calling onFileSelected callback...');
    widget.onFileSelected(filePath);

    // Show success message for gallery uploads in contractor/painter forms
    if (_isContractorOrPainterForm()) {
      _showSuccessSnackBar('${widget.label} selected successfully');
    }

    // Upload functionality is disabled for now
    // try {
    //   final uploadResult = await UploadService.uploadFile(
    //     filePath,
    //     originalName: originalName,
    //   );

    //   if (uploadResult['success']) {
    //     setState(() {
    //       _isUploading = false;
    //       _isUploaded = true;
    //     });

    //     print('Upload successful, calling onFileSelected callback...');
    //     widget.onFileSelected(filePath);
    //     _showSuccessSnackBar('${widget.label} uploaded successfully');
    //   } else {
    //     setState(() {
    //       _isUploading = false;
    //       _uploadError = uploadResult['error'];
    //     });
    //     _showErrorSnackBar('Upload failed: ${uploadResult['error']}');
    //   }
    // } catch (e) {
    //   setState(() {
    //     _isUploading = false;
    //     _uploadError = e.toString();
    //   });
    //   _showErrorSnackBar('Upload failed: $e');
    // }
  }

  // Future<void> _retryUpload() async {
  //   if (_selectedFilePath == null) return;

  //   setState(() {
  //     _isUploading = true;
  //     _uploadError = null;
  //   });

  //   try {
  //     final uploadResult = await UploadService.uploadFile(
  //       _selectedFilePath!,
  //       originalName: _originalFileName,
  //     );

  //     if (uploadResult['success']) {
  //       setState(() {
  //         _isUploading = false;
  //         _isUploaded = true;
  //       });
  //       _showSuccessSnackBar('${widget.label} uploaded successfully');
  //     } else {
  //       setState(() {
  //         _isUploading = false;
  //         _uploadError = uploadResult['error'];
  //       });
  //       _showErrorSnackBar('Upload failed: ${uploadResult['error']}');
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _isUploading = false;
  //       _uploadError = e.toString();
  //     });
  //     _showErrorSnackBar('Upload failed: $e');
  //   }
  // }

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
          'Are you sure you want to remove "${_getFileName(_selectedFilePath!)}"?',
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(message),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 5),
          action: message.toLowerCase().contains('camera')
              ? SnackBarAction(
                  label: 'Try Gallery',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    _pickFromGallery(context);
                  },
                )
              : null,
        ),
      );
    }
  }

  void _showWebCameraHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Camera Access Help'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To use the camera feature in your browser:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text('1. Ensure you\'re using HTTPS (secure connection)'),
            const SizedBox(height: 8),
            const Text('2. Allow camera permissions when prompted'),
            const SizedBox(height: 8),
            const Text('3. Check that no other app is using your camera'),
            const SizedBox(height: 8),
            const Text(
              '4. Try refreshing the page and allowing permissions again',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You can also use "Choose from Gallery" as an alternative.',
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
            child: const Text('Got it'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showUploadOptions(context);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  bool _isImageFile(String path) {
    // First check if we have stored file type information
    if (_fileType != null) {
      return _fileType == 'image';
    }

    // Fallback to extension-based detection
    if (!path.contains('.')) {
      // For files without extension (like camera photos), assume it's an image
      return true;
    }

    final extension = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  void _showFilePreview() {
    if (_selectedFilePath == null) return;

    final isImage = _isImageFile(_selectedFilePath!);

    if (isImage) {
      // Show full-screen image viewer for both web and mobile
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
                  onPressed: () => _showFileDetails(),
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
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error,
                                          size: 64,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Unable to load image',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                            )
                          : Image.network(
                              _selectedFilePath!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error,
                                          size: 64,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Unable to load image',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                            ))
                    : Image.file(
                        File(_selectedFilePath!),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Unable to load image',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                      ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Show document viewer
      _showDocumentViewer();
    }
  }

  void _showDocumentViewer() {
    if (_selectedFilePath == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(widget.label),
            actions: [
              IconButton(
                onPressed: () => _showFileDetails(),
                icon: const Icon(Icons.info_outline),
                tooltip: 'File Details',
              ),
            ],
          ),
          body: _buildDocumentContent(),
        ),
      ),
    );
  }

  Widget _buildDocumentContent() {
    // Use stored file type if available, otherwise fall back to extension
    String fileType = _fileType ?? 'unknown';

    if (fileType == 'unknown') {
      final extension = _getFileExtension(_selectedFilePath!);
      if (['pdf'].contains(extension)) {
        fileType = 'pdf';
      } else if (['txt'].contains(extension)) {
        fileType = 'text';
      } else if (['doc', 'docx'].contains(extension)) {
        fileType = 'word';
      } else if (['xls', 'xlsx'].contains(extension)) {
        fileType = 'excel';
      } else if (['ppt', 'pptx'].contains(extension)) {
        fileType = 'powerpoint';
      }
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, size: 80, color: Colors.red.shade600),
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
            _getFileName(_selectedFilePath!),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openExternalViewer(),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open with External App'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
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
            _getFileIcon(_selectedFilePath!),
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
            _getFileName(_selectedFilePath!),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openExternalViewer(),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open with External App'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  _originalFileName ?? _getFileName(_selectedFilePath!),
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
                const Text(
                  'Image Uploaded Successfully',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your image has been uploaded and is ready for processing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedDocument() {
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
            _originalFileName ?? _getFileName(_selectedFilePath!),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${_getFileExtension(_selectedFilePath!).toUpperCase()} files cannot be previewed',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openExternalViewer(),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open with External App'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening ${_getFileName(_selectedFilePath!)} with external app...',
        ),
        backgroundColor: Colors.blue,
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
            Icon(_getFileIcon(_selectedFilePath!), color: Colors.blue),
            const SizedBox(width: 8),
            const Text('File Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Label', widget.label),
            _buildDetailRow('Name', _getFileName(_selectedFilePath!)),
            _buildDetailRow(
              'Type',
              _getFileExtension(_selectedFilePath!).toUpperCase(),
            ),
            _buildDetailRow('Path', _selectedFilePath!),
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
          if (_isImageFile(_selectedFilePath!) && !kIsWeb)
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

  String _getFileExtension(String path) {
    if (!path.contains('.')) {
      // For files without extension (like camera photos), assume it's an image
      return 'jpg';
    }
    return path.split('.').last.toLowerCase();
  }

  String _getFileSize(String path) {
    if (kIsWeb) return 'Unknown size';

    try {
      final file = File(path);
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Unknown size';
    }
  }

  IconData _getFileIcon(String path) {
    final extension = path.split('.').last.toLowerCase();
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
}
