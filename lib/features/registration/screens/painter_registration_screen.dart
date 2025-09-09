import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/file_upload_widget.dart';
import '../../../core/services/uae_id_ocr_service.dart';
import '../../../core/services/bank_details_ocr_service.dart';
import '../../../core/widgets/modern_dropdown.dart';

class PainterRegistrationScreen extends StatefulWidget {
  const PainterRegistrationScreen({super.key});

  @override
  State<PainterRegistrationScreen> createState() =>
      _PainterRegistrationScreenState();
}

class _PainterRegistrationScreenState extends State<PainterRegistrationScreen>
    with TickerProviderStateMixin {
  String? _emiratesIdFrontImage;
  String? _emiratesIdBackImage;
  String? _photoImage;
  String? _chequeBookImage;
  String? _bankDocumentImage;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _emiratesController = TextEditingController();
  String? _selectedReference;
  // Emirates ID Details
  final _emiratesIdController = TextEditingController();
  final _idNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _companyDetailsController = TextEditingController();
  final _issueDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _occupationController = TextEditingController();
  // Bank Details (Non-Mandatory)
  final _accountHolderController = TextEditingController();
  final _ibanController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _bankAddressController = TextEditingController();
  bool _isSubmitting = false;
  bool _isProcessingEmiratesId = false;
  bool _isProcessingBankDocument = false;
  AnimationController? _mainController;
  AnimationController? _fabController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController!,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _mainController!,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController!,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _mainController?.forward();
    _fabController?.forward();
  }

  // Check if both sides are uploaded and process together
  Future<void> _checkAndProcessEmiratesId() async {
    // Only process if both front and back images are uploaded
    if (_emiratesIdFrontImage == null ||
        _emiratesIdFrontImage!.isEmpty ||
        _emiratesIdBackImage == null ||
        _emiratesIdBackImage!.isEmpty) {
      print('=== WAITING FOR BOTH SIDES ===');
      print('Front: ${_emiratesIdFrontImage != null ? 'Uploaded' : 'Missing'}');
      print('Back: ${_emiratesIdBackImage != null ? 'Uploaded' : 'Missing'}');
      return;
    }

    setState(() {
      _isProcessingEmiratesId = true;
    });

    try {
      print('=== EMIRATES ID COMBINED OCR PROCESSING ===');
      print('Processing front image: $_emiratesIdFrontImage');
      print('Processing back image: $_emiratesIdBackImage');

      // Process front side
      final frontData = await UAEIdOCRService.processUAEId(
        _emiratesIdFrontImage!,
      );
      print('Front OCR completed: ${frontData.toJson()}');

      // Process back side
      final backData = await UAEIdOCRService.processUAEId(
        _emiratesIdBackImage!,
      );
      print('Back OCR completed: ${backData.toJson()}');

      // Combine data from both sides
      final combinedData = _combineEmiratesIdData(frontData, backData);
      print('Combined data: ${combinedData.toJson()}');

      // Fill all form fields with combined data
      _fillEmiratesIdFields(combinedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Emirates ID processed successfully! Both sides analyzed and all fields auto-filled.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('=== EMIRATES ID OCR ERROR ===');
      print('Error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to process Emirates ID: $e')),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingEmiratesId = false;
        });
      }
    }
  }

  // Combine data from front and back sides
  UAEIdData _combineEmiratesIdData(UAEIdData frontData, UAEIdData backData) {
    return UAEIdData(
      // Prefer front side for basic personal info
      name: frontData.name ?? backData.name,
      idNumber: frontData.idNumber ?? backData.idNumber,
      dateOfBirth: frontData.dateOfBirth ?? backData.dateOfBirth,
      nationality: frontData.nationality ?? backData.nationality,
      issuingDate: frontData.issuingDate ?? backData.issuingDate,
      expiryDate: frontData.expiryDate ?? backData.expiryDate,
      sex: frontData.sex ?? backData.sex,
      signature: frontData.signature ?? backData.signature,

      // Prefer back side for professional info
      cardNumber: backData.cardNumber ?? frontData.cardNumber,
      occupation: backData.occupation ?? frontData.occupation,
      employer: backData.employer ?? frontData.employer,
      issuingPlace: backData.issuingPlace ?? frontData.issuingPlace,
    );
  }

  // Get status color based on upload and processing state
  Color _getStatusColor() {
    if (_isProcessingEmiratesId) return Colors.blue;

    final frontUploaded =
        _emiratesIdFrontImage != null && _emiratesIdFrontImage!.isNotEmpty;
    final backUploaded =
        _emiratesIdBackImage != null && _emiratesIdBackImage!.isNotEmpty;

    if (frontUploaded && backUploaded) return Colors.green;
    if (frontUploaded || backUploaded) return Colors.orange;
    return Colors.grey;
  }

  // Get status icon based on upload and processing state
  IconData _getStatusIcon() {
    final frontUploaded =
        _emiratesIdFrontImage != null && _emiratesIdFrontImage!.isNotEmpty;
    final backUploaded =
        _emiratesIdBackImage != null && _emiratesIdBackImage!.isNotEmpty;

    if (frontUploaded && backUploaded) return Icons.check_circle;
    if (frontUploaded || backUploaded) return Icons.upload_file;
    return Icons.info_outline;
  }

  // Get status message based on upload and processing state
  String _getStatusMessage() {
    if (_isProcessingEmiratesId) {
      return 'Processing both sides of Emirates ID... Please wait while we extract and combine all information.';
    }

    final frontUploaded =
        _emiratesIdFrontImage != null && _emiratesIdFrontImage!.isNotEmpty;
    final backUploaded =
        _emiratesIdBackImage != null && _emiratesIdBackImage!.isNotEmpty;

    if (frontUploaded && backUploaded) {
      return '✅ Both sides uploaded successfully! All fields have been auto-filled with extracted data.';
    }

    if (frontUploaded && !backUploaded) {
      return 'Front side uploaded. Please upload the back side to start processing and auto-fill fields.';
    }

    if (!frontUploaded && backUploaded) {
      return 'Back side uploaded. Please upload the front side to start processing and auto-fill fields.';
    }

    return 'Please upload both front and back sides of your Emirates ID to auto-fill the form fields.';
  }

  // Get bank document status color based on upload and processing state
  Color _getBankDocumentStatusColor() {
    if (_isProcessingBankDocument) return Colors.blue;

    final bankDocumentUploaded =
        _bankDocumentImage != null && _bankDocumentImage!.isNotEmpty;

    if (bankDocumentUploaded) return Colors.green;
    return Colors.grey;
  }

  // Get bank document status icon based on upload and processing state
  IconData _getBankDocumentStatusIcon() {
    final bankDocumentUploaded =
        _bankDocumentImage != null && _bankDocumentImage!.isNotEmpty;

    if (bankDocumentUploaded) return Icons.check_circle;
    return Icons.info_outline;
  }

  // Get bank document status message based on upload and processing state
  String _getBankDocumentStatusMessage() {
    if (_isProcessingBankDocument) {
      return 'Processing bank document... Please wait while we extract your bank details.';
    }

    final bankDocumentUploaded =
        _bankDocumentImage != null && _bankDocumentImage!.isNotEmpty;

    if (bankDocumentUploaded) {
      return '✅ Bank document uploaded successfully! Bank details have been auto-filled from the document.';
    }

    return 'Upload a bank statement, cheque, or bank document to auto-fill your bank details.';
  }

  // Enhanced form field filling with automatic mapping
  void _fillEmiratesIdFields(UAEIdData data, {bool mergeWithExisting = false}) {
    print('=== ENHANCED FORM FIELD FILLING ===');
    print('Merge with existing: $mergeWithExisting');
    print('Input data: ${data.toJson()}');

    // Get enhanced field mapping
    final fieldMapping = UAEIdOCRService.getFormFieldMapping(data);
    print('Field mapping: $fieldMapping');

    // Auto-fill personal details from name
    if (fieldMapping['firstName'] != null &&
        (!mergeWithExisting || _firstNameController.text.isEmpty)) {
      _firstNameController.text = fieldMapping['firstName']!;
      print('Auto-filled first name: ${fieldMapping['firstName']}');
    }

    if (fieldMapping['middleName'] != null &&
        (!mergeWithExisting || _middleNameController.text.isEmpty)) {
      _middleNameController.text = fieldMapping['middleName']!;
      print('Auto-filled middle name: ${fieldMapping['middleName']}');
    }

    if (fieldMapping['lastName'] != null &&
        (!mergeWithExisting || _lastNameController.text.isEmpty)) {
      _lastNameController.text = fieldMapping['lastName']!;
      print('Auto-filled last name: ${fieldMapping['lastName']}');
    }

    // Fill ID name field
    if (fieldMapping['idName'] != null &&
        (!mergeWithExisting || _idNameController.text.isEmpty)) {
      _idNameController.text = fieldMapping['idName']!;
      print('Set ID name: ${fieldMapping['idName']}');
    }

    // Fill Emirates ID specific fields (merge logic for each field)
    if (data.idNumber != null &&
        data.idNumber!.isNotEmpty &&
        (!mergeWithExisting || _emiratesIdController.text.isEmpty)) {
      _emiratesIdController.text = data.idNumber!;
      print('Set Emirates ID: ${data.idNumber}');
    }

    if (data.dateOfBirth != null &&
        data.dateOfBirth!.isNotEmpty &&
        (!mergeWithExisting || _dobController.text.isEmpty)) {
      _dobController.text = data.dateOfBirth!;
      print('Set DOB: ${data.dateOfBirth}');
    }

    if (data.nationality != null &&
        data.nationality!.isNotEmpty &&
        (!mergeWithExisting || _nationalityController.text.isEmpty)) {
      _nationalityController.text = data.nationality!;
      print('Set nationality: ${data.nationality}');
    }

    if (data.issuingDate != null &&
        data.issuingDate!.isNotEmpty &&
        (!mergeWithExisting || _issueDateController.text.isEmpty)) {
      _issueDateController.text = data.issuingDate!;
      print('Set issue date: ${data.issuingDate}');
    }

    if (data.expiryDate != null &&
        data.expiryDate!.isNotEmpty &&
        (!mergeWithExisting || _expiryDateController.text.isEmpty)) {
      _expiryDateController.text = data.expiryDate!;
      print('Set expiry date: ${data.expiryDate}');
    }

    // Fill new extracted fields (merge logic)
    if (data.occupation != null &&
        data.occupation!.isNotEmpty &&
        (!mergeWithExisting || _occupationController.text.isEmpty)) {
      _occupationController.text = data.occupation!;
      print('Set occupation: ${data.occupation}');
    }

    if (data.employer != null &&
        data.employer!.isNotEmpty &&
        (!mergeWithExisting || _companyDetailsController.text.isEmpty)) {
      _companyDetailsController.text = data.employer!;
      print('Set company details/employer: ${data.employer}');
    }

    // Set issuing place in Emirates dropdown if available (merge logic)
    if (data.issuingPlace != null &&
        data.issuingPlace!.isNotEmpty &&
        (!mergeWithExisting || _emiratesController.text.isEmpty)) {
      final emirates = [
        'Dubai',
        'Abu Dhabi',
        'Sharjah',
        'Ajman',
        'Umm Al Quwain',
        'Ras Al Khaimah',
        'Fujairah',
      ];
      final matchingEmirate = emirates.firstWhere(
        (emirate) =>
            emirate.toLowerCase().contains(data.issuingPlace!.toLowerCase()) ||
            data.issuingPlace!.toLowerCase().contains(emirate.toLowerCase()),
        orElse: () => '',
      );
      if (matchingEmirate.isNotEmpty) {
        _emiratesController.text = matchingEmirate;
        print(
          'Set Emirates: $matchingEmirate (from issuing place: ${data.issuingPlace})',
        );
      }
    }

    print('=== NEW FIELDS FILLED ===');
    print('Card Number: ${data.cardNumber}');
    print('Occupation: ${data.occupation}');
    print('Employer: ${data.employer}');
    print('Issuing Place: ${data.issuingPlace}');
    print('=== FORM FIELDS FILLED ===');

    // Force a rebuild to show the updated fields
    setState(() {});
  }

  // Process bank document with OCR
  Future<void> _processBankDocument() async {
    if (_bankDocumentImage == null || _bankDocumentImage!.isEmpty) {
      print('=== NO BANK DOCUMENT TO PROCESS ===');
      return;
    }

    setState(() {
      _isProcessingBankDocument = true;
    });

    try {
      print('=== BANK DOCUMENT OCR PROCESSING ===');
      print('Processing bank document: $_bankDocumentImage');

      // Process bank document using the new service
      final bankData = await BankDetailsOCRService.processBankDocument(
        _bankDocumentImage!,
      );
      print('Bank OCR completed: ${bankData.toJson()}');

      // Fill bank detail fields with extracted data
      _fillBankDetailsFields(bankData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bank document processed successfully! Bank details have been auto-filled.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('=== BANK DOCUMENT OCR ERROR ===');
      print('Error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to process bank document: $e')),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingBankDocument = false;
        });
      }
    }
  }

  // Fill bank details form fields with OCR data
  void _fillBankDetailsFields(BankDetailsData data) {
    print('=== FILLING BANK DETAILS FIELDS ===');
    print('Bank data: ${data.toJson()}');

    if (data.accountHolderName != null &&
        _accountHolderController.text.isEmpty) {
      _accountHolderController.text = data.accountHolderName!;
      print('Set account holder: ${data.accountHolderName}');
    }

    if (data.ibanNumber != null && _ibanController.text.isEmpty) {
      _ibanController.text = data.ibanNumber!;
      print('Set IBAN: ${data.ibanNumber}');
    }

    if (data.bankName != null && _bankNameController.text.isEmpty) {
      _bankNameController.text = data.bankName!;
      print('Set bank name: ${data.bankName}');
    }

    if (data.branchName != null && _branchNameController.text.isEmpty) {
      _branchNameController.text = data.branchName!;
      print('Set branch name: ${data.branchName}');
    }

    if (data.bankAddress != null && _bankAddressController.text.isEmpty) {
      _bankAddressController.text = data.bankAddress!;
      print('Set bank address: ${data.bankAddress}');
    }

    print('=== BANK FIELDS FILLED ===');

    // Force a rebuild to show the updated fields
    setState(() {});
  }

  @override
  void dispose() {
    _mainController?.dispose();
    _fabController?.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _emiratesController.dispose();
    _emiratesIdController.dispose();
    _idNameController.dispose();
    _dobController.dispose();
    _nationalityController.dispose();
    _companyDetailsController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    _occupationController.dispose();
    _accountHolderController.dispose();
    _ibanController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    _bankAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildModernAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation ?? AlwaysStoppedAnimation(1.0),
        child: SlideTransition(
          position: _slideAnimation ?? AlwaysStoppedAnimation(Offset.zero),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade50,
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ScaleTransition(
                scale: _scaleAnimation ?? AlwaysStoppedAnimation(1.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Header with animation
                      _buildAnimatedHeader(),
                      const SizedBox(height: 30),
                      // Personal Details Section
                      _buildModernSection(
                        title: 'Personal Details',
                        icon: Icons.person_rounded,
                        children: [
                          _buildModernTextField(
                            controller: _firstNameController,
                            label: 'First Name',
                            icon: Icons.person_outline_rounded,
                            delay: const Duration(milliseconds: 100),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _middleNameController,
                            label: 'Middle Name',
                            icon: Icons.person_outline_rounded,
                            isRequired: false,
                            delay: const Duration(milliseconds: 150),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _lastNameController,
                            label: 'Last Name',
                            icon: Icons.person_outline_rounded,
                            delay: const Duration(milliseconds: 200),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _mobileController,
                            label: 'Mobile Number',
                            icon: Icons.phone_outlined,
                            isPhone: true,
                            delay: const Duration(milliseconds: 250),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _addressController,
                            label: 'Address',
                            icon: Icons.home_outlined,
                            delay: const Duration(milliseconds: 300),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _areaController,
                            label: 'Area',
                            icon: Icons.location_on_outlined,
                            delay: const Duration(milliseconds: 350),
                          ),
                          const SizedBox(height: 16),
                          ModernDropdown(
                            label: "Emirates",
                            icon: Icons.public_outlined,
                            items: const [
                              'Dubai',
                              'Abu Dhabi',
                              'Sharjah',
                              'Ajman',
                              'Umm Al Quwain',
                              'Ras Al Khaimah',
                              'Fujairah',
                            ],
                            value: _emiratesController.text.isEmpty
                                ? _emiratesController.text
                                : null,
                            onChanged: (value) {
                              setState(() {
                                _emiratesController.text = value ?? '';
                              });
                            },
                            delay: const Duration(milliseconds: 400),
                          ),
                          const SizedBox(height: 16),
                          ModernDropdown(
                            label: "Reference",
                            icon: Icons.contact_page_outlined,
                            items: const [
                              'Employee',
                              'Retailer',
                              'Distributor',
                              'Salesman',
                            ],
                            value: _selectedReference,
                            onChanged: (value) {
                              setState(() {
                                _selectedReference = value;
                              });
                            },
                            delay: const Duration(milliseconds: 450),
                          ),
                          const SizedBox(height: 16),
                          FileUploadWidget(
                            label: 'Profile Photo',
                            icon: Icons.camera_alt_outlined,
                            onFileSelected: (value) {
                              print(
                                '=== PAINTER REGISTRATION PHOTO CALLBACK ===',
                              );
                              print('Received value: $value');
                              print('Previous _photoImage: $_photoImage');
                              setState(() => _photoImage = value);
                              print('Updated _photoImage: $_photoImage');
                            },
                            delay: const Duration(milliseconds: 500),
                            allowedExtensions: const [
                              '*',
                            ], // Allow all file types
                            maxSizeInMB: 10.0,
                            currentFilePath: _photoImage,
                            formType: 'painter',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Emirates ID Section
                      _buildModernSection(
                        title: 'Emirates ID',
                        icon: Icons.badge_outlined,
                        children: [
                          // Emirates ID Upload with OCR Processing Status
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getStatusIcon(),
                                      color: _getStatusColor(),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Emirates ID Processing Status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _getStatusColor(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getStatusMessage(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                if (_isProcessingEmiratesId) ...[
                                  const SizedBox(height: 12),
                                  const LinearProgressIndicator(),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Front Side Upload
                          FileUploadWidget(
                            label: 'Emirates ID - Front Side',
                            icon: Icons.credit_card_outlined,
                            onFileSelected: (value) {
                              setState(() => _emiratesIdFrontImage = value);
                              _checkAndProcessEmiratesId();
                            },
                            delay: const Duration(milliseconds: 100),
                            allowedExtensions: const ['jpg', 'jpeg', 'png'],
                            maxSizeInMB: 10.0,
                            currentFilePath: _emiratesIdFrontImage,
                            formType: 'painter',
                          ),
                          const SizedBox(height: 16),
                          // Back Side Upload
                          FileUploadWidget(
                            label: 'Emirates ID - Back Side',
                            icon: Icons.credit_card_outlined,
                            onFileSelected: (value) {
                              setState(() => _emiratesIdBackImage = value);
                              _checkAndProcessEmiratesId();
                            },
                            delay: const Duration(milliseconds: 200),
                            allowedExtensions: const ['jpg', 'jpeg', 'png'],
                            maxSizeInMB: 10.0,
                            currentFilePath: _emiratesIdBackImage,
                            formType: 'painter',
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _emiratesIdController,
                            label: 'Emirates ID Number',
                            icon: Icons.pin_outlined,
                            delay: const Duration(milliseconds: 200),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _idNameController,
                            label: 'Name of Holder',
                            icon: Icons.person_outline_rounded,
                            delay: const Duration(milliseconds: 300),
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: _dobController,
                            label: 'Date of Birth',
                            icon: Icons.cake_outlined,
                            delay: const Duration(milliseconds: 400),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _nationalityController,
                            label: 'Nationality',
                            icon: Icons.flag_outlined,
                            delay: const Duration(milliseconds: 500),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _companyDetailsController,
                            label: 'Company Details',
                            icon: Icons.business_outlined,
                            delay: const Duration(milliseconds: 600),
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: _issueDateController,
                            label: 'Issue Date',
                            icon: Icons.event_outlined,
                            delay: const Duration(milliseconds: 700),
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: _expiryDateController,
                            label: 'Expiry Date',
                            icon: Icons.event_available_outlined,
                            delay: const Duration(milliseconds: 800),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _occupationController,
                            label: 'Occupation',
                            icon: Icons.work_outline,
                            delay: const Duration(milliseconds: 900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Bank Details Section
                      _buildModernSection(
                        title: 'Bank Details',
                        icon: Icons.account_balance_outlined,
                        isOptional: true,
                        children: [
                          // Bank Document OCR Processing Status
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _getBankDocumentStatusColor().withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getBankDocumentStatusColor(),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getBankDocumentStatusIcon(),
                                      color: _getBankDocumentStatusColor(),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Bank Document OCR Status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _getBankDocumentStatusColor(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getBankDocumentStatusMessage(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                if (_isProcessingBankDocument) ...[
                                  const SizedBox(height: 12),
                                  const LinearProgressIndicator(),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Bank Document Upload
                          FileUploadWidget(
                            label: 'Bank Statement or Cheque',
                            icon: Icons.receipt_long_outlined,
                            onFileSelected: (value) {
                              setState(() => _bankDocumentImage = value);
                              _processBankDocument();
                            },
                            delay: const Duration(milliseconds: 50),
                            allowedExtensions: const [
                              'jpg',
                              'jpeg',
                              'png',
                              'pdf',
                            ],
                            maxSizeInMB: 10.0,
                            currentFilePath: _bankDocumentImage,
                            formType: 'painter',
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _accountHolderController,
                            label: 'Account Holder Name',
                            icon: Icons.person_outline_rounded,
                            isRequired: false,
                            delay: const Duration(milliseconds: 100),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _ibanController,
                            label: 'IBAN Number',
                            icon: Icons.account_balance_wallet_outlined,
                            isRequired: false,
                            delay: const Duration(milliseconds: 200),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _bankNameController,
                            label: 'Bank Name',
                            icon: Icons.business_outlined,
                            isRequired: false,
                            delay: const Duration(milliseconds: 300),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _branchNameController,
                            label: 'Branch Name',
                            icon: Icons.location_on_outlined,
                            isRequired: false,
                            delay: const Duration(milliseconds: 400),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _bankAddressController,
                            label: 'Bank Address',
                            icon: Icons.location_city_outlined,
                            isRequired: false,
                            delay: const Duration(milliseconds: 500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      // Submit Button
                      _buildAnimatedSubmitButton(),
                      const SizedBox(height: 40),
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

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.blue.shade800,
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
      title: Text(
        'Painter Registration',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded),
          onPressed: () => _showHelpDialog(),
        ),
      ],
    );
  }

  Widget _buildAnimatedHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Text(
              'Welcome!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Text(
              'Complete your painter registration',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isOptional = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
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
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      if (isOptional)
                        Text(
                          'Optional',
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
          ),
          // Section Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Duration delay = Duration.zero,
    bool isPhone = false,
    bool isRequired = true,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
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
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'Please enter $label';
          }
          if (isPhone && value != null && value.isNotEmpty) {
            if (!RegExp(r'^[50|52|54|55|56|58]\d{7}$').hasMatch(value)) {
              return 'Please enter valid UAE mobile number';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildModernDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Duration delay = Duration.zero,
    bool isRequired = true,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          suffixIcon: const Icon(
            Icons.calendar_today_rounded,
            color: Colors.grey,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
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
        readOnly: true,
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(primary: Colors.blue),
                ),
                child: child!,
              );
            },
          );
          if (date != null) {
            controller.text = date.toString().split(' ')[0];
          }
        },
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildModernImageUpload({
    required String label,
    required IconData icon,
    required Function(String?) onImageSelected,
    bool isRequired = true,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRequired ? '$label *' : label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              onImageSelected('uploaded_image_path');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$label uploaded successfully',
                    style: AppTheme.success,
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40, color: Colors.grey.shade500),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PNG, JPG up to 10MB',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSubmitButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(scale: 0.8 + (0.2 * value), child: child);
      },
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: Colors.blue.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSubmitting
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text('Submitting...', style: AppTheme.body),
                  ],
                )
              : Text(
                  'Submit Registration',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.help_outline_rounded,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                'Registration Help',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Fill in all required fields marked with *. '
                'Bank details are optional but recommended for payments.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Got it', style: AppTheme.body),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Map OCR results to form fields
  void _mapOcrResultsToFields(Map<String, String> ocrResults) {
    print('=== MAPPING OCR RESULTS ===');
    print('OCR Results: $ocrResults');

    // Map basic fields
    if (ocrResults['name'] != null && ocrResults['name']!.isNotEmpty) {
      final nameParts = ocrResults['name']!.split(' ');
      if (nameParts.isNotEmpty) {
        _firstNameController.text = nameParts.first;
        _idNameController.text = ocrResults['name']!;
      }
      if (nameParts.length > 1) {
        _lastNameController.text = nameParts.last;
      }
      if (nameParts.length > 2) {
        _middleNameController.text = nameParts
            .skip(1)
            .take(nameParts.length - 2)
            .join(' ');
      }
    }

    if (ocrResults['aadhaar'] != null && ocrResults['aadhaar']!.isNotEmpty) {
      _emiratesIdController.text = ocrResults['aadhaar']!;
    }

    if (ocrResults['dob'] != null && ocrResults['dob']!.isNotEmpty) {
      _dobController.text = ocrResults['dob']!;
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text('OCR data mapped to form fields successfully!'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {});
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        Navigator.pushNamed(context, '/success');
      }
    }
  }
}
