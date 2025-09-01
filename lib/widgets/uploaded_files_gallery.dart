import 'dart:io';
import 'package:flutter/material.dart';
import 'file_viewer_widget.dart';

class UploadedFilesGallery extends StatefulWidget {
  final Map<String, String?> uploadedFiles;
  final Function(String key, String? filePath)? onFileChanged;
  final bool showActions;
  final String title;
  final IconData icon;

  const UploadedFilesGallery({
    super.key,
    required this.uploadedFiles,
    this.onFileChanged,
    this.showActions = true,
    this.title = 'Uploaded Files',
    this.icon = Icons.folder_rounded,
  });

  @override
  State<UploadedFilesGallery> createState() => _UploadedFilesGalleryState();
}

class _UploadedFilesGalleryState extends State<UploadedFilesGallery>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadedEntries = widget.uploadedFiles.entries
        .where((entry) => entry.value != null)
        .toList();

    if (uploadedEntries.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          Text(
                            '${uploadedEntries.length} file${uploadedEntries.length != 1 ? 's' : ''} uploaded',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.showActions)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.blue.shade600),
                        onSelected: (value) {
                          switch (value) {
                            case 'clear_all':
                              _confirmClearAll();
                              break;
                            case 'view_details':
                              _showAllFileDetails();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view_details',
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 18),
                                SizedBox(width: 8),
                                Text('View All Details'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'clear_all',
                            child: Row(
                              children: [
                                Icon(Icons.clear_all, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Clear All Files', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Files Grid
              Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: uploadedEntries.length,
                      itemBuilder: (context, index) {
                        final entry = uploadedEntries[index];
                        return _buildFileCard(entry.key, entry.value!);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Files Uploaded',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload files using the forms above to see them here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(String label, String filePath) {
    return FileViewerWidget(
      filePath: filePath,
      label: label,
      showActions: widget.showActions,
      onRemove: widget.showActions
          ? () => widget.onFileChanged?.call(label, null)
          : null,
      onReplace: widget.showActions
          ? () => _showReplaceOptions(label)
          : null,
    );
  }

  void _showReplaceOptions(String label) {
    // This would typically trigger the file upload widget again
    // For now, we'll show a placeholder dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Replace $label'),
          ],
        ),
        content: const Text('This would open the file upload options to replace the current file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Here you would typically call the upload widget
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Replace functionality for $label would be triggered here'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Clear All Files'),
          ],
        ),
        content: const Text('Are you sure you want to remove all uploaded files? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllFiles();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _clearAllFiles() {
    if (widget.onFileChanged != null) {
      for (final key in widget.uploadedFiles.keys) {
        widget.onFileChanged!(key, null);
      }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('All files cleared successfully'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAllFileDetails() {
    final uploadedEntries = widget.uploadedFiles.entries
        .where((entry) => entry.value != null)
        .toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'All File Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: uploadedEntries.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final entry = uploadedEntries[index];
                    return _buildFileDetailTile(entry.key, entry.value!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileDetailTile(String label, String filePath) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Icon(
          _getFileIcon(filePath),
          color: Colors.blue.shade700,
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getFileName(filePath)),
          Text(
            '${_getFileExtension(filePath).toUpperCase()} • ${_getFileSize(filePath)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              // Show individual file content
              _showIndividualFileDetails(label, filePath);
            },
            icon: const Icon(Icons.visibility, size: 18),
            tooltip: 'View File',
          ),
          if (widget.showActions)
            IconButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onFileChanged?.call(label, null);
              },
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              tooltip: 'Remove',
            ),
        ],
      ),
    );
  }

  void _showIndividualFileDetails(String label, String filePath) {
    _showFileContent(context, label, filePath);
  }

  void _showFileContent(BuildContext context, String label, String filePath) {
    final isImage = _isImageFile(filePath);
    
    if (isImage) {
      _showFullScreenImage(context, label, filePath);
    } else {
      _showDocumentViewer(context, label, filePath);
    }
  }

  void _showFullScreenImage(BuildContext context, String label, String filePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(label),
            actions: [
              IconButton(
                onPressed: () => _showFileDetailsDialog(context, label, filePath),
                icon: const Icon(Icons.info_outline),
                tooltip: 'File Details',
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                File(filePath),
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

  void _showDocumentViewer(BuildContext context, String label, String filePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(label),
            actions: [
              IconButton(
                onPressed: () => _showFileDetailsDialog(context, label, filePath),
                icon: const Icon(Icons.info_outline),
                tooltip: 'File Details',
              ),
            ],
          ),
          body: _buildDocumentContent(filePath),
        ),
      ),
    );
  }

  Widget _buildDocumentContent(String filePath) {
    final extension = _getFileExtension(filePath);
    
    switch (extension) {
      case 'pdf':
        return _buildPdfViewer(filePath);
      case 'txt':
        return _buildTextViewer(filePath);
      case 'doc':
      case 'docx':
        return _buildDocumentPlaceholder(filePath, 'Word Document');
      case 'xls':
      case 'xlsx':
        return _buildDocumentPlaceholder(filePath, 'Excel Spreadsheet');
      case 'ppt':
      case 'pptx':
        return _buildDocumentPlaceholder(filePath, 'PowerPoint Presentation');
      default:
        return _buildUnsupportedDocument(filePath);
    }
  }

  Widget _buildPdfViewer(String filePath) {
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
            _getFileName(filePath),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openExternalViewer(filePath),
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

  Widget _buildTextViewer(String filePath) {
    return FutureBuilder<String>(
      future: _readTextFile(filePath),
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
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentPlaceholder(String filePath, String documentType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileIcon(filePath),
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
            _getFileName(filePath),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openExternalViewer(filePath),
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

  Widget _buildUnsupportedDocument(String filePath) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 80,
            color: Colors.grey.shade600,
          ),
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
            _getFileName(filePath),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${_getFileExtension(filePath).toUpperCase()} files cannot be previewed',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openExternalViewer(filePath),
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

  Future<String> _readTextFile(String filePath) async {
    try {
      final file = File(filePath);
      return await file.readAsString();
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }

  void _openExternalViewer(String filePath) {
    // This would typically use url_launcher or similar to open the file
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${_getFileName(filePath)} with external app...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showFileDetailsDialog(BuildContext context, String label, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_getFileIcon(filePath), color: Colors.blue),
            const SizedBox(width: 8),
            const Text('File Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', _getFileName(filePath)),
            _buildDetailRow('Type', _getFileExtension(filePath).toUpperCase()),
            _buildDetailRow('Size', _getFileSize(filePath)),
            _buildDetailRow('Path', filePath),
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

  bool _isImageFile(String path) {
    final extension = _getFileExtension(path);
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  int _getCrossAxisCount(double width) {
    if (width < 600) return 1; // Mobile
    if (width < 900) return 2; // Tablet
    return 3; // Desktop
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  String _getFileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }

  String _getFileSize(String path) {
    // This is a simplified version - in real app you'd get actual file size
    return '2.5 MB'; // Placeholder
  }

  IconData _getFileIcon(String path) {
    final extension = _getFileExtension(path);
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}