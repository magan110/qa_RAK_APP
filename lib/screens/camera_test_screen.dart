import 'package:flutter/material.dart';
import '../widgets/file_upload_widget.dart';

class CameraTestScreen extends StatefulWidget {
  const CameraTestScreen({super.key});

  @override
  State<CameraTestScreen> createState() => _CameraTestScreenState();
}

class _CameraTestScreenState extends State<CameraTestScreen> {
  String? _uploadedFilePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Upload Test'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Camera Upload Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Test the camera upload functionality. This should allow you to take photos or select from gallery.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            FileUploadWidget(
              label: 'Test Photo Upload',
              icon: Icons.camera_alt,
              onFileSelected: (filePath) {
                print(
                  'CameraTestScreen: onFileSelected called with: $filePath',
                );

                setState(() {
                  _uploadedFilePath = filePath;
                });

                if (filePath != null) {
                  print('CameraTestScreen: File path received: $filePath');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'File uploaded successfully: ${filePath.split('/').last}',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } else {
                  print('CameraTestScreen: File path is null');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File upload cancelled or failed'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              },
              currentFilePath: _uploadedFilePath,
              allowedExtensions: const ['*'], // Allow all file types
              maxSizeInMB: 10.0, // Generous size limit
            ),

            const SizedBox(height: 32),

            if (_uploadedFilePath != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'Upload Successful!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'File: ${_uploadedFilePath!.split('/').last}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Path: $_uploadedFilePath',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Troubleshooting Tips',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• Ensure camera permissions are allowed'),
                  const Text('• Use HTTPS for web browsers'),
                  const Text('• Try gallery option if camera fails'),
                  const Text('• Check if other apps are using camera'),
                  const Text('• Refresh page if stuck on "Requesting access"'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Refresh the page for web users
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'If camera is stuck, try refreshing the page or clearing browser cache',
                          ),
                          duration: Duration(seconds: 4),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Troubleshooting Help'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
