import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/uae_id_ocr_service.dart';
import '../../../core/services/contractor_service.dart';
import '../../../core/models/contractor_models.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/file_upload_widget.dart';
import '../../../core/widgets/modern_dropdown.dart';

class ContractorRegistrationScreen extends StatefulWidget {
  const ContractorRegistrationScreen({super.key});

  @override
  State<ContractorRegistrationScreen> createState() =>
      _ContractorRegistrationScreenState();
}

class _ContractorRegistrationScreenState
    extends State<ContractorRegistrationScreen>
    with TickerProviderStateMixin {
  String? _emiratesIdFrontImage;
  String? _emiratesIdBackImage;
  String? _vatCertificateImage;
  String? _commercialLicenseImage;
  String? _photoImage;
  final _formKey = GlobalKey<FormState>();
  final _contractorTypeController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _emiratesController = TextEditingController();
  final _referenceController = TextEditingController();
  // Emirates ID Details
  final _emiratesIdController = TextEditingController();
  final _idNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _companyDetailsController = TextEditingController();
  final _issueDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _occupationController = TextEditingController();
  // Bank Details
  final _accountHolderController = TextEditingController();
  final _ibanController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _bankAddressController = TextEditingController();
  // VAT Details
  final _firmNameController = TextEditingController();
  final _vatAddressController = TextEditingController();
  final _trnController = TextEditingController();
  final _vatDateController = TextEditingController();
  // Commercial License
  final _licenseNumberController = TextEditingController();
  final _issuingAuthorityController = TextEditingController();
  final _licenseTypeController = TextEditingController();
  final _establishmentDateController = TextEditingController();
  final _licenseExpiryDateController = TextEditingController();
  final _tradeNameController = TextEditingController();
  final _responsiblePersonController = TextEditingController();
  final _licenseAddressController = TextEditingController();
  final _effectiveDateController = TextEditingController();
  bool _isSubmitting = false;
  bool _isProcessingEmiratesId = false;
  
  // API dropdown data
  List<String> _contractorTypes = [];
  List<String> _emirates = [];
  bool _isLoadingDropdowns = true;
  late AnimationController _mainController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

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
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _mainController.forward();
    _fabController.forward();
    _loadDropdownData();
  }

  // Load dropdown data from API
  Future<void> _loadDropdownData() async {
    try {
      final contractorTypes = await ContractorService.getContractorTypes();
      final emirates = await ContractorService.getEmiratesList();
      
      setState(() {
        _contractorTypes = contractorTypes;
        _emirates = emirates;
        _isLoadingDropdowns = false;
      });
    } catch (e) {
      print('Error loading dropdown data: $e');
      // Use fallback data if API fails
      setState(() {
        _contractorTypes = ContractorTypes.all;
        _emirates = EmiratesConstants.all;
        _isLoadingDropdowns = false;
      });
    }
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
                    'Emirates ID processed successfully! Emirates ID information has been auto-filled. Please manually enter your personal details.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
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
      return 'Processing both sides of Emirates ID... Please wait while we extract Emirates ID information.';
    }

    final frontUploaded =
        _emiratesIdFrontImage != null && _emiratesIdFrontImage!.isNotEmpty;
    final backUploaded =
        _emiratesIdBackImage != null && _emiratesIdBackImage!.isNotEmpty;

    if (frontUploaded && backUploaded) {
      return '✅ Both sides uploaded successfully! Emirates ID information has been extracted and auto-filled below.';
    }

    if (frontUploaded && !backUploaded) {
      return 'Front side uploaded. Please upload the back side to start processing and auto-fill Emirates ID fields.';
    }

    if (!frontUploaded && backUploaded) {
      return 'Back side uploaded. Please upload the front side to start processing and auto-fill Emirates ID fields.';
    }

    return 'Please upload both front and back sides of your Emirates ID to auto-fill the Emirates ID information fields only.';
  }

  // Enhanced form field filling - ONLY Emirates ID section fields
  void _fillEmiratesIdFields(UAEIdData data, {bool mergeWithExisting = false}) {
    print('=== EMIRATES ID SECTION FILLING ONLY ===');
    print('Merge with existing: $mergeWithExisting');
    print('Input data: ${data.toJson()}');

    // Get enhanced field mapping
    final fieldMapping = UAEIdOCRService.getFormFieldMapping(data);
    print('Field mapping: $fieldMapping');

    // SKIP Personal Details Section - Do NOT auto-fill these fields:
    // - _firstNameController (First Name)
    // - _middleNameController (Middle Name)
    // - _lastNameController (Last Name)
    // - _mobileController (Mobile Number)
    // - _addressController (Address)
    // - _areaController (Area)
    // - _emiratesController (Emirates dropdown)
    // - _referenceController (Reference)

    print('=== SKIPPING PERSONAL DETAILS AUTO-FILL ===');
    print('Personal details will remain empty for manual entry');

    // ONLY fill Emirates ID extracted information fields
    // Fill ID name field (full name as per Emirates ID)
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

    // Do NOT auto-fill Emirates dropdown - let user select manually
    print('=== EMIRATES ID FIELDS FILLED ===');
    print('Card Number: ${data.cardNumber}');
    print('Occupation: ${data.occupation}');
    print('Employer: ${data.employer}');
    print('Issuing Place: ${data.issuingPlace}');
    print('=== PERSONAL DETAILS SECTION SKIPPED ===');

    // Force a rebuild to show the updated fields
    setState(() {});
  }

  @override
  void dispose() {
    _mainController.dispose();
    _fabController.dispose();
    _contractorTypeController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _emiratesController.dispose();
    _referenceController.dispose();
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
    _firmNameController.dispose();
    _vatAddressController.dispose();
    _trnController.dispose();
    _vatDateController.dispose();
    _licenseNumberController.dispose();
    _issuingAuthorityController.dispose();
    _licenseTypeController.dispose();
    _establishmentDateController.dispose();
    _expiryDateController.dispose();
    _tradeNameController.dispose();
    _responsiblePersonController.dispose();
    _licenseAddressController.dispose();
    _effectiveDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildModernAppBar(),
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
                  Colors.blue.shade50,
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ScaleTransition(
                scale: _scaleAnimation,
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
                          ModernDropdown(
                            label: 'Contractor Type',
                            icon: Icons.business_center_outlined,
                            items: _contractorTypes,
                            value: _contractorTypeController.text.isNotEmpty
                                ? _contractorTypeController.text
                                : null,
                            onChanged: (String? value) {
                              if (!_isLoadingDropdowns) {
                                setState(() {
                                  _contractorTypeController.text = value ?? '';
                                });
                              }
                            },
                            delay: const Duration(milliseconds: 50),
                          ),
                          const SizedBox(height: 16),
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
                            delay: const Duration(milliseconds: 200),
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
                            delay: const Duration(milliseconds: 400),
                          ),
                          const SizedBox(height: 16),
                          ModernDropdown(
                            label: 'Emirates',
                            icon: Icons.public_outlined,
                            items: _emirates,
                            value: _emiratesController.text.isNotEmpty
                                ? _emiratesController.text
                                : null,
                            onChanged: (String? value) {
                              if (!_isLoadingDropdowns) {
                                setState(() {
                                  _emiratesController.text = value ?? '';
                                });
                              }
                            },
                            delay: const Duration(milliseconds: 500),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _referenceController,
                            label: 'Reference',
                            icon: Icons.contact_page_outlined,
                            delay: const Duration(milliseconds: 600),
                          ),
                          const SizedBox(height: 16),
                          FileUploadWidget(
                            label: 'Profile Photo',
                            icon: Icons.camera_alt_outlined,
                            onFileSelected: (value) =>
                                setState(() => _photoImage = value),
                            delay: const Duration(milliseconds: 700),
                            allowedExtensions: const [
                              'jpg',
                              'jpeg',
                              'png',
                              'pdf',
                            ],
                            maxSizeInMB: 10.0,
                            currentFilePath: _photoImage,
                            formType: 'contractor',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Emirates ID Section
                      _buildModernSection(
                        title: 'Emirates ID',
                        icon: Icons.badge_outlined,
                        children: [
                          // Status indicator
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor().withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                if (_isProcessingEmiratesId)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  Icon(
                                    _getStatusIcon(),
                                    color: _getStatusColor(),
                                    size: 20,
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getStatusMessage(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _getStatusColor(),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Front side upload
                          FileUploadWidget(
                            label: 'Emirates ID - Front Side',
                            icon: Icons.credit_card_outlined,
                            onFileSelected: (value) {
                              setState(() => _emiratesIdFrontImage = value);
                              _checkAndProcessEmiratesId();
                            },
                            delay: const Duration(milliseconds: 800),
                            allowedExtensions: const [
                              'jpg',
                              'jpeg',
                              'png',
                              'pdf',
                            ],
                            maxSizeInMB: 10.0,
                            currentFilePath: _emiratesIdFrontImage,
                            formType: 'contractor',
                          ),
                          const SizedBox(height: 16),

                          // Back side upload
                          FileUploadWidget(
                            label: 'Emirates ID - Back Side',
                            icon: Icons.credit_card_outlined,
                            onFileSelected: (value) {
                              setState(() => _emiratesIdBackImage = value);
                              _checkAndProcessEmiratesId();
                            },
                            delay: const Duration(milliseconds: 900),
                            allowedExtensions: const [
                              'jpg',
                              'jpeg',
                              'png',
                              'pdf',
                            ],
                            maxSizeInMB: 10.0,
                            currentFilePath: _emiratesIdBackImage,
                            formType: 'contractor',
                          ),
                          const SizedBox(height: 16),

                          // Extracted Emirates ID fields
                          if (_emiratesIdFrontImage != null ||
                              _emiratesIdBackImage != null) ...[
                            const Divider(height: 32),
                            Text(
                              'Extracted Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildModernTextField(
                              controller: _emiratesIdController,
                              label: 'Emirates ID Number',
                              icon: Icons.badge_outlined,
                              delay: const Duration(milliseconds: 1000),
                            ),
                            const SizedBox(height: 16),
                            _buildModernTextField(
                              controller: _idNameController,
                              label: 'Full Name (as per Emirates ID)',
                              icon: Icons.person_outlined,
                              delay: const Duration(milliseconds: 1100),
                            ),
                            const SizedBox(height: 16),
                            _buildModernTextField(
                              controller: _dobController,
                              label: 'Date of Birth',
                              icon: Icons.cake_outlined,
                              delay: const Duration(milliseconds: 1200),
                            ),
                            const SizedBox(height: 16),
                            _buildModernTextField(
                              controller: _nationalityController,
                              label: 'Nationality',
                              icon: Icons.flag_outlined,
                              delay: const Duration(milliseconds: 1300),
                            ),
                            const SizedBox(height: 16),
                            _buildModernTextField(
                              controller: _issueDateController,
                              label: 'Issue Date',
                              icon: Icons.event_outlined,
                              delay: const Duration(milliseconds: 1400),
                            ),
                            const SizedBox(height: 16),
                            _buildModernTextField(
                              controller: _expiryDateController,
                              label: 'Expiry Date',
                              icon: Icons.event_available_outlined,
                              delay: const Duration(milliseconds: 1500),
                            ),
                            const SizedBox(height: 16),
                            _buildModernTextField(
                              controller: _occupationController,
                              label: 'Occupation',
                              icon: Icons.work_outlined,
                              isRequired: false,
                              delay: const Duration(milliseconds: 1600),
                            ),
                            const SizedBox(height: 16),
                            _buildModernTextField(
                              controller: _companyDetailsController,
                              label: 'Employer/Company',
                              icon: Icons.business_outlined,
                              isRequired: false,
                              delay: const Duration(milliseconds: 1700),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Bank Details Section
                      _buildModernSection(
                        title: 'Bank Details',
                        icon: Icons.account_balance_outlined,
                        children: [
                          _buildModernTextField(
                            controller: _accountHolderController,
                            label: 'Account Holder Name',
                            icon: Icons.person_outline_rounded,
                            delay: const Duration(milliseconds: 100),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _ibanController,
                            label: 'IBAN Number',
                            icon: Icons.account_balance_wallet_outlined,
                            delay: const Duration(milliseconds: 200),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _bankNameController,
                            label: 'Bank Name',
                            icon: Icons.business_outlined,
                            delay: const Duration(milliseconds: 300),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _branchNameController,
                            label: 'Branch Name',
                            icon: MapsIcons.map_outlined,
                            delay: const Duration(milliseconds: 400),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _bankAddressController,
                            label: 'Bank Address',
                            icon: Icons.location_city_outlined,
                            delay: const Duration(milliseconds: 500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // VAT Certificate Section
                      _buildModernSection(
                        title: 'VAT Certificate',
                        icon: Icons.receipt_long_outlined,
                        isOptional: true,
                        children: [
                          FileUploadWidget(
                            label: 'VAT Certificate',
                            icon: Icons.description_outlined,
                            onFileSelected: (value) =>
                                setState(() => _vatCertificateImage = value),
                            delay: const Duration(milliseconds: 100),
                            allowedExtensions: const [
                              'jpg',
                              'jpeg',
                              'png',
                              'pdf',
                            ],
                            maxSizeInMB: 10.0,
                            currentFilePath: _vatCertificateImage,
                            formType: 'contractor',
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _firmNameController,
                            label: 'Firm Name',
                            icon: Icons.business_outlined,
                            isRequired: false,
                            delay: const Duration(milliseconds: 200),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _vatAddressController,
                            label: 'Registered Address',
                            icon: Icons.home_outlined,
                            isRequired: false,
                            delay: const Duration(milliseconds: 300),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _trnController,
                            label: 'Tax Registration Number',
                            icon: Icons.pin_outlined,
                            isRequired: false,
                            delay: const Duration(milliseconds: 400),
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: _vatDateController,
                            label: 'Effective Date',
                            icon: Icons.event_outlined,
                            isRequired: false,
                            delay: const Duration(milliseconds: 500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Commercial License Section
                      _buildModernSection(
                        title: 'Commercial License',
                        icon: Icons.workspace_premium_outlined,
                        children: [
                          FileUploadWidget(
                            label: 'License Document',
                            icon: Icons.file_present_outlined,
                            onFileSelected: (value) =>
                                setState(() => _commercialLicenseImage = value),
                            delay: const Duration(milliseconds: 100),
                            allowedExtensions: const [
                              'jpg',
                              'jpeg',
                              'png',
                              'pdf',
                            ],
                            maxSizeInMB: 10.0,
                            currentFilePath: _commercialLicenseImage,
                            formType: 'contractor',
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _licenseNumberController,
                            label: 'License Number',
                            icon: Icons.pin_outlined,
                            delay: const Duration(milliseconds: 200),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _issuingAuthorityController,
                            label: 'Issuing Authority',
                            icon: Icons.account_balance_outlined,
                            delay: const Duration(milliseconds: 300),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _licenseTypeController,
                            label: 'License Type',
                            icon: Icons.category_outlined,
                            delay: const Duration(milliseconds: 400),
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: _establishmentDateController,
                            label: 'Establishment Date',
                            icon: Icons.event_outlined,
                            delay: const Duration(milliseconds: 500),
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: _expiryDateController,
                            label: 'Expiry Date',
                            icon: Icons.event_available_outlined,
                            delay: const Duration(milliseconds: 600),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _tradeNameController,
                            label: 'Trade Name',
                            icon: Icons.store_outlined,
                            delay: const Duration(milliseconds: 700),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _responsiblePersonController,
                            label: 'Responsible Person',
                            icon: Icons.person_outline_rounded,
                            delay: const Duration(milliseconds: 800),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _licenseAddressController,
                            label: 'Registered Address',
                            icon: Icons.home_outlined,
                            delay: const Duration(milliseconds: 900),
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: _effectiveDateController,
                            label: 'Effective Date',
                            icon: Icons.event_outlined,
                            delay: const Duration(milliseconds: 1000),
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
        'Contractor Registration',
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
              'Complete your contractor registration',
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
            return ContractorService.validateMobileNumber(value);
          }
          // Emirates ID validation
          if (label.toLowerCase().contains('emirates id')) {
            return ContractorService.validateEmiratesId(value);
          }
          // IBAN validation
          if (label.toLowerCase().contains('iban')) {
            return ContractorService.validateIban(value);
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
                'Optional fields can be skipped if not applicable.',
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // First, upload documents if they exist
        final documents = <DocumentUploadRequest>[];
        
        if (_photoImage != null && _photoImage!.isNotEmpty) {
          documents.add(DocumentUploadRequest(
            documentType: DocumentTypes.profilePhoto,
            filePath: _photoImage!,
            originalFileName: 'profile_photo.jpg',
          ));
        }
        
        if (_emiratesIdFrontImage != null && _emiratesIdFrontImage!.isNotEmpty) {
          documents.add(DocumentUploadRequest(
            documentType: DocumentTypes.emiratesIdFront,
            filePath: _emiratesIdFrontImage!,
            originalFileName: 'emirates_id_front.jpg',
          ));
        }
        
        if (_emiratesIdBackImage != null && _emiratesIdBackImage!.isNotEmpty) {
          documents.add(DocumentUploadRequest(
            documentType: DocumentTypes.emiratesIdBack,
            filePath: _emiratesIdBackImage!,
            originalFileName: 'emirates_id_back.jpg',
          ));
        }
        
        if (_vatCertificateImage != null && _vatCertificateImage!.isNotEmpty) {
          documents.add(DocumentUploadRequest(
            documentType: DocumentTypes.vatCertificate,
            filePath: _vatCertificateImage!,
            originalFileName: 'vat_certificate.pdf',
          ));
        }
        
        if (_commercialLicenseImage != null && _commercialLicenseImage!.isNotEmpty) {
          documents.add(DocumentUploadRequest(
            documentType: DocumentTypes.licenseDocument,
            filePath: _commercialLicenseImage!,
            originalFileName: 'commercial_license.pdf',
          ));
        }

        // Upload documents if any exist
        String? profilePhotoPath;
        String? emiratesIdFrontPath;
        String? emiratesIdBackPath;
        String? vatCertPath;
        String? licensePath;
        
        if (documents.isNotEmpty) {
          final uploadResponses = await ContractorService.uploadMultipleDocuments(documents);
          
          for (int i = 0; i < uploadResponses.length; i++) {
            final response = uploadResponses[i];
            final document = documents[i];
            
            if (response.success && response.filePath != null) {
              switch (document.documentType) {
                case DocumentTypes.profilePhoto:
                  profilePhotoPath = response.filePath;
                  break;
                case DocumentTypes.emiratesIdFront:
                  emiratesIdFrontPath = response.filePath;
                  break;
                case DocumentTypes.emiratesIdBack:
                  emiratesIdBackPath = response.filePath;
                  break;
                case DocumentTypes.vatCertificate:
                  vatCertPath = response.filePath;
                  break;
                case DocumentTypes.licenseDocument:
                  licensePath = response.filePath;
                  break;
              }
            } else {
              // Document upload failed, but continue with registration
              print('Document upload failed: ${document.documentType} - ${response.message}');
            }
          }
        }

        // Create contractor registration request
        final request = ContractorRegistrationRequest(
          // Personal Details
          contractorType: _contractorTypeController.text.trim(),
          firstName: _firstNameController.text.trim(),
          middleName: _middleNameController.text.trim().isEmpty ? null : _middleNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          mobileNumber: ContractorService.formatMobileNumber(_mobileController.text.trim()),
          address: _addressController.text.trim(),
          area: _areaController.text.trim(),
          emirates: _emiratesController.text.trim(),
          reference: _referenceController.text.trim(),
          profilePhoto: profilePhotoPath,

          // Emirates ID Details
          emiratesIdFront: emiratesIdFrontPath,
          emiratesIdBack: emiratesIdBackPath,
          emiratesIdNumber: ContractorService.formatEmiratesId(_emiratesIdController.text.trim()),
          idHolderName: _idNameController.text.trim(),
          dateOfBirth: _dobController.text.trim().isEmpty ? null : _dobController.text.trim(),
          nationality: _nationalityController.text.trim(),
          emiratesIdIssueDate: _issueDateController.text.trim().isEmpty ? null : _issueDateController.text.trim(),
          emiratesIdExpiryDate: _expiryDateController.text.trim().isEmpty ? null : _expiryDateController.text.trim(),
          occupation: _occupationController.text.trim().isEmpty ? null : _occupationController.text.trim(),
          employer: _companyDetailsController.text.trim().isEmpty ? null : _companyDetailsController.text.trim(),

          // Bank Details
          accountHolderName: _accountHolderController.text.trim().isEmpty ? null : _accountHolderController.text.trim(),
          ibanNumber: _ibanController.text.trim().isEmpty ? null : ContractorService.formatIban(_ibanController.text.trim()),
          bankName: _bankNameController.text.trim().isEmpty ? null : _bankNameController.text.trim(),
          branchName: _branchNameController.text.trim().isEmpty ? null : _branchNameController.text.trim(),
          bankAddress: _bankAddressController.text.trim().isEmpty ? null : _bankAddressController.text.trim(),

          // VAT Certificate Details
          vatCertificate: vatCertPath,
          firmName: _firmNameController.text.trim().isEmpty ? null : _firmNameController.text.trim(),
          vatAddress: _vatAddressController.text.trim().isEmpty ? null : _vatAddressController.text.trim(),
          taxRegistrationNumber: _trnController.text.trim().isEmpty ? null : _trnController.text.trim(),
          vatEffectiveDate: _vatDateController.text.trim().isEmpty ? null : _vatDateController.text.trim(),

          // Commercial License Details
          licenseDocument: licensePath,
          licenseNumber: _licenseNumberController.text.trim(),
          issuingAuthority: _issuingAuthorityController.text.trim(),
          licenseType: _licenseTypeController.text.trim(),
          establishmentDate: _establishmentDateController.text.trim().isEmpty ? null : _establishmentDateController.text.trim(),
          licenseExpiryDate: _licenseExpiryDateController.text.trim().isEmpty ? null : _licenseExpiryDateController.text.trim(),
          tradeName: _tradeNameController.text.trim(),
          responsiblePerson: _responsiblePersonController.text.trim(),
          licenseAddress: _licenseAddressController.text.trim(),
          effectiveDate: _effectiveDateController.text.trim().isEmpty ? null : _effectiveDateController.text.trim(),
        );

        // Submit contractor registration
        final response = await ContractorService.registerContractor(request);

        setState(() {
          _isSubmitting = false;
        });

        if (mounted) {
          if (response.success) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Registration successful! Contractor ID: ${response.contractorId ?? 'N/A'}',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
            
            // Navigate to success screen or previous screen
            Navigator.pop(context);
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Registration failed: ${response.message}'),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Registration failed: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }
}

// Custom icons class
class MapsIcons {
  static const map_outlined = IconData(0xe3f5, fontFamily: 'MaterialIcons');
}
