import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/file_upload_widget.dart';
import '../../../core/services/uae_id_ocr_service.dart';
import '../../../core/services/bank_details_ocr_service.dart';
import '../../../core/widgets/modern_dropdown.dart';

// NEW: API model + service
import '../../../core/models/painter_models.dart';
import '../../../core/services/painter_service.dart';

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

  // ---------- Emirates ID processing ----------
  Future<void> _checkAndProcessEmiratesId() async {
    if (_emiratesIdFrontImage == null ||
        _emiratesIdFrontImage!.isEmpty ||
        _emiratesIdBackImage == null ||
        _emiratesIdBackImage!.isEmpty) {
      return;
    }

    setState(() => _isProcessingEmiratesId = true);

    try {
      final frontData = await UAEIdOCRService.processUAEId(_emiratesIdFrontImage!);
      final backData = await UAEIdOCRService.processUAEId(_emiratesIdBackImage!);
      final combinedData = _combineEmiratesIdData(frontData, backData);
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
                    'Emirates ID processed successfully!',
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
      if (mounted) setState(() => _isProcessingEmiratesId = false);
    }
  }

  UAEIdData _combineEmiratesIdData(UAEIdData frontData, UAEIdData backData) {
    return UAEIdData(
      name: frontData.name ?? backData.name,
      idNumber: frontData.idNumber ?? backData.idNumber,
      dateOfBirth: frontData.dateOfBirth ?? backData.dateOfBirth,
      nationality: frontData.nationality ?? backData.nationality,
      issuingDate: frontData.issuingDate ?? backData.issuingDate,
      expiryDate: frontData.expiryDate ?? backData.expiryDate,
      sex: frontData.sex ?? backData.sex,
      signature: frontData.signature ?? backData.signature,
      cardNumber: backData.cardNumber ?? frontData.cardNumber,
      occupation: backData.occupation ?? frontData.occupation,
      employer: backData.employer ?? frontData.employer,
      issuingPlace: backData.issuingPlace ?? frontData.issuingPlace,
    );
  }

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

  IconData _getStatusIcon() {
    final frontUploaded =
        _emiratesIdFrontImage != null && _emiratesIdFrontImage!.isNotEmpty;
    final backUploaded =
        _emiratesIdBackImage != null && _emiratesIdBackImage!.isNotEmpty;
    if (frontUploaded && backUploaded) return Icons.check_circle;
    if (frontUploaded || backUploaded) return Icons.upload_file;
    return Icons.info_outline;
  }

  String _getStatusMessage() {
    if (_isProcessingEmiratesId) {
      return 'Processing both sides of Emirates ID...';
    }
    final frontUploaded =
        _emiratesIdFrontImage != null && _emiratesIdFrontImage!.isNotEmpty;
    final backUploaded =
        _emiratesIdBackImage != null && _emiratesIdBackImage!.isNotEmpty;

    if (frontUploaded && backUploaded) {
      return '✅ Both sides uploaded successfully!';
    }
    if (frontUploaded && !backUploaded) {
      return 'Front side uploaded. Please upload the back side.';
    }
    if (!frontUploaded && backUploaded) {
      return 'Back side uploaded. Please upload the front side.';
    }
    return 'Please upload both sides of your Emirates ID.';
  }

  // ---------- Bank doc OCR ----------
  Color _getBankDocumentStatusColor() {
    if (_isProcessingBankDocument) return Colors.blue;
    final bankDocumentUploaded =
        _bankDocumentImage != null && _bankDocumentImage!.isNotEmpty;
    if (bankDocumentUploaded) return Colors.green;
    return Colors.grey;
  }

  IconData _getBankDocumentStatusIcon() {
    final bankDocumentUploaded =
        _bankDocumentImage != null && _bankDocumentImage!.isNotEmpty;
    if (bankDocumentUploaded) return Icons.check_circle;
    return Icons.info_outline;
  }

  String _getBankDocumentStatusMessage() {
    if (_isProcessingBankDocument) {
      return 'Processing bank document...';
    }
    final bankDocumentUploaded =
        _bankDocumentImage != null && _bankDocumentImage!.isNotEmpty;
    if (bankDocumentUploaded) {
      return '✅ Bank document uploaded successfully!';
    }
    return 'Upload a bank statement, cheque, or bank document.';
  }

  void _fillEmiratesIdFields(UAEIdData data, {bool mergeWithExisting = false}) {
    final fieldMapping = UAEIdOCRService.getFormFieldMapping(data);

    if (fieldMapping['firstName'] != null &&
        (!mergeWithExisting || _firstNameController.text.isEmpty)) {
      _firstNameController.text = fieldMapping['firstName']!;
    }
    if (fieldMapping['middleName'] != null &&
        (!mergeWithExisting || _middleNameController.text.isEmpty)) {
      _middleNameController.text = fieldMapping['middleName']!;
    }
    if (fieldMapping['lastName'] != null &&
        (!mergeWithExisting || _lastNameController.text.isEmpty)) {
      _lastNameController.text = fieldMapping['lastName']!;
    }
    if (fieldMapping['idName'] != null &&
        (!mergeWithExisting || _idNameController.text.isEmpty)) {
      _idNameController.text = fieldMapping['idName']!;
    }

    if (data.idNumber?.isNotEmpty == true &&
        (!mergeWithExisting || _emiratesIdController.text.isEmpty)) {
      _emiratesIdController.text = data.idNumber!;
    }
    if (data.dateOfBirth?.isNotEmpty == true &&
        (!mergeWithExisting || _dobController.text.isEmpty)) {
      _dobController.text = data.dateOfBirth!;
    }
    if (data.nationality?.isNotEmpty == true &&
        (!mergeWithExisting || _nationalityController.text.isEmpty)) {
      _nationalityController.text = data.nationality!;
    }
    if (data.issuingDate?.isNotEmpty == true &&
        (!mergeWithExisting || _issueDateController.text.isEmpty)) {
      _issueDateController.text = data.issuingDate!;
    }
    if (data.expiryDate?.isNotEmpty == true &&
        (!mergeWithExisting || _expiryDateController.text.isEmpty)) {
      _expiryDateController.text = data.expiryDate!;
    }
    if (data.occupation?.isNotEmpty == true &&
        (!mergeWithExisting || _occupationController.text.isEmpty)) {
      _occupationController.text = data.occupation!;
    }
    if (data.employer?.isNotEmpty == true &&
        (!mergeWithExisting || _companyDetailsController.text.isEmpty)) {
      _companyDetailsController.text = data.employer!;
    }

    if (data.issuingPlace?.isNotEmpty == true &&
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
        (e) =>
            e.toLowerCase().contains(data.issuingPlace!.toLowerCase()) ||
            data.issuingPlace!.toLowerCase().contains(e.toLowerCase()),
        orElse: () => '',
      );
      if (matchingEmirate.isNotEmpty) {
        _emiratesController.text = matchingEmirate;
      }
    }
    setState(() {});
  }

  Future<void> _processBankDocument() async {
    if (_bankDocumentImage == null || _bankDocumentImage!.isEmpty) return;

    setState(() => _isProcessingBankDocument = true);

    try {
      final bankData =
          await BankDetailsOCRService.processBankDocument(_bankDocumentImage!);
      _fillBankDetailsFields(bankData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Bank document processed successfully!'),
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
      if (mounted) setState(() => _isProcessingBankDocument = false);
    }
  }

  void _fillBankDetailsFields(BankDetailsData data) {
    if (data.accountHolderName != null &&
        _accountHolderController.text.isEmpty) {
      _accountHolderController.text = data.accountHolderName!;
    }
    if (data.ibanNumber != null && _ibanController.text.isEmpty) {
      _ibanController.text = data.ibanNumber!;
    }
    if (data.bankName != null && _bankNameController.text.isEmpty) {
      _bankNameController.text = data.bankName!;
    }
    if (data.branchName != null && _branchNameController.text.isEmpty) {
      _branchNameController.text = data.branchName!;
    }
    if (data.bankAddress != null && _bankAddressController.text.isEmpty) {
      _bankAddressController.text = data.bankAddress!;
    }
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
        opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
        child: SlideTransition(
          position: _slideAnimation ?? const AlwaysStoppedAnimation(Offset.zero),
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
                scale: _scaleAnimation ?? const AlwaysStoppedAnimation(1.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildAnimatedHeader(),
                      const SizedBox(height: 30),

                      // Personal Details
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
                            // FIXED: show selected value correctly
                            value: _emiratesController.text.isNotEmpty
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
                              setState(() => _photoImage = value);
                            },
                            delay: const Duration(milliseconds: 500),
                            allowedExtensions: const ['*'],
                            maxSizeInMB: 10.0,
                            currentFilePath: _photoImage,
                            formType: 'painter',
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Emirates ID
                      _buildModernSection(
                        title: 'Emirates ID',
                        icon: Icons.badge_outlined,
                        children: [
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

                      // Bank Details
                      _buildModernSection(
                        title: 'Bank Details',
                        icon: Icons.account_balance_outlined,
                        isOptional: true,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _getBankDocumentStatusColor().withOpacity(0.1),
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
                          FileUploadWidget(
                            label: 'Bank Statement or Cheque',
                            icon: Icons.receipt_long_outlined,
                            onFileSelected: (value) {
                              setState(() => _bankDocumentImage = value);
                              _processBankDocument();
                            },
                            delay: const Duration(milliseconds: 50),
                            allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
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
      title: const Text(
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Complete your painter registration',
            style: TextStyle(fontSize: 16, color: Colors.white70),
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
          // header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800)),
                      if (isOptional)
                        Text('Optional',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // content
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      // ✅ No phone-format validation — allow any input
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'Please enter $label';
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
          suffixIcon: const Icon(Icons.calendar_today_rounded, color: Colors.grey),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              : const Text(
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
              const Icon(Icons.help_outline_rounded, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              const Text('Registration Help',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                'Fill in all required fields marked with *. Bank details are optional but recommended for payments.',
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

  // Map OCR (optional helper)
  void _mapOcrResultsToFields(Map<String, String> ocrResults) {
    if (ocrResults['name']?.isNotEmpty == true) {
      final nameParts = ocrResults['name']!.split(' ');
      if (nameParts.isNotEmpty) {
        _firstNameController.text = nameParts.first;
        _idNameController.text = ocrResults['name']!;
      }
      if (nameParts.length > 1) {
        _lastNameController.text = nameParts.last;
      }
      if (nameParts.length > 2) {
        _middleNameController.text =
            nameParts.skip(1).take(nameParts.length - 2).join(' ');
      }
    }
    if (ocrResults['aadhaar']?.isNotEmpty == true) {
      _emiratesIdController.text = ocrResults['aadhaar']!;
    }
    if (ocrResults['dob']?.isNotEmpty == true) {
      _dobController.text = ocrResults['dob']!;
    }
    setState(() {});
  }

  // --------------------- SUBMIT ---------------------
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final req = PainterRegistrationRequest(
          // Personal
          firstName: _firstNameController.text.trim(),
          middleName: _middleNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          address: _addressController.text.trim(),
          area: _areaController.text.trim(),
          emirates: _emiratesController.text.trim(),
          reference: (_selectedReference ?? '').trim(),

          // Emirates ID
          emiratesIdNumber: _emiratesIdController.text.trim(),
          idName: _idNameController.text.trim(),
          dateOfBirth: _dobController.text.trim(),
          nationality: _nationalityController.text.trim(),
          companyDetails: _companyDetailsController.text.trim(),
          issueDate: _issueDateController.text.trim(),
          expiryDate: _expiryDateController.text.trim(),
          occupation: _occupationController.text.trim(),

          // Bank
          accountHolderName: _accountHolderController.text.trim(),
          ibanNumber: PainterService.formatIban(_ibanController.text.trim()),
          bankName: _bankNameController.text.trim(),
          branchName: _branchNameController.text.trim(),
          bankAddress: _bankAddressController.text.trim(),
        );

        final resp = await PainterService.registerPainter(req);

        if (!mounted) return;
        setState(() => _isSubmitting = false);

        if (resp.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Saved! ID: ${resp.influencerCode ?? 'N/A'}')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          Navigator.pop(context); // or pushNamed('/success')
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(resp.message)),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
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
