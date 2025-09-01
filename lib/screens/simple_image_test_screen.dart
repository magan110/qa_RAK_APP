import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class SimpleImageTestScreen extends StatefulWidget {
  const SimpleImageTestScreen({super.key});

  @override
  State<SimpleImageTestScreen> createState() => _SimpleImageTestScreenState();
}

class _SimpleImageTestScreenState extends State<SimpleImageTestScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String _debugInfo = '';

  void _updateDebugInfo(String info) {
    setState(() {
      _debugInfo += '$info\n';
    });
    print(info);
  }

  Future<void> _testImagePicker() async {
    try {
      _updateDebugInfo('=== TESTING IMAGE PICKER ===');

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        _updateDebugInfo('✅ Image picked successfully');
        _updateDebugInfo('Path: ${image.path}');
        _updateDebugInfo('Name: ${image.name}');
        _updateDebugInfo('MIME: ${image.mimeType ?? "null"}');

        // Check if file exists
        final file = File(image.path);
        final exists = await file.exists();
        _updateDebugInfo('File exists: $exists');

        if (exists) {
          final size = await file.length();
          _updateDebugInfo('File size: $size bytes');

          setState(() {
            _selectedImage = image;
          });
          _updateDebugInfo('✅ All checks passed - no validation errors!');
        } else {
          _updateDebugInfo('❌ File does not exist at path');
        }
      } else {
        _updateDebugInfo('❌ No image selected');
      }
    } catch (e) {
      _updateDebugInfo('❌ Error in image picker: $e');
    }
  }

  Future<void> _testFilePicker() async {
    try {
      _updateDebugInfo('=== TESTING FILE PICKER ===');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        _updateDebugInfo('✅ File picked successfully');
        _updateDebugInfo('Name: ${file.name}');
        _updateDebugInfo('Path: ${file.path ?? "null"}');
        _updateDebugInfo('Size: ${file.size} bytes');
        _updateDebugInfo('Extension: ${file.extension ?? "null"}');

        if (file.path != null) {
          final fileObj = File(file.path!);
          final exists = await fileObj.exists();
          _updateDebugInfo('File exists: $exists');

          if (exists) {
            final xFile = XFile(file.path!);
            setState(() {
              _selectedImage = xFile;
            });
            _updateDebugInfo('✅ All checks passed - no validation errors!');
          }
        }
      } else {
        _updateDebugInfo('❌ No file selected');
      }
    } catch (e) {
      _updateDebugInfo('❌ Error in file picker: $e');
    }
  }

  void _clearDebug() {
    setState(() {
      _debugInfo = '';
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Upload Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Simple Image Upload Test (No Validation)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testImagePicker,
                    child: const Text('Test Image Picker'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testFilePicker,
                    child: const Text('Test File Picker'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _clearDebug,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear', style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 20),

            if (_selectedImage != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_selectedImage!.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(child: Text('Error loading image: $error'));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo.isEmpty
                        ? 'Debug information will appear here...'
                        : _debugInfo,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
