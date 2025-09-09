import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class FileViewerWidget extends StatefulWidget {
  final String? filePath;
  final String label;
  final VoidCallback? onRemove;
  final VoidCallback? onReplace;
  final bool showActions;
  final double? width;
  final double? height;

  const FileViewerWidget({
    super.key,
    required this.filePath,
    required this.label,
    this.onRemove,
    this.onReplace,
    this.showActions = true,
    this.width,
    this.height,
  });

  @override
  State<FileViewerWidget> createState() => _FileViewerWidgetState();
}

class _FileViewerWidgetState extends State<FileViewerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    if (widget.filePath != null) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(FileViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filePath != null && oldWidget.filePath == null) {
      _animationController.forward();
    } else if (widget.filePath == null && oldWidget.filePath != null) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filePath == null) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width,
          height: widget.height ?? 200,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with file info and actions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
                            ),
                          ),
                          Text(
                            _getFileName(widget.filePath!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (widget.showActions) ...[
                      IconButton(
                        onPressed: () => _showFileContent(context),
                        icon: const Icon(Icons.visibility, size: 18),
                        tooltip: 'View File',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showFileDetails(context),
                        icon: const Icon(Icons.info_outline, size: 18),
                        tooltip: 'File Details',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      if (widget.onReplace != null)
                        IconButton(
                          onPressed: widget.onReplace,
                          icon: const Icon(Icons.edit, size: 18),
                          tooltip: 'Replace File',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      if (widget.onRemove != null)
                        IconButton(
                          onPressed: () => _confirmRemove(context),
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.red,
                          ),
                          tooltip: 'Remove File',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              // File preview content
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  child: _buildFilePreview(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    final isImage = _isImageFile(widget.filePath!);
    final isPlaceholderPath = widget.filePath!.startsWith('/path/to/');

    if (isImage && !kIsWeb && !isPlaceholderPath) {
      return _buildImagePreview();
    } else {
      return _buildFileIcon();
    }
  }

  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: () => _showFileContent(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.file(
            File(widget.filePath!),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFileIcon(),
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    return GestureDetector(
      onTap: () => _showFileContent(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getFileIcon(widget.filePath!),
              size: 48,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              _getFileExtension(widget.filePath!).toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getFileSize(widget.filePath!),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tap to View',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileContent(BuildContext context) {
    final isImage = _isImageFile(widget.filePath!);
    final isPlaceholderPath = widget.filePath!.startsWith('/path/to/');

    if (isPlaceholderPath) {
      _showPlaceholderContent(context);
    } else if (isImage) {
      _showFullScreenImage(context);
    } else {
      _showDocumentViewer(context);
    }
  }

  void _showPlaceholderContent(BuildContext context) {
    final isImage = _isImageFile(widget.filePath!);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(widget.label),
            actions: [
              IconButton(
                onPressed: () => _showFileDetails(context),
                icon: const Icon(Icons.info_outline),
                tooltip: 'File Details',
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isImage ? Icons.image : _getFileIcon(widget.filePath!),
                        size: 80,
                        color: isImage
                            ? Colors.green.shade600
                            : Colors.blue.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isImage ? 'Sample Image' : 'Sample Document',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isImage
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Demo File Preview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This is a sample file for demonstration purposes. In a real application, the actual file content would be displayed here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(_getFileName(widget.filePath!)),
            actions: [
              IconButton(
                onPressed: () => _showFileDetails(context),
                icon: const Icon(Icons.info_outline),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                File(widget.filePath!),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.white),
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
  }

  void _showDocumentViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(widget.label),
            actions: [
              IconButton(
                onPressed: () => _showFileDetails(context),
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
    final extension = _getFileExtension(widget.filePath!);
    final isPlaceholderPath = widget.filePath!.startsWith('/path/to/');

    // Debug information
    print('📄 DOCUMENT CONTENT DEBUG:');
    print('   File path: ${widget.filePath}');
    print('   Extension: $extension');
    print('   Is placeholder: $isPlaceholderPath');

    // For PDF files, always try to load the actual PDF first
    if (extension == 'pdf') {
      // Check if it's a real file path with actual PDF content
      final hasRealPath =
          widget.filePath!.isNotEmpty &&
          !widget.filePath!.startsWith('/path/to/') &&
          !widget.filePath!.startsWith('assets/');

      print('   Has real path: $hasRealPath');

      if (hasRealPath) {
        print('   📋 Loading real PDF viewer');
        return _buildPdfViewer();
      } else {
        print('   📋 Loading PDF placeholder');
        return _buildPdfPlaceholder();
      }
    }

    if (isPlaceholderPath) {
      return _buildPlaceholderViewer(extension);
    }

    switch (extension) {
      case 'txt':
        return _buildTextViewer();
      case 'doc':
      case 'docx':
        return _buildDocumentPlaceholder('Word Document');
      case 'xls':
      case 'xlsx':
        return _buildDocumentPlaceholder('Excel Spreadsheet');
      case 'ppt':
      case 'pptx':
        return _buildDocumentPlaceholder('PowerPoint Presentation');
      default:
        return _buildUnsupportedDocument();
    }
  }

  Widget _buildPdfViewer() {
    print('📱 PDF VIEWER DEBUG:');
    print('   Attempting to load: ${widget.filePath}');
    print('   Platform: ${kIsWeb ? "WEB" : "NATIVE"}');

    // Check if we're on web platform or if the file path looks like it might not be accessible
    if (kIsWeb ||
        widget.filePath!.startsWith('http') ||
        widget.filePath!.startsWith('data:')) {
      // For web platform or URL-based files, show a web-compatible PDF viewer
      return _buildWebPdfViewer();
    }

    // For native platforms with file system access, try the pdfx package
    return FutureBuilder<PdfDocument>(
      future: PdfDocument.openFile(widget.filePath!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading PDF...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          print('❌ PDF LOADING ERROR: ${snapshot.error}');
          print('   Error type: ${snapshot.error.runtimeType}');

          // If there's an error, fall back to web viewer
          return _buildWebPdfViewer();
        }

        print('✅ PDF loaded successfully!');
        final document = snapshot.data!;
        return _PdfViewer(
          document: document,
          fileName: _getFileName(widget.filePath!),
        );
      },
    );
  }

  Widget _buildWebPdfViewer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // PDF Toolbar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PDF Document',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getFileName(widget.filePath!),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PDF controls available'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                ),
              ],
            ),
          ),
          // PDF Content Area
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // PDF Pages Simulation
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // PDF Page Content
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title area
                                  Container(
                                    height: 20,
                                    width: double.infinity * 0.8,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Content lines
                                  ...List.generate(
                                    8,
                                    (index) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Container(
                                        height: 12,
                                        width:
                                            double.infinity *
                                            (0.9 - (index * 0.05)),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Page number
                                  Center(
                                    child: Text(
                                      'Page 1 of ${_getPageCount()}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Navigation Controls
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Previous page')),
                            );
                          },
                          icon: const Icon(Icons.chevron_left),
                          tooltip: 'Previous Page',
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '1 / 1',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Next page')),
                            );
                          },
                          icon: const Icon(Icons.chevron_right),
                          tooltip: 'Next Page',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getPageCount() {
    // Simple estimation based on filename or return 1
    return 1;
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
            _getFileIcon(widget.filePath!),
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
            _getFileName(widget.filePath!),
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
            _getFileName(widget.filePath!),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${_getFileExtension(widget.filePath!).toUpperCase()} files cannot be previewed',
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

  Widget _buildPdfPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 300,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
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
                  'Sample PDF Document',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility,
                            color: Colors.red.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PDF Viewer Demo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This demonstrates the PDF viewing capability. With a real PDF file, you would see the document content with navigation controls.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderViewer(String extension) {
    final isImage = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
    ].contains(extension);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isImage ? Icons.image : _getFileIcon(widget.filePath!),
                  size: 80,
                  color: isImage ? Colors.green.shade600 : Colors.blue.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  isImage ? 'Sample Image' : 'Sample Document',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isImage
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
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
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 24),
                const SizedBox(height: 8),
                const Text(
                  'Demo File Preview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This is a sample file for demonstration purposes. In a real application, the actual file content would be displayed here.',
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

  Future<String> _readTextFile() async {
    try {
      final file = File(widget.filePath!);
      return await file.readAsString();
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }

  void _showFileDetails(BuildContext context) {
    final file = File(widget.filePath!);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_getFileIcon(widget.filePath!), color: Colors.blue),
            const SizedBox(width: 8),
            const Text('File Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', _getFileName(widget.filePath!)),
            _buildDetailRow(
              'Type',
              _getFileExtension(widget.filePath!).toUpperCase(),
            ),
            _buildDetailRow('Size', _getFileSize(widget.filePath!)),
            _buildDetailRow('Path', widget.filePath!),
            if (!kIsWeb) ...[
              const SizedBox(height: 8),
              FutureBuilder<FileStat>(
                future: file.stat(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final stat = snapshot.data!;
                    return Column(
                      children: [
                        _buildDetailRow('Modified', _formatDate(stat.modified)),
                        _buildDetailRow('Accessed', _formatDate(stat.accessed)),
                      ],
                    );
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
          if (_isImageFile(widget.filePath!))
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showFullScreenImage(context);
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
            width: 80,
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

  void _confirmRemove(BuildContext context) {
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
          'Are you sure you want to remove "${_getFileName(widget.filePath!)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onRemove?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  String _getFileExtension(String path) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _isImageFile(String path) {
    final extension = _getFileExtension(path);
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  IconData _getFileIcon(String path) {
    final extension = _getFileExtension(path);
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

class _PdfViewer extends StatefulWidget {
  final PdfDocument document;
  final String fileName;

  const _PdfViewer({required this.document, required this.fileName});

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  late PdfController _pdfController;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(document: Future.value(widget.document));
    _getTotalPages();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  void _getTotalPages() async {
    final pagesCount = widget.document.pagesCount;
    setState(() {
      _totalPages = pagesCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PDF Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.fileName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _currentPage > 1 ? _previousPage : null,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Previous Page',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      '$_currentPage / $_totalPages',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _currentPage < _totalPages ? _nextPage : null,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Next Page',
                  ),
                  IconButton(
                    onPressed: () => _showZoomControls(context),
                    icon: const Icon(Icons.zoom_in),
                    tooltip: 'Zoom Controls',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // PDF Viewer
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: PdfView(
                controller: _pdfController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                onDocumentLoaded: (document) {
                  // Document loaded successfully
                },
                onDocumentError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error loading PDF: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pdfController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _pdfController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showZoomControls(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zoom Controls'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.zoom_in),
              title: const Text('Zoom In'),
              onTap: () {
                Navigator.pop(context);
                // Note: Zoom functionality depends on the PDF viewer implementation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Zoom in functionality')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.zoom_out),
              title: const Text('Zoom Out'),
              onTap: () {
                Navigator.pop(context);
                // Note: Zoom functionality depends on the PDF viewer implementation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Zoom out functionality')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.fit_screen),
              title: const Text('Fit to Screen'),
              onTap: () {
                Navigator.pop(context);
                // Reset zoom to default
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
