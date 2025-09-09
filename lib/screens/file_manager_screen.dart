import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rak_web/core/widgets/custom_back_button.dart';
import 'package:rak_web/core/widgets/uploaded_files_gallery.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Sample uploaded files data - in a real app, this would come from a state management solution
  final Map<String, String?> _contractorFiles = {
    'Profile Photo': '/path/to/contractor_photo.jpg',
    'Emirates ID': '/path/to/contractor_emirates_id.pdf',
    'Commercial License': '/path/to/contractor_license.pdf',
    'VAT Certificate': '/path/to/contractor_vat.pdf',
  };

  final Map<String, String?> _painterFiles = {
    'Profile Photo': '/path/to/painter_photo.jpg',
    'Emirates ID': '/path/to/painter_emirates_id.pdf',
    'Cheque Book': '/path/to/painter_cheque.pdf',
  };

  final Map<String, String?> _demoFiles = {
    'ID Document': '/path/to/demo_id.jpg',
    'Certificate': '/path/to/demo_certificate.pdf',
  };

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
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

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
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
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.indigo.shade50,
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 30),

                  // File Statistics
                  _buildFileStatistics(),
                  const SizedBox(height: 30),

                  // Contractor Files
                  UploadedFilesGallery(
                    uploadedFiles: _contractorFiles,
                    title: 'Contractor Registration Files',
                    icon: Icons.business_rounded,
                    onFileChanged: (key, filePath) {
                      setState(() {
                        _contractorFiles[key] = filePath;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // Painter Files
                  UploadedFilesGallery(
                    uploadedFiles: _painterFiles,
                    title: 'Painter Registration Files',
                    icon: Icons.format_paint_rounded,
                    onFileChanged: (key, filePath) {
                      setState(() {
                        _painterFiles[key] = filePath;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // Demo Files
                  UploadedFilesGallery(
                    uploadedFiles: _demoFiles,
                    title: 'Demo Upload Files',
                    icon: Icons.science_rounded,
                    onFileChanged: (key, filePath) {
                      setState(() {
                        _demoFiles[key] = filePath;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  // Action Buttons
                  _buildActionButtons(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.indigo.shade800,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      leading: Navigator.of(context).canPop()
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomBackButton(animated: false, size: 36),
            )
          : null,
      title: const Text(
        'File Manager',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      actions: [
        IconButton(
          onPressed: _showFileSearch,
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Search Files',
        ),
        IconButton(
          onPressed: _showFileOptions,
          icon: const Icon(Icons.more_vert_rounded),
          tooltip: 'More Options',
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade700, Colors.indigo.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.2),
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
                    const Text(
                      'File Manager',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'View, manage, and organize all uploaded files',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildFeatureChip('📁 Organize'),
                        const SizedBox(width: 8),
                        _buildFeatureChip('👁️ Preview'),
                        const SizedBox(width: 8),
                        _buildFeatureChip('🗑️ Manage'),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFileStatistics() {
    final totalFiles = _getTotalFileCount();
    final filesByType = _getFilesByType();

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Colors.indigo),
              const SizedBox(width: 12),
              const Text(
                'File Statistics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Files',
                  totalFiles.toString(),
                  Icons.folder_rounded,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Images',
                  filesByType['images'].toString(),
                  Icons.image_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Documents',
                  filesByType['documents'].toString(),
                  Icons.description_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _exportAllFiles,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Export All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearAllFiles,
            icon: const Icon(Icons.clear_all_rounded, color: Colors.red),
            label: const Text('Clear All', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _getTotalFileCount() {
    int count = 0;
    count += _contractorFiles.values.where((v) => v != null).length;
    count += _painterFiles.values.where((v) => v != null).length;
    count += _demoFiles.values.where((v) => v != null).length;
    return count;
  }

  Map<String, int> _getFilesByType() {
    int images = 0;
    int documents = 0;

    final allFiles = [
      ..._contractorFiles.values,
      ..._painterFiles.values,
      ..._demoFiles.values,
    ].where((f) => f != null).cast<String>();

    for (final file in allFiles) {
      final extension = file.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
        images++;
      } else {
        documents++;
      }
    }

    return {'images': images, 'documents': documents};
  }

  void _showFileSearch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.search_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Search Files'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by filename or type...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Search functionality would be implemented here'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFileOptions() {
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
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'File Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sort_rounded),
              title: const Text('Sort Files'),
              onTap: () {
                Navigator.pop(context);
                _showSortOptions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_list_rounded),
              title: const Text('Filter Files'),
              onTap: () {
                Navigator.pop(context);
                _showFilterOptions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _showSettings();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    // Implementation for sort options
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sort options would be implemented here')),
    );
  }

  void _showFilterOptions() {
    // Implementation for filter options
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter options would be implemented here')),
    );
  }

  void _showSettings() {
    // Implementation for settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings would be implemented here')),
    );
  }

  void _exportAllFiles() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Export All Files'),
          ],
        ),
        content: const Text(
          'This would export all uploaded files to a zip archive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Files exported successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _clearAllFiles() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Clear All Files'),
          ],
        ),
        content: const Text(
          'Are you sure you want to clear all uploaded files? This action cannot be undone.',
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
                _contractorFiles.updateAll((key, value) => null);
                _painterFiles.updateAll((key, value) => null);
                _demoFiles.updateAll((key, value) => null);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All files cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
