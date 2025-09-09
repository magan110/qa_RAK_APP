import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/modern_dropdown.dart';

class SampleDistributEntry extends StatefulWidget {
  @override
  _SampleDistributEntryState createState() => _SampleDistributEntryState();
}

class _SampleDistributEntryState extends State<SampleDistributEntry>
    with TickerProviderStateMixin {
  // Controllers
  final emiratesController = TextEditingController();
  final areaController = TextEditingController();
  final retailerNameController = TextEditingController();
  final retailerCodeController = TextEditingController();
  final distributorController = TextEditingController();
  final painterNameController = TextEditingController();
  final painterMobileController = TextEditingController();
  final skuSizeController = TextEditingController();
  final materialQtyController = TextEditingController();
  final distributionDateController = TextEditingController();

  // Animation controllers
  AnimationController? _mainController;
  AnimationController? _fabController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _scaleAnimation;

  bool _isSubmitting = false;
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
  }

  @override
  void dispose() {
    _mainController?.dispose();
    _fabController?.dispose();
    emiratesController.dispose();
    areaController.dispose();
    retailerNameController.dispose();
    retailerCodeController.dispose();
    distributorController.dispose();
    painterNameController.dispose();
    painterMobileController.dispose();
    skuSizeController.dispose();
    materialQtyController.dispose();
    distributionDateController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('emirates', emiratesController.text);
        await prefs.setString('area', areaController.text);
        await prefs.setString('retailerName', retailerNameController.text);
        await prefs.setString('retailerCode', retailerCodeController.text);
        await prefs.setString('distributor', distributorController.text);
        await prefs.setString('painterName', painterNameController.text);
        await prefs.setString('painterMobile', painterMobileController.text);
        await prefs.setString('skuSize', skuSizeController.text);
        await prefs.setString('materialQty', materialQtyController.text);
        await prefs.setString(
          'distributionDate',
          distributionDateController.text,
        );

        // Simulate API call
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Sample distribution data saved successfully!'),
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
                      // Retailer Details Section
                      _buildModernSection(
                        title: 'Retailer Details',
                        icon: Icons.store_rounded,
                        children: [
                          _buildModernTextField(
                            controller: emiratesController,
                            label: 'Emirates ID',
                            icon: Icons.badge_outlined,
                            delay: const Duration(milliseconds: 100),
                          ),
                          const SizedBox(height: 16),
                          ModernDropdown(
                            label: 'Area',
                            icon: Icons.location_on_outlined,
                            items: const ['Area 1', 'Area 2', 'Area 3'],
                            value: areaController.text.isEmpty
                                ? null
                                : areaController.text,
                            onChanged: (value) {
                              setState(() {
                                areaController.text = value ?? '';
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: retailerNameController,
                            label: 'Retailer Name',
                            icon: Icons.store_outlined,
                            delay: const Duration(milliseconds: 200),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: retailerCodeController,
                            label: 'Retailer Code',
                            icon: Icons.qr_code_outlined,
                            delay: const Duration(milliseconds: 250),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: distributorController,
                            label: 'Concern Distributor',
                            icon: Icons.business_outlined,
                            delay: const Duration(milliseconds: 300),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Distribution Details Section
                      _buildModernSection(
                        title: 'Distribution Details',
                        icon: Icons.local_shipping_outlined,
                        children: [
                          _buildModernTextField(
                            controller: painterNameController,
                            label: 'Name of Painter / Contractor',
                            icon: Icons.person_outline_rounded,
                            delay: const Duration(milliseconds: 100),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: painterMobileController,
                            label: 'Mobile no Painter / Contractor',
                            icon: Icons.phone_outlined,
                            isPhone: true,
                            delay: const Duration(milliseconds: 150),
                          ),
                          const SizedBox(height: 16),
                          ModernDropdown(
                            label: 'SKU Size (1/5 Kg)',
                            icon: Icons.inventory_2_outlined,
                            items: const ['1 Kg', '5 Kg'],
                            value: skuSizeController.text.isEmpty
                                ? null
                                : skuSizeController.text,
                            onChanged: (value) {
                              setState(() {
                                skuSizeController.text = value ?? '';
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: materialQtyController,
                            label: 'Material distributed in Kg.',
                            icon: Icons.scale_outlined,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            delay: const Duration(milliseconds: 250),
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: distributionDateController,
                            label: 'Date of distribution',
                            icon: Icons.event_available_outlined,
                            delay: const Duration(milliseconds: 300),
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
        'Retailer Onboarding Form',
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
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
        keyboardType:
            keyboardType ??
            (isPhone ? TextInputType.phone : TextInputType.text),
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
                  'Submit Distribution',
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
                'Distribution Help',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Fill in all required fields marked with *. '
                'Ensure all distribution details are accurate before submission.',
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
