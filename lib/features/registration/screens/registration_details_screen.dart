import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';

class RegistrationDetailsScreen extends StatefulWidget {
  const RegistrationDetailsScreen({super.key});

  @override
  State<RegistrationDetailsScreen> createState() =>
      _RegistrationDetailsScreenState();
}

class _RegistrationDetailsScreenState extends State<RegistrationDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _cardAnimations = [];

  // Sample registration data
  final Map<String, dynamic> _registrationData = {
    'id': 'REG001',
    'name': 'John Doe',
    'type': 'Contractor',
    'mobile': '+971 501234567',
    'email': 'john.doe@example.com',
    'submittedDate': '2024-01-15',
    'status': 'Pending',
    'fullName': 'John Doe',
    'address': 'Dubai, UAE',
    'reference': 'Employee - Ahmed Ali',
    'companyName': 'John Doe Contracting',
    'licenseNumber': 'LIC-001234',
    'trnNumber': '123456789012345',
    'accountHolder': 'John Doe',
    'iban': 'AE123456789012345678901',
    'bankName': 'Emirates NBD',
    'branch': 'Dubai Main Branch',
    'avatar': 'JD',
  };

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

    // Initialize card animations
    for (int i = 0; i < 4; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      final animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      );
      _cardControllers.add(controller);
      _cardAnimations.add(animation);

      // Stagger the card animations
      Future.delayed(Duration(milliseconds: 200 + (i * 100)), () {
        if (mounted) controller.forward();
      });
    }

    _mainController.forward();
    _fabController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _fabController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

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
                  Colors.cyan.shade50,
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final isTablet =
                    constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
                final isDesktop = constraints.maxWidth >= 1200;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : (isTablet ? 24 : 32)),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with animation
                        _buildAnimatedHeader(isMobile, isTablet, isDesktop),

                        SizedBox(height: isMobile ? 24 : 32),

                        // Registration Information Card
                        _buildRegistrationInfoCard(isMobile, 0),

                        SizedBox(height: isMobile ? 16 : 24),

                        // Personal Details Card
                        _buildPersonalDetailsCard(isMobile, 1),

                        SizedBox(height: isMobile ? 16 : 24),

                        // Business Details Card
                        _buildBusinessDetailsCard(isMobile, 2),

                        SizedBox(height: isMobile ? 16 : 24),

                        // Bank Details Card
                        _buildBankDetailsCard(isMobile, 3),

                        SizedBox(height: isMobile ? 24 : 32),

                        // Action Buttons
                        _buildActionButtons(isMobile),

                        SizedBox(height: isMobile ? 24 : 32),
                      ],
                    ),
                  ),
                );
              },
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
      foregroundColor: Colors.cyan.shade800,
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
        'Registration Details',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
    );
  }

  Widget _buildAnimatedHeader(bool isMobile, bool isTablet, bool isDesktop) {
    final statusColor = _registrationData['status'] == 'Pending'
        ? Colors.orange
        : _registrationData['status'] == 'Approved'
        ? Colors.green
        : Colors.red;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : (isTablet ? 25 : 30)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan.shade700, Colors.cyan.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          isMobile ? 16 : (isTablet ? 18 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.2),
            blurRadius: isMobile ? 15 : 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
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
                        'Registration Details',
                        style: TextStyle(
                          fontSize: isMobile ? 24 : (isTablet ? 28 : 32),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
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
                            'ID: ${_registrationData['id']}',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _registrationData['status'] as String,
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  width: isMobile ? 50 : 60,
                  height: isMobile ? 50 : 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _registrationData['type'] == 'Contractor'
                        ? Icons.business_rounded
                        : Icons.format_paint_rounded,
                    color: Colors.white,
                    size: isMobile ? 24 : 30,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationInfoCard(bool isMobile, int cardIndex) {
    return ScaleTransition(
      scale: _cardAnimations[cardIndex],
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
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
            Row(
              children: [
                Container(
                  width: isMobile ? 36 : 40,
                  height: isMobile ? 36 : 40,
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_rounded,
                    color: Colors.cyan.shade700,
                    size: isMobile ? 18 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Registration Information',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Registration ID:',
              _registrationData['id'] as String,
              isMobile,
            ),
            _buildInfoRow(
              'Name:',
              _registrationData['name'] as String,
              isMobile,
            ),
            _buildInfoRow(
              'Type:',
              _registrationData['type'] as String,
              isMobile,
            ),
            _buildInfoRow(
              'Mobile:',
              _registrationData['mobile'] as String,
              isMobile,
            ),
            _buildInfoRow(
              'Email:',
              _registrationData['email'] as String,
              isMobile,
            ),
            _buildInfoRow(
              'Submitted Date:',
              _registrationData['submittedDate'] as String,
              isMobile,
            ),
            _buildInfoRow(
              'Status:',
              _registrationData['status'] as String,
              isMobile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsCard(bool isMobile, int cardIndex) {
    return ScaleTransition(
      scale: _cardAnimations[cardIndex],
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
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
            Row(
              children: [
                Container(
                  width: isMobile ? 36 : 40,
                  height: isMobile ? 36 : 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.blue.shade700,
                    size: isMobile ? 18 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Personal Details',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Full Name:',
              _registrationData['fullName'] as String,
              isMobile,
            ),
            _buildInfoRow(
              'Address:',
              _registrationData['address'] as String,
              isMobile,
            ),
            _buildInfoRow(
              'Reference:',
              _registrationData['reference'] as String,
              isMobile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessDetailsCard(bool isMobile, int cardIndex) {
    return ScaleTransition(
      scale: _cardAnimations[cardIndex],
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
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
            Row(
              children: [
                Container(
                  width: isMobile ? 36 : 40,
                  height: isMobile ? 36 : 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    color: Colors.green.shade700,
                    size: isMobile ? 18 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Business Details',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Company Name:',
              _registrationData['companyName'] as String,
              isMobile,
            ),
            _buildInfoRow(
              'License Number:',
              _registrationData['licenseNumber'] as String,
              isMobile,
            ),
            _buildInfoRow(
              'TRN Number:',
              _registrationData['trnNumber'] as String,
              isMobile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetailsCard(bool isMobile, int cardIndex) {
    return ScaleTransition(
      scale: _cardAnimations[cardIndex],
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
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
            Row(
              children: [
                Container(
                  width: isMobile ? 36 : 40,
                  height: isMobile ? 36 : 40,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: Colors.purple.shade700,
                    size: isMobile ? 18 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Bank Details',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Account Holder:',
              _registrationData['accountHolder'] as String,
              isMobile,
            ),
            _buildInfoRow(
              'IBAN:',
              _registrationData['iban'] as String,
              isMobile,
            ),
            _buildInfoRow(
              'Bank Name:',
              _registrationData['bankName'] as String,
              isMobile,
            ),
            _buildInfoRow(
              'Branch:',
              _registrationData['branch'] as String,
              isMobile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 120 : 150,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _showApproveDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 4,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded),
                const SizedBox(width: 8),
                Text(
                  'Approve',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _showRejectDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 4,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cancel_rounded),
                const SizedBox(width: 8),
                Text(
                  'Reject',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 30,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Approve Registration',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to approve this registration?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '100 bonus points will be awarded upon \napproval.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 19, 149, 255),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Cancel', style: AppTheme.body),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/success');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Approve',
                        style: AppTheme.success.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_rounded,
                  size: 30,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reject Registration',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please provide a reason for rejection:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Enter rejection reason...',
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Registration rejected successfully',
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
