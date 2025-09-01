import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/uae_id_ocr_service.dart';
import '../theme.dart';

class UAEIdFormScreen extends StatefulWidget {
  const UAEIdFormScreen({super.key});

  @override
  State<UAEIdFormScreen> createState() => _UAEIdFormScreenState();
}

class _UAEIdFormScreenState extends State<UAEIdFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Form Controllers
  final _nameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _issuingDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _sexController = TextEditingController();

  // State variables
  bool _isProcessing = false;
  bool _hasScannedId = false;
  XFile? _selectedImage;
  UAEIdData? _extractedData;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idNumberController.dispose();
    _dateOfBirthController.dispose();
    _nationalityController.dispose();
    _issuingDateController.dispose();
    _expiryDateController.dispose();
    _sexController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      print('=== IMAGE PICKER DEBUG ===');
      print(
        'Picking image from: ${source == ImageSource.camera ? "Camera" : "Gallery"}',
      );

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
        requestFullMetadata: false,
      );

      print(
        'Image picker result: ${image != null ? "Success" : "Null/Cancelled"}',
      );

      if (image != null) {
        print('Selected image: ${image.path}');
        print('Image name: ${image.name}');
        print('Image mime type: ${image.mimeType}');

        // Always proceed with validation (which now always returns true for debugging)
        final isValid = await _validateImageFile(image);
        print('Validation result: $isValid');

        if (isValid) {
          setState(() {
            _selectedImage = image;
            _isProcessing = true;
          });

          await _processImage(image);
        } else {
          print('Validation failed - this should not happen in debug mode');
          _showErrorSnackBar('Validation failed');
        }
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('=== IMAGE PICKER ERROR ===');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<bool> _validateImageFile(XFile image) async {
    try {
      print('=== FILE VALIDATION DEBUG ===');
      print('Image path: ${image.path}');
      print('Image name: ${image.name}');
      print('Image mimeType: ${image.mimeType}');

      // Check if file exists
      final file = File(image.path);
      final fileExists = await file.exists();
      print('File exists: $fileExists');

      if (!fileExists) {
        print('ERROR: File does not exist');
        _showErrorSnackBar('Selected file does not exist');
        return false;
      }

      // Get file info
      final fileSizeInBytes = await file.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      print(
        'File size: $fileSizeInBytes bytes (${fileSizeInMB.toStringAsFixed(2)} MB)',
      );

      // Very basic size check - just ensure it's not empty or too large
      if (fileSizeInBytes == 0) {
        print('ERROR: File is empty');
        _showErrorSnackBar('Selected file is empty');
        return false;
      }

      if (fileSizeInMB > 50) {
        // Increased to 50MB for testing
        print('ERROR: File too large');
        _showErrorSnackBar(
          'File too large (${fileSizeInMB.toStringAsFixed(1)}MB). Maximum size is 50MB.',
        );
        return false;
      }

      // Get file extension from path and name
      final pathExtension = image.path.toLowerCase().split('.').last;
      final nameExtension = image.name.toLowerCase().split('.').last;
      print('Path extension: $pathExtension');
      print('Name extension: $nameExtension');

      // Very permissive extension check
      final commonImageExtensions = [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'bmp',
        'webp',
        'heic',
        'heif',
        'tiff',
        'tif',
        'svg',
        'ico',
      ];

      bool hasValidExtension =
          commonImageExtensions.contains(pathExtension) ||
          commonImageExtensions.contains(nameExtension);
      print('Has valid extension: $hasValidExtension');

      // Check MIME type if available
      final mimeType = image.mimeType?.toLowerCase() ?? '';
      print('MIME type: $mimeType');

      bool hasValidMimeType = mimeType.isEmpty || mimeType.startsWith('image/');
      print('Has valid MIME type: $hasValidMimeType');

      // For debugging, let's be very permissive
      if (!hasValidExtension && !hasValidMimeType && mimeType.isNotEmpty) {
        print(
          'WARNING: Questionable file type, but proceeding anyway for debugging',
        );
        _showErrorSnackBar(
          'Warning: Unusual file type detected. Processing anyway...',
        );
      }

      print('=== VALIDATION RESULT: PASSED ===');
      return true; // Always return true for debugging
    } catch (e) {
      print('=== FILE VALIDATION ERROR ===');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');
      _showErrorSnackBar('Validation error: $e');
      return true; // Return true even on error for debugging
    }
  }

  Future<void> _processImage(XFile image) async {
    try {
      print('=== OCR PROCESSING DEBUG ===');
      print('Starting OCR processing for: ${image.path}');

      // Process the image using OCR
      final extractedData = await UAEIdOCRService.processUAEId(image.path);

      print('OCR processing completed successfully');
      print('Extracted data: ${extractedData.toJson()}');

      setState(() {
        _extractedData = extractedData;
        _hasScannedId = true;
        _isProcessing = false;
      });

      // Auto-fill the form fields
      _fillFormFields(extractedData);

      _showSuccessSnackBar('UAE ID processed successfully!');
    } catch (e) {
      print('=== OCR PROCESSING ERROR ===');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');

      setState(() {
        _isProcessing = false;
      });
      _showErrorSnackBar('Failed to process UAE ID: $e');
    }
  }

  void _fillFormFields(UAEIdData data) {
    _nameController.text = data.name ?? '';
    _idNumberController.text = data.idNumber ?? '';
    _dateOfBirthController.text = data.dateOfBirth ?? '';
    _nationalityController.text = data.nationality ?? '';
    _issuingDateController.text = data.issuingDate ?? '';
    _expiryDateController.text = data.expiryDate ?? '';
    _sexController.text = data.sex ?? '';
  }

  Future<void> _pickFromFiles() async {
    try {
      print('=== FILE PICKER DEBUG ===');
      print('Starting FilePicker...');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Changed to any for debugging
        allowMultiple: false,
        allowedExtensions: null,
        withData: false,
        withReadStream: false,
      );

      print(
        'FilePicker result: ${result != null ? "Success" : "Null/Cancelled"}',
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        print('Selected file details:');
        print('  Name: ${file.name}');
        print('  Path: ${file.path}');
        print('  Size: ${file.size} bytes');
        print('  Extension: ${file.extension}');

        if (file.path != null) {
          final xFile = XFile(file.path!);

          // Always proceed with validation (which now always returns true)
          final isValid = await _validateImageFile(xFile);
          print('Validation result: $isValid');

          if (isValid) {
            setState(() {
              _selectedImage = xFile;
              _isProcessing = true;
            });

            await _processImage(xFile);
          } else {
            print('Validation failed - this should not happen in debug mode');
            _showErrorSnackBar('Validation failed');
          }
        } else {
          print('ERROR: File path is null');
          _showErrorSnackBar('Could not access the selected file');
        }
      } else {
        print('No file selected or result is empty');
      }
    } catch (e) {
      print('=== FILE PICKER ERROR ===');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');
      _showErrorSnackBar('Failed to pick file: $e');
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Select UAE ID Image',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how you want to upload your Emirates ID',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.photo_camera, color: Colors.blue),
                    ),
                    title: const Text('Take Photo'),
                    subtitle: const Text('Use camera to capture ID'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: Colors.green,
                      ),
                    ),
                    title: const Text('Photo Gallery'),
                    subtitle: const Text('Select from your photos'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.folder, color: Colors.orange),
                    ),
                    title: const Text('Browse Files'),
                    subtitle: const Text('Select from file manager'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromFiles();
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Supported formats: JPG, PNG, HEIC, WEBP (Max 10MB)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Process form submission
      final formData = {
        'name': _nameController.text,
        'idNumber': _idNumberController.text,
        'dateOfBirth': _dateOfBirthController.text,
        'nationality': _nationalityController.text,
        'issuingDate': _issuingDateController.text,
        'expiryDate': _expiryDateController.text,
        'sex': _sexController.text,
      };

      _showSuccessSnackBar('Form submitted successfully!');
      // Navigate to next screen or save data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('UAE ID Registration'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScanSection(),
                  const SizedBox(height: 32),
                  _buildFormSection(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanSection() {
    return Card(
      elevation: 8,
      shadowColor: Colors.blue.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan UAE ID',
              style: AppTheme.title.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 12),
            Text(
              'Take a photo or select an image of your UAE Resident Identity Card to auto-fill the form.',
              style: AppTheme.body.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            if (_selectedImage != null) _buildImagePreview(),
            const SizedBox(height: 16),
            _buildScanButton(),
            if (_isProcessing) _buildProcessingIndicator(),
            if (_hasScannedId && _extractedData != null) _buildScanResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _showImagePickerDialog,
        icon: const Icon(Icons.camera_alt_outlined),
        label: Text(_selectedImage == null ? 'Scan UAE ID' : 'Rescan UAE ID'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 16),
          Text('Processing UAE ID...'),
        ],
      ),
    );
  }

  Widget _buildScanResults() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'ID Processed Successfully',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Extracted: Name, ID Number, DOB, Nationality, and more',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Card(
      elevation: 8,
      shadowColor: Colors.blue.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: AppTheme.title.copyWith(color: Colors.blue),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Name is required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _idNumberController,
              label: 'UAE ID Number',
              icon: Icons.credit_card,
              hintText: 'XXX-XXXX-XXXXXXX-X',
              validator: (value) {
                if (value?.isEmpty ?? true) return 'ID number is required';
                if (!UAEIdOCRService.validateUAEIdNumber(value!)) {
                  return 'Invalid UAE ID format';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _dateOfBirthController,
              label: 'Date of Birth',
              icon: Icons.calendar_today,
              hintText: 'DD/MM/YYYY',
              readOnly: true,
              onTap: () => _selectDate(_dateOfBirthController),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Date of birth is required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nationalityController,
              label: 'Nationality',
              icon: Icons.flag,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Nationality is required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _issuingDateController,
                    label: 'Issuing Date',
                    icon: Icons.date_range,
                    hintText: 'DD/MM/YYYY',
                    readOnly: true,
                    onTap: () => _selectDate(_issuingDateController),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _expiryDateController,
                    label: 'Expiry Date',
                    icon: Icons.schedule,
                    hintText: 'DD/MM/YYYY',
                    readOnly: true,
                    onTap: () => _selectDate(_expiryDateController),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDropdownField(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _sexController.text.isEmpty ? null : _sexController.text,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.person, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items: ['M', 'F'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value == 'M' ? 'Male' : 'Female'),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          _sexController.text = newValue;
        }
      },
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Gender is required';
        return null;
      },
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text =
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: Colors.blue.withValues(alpha: 0.3),
        ),
        child: const Text(
          'Submit Registration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
