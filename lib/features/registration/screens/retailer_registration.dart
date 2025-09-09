import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../screens/home_screen.dart';
import '../../../core/widgets/file_upload_widget.dart';
import '../../../core/widgets/modern_dropdown.dart';

class RetailerRegistration extends StatelessWidget {
  const RetailerRegistration({super.key});

  @override
  Widget build(BuildContext context) {
    return const RetailerRegistrationPage();
  }
}

class RetailerRegistrationPage extends StatefulWidget {
  const RetailerRegistrationPage({super.key});

  @override
  State<RetailerRegistrationPage> createState() =>
      _RetailerRegistrationPageState();
}

class _RetailerRegistrationPageState extends State<RetailerRegistrationPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  //  late final RetailerService _retailerService;
  String? _areasCode;
  List<String>? _areas;
  List<String>? _states;

  // Upload widget variables
  String? _retailerProfileImage;
  String? _panGstImage;
  String? _aadharImage;

  // Form controllers
  TextEditingController ProcesTp = TextEditingController();
  TextEditingController retailCat = TextEditingController();
  TextEditingController Area = TextEditingController();
  TextEditingController District = TextEditingController();
  TextEditingController GST = TextEditingController();
  TextEditingController PAN = TextEditingController();
  TextEditingController Mobile = TextEditingController();
  TextEditingController Address = TextEditingController();
  TextEditingController Scheme = TextEditingController();
  TextEditingController firmNameController = TextEditingController();
  TextEditingController officeTelephoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController address2Controller = TextEditingController();
  TextEditingController address3Controller = TextEditingController();
  TextEditingController tallyRetailerCodeController = TextEditingController();
  TextEditingController concernEmployeeController = TextEditingController();
  TextEditingController aadharCardController = TextEditingController();
  TextEditingController proprietorNameController = TextEditingController();

  // Animation controllers
  AnimationController? _mainController;
  AnimationController? _fabController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _scaleAnimation;

  bool _isSubmitting = false;

  String? selectedOption; // To track the selected option

  // Future<void> _loadStates() async {
  //   try {
  //     final data = await api.getStates();
  //     setState(() {
  //       _states = data;
  //     });
  //   } catch (e) {
  //     print('Error loading data: $e');
  //   }
  // }

  Future<String> retailCodes(String cat) async {
    final categoryMap = {'Urban': 'URB', 'Rural': 'RUR', 'Direct': 'DDR'};
    return categoryMap[cat] ?? '';
  }

  @override
  void initState() {
    super.initState();
    // _retailerService = RetailerService(api: ApiService());
    // _loadStates();

    // Initialize animations
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

  // Future<void> _loadArea(String state) async {
  //   try {
  //     final areas = await _retailerService.getAreas(state);
  //     setState(() {
  //       _areas = areas;
  //     });
  //   } catch (e) {
  //     _showError('Error loading areas: $e');
  //   }
  // }

  // Future<void> areaCodes(String district) async {
  //   try {
  //     final code = await _retailerService.getAreaCode(district);
  //     setState(() {
  //       _areasCode = code;
  //     });
  //     print(_areasCode);
  //   } catch (e) {
  //     _showError('Error getting area code: $e');
  //   }
  // }

  // Add this helper method for showing errors
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Modify your submit button's onPressed handler
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fill all required fields');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get area code first
      final areaCode = District.text;
      print('Retrieved area code: $areaCode'); // Debug log
      if (areaCode.isEmpty) {
        throw Exception('Invalid area code received');
      }

      // Get retail code
      final retailCode = await retailCodes(retailCat.text);
      print('Retrieved retail code: $retailCode'); // Debug log
      if (retailCode.isEmpty) {
        throw Exception('Invalid retail code received');
      }

      // Generate document number
      final year = (DateTime.now().year % 100).toString();
      // final doc = await _retailerService.generateDocumentNumber(
      //   year,
      //   areaCode,
      //   retailCode,
      // );
      // print('Generated document number: $doc'); // Debug log

      // // Submit data
      // await _retailerService.submitRetailerData(
      //   doc: doc,
      //   processType: ProcesTp.text,
      //   gst: GST.text,
      //   time: DateTime.now(),
      //   mobile: Mobile.text,
      //   area: Area.text,
      //   district: District.text,
      //   retailCategory: retailCat.text,
      //   address: Address.text,
      // );

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _mainController?.dispose();
    _fabController?.dispose();
    ProcesTp.dispose();
    retailCat.dispose();
    Area.dispose();
    District.dispose();
    GST.dispose();
    PAN.dispose();
    Mobile.dispose();
    Address.dispose();
    Scheme.dispose();
    firmNameController.dispose();
    officeTelephoneController.dispose();
    emailController.dispose();
    address2Controller.dispose();
    address3Controller.dispose();
    tallyRetailerCodeController.dispose();
    concernEmployeeController.dispose();
    aadharCardController.dispose();
    proprietorNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildModernAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white, Colors.grey.shade50],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                _buildAnimatedHeader(),
                const SizedBox(height: 30),
                // Basic Details Section
                _buildModernSection(
                  title: 'Basic Details',
                  icon: Icons.person_rounded,
                  children: [
                    ModernDropdown(
                      label: 'Process Type',
                      icon: Icons.swap_horiz_outlined,
                      items: const ['Add', 'Update'],
                      value: ProcesTp.text.isNotEmpty ? ProcesTp.text : null,
                      onChanged: (value) {
                        setState(() {
                          ProcesTp.text = value ?? '';
                        });
                      },
                      delay: const Duration(milliseconds: 50),
                    ),
                    const SizedBox(height: 16),
                    ModernDropdown(
                      label: 'Retailer Category',
                      icon: Icons.store_outlined,
                      items: const ['Urban', 'Rural', 'Direct Dealer'],
                      value: retailCat.text.isNotEmpty ? retailCat.text : null,
                      onChanged: (value) {
                        setState(() {
                          retailCat.text = value ?? '';
                        });
                      },
                      delay: const Duration(milliseconds: 100),
                    ),
                    const SizedBox(height: 16),
                    ModernDropdown(
                      label: 'Area',
                      icon: Icons.location_on_outlined,
                      items: _states ?? [],
                      value: Area.text.isNotEmpty ? Area.text : null,
                      onChanged: (value) {
                        setState(() {
                          Area.text = value ?? '';
                          District.text = '';
                        });
                      },
                      delay: const Duration(milliseconds: 150),
                    ),
                    const SizedBox(height: 16),
                    ModernDropdown(
                      label: 'District',
                      icon: Icons.location_city_outlined,
                      items: _areas ?? [],
                      value: District.text.isNotEmpty ? District.text : null,
                      onChanged: (value) {
                        setState(() {
                          District.text = value ?? '';
                        });
                      },
                      delay: const Duration(milliseconds: 200),
                    ),
                    const SizedBox(height: 16),
                    _buildClickableOptions('Register With PAN/GST', [
                      'GST',
                      'PAN',
                    ]),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: GST,
                      label: 'GST Number',
                      icon: Icons.receipt_long_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: PAN,
                      label: 'PAN Number',
                      icon: Icons.credit_card_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: firmNameController,
                      label: 'Firm Name',
                      icon: Icons.business_outlined,
                      isRequired: false,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: Mobile,
                      label: 'Mobile',
                      icon: Icons.phone_outlined,
                      isPhone: true,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: officeTelephoneController,
                      label: 'Office Telephone',
                      icon: Icons.call_outlined,
                      isRequired: false,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      isRequired: false,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: Address,
                      label: 'Address 1',
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: address2Controller,
                      label: 'Address 2',
                      icon: Icons.home_outlined,
                      isRequired: false,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: address3Controller,
                      label: 'Address 3',
                      icon: Icons.home_outlined,
                      isRequired: false,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Contact Details Section
                _buildModernSection(
                  title: 'Contact Details',
                  icon: Icons.contact_page_outlined,
                  children: [
                    _buildPredefinedField('Stockist Code', '4401S711'),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: tallyRetailerCodeController,
                      label: 'Tally Retailer Code',
                      icon: Icons.qr_code_outlined,
                      isRequired: false,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: concernEmployeeController,
                      label: 'Concern Employee',
                      icon: Icons.person_outline_rounded,
                      isRequired: false,
                    ),
                    const SizedBox(height: 16),
                    FileUploadWidget(
                      label: 'Retailer Profile Image',
                      icon: Icons.camera_alt_outlined,
                      onFileSelected: (value) =>
                          setState(() => _retailerProfileImage = value),
                      allowedExtensions: const ['*'],
                      maxSizeInMB: 5.0,
                      currentFilePath: _retailerProfileImage,
                      formType: 'retailer',
                    ),
                    const SizedBox(height: 16),
                    FileUploadWidget(
                      label: 'PAN / GST No Image Upload / View',
                      icon: Icons.file_upload_outlined,
                      onFileSelected: (value) =>
                          setState(() => _panGstImage = value),
                      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
                      maxSizeInMB: 5.0,
                      currentFilePath: _panGstImage,
                      formType: 'retailer',
                    ),
                    const SizedBox(height: 16),
                    ModernDropdown(
                      label: 'Scheme Required',
                      icon: Icons.card_giftcard_outlined,
                      items: const ['Yes', 'No'],
                      value: Scheme.text.isNotEmpty ? Scheme.text : null,
                      onChanged: (value) {
                        setState(() {
                          Scheme.text = value ?? '';
                        });
                      },
                      delay: const Duration(milliseconds: 250),
                      isRequired: false,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: aadharCardController,
                      label: 'Aadhar Card No',
                      icon: Icons.perm_identity_outlined,
                      isRequired: false,
                    ),
                    const SizedBox(height: 16),
                    FileUploadWidget(
                      label: 'Aadhar Card Upload',
                      icon: Icons.file_upload_outlined,
                      onFileSelected: (value) =>
                          setState(() => _aadharImage = value),
                      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
                      maxSizeInMB: 5.0,
                      currentFilePath: _aadharImage,
                      formType: 'retailer',
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: proprietorNameController,
                      label: 'Proprietor / Partner Name',
                      icon: Icons.person_outline_rounded,
                      isRequired: false,
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
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  }
                },
              ),
            )
          : null,
      title: Text(
        'Retailer Registration',
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
          Text(
            'Welcome!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your retailer registration',
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
    required dynamic icon,
    bool isPhone = false,
    bool isRequired = true,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: icon is Icon
            ? icon
            : Icon(icon as IconData, color: Colors.grey.shade600),
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
      inputFormatters: inputFormatters,
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
    );
  }

  Widget _buildClickableOptions(String label, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: options.map((option) {
            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedOption = option;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedOption == option
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: selectedOption == option
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: selectedOption == option
                          ? Colors.blue
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPredefinedField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 56,
          child: TextFormField(
            initialValue: value,
            enabled: false,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.lock_outlined, color: Colors.grey),
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
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildAnimatedSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
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
                  Text('Submitting...'),
                ],
              )
            : Text(
                'Submit Registration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                'Contact details are important for verification.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
