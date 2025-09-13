import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/contractor_service.dart';
import '../../../core/models/contractor_models.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';
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
  final _formKey = GlobalKey<FormState>();

  // Personal
  final _contractorTypeController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _emiratesController = TextEditingController();
  final _referenceController = TextEditingController();

  // Bank
  final _accountHolderController = TextEditingController();
  final _ibanController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _bankAddressController = TextEditingController();

  // VAT
  final _firmNameController = TextEditingController();
  final _vatAddressController = TextEditingController();
  final _trnController = TextEditingController();
  final _vatDateController = TextEditingController();

  // License
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

  Future<void> _loadDropdownData() async {
    try {
      final contractorTypes = await ContractorService.getContractorTypes();
      final emirates = await ContractorService.getEmiratesList();
      setState(() {
        _contractorTypes = contractorTypes;
        _emirates = emirates;
        _isLoadingDropdowns = false;
      });
    } catch (_) {
      setState(() {
        _contractorTypes = const ['Maintenance Contractor', 'Petty contractors'];
        _emirates = const [
          'Dubai',
          'Abu Dhabi',
          'Sharjah',
          'Ajman',
          'Umm Al Quwain',
          'Ras Al Khaimah',
          'Fujairah'
        ];
        _isLoadingDropdowns = false;
      });
    }
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
    _licenseExpiryDateController.dispose();
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
                      _buildAnimatedHeader(),
                      const SizedBox(height: 30),

                      // Personal Details
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
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _firstNameController,
                            label: 'First Name',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _middleNameController,
                            label: 'Middle Name',
                            icon: Icons.person_outline_rounded,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _lastNameController,
                            label: 'Last Name',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _mobileController,
                            label: 'Mobile Number',
                            icon: Icons.phone_outlined,
                            isPhone: true,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _addressController,
                            label: 'Address',
                            icon: Icons.home_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _areaController,
                            label: 'Area',
                            icon: Icons.location_on_outlined,
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
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _referenceController,
                            label: 'Reference',
                            icon: Icons.contact_page_outlined,
                            isRequired: false,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Bank Details
                      _buildModernSection(
                        title: 'Bank Details',
                        icon: Icons.account_balance_outlined,
                        children: [
                          _buildModernTextField(
                            controller: _accountHolderController,
                            label: 'Account Holder Name',
                            icon: Icons.person_outline_rounded,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _ibanController,
                            label: 'IBAN Number',
                            icon: Icons.account_balance_wallet_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _bankNameController,
                            label: 'Bank Name',
                            icon: Icons.business_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _branchNameController,
                            label: 'Branch Name',
                            icon: Icons.map_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _bankAddressController,
                            label: 'Bank Address',
                            icon: Icons.location_city_outlined,
                            isRequired: false,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // VAT Certificate (no upload, all optional)
                      _buildModernSection(
                        title: 'VAT Certificate',
                        icon: Icons.receipt_long_outlined,
                        children: [
                          _buildModernTextField(
                            controller: _firmNameController,
                            label: 'Firm Name',
                            icon: Icons.business_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _vatAddressController,
                            label: 'Registered Address',
                            icon: Icons.home_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _trnController,
                            label: 'Tax Registration Number',
                            icon: Icons.pin_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: _vatDateController,
                            label: 'Effective Date',
                            icon: Icons.event_outlined,
                            isRequired: false,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Commercial License (no upload)
                      _buildModernSection(
                        title: 'Commercial License',
                        icon: Icons.workspace_premium_outlined,
                        children: [
                          _buildModernTextField(
                            controller: _licenseNumberController,
                            label: 'License Number',
                            icon: Icons.pin_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _issuingAuthorityController,
                            label: 'Issuing Authority',
                            icon: Icons.account_balance_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _licenseTypeController,
                            label: 'License Type',
                            icon: Icons.category_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: _establishmentDateController,
                            label: 'Establishment Date',
                            icon: Icons.event_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: _licenseExpiryDateController,
                            label: 'Expiry Date',
                            icon: Icons.event_available_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _tradeNameController,
                            label: 'Trade Name',
                            icon: Icons.store_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _responsiblePersonController,
                            label: 'Responsible Person',
                            icon: Icons.person_outline_rounded,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _licenseAddressController,
                            label: 'Registered Address',
                            icon: Icons.home_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: _effectiveDateController,
                            label: 'Effective Date',
                            icon: Icons.event_outlined,
                            isRequired: false,
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
      title: const Text('Contractor Registration',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded),
          onPressed: () => _showHelpDialog(),
        ),
      ],
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
    bool isPhone = false,
    bool isRequired = true,
  }) {
    return TextFormField(
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
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'Please enter $label';
        }
        if (isPhone && value != null && value.isNotEmpty) {
          return ContractorService.validateMobileNumber(value);
        }
        if (label.toLowerCase().contains('iban')) {
          return ContractorService.validateIban(value);
        }
        return null;
      },
    );
  }

  Widget _buildModernDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = true,
  }) {
    return TextFormField(
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
          controller.text = date.toString().split(' ').first;
        }
      },
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildAnimatedSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.blue.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            : const Text('Submit Registration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                'Fill in all required fields marked with *. Optional fields can be skipped.',
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
          Text('Welcome!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )),
          SizedBox(height: 8),
          Text('Complete your contractor registration',
              style: TextStyle(fontSize: 16, color: Colors.white70)),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final request = ContractorRegistrationRequest(
  contractorType: _contractorTypeController.text,
  firstName: _firstNameController.text,
  middleName: _middleNameController.text,
  lastName: _lastNameController.text,
  mobileNumber: ContractorService.formatMobileNumber(_mobileController.text),
  address: _addressController.text,
  area: _areaController.text,
  emirates: _emiratesController.text,
  reference: _referenceController.text,

  // Bank
  accountHolderName: _accountHolderController.text,
  ibanNumber: ContractorService.formatIban(_ibanController.text),
  bankName: _bankNameController.text,
  branchName: _branchNameController.text,
  bankAddress: _bankAddressController.text,

  // VAT
  firmName: _firmNameController.text,
  vatAddress: _vatAddressController.text,
  taxRegistrationNumber: _trnController.text,
  vatEffectiveDate: _vatDateController.text,

  // License
  licenseNumber: _licenseNumberController.text,
  issuingAuthority: _issuingAuthorityController.text,
  licenseType: _licenseTypeController.text,
  establishmentDate: _establishmentDateController.text,
  licenseExpiryDate: _licenseExpiryDateController.text,
  tradeName: _tradeNameController.text,
  responsiblePerson: _responsiblePersonController.text,
  licenseAddress: _licenseAddressController.text,
  effectiveDate: _effectiveDateController.text,
);

        final response = await ContractorService.registerContractor(request);
        if (!mounted) return;
        setState(() => _isSubmitting = false);

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          'Registration successful! Contractor ID: ${response.contractorId ?? 'N/A'}')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Registration failed: ${response.message}')),
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
