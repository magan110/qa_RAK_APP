import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

@JS()
@staticInterop
class WindowWithGeoLocation {}

extension WindowGeoLocationExtension on WindowWithGeoLocation {
  external JSPromise<JSAny?> requestGeoPosition();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RetailerOnboardingApp());
}

class RetailerOnboardingApp extends StatelessWidget {
  const RetailerOnboardingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retailer Onboarding',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: RetailerFormPage(),
    );
  }
}

class RetailerFormPage extends StatefulWidget {
  const RetailerFormPage({super.key});

  @override
  _RetailerFormPageState createState() => _RetailerFormPageState();
}

class _RetailerFormPageState extends State<RetailerFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final bool _isVATRequired = true;
  bool _isSubmitting = false;
  bool _isGettingLocation = false;

  // File paths (reserved for future use)
  String? _licenseImage;
  String? _vatCertificateImage;
  String? _addressProofImage;

  // Controllers
  final firmNameController = TextEditingController();
  final taxRegNumberController = TextEditingController();
  final registeredAddressController = TextEditingController();
  final effectiveDateController = TextEditingController();
  final licenseNumberController = TextEditingController();
  final issuingAuthorityController = TextEditingController();
  final establishmentDateController = TextEditingController();
  final expiryDateController = TextEditingController();
  final tradeNameController = TextEditingController();
  final responsiblePersonController = TextEditingController();
  final accountNameController = TextEditingController();
  final ibanController = TextEditingController();
  final bankNameController = TextEditingController();
  final branchNameController = TextEditingController();
  final branchAddressController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();

  // Animations
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

    // Auto-fill on load
    _initLocation();
  }

  @override
  void dispose() {
    _mainController?.dispose();
    _fabController?.dispose();
    firmNameController.dispose();
    taxRegNumberController.dispose();
    registeredAddressController.dispose();
    effectiveDateController.dispose();
    licenseNumberController.dispose();
    issuingAuthorityController.dispose();
    establishmentDateController.dispose();
    expiryDateController.dispose();
    tradeNameController.dispose();
    responsiblePersonController.dispose();
    accountNameController.dispose();
    ibanController.dispose();
    bankNameController.dispose();
    branchNameController.dispose();
    branchAddressController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  // --- GEOLOCATION (using web JavaScript helper from index.html) ---
  Future<void> _initLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      await _getWebLocation();
    } catch (e) {
      _toast('Could not fetch location: $e');
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _getWebLocation() async {
    try {
      // First try to get from localStorage (cached values from index.html)
      final lastLat = web.window.localStorage.getItem('lastLat');
      final lastLng = web.window.localStorage.getItem('lastLng');

      if (lastLat != null && lastLng != null && mounted) {
        latitudeController.text = double.parse(lastLat).toStringAsFixed(6);
        longitudeController.text = double.parse(lastLng).toStringAsFixed(6);
      }

      // Use the JavaScript geolocation helper from index.html
      final jsWindow = web.window as WindowWithGeoLocation;
      final result = await jsWindow.requestGeoPosition().toDart;

      if (result != null) {
        // Convert JSAny to proper Dart object
        final resultDart = result.dartify();

        if (resultDart is Map<String, dynamic>) {
          if (resultDart['ok'] == true) {
            if (mounted) {
              final lat = resultDart['lat'] as num?;
              final lng = resultDart['lng'] as num?;
              if (lat != null && lng != null) {
                latitudeController.text = lat.toStringAsFixed(6);
                longitudeController.text = lng.toStringAsFixed(6);
              }
            }
          } else {
            final error = resultDart['error']?.toString() ?? 'Unknown error';
            _toast('Web geolocation failed: $error');
          }
        }
      }
    } catch (e) {
      _toast('Web geolocation error: $e');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _saveData() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2)); // simulate API
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firmName', firmNameController.text);
    await prefs.setString('taxRegNumber', taxRegNumberController.text);
    await prefs.setString(
      'registeredAddress',
      registeredAddressController.text,
    );
    await prefs.setString('effectiveDate', effectiveDateController.text);
    await prefs.setString('licenseNumber', licenseNumberController.text);
    await prefs.setString('issuingAuthority', issuingAuthorityController.text);
    await prefs.setString(
      'establishmentDate',
      establishmentDateController.text,
    );
    await prefs.setString('expiryDate', expiryDateController.text);
    await prefs.setString('tradeName', tradeNameController.text);
    await prefs.setString(
      'responsiblePerson',
      responsiblePersonController.text,
    );
    await prefs.setString('accountName', accountNameController.text);
    await prefs.setString('iban', ibanController.text);
    await prefs.setString('bankName', bankNameController.text);
    await prefs.setString('branchName', branchNameController.text);
    await prefs.setString('branchAddress', branchAddressController.text);
    await prefs.setString('latitude', latitudeController.text);
    await prefs.setString('longitude', longitudeController.text);

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Data Saved Successfully')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushNamed(context, '/success');
    }
  }

  String? _validateTaxRegNumber(String? value) {
    if (_isVATRequired && (value == null || value.isEmpty)) {
      return 'Please enter Tax Registration Number';
    }
    if (value != null &&
        value.isNotEmpty &&
        !RegExp(r'^\d{15}$').hasMatch(value)) {
      return 'Tax Registration Number must be 15 digits';
    }
    return null;
  }

  String? _validateLicense(String? value) {
    if (value == null || value.isEmpty) return 'Please enter License Number';
    if (value.length > 20) return 'Max 20 characters allowed';
    return null;
  }

  String? _validateIBAN(String? value) {
    if (value != null &&
        value.isNotEmpty &&
        !RegExp(r'^AE\d{21}$').hasMatch(value)) {
      return 'IBAN must start with AE and be 23 characters';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) return 'Please enter $fieldName';
    return null;
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
      title: const Text(
        'Retailer Onboarding',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded),
          onPressed: _showHelpDialog,
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
            color: Colors.blue.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _FadeSlide(text: 'Welcome!', big: true),
          SizedBox(height: 8),
          _FadeSlide(text: 'Complete your retailer registration'),
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
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                  decoration: const BoxDecoration(
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
                if (title == 'Location Details')
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _isGettingLocation ? 1 : 0,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content
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
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          suffixIcon: suffix,
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
            (isRequired ? (v) => _validateRequired(v, label) : null),
      ),
    );
  }

  Widget _buildModernDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required BuildContext context,
    bool isRequired = true,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: true,
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
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: Colors.blue),
              ),
              child: child!,
            ),
          );
          if (date != null && mounted) {
            controller.text = date.toString().split(' ').first;
          }
        },
        validator: isRequired ? (v) => _validateRequired(v, label) : null,
      ),
    );
  }

  Widget _buildAnimatedSubmitButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) =>
          Transform.scale(scale: 0.8 + (0.2 * value), child: child),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: Colors.blue.withValues(alpha: 0.3),
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
                'Fill in all required fields marked with *.\nVAT Registration is required only if your firm\'s Annual Turnover exceeds AED 375,000.',
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      await _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildModernAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
        child: SlideTransition(
          position:
              _slideAnimation ?? const AlwaysStoppedAnimation(Offset.zero),
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

                      // Trade License
                      _buildModernSection(
                        title: 'Trade License Details',
                        icon: Icons.assignment_rounded,
                        children: [
                          _buildModernTextField(
                            controller: licenseNumberController,
                            label: 'License Number',
                            icon: Icons.confirmation_number,
                            validator: _validateLicense,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: issuingAuthorityController,
                            label: 'Issuing Authority',
                            icon: Icons.account_balance,
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: establishmentDateController,
                            label: 'Establishment Date',
                            icon: Icons.event,
                            context: context,
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: expiryDateController,
                            label: 'Expiry Date',
                            icon: Icons.event_busy,
                            context: context,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: tradeNameController,
                            label: 'Trade Name',
                            icon: Icons.store,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: responsiblePersonController,
                            label: 'Responsible Person',
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: registeredAddressController,
                            label: 'Registered Address',
                            icon: Icons.location_on,
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: effectiveDateController,
                            label: 'Effective Registration Date',
                            icon: Icons.calendar_today,
                            context: context,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'License Numbers vary across Emirates. (Max 20 Characters)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // VAT
                      if (_isVATRequired)
                        _buildModernSection(
                          title: 'VAT Registration Details',
                          icon: Icons.receipt_long,
                          isOptional: true,
                          children: [
                            _buildModernTextField(
                              controller: taxRegNumberController,
                              label: 'Tax Registration Number',
                              icon: Icons.numbers,
                              validator: _validateTaxRegNumber,
                            ),
                            const SizedBox(height: 16),
                            _buildModernTextField(
                              controller: firmNameController,
                              label: 'Firm Name',
                              icon: Icons.business,
                            ),
                            const SizedBox(height: 16),
                            _buildModernDateField(
                              controller: effectiveDateController,
                              label: 'Effective Registration Date',
                              icon: Icons.calendar_today,
                              context: context,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Required only if the firm\'s Annual Turnover exceeds AED 375,000.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // Bank
                      _buildModernSection(
                        title: 'Bank Details',
                        icon: Icons.account_balance_outlined,
                        isOptional: true,
                        children: [
                          _buildModernTextField(
                            controller: accountNameController,
                            label: 'Account Holder Name',
                            icon: Icons.person_outline_rounded,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: ibanController,
                            label: 'IBAN Number',
                            icon: Icons.account_balance_wallet_outlined,
                            isRequired: false,
                            validator: _validateIBAN,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: bankNameController,
                            label: 'Bank Name',
                            icon: Icons.business_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: branchNameController,
                            label: 'Branch Name',
                            icon: Icons.location_on_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: branchAddressController,
                            label: 'Branch Address',
                            icon: Icons.location_city_outlined,
                            isRequired: false,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Location
                      _buildModernSection(
                        title: 'Location Details',
                        icon: Icons.location_on_outlined,
                        isOptional: true,
                        children: [
                          _buildModernTextField(
                            controller: latitudeController,
                            label: 'Latitude',
                            icon: Icons.my_location,
                            isRequired: false,
                            suffix: IconButton(
                              tooltip: 'Refresh location',
                              icon: const Icon(Icons.gps_fixed),
                              onPressed: _isGettingLocation
                                  ? null
                                  : () async {
                                      HapticFeedback.selectionClick();
                                      await _initLocation();
                                    },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: longitudeController,
                            label: 'Longitude',
                            icon: Icons.my_location,
                            isRequired: false,
                            suffix: IconButton(
                              tooltip: 'Refresh location',
                              icon: const Icon(Icons.gps_fixed),
                              onPressed: _isGettingLocation
                                  ? null
                                  : () async {
                                      HapticFeedback.selectionClick();
                                      await _initLocation();
                                    },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _isGettingLocation
                                      ? 'Fetching GPS…'
                                      : (latitudeController.text.isEmpty ||
                                            longitudeController.text.isEmpty)
                                      ? 'Tap the GPS icon if fields are empty.'
                                      : 'Coordinates captured from your device GPS.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
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
}

class _FadeSlide extends StatelessWidget {
  final String text;
  final bool big;
  const _FadeSlide({required this.text, this.big = false});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 30 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: big ? 32 : 16,
          fontWeight: big ? FontWeight.bold : FontWeight.normal,
          color: big ? Colors.white : Colors.white70,
        ),
      ),
    );
  }
}
