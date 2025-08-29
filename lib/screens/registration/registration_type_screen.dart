import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rak_web/theme.dart';

class RegistrationTypeScreen extends StatefulWidget {
  const RegistrationTypeScreen({super.key});

  @override
  State<RegistrationTypeScreen> createState() => _RegistrationTypeScreenState();
}

class _RegistrationTypeScreenState extends State<RegistrationTypeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _contractorCardController;
  late AnimationController _painterCardController;
  late AnimationController _ocrCardController; // Added OCR card controller
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _contractorCardAnimation;
  late Animation<double> _painterCardAnimation;
  late Animation<double> _ocrCardAnimation; // Added OCR card animation

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _contractorCardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _painterCardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _ocrCardController = AnimationController(
      // Initialize OCR controller
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
      ),
    );
    _contractorCardAnimation = CurvedAnimation(
      parent: _contractorCardController,
      curve: Curves.elasticOut,
    );
    _painterCardAnimation = CurvedAnimation(
      parent: _painterCardController,
      curve: Curves.elasticOut,
    );
    _ocrCardAnimation = CurvedAnimation(
      // Initialize OCR animation
      parent: _ocrCardController,
      curve: Curves.elasticOut,
    );

    _animationController.forward();
    // Stagger the card animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contractorCardController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _painterCardController.forward();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      // Added delay for OCR card
      if (mounted) _ocrCardController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _contractorCardController.dispose();
    _painterCardController.dispose();
    _ocrCardController.dispose(); // Dispose OCR controller
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
                  Colors.blue.shade50,
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
                      children: [
                        // Header with animation
                        _buildAnimatedHeader(isMobile, isTablet, isDesktop),
                        SizedBox(height: isMobile ? 24 : 40),
                        // Registration type cards
                        isMobile
                            ? _buildMobileCards()
                            : _buildDesktopCards(isTablet, isDesktop),
                        SizedBox(height: isMobile ? 24 : 40),
                        // Information section
                        _buildInformationSection(isMobile),
                        SizedBox(height: isMobile ? 24 : 40),
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
      foregroundColor: Colors.blue.shade800,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      title: Text(
        'Registration Type',
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

  Widget _buildAnimatedHeader(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : (isTablet ? 25 : 30)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          isMobile ? 16 : (isTablet ? 18 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: isMobile ? 15 : 20,
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
                fontSize: isMobile ? 24 : (isTablet ? 28 : 32),
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
              'Select your registration type to continue',
              style: TextStyle(
                fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCards() {
    return Column(
      children: [
        // Contractor Card
        ScaleTransition(
          scale: _contractorCardAnimation,
          child: _ModernRegistrationTypeCard(
            title: 'Contractor',
            subtitle: 'Maintenance Contractor',
            icon: Icons.business_rounded,
            primaryColor: Colors.blue,
            onTap: () {
              Navigator.pushNamed(context, '/contractor-registration');
            },
            isMobile: true,
          ),
        ),
        const SizedBox(height: 20),
        // Painter Card
        ScaleTransition(
          scale: _painterCardAnimation,
          child: _ModernRegistrationTypeCard(
            title: 'Painter',
            subtitle: 'Works under contractor',
            icon: Icons.format_paint_rounded,
            primaryColor: Colors.blue,
            onTap: () {
              Navigator.pushNamed(context, '/painter-registration');
            },
            isMobile: true,
          ),
        ),
        const SizedBox(height: 20),
        // OCR Card - New
        ScaleTransition(
          scale: _ocrCardAnimation,
          child: _ModernRegistrationTypeCard(
            title: 'OCR',
            subtitle: 'Read text from image',
            icon: Icons.document_scanner_rounded,
            primaryColor: Colors.green, // Different color for OCR card
            onTap: () {
              Navigator.pushNamed(context, '/ocr-screen');
            },
            isMobile: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopCards(bool isTablet, bool isDesktop) {
    // Use a Wrap so cards will wrap to the next line instead of overflowing
    // horizontally. This ensures the OCR card remains visible on narrower
    // desktop/tablet widths.
    final cardWidth = isTablet ? 240.0 : (isDesktop ? 280.0 : 300.0);
    final spacing = isTablet ? 20.0 : 32.0;

    return Center(
      child: Wrap(
        spacing: spacing,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [
          // Contractor Card
          ScaleTransition(
            scale: _contractorCardAnimation,
            child: _ModernRegistrationTypeCard(
              title: 'Contractor',
              subtitle: 'Maintenance Contractor',
              icon: Icons.business_rounded,
              primaryColor: Colors.blue,
              onTap: () {
                Navigator.pushNamed(context, '/contractor-registration');
              },
              isMobile: false,
              cardWidth: cardWidth,
            ),
          ),

          // Painter Card
          ScaleTransition(
            scale: _painterCardAnimation,
            child: _ModernRegistrationTypeCard(
              title: 'Painter',
              subtitle: 'Works under contractor',
              icon: Icons.format_paint_rounded,
              primaryColor: Colors.blue,
              onTap: () {
                Navigator.pushNamed(context, '/painter-registration');
              },
              isMobile: false,
              cardWidth: cardWidth,
            ),
          ),

          // OCR Card - New
          ScaleTransition(
            scale: _ocrCardAnimation,
            child: _ModernRegistrationTypeCard(
              title: 'OCR',
              subtitle: 'Read text from image',
              icon: Icons.document_scanner_rounded,
              primaryColor: Colors.green, // Different color for OCR card
              onTap: () {
                Navigator.pushNamed(context, '/ocr-screen');
              },
              isMobile: false,
              cardWidth: cardWidth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
          Text(
            'Which type should I choose?',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildInfoItem(
            icon: Icons.business_rounded,
            iconColor: Colors.blue,
            title: 'Contractor',
            description:
                'If you run a business that hires painters or provide painting services directly to clients.',
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildInfoItem(
            icon: Icons.format_paint_rounded,
            iconColor: Colors.blue,
            title: 'Painter',
            description:
                'If you work as a painter under a contractor or as an individual service provider.',
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          // Added OCR info item
          _buildInfoItem(
            icon: Icons.document_scanner_rounded,
            iconColor: Colors.green,
            title: 'OCR',
            description:
                'Use OCR to read text from images and convert it to editable text.',
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isMobile,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isMobile ? 36 : 40,
          height: isMobile ? 36 : 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: isMobile ? 18 : 20),
        ),
        SizedBox(width: isMobile ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: isMobile ? 3 : 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
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
                'Need Help?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'If you\'re unsure which registration type to select, '
                'please contact our support team for assistance.',
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
}

class _ModernRegistrationTypeCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final VoidCallback onTap;
  final bool isMobile;
  final double? cardWidth;

  const _ModernRegistrationTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.onTap,
    required this.isMobile,
    this.cardWidth,
  });

  @override
  State<_ModernRegistrationTypeCard> createState() =>
      _ModernRegistrationTypeCardState();
}

class _ModernRegistrationTypeCardState
    extends State<_ModernRegistrationTypeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth =
        widget.cardWidth ?? (widget.isMobile ? double.infinity : 280);
    final iconSize = widget.isMobile ? 60.0 : 80.0;
    final titleSize = widget.isMobile ? 18.0 : 22.0;
    final subtitleSize = widget.isMobile ? 13.0 : 14.0;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
          _animationController.forward();
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
          _animationController.reverse();
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnimation.value, child: child);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: cardWidth,
            constraints: BoxConstraints(
              minHeight: widget.isMobile ? 200 : 280,
              maxHeight: widget.isMobile ? 300 : 350,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(widget.isMobile ? 16 : 20),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withOpacity(
                    _isHovered ? 0.3 : 0.1,
                  ),
                  blurRadius: _isHovered ? 20 : 10,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: widget.primaryColor.withOpacity(_isHovered ? 0.5 : 0.1),
                width: _isHovered ? 2 : 1,
              ),
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: widget.isMobile ? 60 : 80,
                            height: widget.isMobile ? 60 : 80,
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withOpacity(
                                _isHovered ? 0.2 : 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.icon,
                              size: iconSize,
                              color: widget.primaryColor,
                            ),
                          ),
                          SizedBox(height: widget.isMobile ? 16 : 24),
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              color: widget.primaryColor,
                            ),
                          ),
                          SizedBox(height: widget.isMobile ? 8 : 12),
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: widget.isMobile ? 12 : 16,
                                ),
                                child: Text(
                                  widget.subtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: subtitleSize,
                                    color: Colors.grey.shade600,
                                    height: 1.4,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: widget.isMobile ? 16 : 24,
                      right: widget.isMobile ? 16 : 24,
                      bottom: widget.isMobile ? 16 : 24,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(
                          _isHovered ? 0.1 : 0.05,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: widget.isMobile ? 12 : 14,
                              fontWeight: FontWeight.bold,
                              color: widget.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: widget.isMobile ? 14 : 16,
                            color: widget.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
