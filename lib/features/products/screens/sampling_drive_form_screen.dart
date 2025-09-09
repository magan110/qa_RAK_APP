import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/file_upload_widget.dart';
import '../../../core/widgets/modern_dropdown.dart';

class SamplingDriveFormPage extends StatefulWidget {
  @override
  _SamplingDriveFormPageState createState() => _SamplingDriveFormPageState();
}

class _SamplingDriveFormPageState extends State<SamplingDriveFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _photoImage;
  // Controllers for all fields
  final retailerController = TextEditingController();
  final retailerCodeController = TextEditingController();
  final distributorController = TextEditingController();
  final areaController = TextEditingController();
  final dateController = TextEditingController();
  final painterController = TextEditingController();
  final phoneController = TextEditingController();
  final skuController = TextEditingController();
  final qtyController = TextEditingController();
  final missedQtyController = TextEditingController();
  final reimbursementModeController = TextEditingController();
  final reimbursementAmtController = TextEditingController();

  bool _isSubmitting = false;
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
    retailerController.dispose();
    retailerCodeController.dispose();
    distributorController.dispose();
    areaController.dispose();
    dateController.dispose();
    painterController.dispose();
    phoneController.dispose();
    skuController.dispose();
    qtyController.dispose();
    missedQtyController.dispose();
    reimbursementModeController.dispose();
    reimbursementAmtController.dispose();
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
                      // Sample Material Distribution Section
                      _buildModernSection(
                        title: 'Sample Material Distribution',
                        icon: Icons.inventory_2_outlined,
                        children: [
                          _buildModernTextField(
                            controller: retailerController,
                            label: 'Retailer',
                            icon: Icons.store_outlined,
                            delay: const Duration(milliseconds: 100),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: retailerCodeController,
                            label: 'Retailer Code',
                            icon: Icons.qr_code_outlined,
                            delay: const Duration(milliseconds: 150),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: distributorController,
                            label: 'Concern Distributor',
                            icon: Icons.business_outlined,
                            delay: const Duration(milliseconds: 200),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: areaController,
                            label: 'Area',
                            icon: Icons.location_city_outlined,
                            delay: const Duration(milliseconds: 250),
                          ),
                          const SizedBox(height: 16),
                          _buildModernDateField(
                            controller: dateController,
                            label: 'Date of Distribution',
                            icon: Icons.calendar_today_outlined,
                            delay: const Duration(milliseconds: 300),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Execution Details Section
                      _buildModernSection(
                        title: 'Execution Details',
                        icon: Icons.engineering_outlined,
                        children: [
                          _buildModernTextField(
                            controller: painterController,
                            label: 'Painter/Contractor Name',
                            icon: Icons.person_outline_rounded,
                            delay: const Duration(milliseconds: 100),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: phoneController,
                            label: 'Contact Number',
                            icon: Icons.phone_outlined,
                            isPhone: true,
                            delay: const Duration(milliseconds: 150),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: skuController,
                            label: 'SKU / Size (kg)',
                            icon: Icons.format_list_numbered_outlined,
                            delay: const Duration(milliseconds: 200),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: qtyController,
                            label: 'Material Qty Distributed (Kg)',
                            icon: Icons.inventory_outlined,
                            isNumeric: true,
                            delay: const Duration(milliseconds: 250),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: missedQtyController,
                            label: 'Missed Quantity (if any)',
                            icon: Icons.error_outline_outlined,
                            isRequired: false,
                            isNumeric: true,
                            delay: const Duration(milliseconds: 300),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Sample Proof Section
                      _buildModernSection(
                        title: 'Sample Proof',
                        icon: Icons.photo_camera_outlined,
                        children: [
                          FileUploadWidget(
                            label: 'Sample Photograph',
                            icon: Icons.camera_alt_outlined,
                            onFileSelected: (value) {
                              setState(() => _photoImage = value);
                            },
                            delay: const Duration(milliseconds: 100),
                            allowedExtensions: const ['jpg', 'jpeg', 'png'],
                            maxSizeInMB: 10.0,
                            currentFilePath: _photoImage,
                            formType: 'sampling',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Reimbursement Section
                      _buildModernSection(
                        title: 'Reimbursement',
                        icon: Icons.payments_outlined,
                        children: [
                          ModernDropdown(
                            label: 'Reimbursement Mode',
                            icon: Icons.monetization_on_outlined,
                            items: [
                              'By Hired Painter: 250 AED',
                              'By Site Painter: 150 AED',
                            ],
                            value: reimbursementModeController.text.isEmpty
                                ? null
                                : reimbursementModeController.text,
                            onChanged: (String? value) {
                              setState(() {
                                reimbursementModeController.text = value ?? '';
                                // Auto-fill amount based on selection
                                if (value != null) {
                                  if (value.contains('250')) {
                                    reimbursementAmtController.text = '250';
                                  } else if (value.contains('150')) {
                                    reimbursementAmtController.text = '150';
                                  }
                                }
                              });
                            },
                            delay: const Duration(milliseconds: 100),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: reimbursementAmtController,
                            label: 'Amount Reimbursed',
                            icon: Icons.attach_money_outlined,
                            isNumeric: true,
                            delay: const Duration(milliseconds: 150),
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
      title: Text(
        'WallCare Putty Sampling Drive',
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
              'Sampling Drive Form',
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
              'WallCare Putty Sampling Drive by Employee',
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
    bool isNumeric = false,
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
        keyboardType: isPhone
            ? TextInputType.phone
            : isNumeric
            ? TextInputType.number
            : TextInputType.text,
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
                    Text('Submitting...', style: TextStyle(fontSize: 16)),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                'Sampling Drive Help',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Fill in all required fields marked with *. '
                'Reimbursement amount will be auto-filled based on the selected mode.',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Sampling Entry Saved Successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
