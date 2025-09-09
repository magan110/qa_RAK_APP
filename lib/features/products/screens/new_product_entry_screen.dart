import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import '../../../core/widgets/file_upload_widget.dart';
import '../../../core/widgets/modern_dropdown.dart';

@JS()
@staticInterop
class WindowWithGeoLocation {}

extension WindowGeoLocationExtension on WindowWithGeoLocation {
  external JSPromise<JSAny?> requestGeoPosition();
}

class NewProductEntry extends StatefulWidget {
  @override
  _NewProductEntryState createState() => _NewProductEntryState();
}

class _NewProductEntryState extends State<NewProductEntry>
    with TickerProviderStateMixin {
  // Controllers
  final areaController = TextEditingController();
  final cityDistrictController = TextEditingController();
  final pinCodeController = TextEditingController();
  final customerNameController = TextEditingController();
  final contractorNameController = TextEditingController();
  final mobileController = TextEditingController();
  final addressController = TextEditingController();
  final siteTypeController = TextEditingController();
  final sampleReceiverController = TextEditingController();
  final targetDateController = TextEditingController();
  final remarksController = TextEditingController();
  final regionController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  final samplingDateController = TextEditingController();
  final productController = TextEditingController();
  final expectedOrderController = TextEditingController();
  final sampleTypeController = TextEditingController();

  // Animation controllers
  AnimationController? _mainController;
  AnimationController? _fabController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _scaleAnimation;

  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  String? _uploadedFileName;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

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

    // Auto-fill location on load
    _initLocation();
  }

  @override
  void dispose() {
    _mainController?.dispose();
    _fabController?.dispose();
    areaController.dispose();
    cityDistrictController.dispose();
    pinCodeController.dispose();
    customerNameController.dispose();
    contractorNameController.dispose();
    mobileController.dispose();
    addressController.dispose();
    siteTypeController.dispose();
    sampleReceiverController.dispose();
    targetDateController.dispose();
    remarksController.dispose();
    regionController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    samplingDateController.dispose();
    productController.dispose();
    expectedOrderController.dispose();
    sampleTypeController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('area', areaController.text);
        await prefs.setString('cityDistrict', cityDistrictController.text);
        await prefs.setString('pinCode', pinCodeController.text);
        await prefs.setString('customerName', customerNameController.text);
        await prefs.setString('contractorName', contractorNameController.text);
        await prefs.setString('mobile', mobileController.text);
        await prefs.setString('address', addressController.text);
        await prefs.setString('siteType', siteTypeController.text);
        await prefs.setString('sampleReceiver', sampleReceiverController.text);
        await prefs.setString('targetDate', targetDateController.text);
        await prefs.setString('remarks', remarksController.text);
        await prefs.setString('region', regionController.text);
        await prefs.setString('latitude', latitudeController.text);
        await prefs.setString('longitude', longitudeController.text);
        await prefs.setString('samplingDate', samplingDateController.text);
        await prefs.setString('product', productController.text);
        await prefs.setString('expectedOrder', expectedOrderController.text);
        await prefs.setString('sampleType', sampleTypeController.text);

        // Simulate API call
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('Form data saved successfully!')),
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
                  Icon(Icons.warning, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('Error saving data: ${e.toString()}')),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
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

  void _captureLocation() {
    // Location capture logic - now calls the web location
    _initLocation();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
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
                      // Site Details Section
                      _buildModernSection(
                        title: 'Site Details',
                        icon: Icons.location_city_rounded,
                        children: [
                          ModernDropdown(
                            label: 'Area',
                            icon: Icons.location_on_outlined,
                            items: const ['Area 1', 'Area 2', 'Area 3'],
                            value: areaController.text.isEmpty
                                ? null
                                : areaController.text,
                            onChanged: (String? newValue) {
                              setState(() {
                                areaController.text = newValue ?? '';
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          ModernDropdown(
                            label: 'City and District',
                            icon: Icons.location_city_outlined,
                            items: ['City 1', 'City 2', 'City 3'],
                            value: cityDistrictController.text.isEmpty
                                ? null
                                : cityDistrictController.text,
                            onChanged: (String? newValue) {
                              setState(() {
                                cityDistrictController.text = newValue ?? '';
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: pinCodeController,
                            label: 'Pin Code',
                            icon: Icons.pin_outlined,
                            isRequired: true,
                            delay: const Duration(milliseconds: 200),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: customerNameController,
                            label: 'Customer Name',
                            icon: Icons.person_outline_rounded,
                            isRequired: true,
                            delay: const Duration(milliseconds: 250),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: contractorNameController,
                            label: 'Contractor/Purchase Name',
                            icon: Icons.business_outlined,
                            isRequired: true,
                            delay: const Duration(milliseconds: 300),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: mobileController,
                            label: 'Mobile',
                            icon: Icons.phone_outlined,
                            isPhone: true,
                            isRequired: true,
                            delay: const Duration(milliseconds: 350),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: addressController,
                            label: 'Address',
                            icon: Icons.home_outlined,
                            isRequired: true,
                            delay: const Duration(milliseconds: 400),
                          ),
                          const SizedBox(height: 16),
                          ModernDropdown(
                            label: 'Site Type',
                            icon: Icons.domain_outlined,
                            items: ['Type 1', 'Type 2', 'Type 3'],
                            value: siteTypeController.text.isEmpty
                                ? null
                                : siteTypeController.text,
                            onChanged: (String? newValue) {
                              setState(() {
                                siteTypeController.text = newValue ?? '';
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          ModernDropdown(
                            label: 'Sample Local Received Person',
                            icon: Icons.person_search_outlined,
                            items: ['Person 1', 'Person 2', 'Person 3'],
                            value: sampleReceiverController.text.isEmpty
                                ? null
                                : sampleReceiverController.text,
                            onChanged: (String? newValue) {
                              setState(() {
                                sampleReceiverController.text = newValue ?? '';
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: targetDateController,
                            label: 'Target Date of Conversion',
                            icon: Icons.event_available_outlined,
                            isRequired: true,
                            delay: const Duration(milliseconds: 550),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: remarksController,
                            label: 'Remarks',
                            icon: Icons.note_outlined,
                            isRequired: true,
                            delay: const Duration(milliseconds: 600),
                          ),
                          const SizedBox(height: 16),
                          ModernDropdown(
                            label: 'Region of Construction',
                            icon: Icons.map_outlined,
                            items: ['Region 1', 'Region 2', 'Region 3'],
                            value: regionController.text.isEmpty
                                ? null
                                : regionController.text,
                            onChanged: (String? newValue) {
                              setState(() {
                                regionController.text = newValue ?? '';
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: [
                              _buildModernTextField(
                                controller: latitudeController,
                                label: 'Latitude',
                                icon: Icons.my_location_outlined,
                                isRequired: false,
                                delay: const Duration(milliseconds: 700),
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
                              const SizedBox(height: 24),
                              _buildModernTextField(
                                controller: longitudeController,
                                label: 'Longitude',
                                icon: Icons.my_location_outlined,
                                isRequired: false,
                                delay: const Duration(milliseconds: 750),
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
                            ],
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
                      const SizedBox(height: 20),
                      // Sampling Details Section
                      _buildModernSection(
                        title: 'Sampling Details',
                        icon: Icons.science_outlined,
                        children: [
                          _buildModernDateField(
                            controller: samplingDateController,
                            label: 'Sampling Date',
                            icon: Icons.calendar_today_outlined,
                            isRequired: false,
                            delay: const Duration(milliseconds: 100),
                          ),
                          const SizedBox(height: 16),
                          ModernDropdown(
                            label: 'Product',
                            icon: Icons.inventory_2_outlined,
                            items: ['Product 1', 'Product 2', 'Product 3'],
                            value: productController.text.isEmpty
                                ? null
                                : productController.text,
                            onChanged: (String? newValue) {
                              setState(() {
                                productController.text = newValue ?? '';
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: expectedOrderController,
                            label: 'Site Material Expected Order (kg)',
                            icon: Icons.scale_outlined,
                            isRequired: false,
                            delay: const Duration(milliseconds: 200),
                          ),
                          const SizedBox(height: 16),
                          ModernDropdown(
                            label: 'Sample Type',
                            icon: Icons.category_outlined,
                            items: ['Type A', 'Type B', 'Type C'],
                            value: sampleTypeController.text.isEmpty
                                ? null
                                : sampleTypeController.text,
                            onChanged: (String? newValue) {
                              setState(() {
                                sampleTypeController.text = newValue ?? '';
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          FileUploadWidget(
                            label: 'Sample Photo',
                            icon: Icons.camera_alt_outlined,
                            onFileSelected: (value) =>
                                setState(() => _uploadedFileName = value),
                            delay: const Duration(milliseconds: 300),
                            allowedExtensions: const ['jpg', 'jpeg', 'png'],
                            maxSizeInMB: 5.0,
                            currentFilePath: _uploadedFileName,
                            formType: 'product_entry',
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
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      title: Text(
        'New Sample Product Entry',
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
    Widget? suffix,
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

  Widget _buildModernButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Duration delay = Duration.zero,
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
      child: SizedBox(
        height: 56,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          label: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: Colors.blue.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                    Text('Submitting...'),
                  ],
                )
              : Text(
                  'Submit Entry',
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
                'Entry Help',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Fill in all required fields marked with *. '
                'You can capture location automatically and upload sample photos.',
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
