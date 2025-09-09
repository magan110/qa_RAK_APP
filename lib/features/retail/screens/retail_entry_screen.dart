import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rak_web/screens/home_screen.dart';

import '../../../core/widgets/modern_dropdown.dart';
import '../../../core/widgets/file_upload_widget.dart';

class RetailerRegistrationApp extends StatelessWidget {
  const RetailerRegistrationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: const RetailerRegistrationPage(),
    );
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
  bool _isSubmitting = false;

  // File paths
  String? _profileImage;
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
  TextEditingController stockistCodeController = TextEditingController();
  TextEditingController tallyRetailerCodeController = TextEditingController();
  TextEditingController concernEmployeeController = TextEditingController();
  TextEditingController aadharCardController = TextEditingController();
  TextEditingController proprietorNameController = TextEditingController();

  // Dropdown options
  List<String>? _states;
  List<String>? _areas;
  String? _areasCode;
  String? selectedOption; // To track the selected option for GST/PAN

  // Animation controllers
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
    stockistCodeController.dispose();
    tallyRetailerCodeController.dispose();
    concernEmployeeController.dispose();
    aadharCardController.dispose();
    proprietorNameController.dispose();
    super.dispose();
  }

  Future<String> retailCodes(String cat) async {
    final categoryMap = {'Urban': 'URB', 'Rural': 'RUR', 'Direct': 'DDR'};
    return categoryMap[cat] ?? '';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fill all required fields');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Get area name
      final areaName = Area.text;
      print('Retrieved area name: $areaName'); // Debug log
      if (areaName.isEmpty) {
        throw Exception('Invalid area name received');
      }

      // Get retail code
      final retailCode = await retailCodes(retailCat.text);
      print('Retrieved retail code: $retailCode'); // Debug log
      if (retailCode.isEmpty) {
        throw Exception('Invalid retail code received');
      }

      // Create a map of all form data
      final formData = {
        'processType': ProcesTp.text,
        'retailCategory': retailCat.text,
        'area': Area.text,
        'district': District.text,
        'gst': GST.text,
        'pan': PAN.text,
        'mobile': Mobile.text,
        'address': Address.text,
        'scheme': Scheme.text,
        'firmName': firmNameController.text,
        'officeTelephone': officeTelephoneController.text,
        'email': emailController.text,
        'address2': address2Controller.text,
        'address3': address3Controller.text,
        'stockistCode': stockistCodeController.text,
        'tallyRetailerCode': tallyRetailerCodeController.text,
        'concernEmployee': concernEmployeeController.text,
        'aadharCard': aadharCardController.text,
        'proprietorName': proprietorNameController.text,
      };

      // Print form data (in real app, you would send this to your API)
      print('Form Data Submitted: $formData');

      setState(() {
        _isSubmitting = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Registration submitted successfully!')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to home screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showError(e.toString());
    }
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        },
      ),
      title: const Text(
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
            child: const Text(
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
            child: const Text(
              'Complete your retailer registration',
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
    bool isRequired = true,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
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
        style: const TextStyle(fontSize: 14),
        inputFormatters: inputFormatters,
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
        validator:
            validator ??
            (isRequired ? (value) => _validateRequired(value, label) : null),
      ),
    );
  }

  Widget _buildModernRadioOptions({
    required String label,
    required List<String> options,
    required String? selectedOption,
    required Function(String?) onChanged,
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
          Row(
            children: [
              Icon(
                Icons.radio_button_checked_outlined,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                isRequired ? '$label *' : label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: options.map((option) {
              final isSelected = selectedOption == option;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () => onChanged(option),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? Colors.blue.shade50
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          option,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.blue.shade700
                                : Colors.grey.shade700,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableOptions({
    required String label,
    required List<String> options,
    required String? selectedOption,
    required Function(String?) onChanged,
    bool isRequired = true,
  }) {
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
                  onChanged(option);
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

  Widget _buildModernPredefinedField({
    required String label,
    required String value,
    required IconData icon,
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
        initialValue: value,
        enabled: false,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
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
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
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
                    Text('Submitting...', style: TextStyle(fontSize: 16)),
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
              const Icon(
                Icons.help_outline_rounded,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Registration Help',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Fill in all required fields marked with *. '
                'Make sure to upload all necessary documents for verification.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter mobile number';
    }
    if (value.length != 10) {
      return 'Mobile number must be 10 digits';
    }
    return null;
  }

  String? _validateGst(String? value) {
    if (selectedOption == 'GST' && (value == null || value.isEmpty)) {
      return 'Please enter GST number';
    }
    return null;
  }

  String? _validatePan(String? value) {
    if (selectedOption == 'PAN' && (value == null || value.isEmpty)) {
      return 'Please enter PAN number';
    }
    return null;
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
                      // Basic Details Section
                      _buildModernSection(
                        title: 'Basic Details',
                        icon: Icons.person_rounded,
                        children: [
                          ModernDropdown(
                            label: 'Process Type',
                            icon: Icons.swap_horiz,
                            items: ['Add', 'Update'],
                            value: ProcesTp.text.isNotEmpty
                                ? ProcesTp.text
                                : null,
                            onChanged: (value) {
                              setState(() {
                                ProcesTp.text = value ?? '';
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          ModernDropdown(
                            label: 'Retailer Category',
                            icon: Icons.category,
                            items: ['Urban', 'Rural', 'Direct Dealer'],
                            value: retailCat.text.isNotEmpty
                                ? retailCat.text
                                : null,
                            onChanged: (value) {
                              setState(() {
                                retailCat.text = value ?? '';
                              });
                            },
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
                          ),
                          const SizedBox(height: 16),
                          ModernDropdown(
                            label: 'District',
                            icon: Icons.location_city_outlined,
                            items: _areas ?? [],
                            value: District.text.isEmpty ? null : District.text,
                            onChanged: (value) {
                              setState(() {
                                District.text = value ?? '';
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildClickableOptions(
                            label: 'Register With',
                            options: ['GST', 'PAN'],
                            selectedOption: selectedOption,
                            onChanged: (value) {
                              setState(() {
                                selectedOption = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: GST,
                            label: 'GST Number',
                            icon: Icons.receipt_long,
                            validator: _validateGst,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: PAN,
                            label: 'PAN Number',
                            icon: Icons.credit_card,
                            validator: _validatePan,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: firmNameController,
                            label: 'Firm Name',
                            icon: Icons.business,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: Mobile,
                            label: 'Mobile',
                            icon: Icons.phone_outlined,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: _validateMobile,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: officeTelephoneController,
                            label: 'Office Telephone',
                            icon: Icons.phone_in_talk_outlined,
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
                          _buildModernPredefinedField(
                            label: 'Stockist Code',
                            value: '4401S711',
                            icon: Icons.qr_code_2_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: tallyRetailerCodeController,
                            label: 'Tally Retailer Code',
                            icon: Icons.code_outlined,
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
                            onFileSelected: (value) {
                              setState(() => _profileImage = value);
                            },
                            currentFilePath: _profileImage,
                            formType: 'retail',
                            allowedExtensions: const ['jpg', 'jpeg', 'png'],
                            maxSizeInMB: 10.0,
                          ),
                          const SizedBox(height: 16),
                          FileUploadWidget(
                            label: 'PAN / GST No Image',
                            icon: Icons.file_present_outlined,
                            onFileSelected: (value) {
                              setState(() => _panGstImage = value);
                            },
                            currentFilePath: _panGstImage,
                            formType: 'retail',
                            allowedExtensions: const [
                              'jpg',
                              'jpeg',
                              'png',
                              'pdf',
                            ],
                            maxSizeInMB: 10.0,
                          ),
                          const SizedBox(height: 16),
                          ModernDropdown(
                            label: 'Scheme Required',
                            icon: Icons.card_giftcard_outlined,
                            items: ['Yes', 'No'],
                            value: Scheme.text.isEmpty ? null : Scheme.text,
                            onChanged: (value) {
                              setState(() {
                                Scheme.text = value ?? '';
                              });
                            },
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: aadharCardController,
                            label: 'Aadhar Card No',
                            icon: Icons.badge_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          FileUploadWidget(
                            label: 'Aadhar Card Upload',
                            icon: Icons.file_upload_outlined,
                            onFileSelected: (value) {
                              setState(() => _aadharImage = value);
                            },
                            currentFilePath: _aadharImage,
                            formType: 'retail',
                            isRequired: false,
                            allowedExtensions: const [
                              'jpg',
                              'jpeg',
                              'png',
                              'pdf',
                            ],
                            maxSizeInMB: 10.0,
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
          ),
        ),
      ),
    );
  }
}
