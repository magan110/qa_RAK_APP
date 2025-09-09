import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rak_web/core/controllers/home_controller.dart';
import 'package:rak_web/core/di/service_locator.dart';
import 'package:rak_web/features/home/widgets/home_tab.dart';
import 'package:rak_web/core/utils/app_logger.dart';

/// Refactored HomeScreen with clean architecture
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late HomeController _controller;
  late AnimationController _mainController;
  late AnimationController _navController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _navScaleAnimation;

  final AppLogger _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    _controller = homeController;
    _controller.addListener(_onControllerChanged);

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _navController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    _navScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _navController, curve: Curves.elasticOut),
    );

    _mainController.forward();
    _navController.forward();

    _logger.info('HomeScreenRefactored initialized');
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _mainController.dispose();
    _navController.dispose();
    _logger.info('HomeScreenRefactored disposed');
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 800;
        final isTablet =
            constraints.maxWidth > 600 && constraints.maxWidth <= 800;
        final isMobile = constraints.maxWidth <= 600;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: _buildAppBar(),
          drawer: _buildDrawerMenu(),
          body: Stack(
            children: [
              _buildMainContent(
                isWeb: isWeb,
                isTablet: isTablet,
                isMobile: isMobile,
              ),
              _buildBottomNavigation(isWeb: isWeb, isTablet: isTablet),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF3F4F6),
      elevation: 0,
      toolbarHeight: 70,
      leading: Builder(
        builder: (context) => IconButton(
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          icon: const Icon(
            Icons.menu_rounded,
            color: Color(0xFF1E3A8A),
            size: 24,
          ),
        ),
      ),
      title: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(Icons.search_rounded, color: Colors.grey[600], size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
              ),
              child: IconButton(
                onPressed: () {},
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF1E3A8A),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_rounded,
                color: Color(0xFF1E3A8A),
                size: 24,
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildDrawerMenu() {
    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.75, // Ensure adequate width
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/rak_logo.jpg',
                height: 100,
                width: 100,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.business, color: Colors.grey, size: 100),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/dashboard');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.format_paint,
                  title: 'Painter Registration',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/painter-registration');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.construction,
                  title: 'Contractor Registration',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/contractor-registration');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.approval,
                  title: 'Approval Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/approval-dashboard');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.storefront,
                  title: 'Retailer Onboarding',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/retailer-onboarding');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person_add,
                  title: 'Retailer Registration',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/retailer-registration');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.store,
                  title: 'Retailer Entry',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/retail-entry');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.add_box,
                  title: 'New Product Entry',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/new-product-entry');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.inventory,
                  title: 'Material Distribution',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/sample-distribution');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.science,
                  title: 'Sampling Drive Form',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/sampling-drive-form');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.science,
                  title: 'Incentive Scheme Form',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/incentive-scheme-form');
                  },
                ),
                const Divider(height: 32),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to settings screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings - Coming Soon!')),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to help screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Help & Support - Coming Soon!'),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login-password',
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF1E3A8A).withOpacity(0.1),
        ),
        child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildMainContent({
    required bool isWeb,
    required bool isTablet,
    required bool isMobile,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            ),
          ),
          child: IndexedStack(
            index: _controller.currentIndex,
            children: [
              HomeTab(
                controller: _controller,
                isWeb: isWeb,
                isTablet: isTablet,
                isMobile: isMobile,
              ),
              _buildQRScannerTab(isWeb: isWeb, isTablet: isTablet),
              _buildProfileTab(isWeb: isWeb, isTablet: isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRScannerTab({bool isWeb = false, bool isTablet = false}) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildScannerHeader(),
              const SizedBox(height: 30),
              Expanded(child: _buildScannerOptions()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331E3A8A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'QR Scanner',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Scan or enter QR codes for quick processing',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOptions() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.1,
      children: [
        _buildScannerCard(
          'Camera Scan',
          Icons.camera_alt,
          const Color(0xFF10B981),
          () => Navigator.pushNamed(context, '/camera-scanner'),
        ),
        _buildScannerCard(
          'Manual Entry',
          Icons.keyboard,
          const Color(0xFF3B82F6),
          () => Navigator.pushNamed(context, '/qr-input'),
        ),
      ],
    );
  }

  Widget _buildScannerCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab({bool isWeb = false, bool isTablet = false}) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: isWeb ? 20 : 120,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x331E3A8A),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 60, color: Color(0xFF1E3A8A)),
                ),
                SizedBox(height: 24),
                Text(
                  'Magan',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Gold Member • Partner ID: RAK2024',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                SizedBox(height: 8),
                Text(
                  'magan@rakwhitecement.ae',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildProfileSection('Account Settings', [
            _buildProfileOption(
              'Personal Information',
              Icons.person,
              const Color(0xFF3B82F6),
              () {},
            ),
            const SizedBox(height: 16),
            _buildProfileOption(
              'Security',
              Icons.security,
              const Color(0xFF10B981),
              () {},
            ),
            const SizedBox(height: 16),
            _buildProfileOption(
              'Notifications',
              Icons.notifications,
              const Color(0xFFF59E0B),
              () {},
            ),
          ]),
          const SizedBox(height: 32),
          _buildProfileSection('Support', [
            _buildProfileOption(
              'Help Center',
              Icons.help,
              const Color(0xFF60A5FA),
              () {},
            ),
            const SizedBox(height: 16),
            _buildProfileOption(
              'Contact Us',
              Icons.contact_support,
              const Color(0xFF1E3A8A),
              () {},
            ),
            const SizedBox(height: 16),
            _buildProfileOption(
              'About',
              Icons.info,
              const Color(0xFF6B7280),
              () {},
            ),
          ]),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/login-password',
                (route) => false,
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildProfileOption(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation({bool isWeb = false, bool isTablet = false}) {
    if (isWeb) {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x191E3A8A),
                blurRadius: 30,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1E3A8A).withOpacity(0.2),
                                const Color(0xFF1E3A8A).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.business,
                            color: Color(0xFF1E3A8A),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'RAK White Cement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildWebNavItem(
                          0,
                          Icons.home_rounded,
                          'Home',
                          const Color(0xFF1E3A8A),
                        ),
                        const SizedBox(width: 8),
                        _buildWebNavItem(
                          1,
                          Icons.qr_code_scanner_rounded,
                          'Scan',
                          const Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 8),
                        _buildWebNavItem(
                          2,
                          Icons.person_rounded,
                          'Profile',
                          const Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Positioned(
      bottom: 4,
      left: 20,
      right: 20,
      child: Container(
        height: 75,
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.85),
              Colors.white.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x331E3A8A),
              blurRadius: 25,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24.0 : 16.0,
              vertical: isTablet ? 12.0 : 10.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  0,
                  Icons.home_rounded,
                  'Home',
                  const Color(0xFF1E3A8A),
                  isTablet: isTablet,
                ),
                _buildNavItem(
                  1,
                  Icons.qr_code_scanner_rounded,
                  'Scan',
                  const Color(0xFF3B82F6),
                  isTablet: isTablet,
                ),
                _buildNavItem(
                  2,
                  Icons.person_rounded,
                  'Profile',
                  const Color(0xFF6B7280),
                  isTablet: isTablet,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebNavItem(int index, IconData icon, String label, Color color) {
    final isSelected = _controller.currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _controller.setCurrentIndex(index);
        _navController.reset();
        _navController.forward();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: EdgeInsets.symmetric(
          horizontal: 16 + (4 * (isSelected ? 1 : 0)),
          vertical: 8 + (2 * (isSelected ? 1 : 0)),
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                )
              : null,
          borderRadius: BorderRadius.circular(12 + (4 * (isSelected ? 1 : 0))),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.4) : Colors.transparent,
            width: 1 + (isSelected ? 1 : 0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20 + (2 * (isSelected ? 1 : 0)),
              color: Color.lerp(
                const Color(0xFF6B7280),
                color,
                isSelected ? 1 : 0,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16 + (isSelected ? 1 : 0),
                fontWeight: FontWeight.lerp(
                  FontWeight.w500,
                  FontWeight.w600,
                  isSelected ? 1 : 0,
                ),
                color: Color.lerp(
                  const Color(0xFF6B7280),
                  color,
                  isSelected ? 1 : 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    Color color, {
    bool isTablet = false,
  }) {
    final isSelected = _controller.currentIndex == index;
    final iconSize = isTablet
        ? (44.0 + (16.0 * (isSelected ? 1 : 0)))
        : (40.0 + (16.0 * (isSelected ? 1 : 0)));
    final iconInnerSize = isTablet
        ? (26.0 + (4.0 * (isSelected ? 1 : 0)))
        : (24.0 + (4.0 * (isSelected ? 1 : 0)));
    final fontSize = isTablet
        ? (12.0 + (2.0 * (isSelected ? 1 : 0)))
        : (10.0 + (2.0 * (isSelected ? 1 : 0)));

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => HapticFeedback.lightImpact(),
        onTap: () {
          HapticFeedback.heavyImpact();
          _controller.setCurrentIndex(index);
          _navController.reset();
          _navController.forward();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.9),
                          color.withOpacity(0.7),
                          color.withOpacity(0.9),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                borderRadius: BorderRadius.circular(iconSize / 2),
                border: Border.all(
                  color: isSelected
                      ? color.withOpacity(0.3)
                      : Colors.white.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        const BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(
                icon,
                size: iconInnerSize,
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF6B7280).withOpacity(0.7),
              ),
            ),
            SizedBox(height: isTablet ? 8 : 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 400),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.lerp(
                  FontWeight.w400,
                  FontWeight.w700,
                  isSelected ? 1 : 0,
                ),
                color: Color.lerp(
                  const Color(0xFF6B7280).withOpacity(0.6),
                  color,
                  isSelected ? 1 : 0,
                ),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
