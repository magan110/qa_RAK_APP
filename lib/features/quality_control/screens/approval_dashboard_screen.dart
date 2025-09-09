import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/modern_dropdown.dart';

class ApprovalDashboardScreen extends StatefulWidget {
  const ApprovalDashboardScreen({super.key});

  @override
  State<ApprovalDashboardScreen> createState() =>
      _ApprovalDashboardScreenState();
}

class _ApprovalDashboardScreenState extends State<ApprovalDashboardScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _pendingRegistrations = [
    {
      'id': 'REG001',
      'name': 'John Doe',
      'type': 'Contractor',
      'date': '2024-01-15',
      'status': 'Pending',
      'avatar': 'JD',
    },
    {
      'id': 'REG002',
      'name': 'Ahmed Ali',
      'type': 'Painter',
      'date': '2024-01-14',
      'status': 'Pending',
      'avatar': 'AA',
    },
    {
      'id': 'REG003',
      'name': 'Mohammed Khan',
      'type': 'Contractor',
      'date': '2024-01-13',
      'status': 'Pending',
      'avatar': 'MK',
    },
    {
      'id': 'REG004',
      'name': 'Sara Johnson',
      'type': 'Painter',
      'date': '2024-01-12',
      'status': 'Pending',
      'avatar': 'SJ',
    },
    {
      'id': 'REG005',
      'name': 'Ali Hassan',
      'type': 'Contractor',
      'date': '2024-01-11',
      'status': 'Pending',
      'avatar': 'AH',
    },
  ];

  late AnimationController _mainController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _cardAnimations = [];

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredRegistrations = [];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();

    _filteredRegistrations = List.from(_pendingRegistrations);

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
    for (int i = 0; i < 3; i++) {
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
    _searchController.dispose();
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      child: Scaffold(
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
                      constraints.maxWidth >= 600 &&
                      constraints.maxWidth < 1200;
                  final isDesktop = constraints.maxWidth >= 1200;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(
                      isMobile ? 16 : (isTablet ? 24 : 32),
                    ),
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with animation
                          _buildAnimatedHeader(isMobile, isTablet, isDesktop),

                          SizedBox(height: isMobile ? 24 : 32),

                          // Stats Cards
                          _buildStatsCards(isMobile, isTablet, isDesktop),

                          SizedBox(height: isMobile ? 24 : 32),

                          // Search and Filter
                          _buildSearchAndFilter(isMobile),

                          SizedBox(height: isMobile ? 24 : 32),

                          // Pending Registrations
                          _buildPendingRegistrations(isMobile),

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
      title: Text(
        'Approval Dashboard',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
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
                        'Approval Dashboard',
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
                    Icons.approval_rounded,
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

  Widget _buildStatsCards(bool isMobile, bool isTablet, bool isDesktop) {
    final totalPending = _pendingRegistrations.length;
    final contractorsCount = _pendingRegistrations
        .where((r) => r['type'] == 'Contractor')
        .length;
    final paintersCount = _pendingRegistrations
        .where((r) => r['type'] == 'Painter')
        .length;

    final stats = [
      {
        'title': 'Total Pending',
        'value': totalPending.toString(),
        'icon': Icons.hourglass_top_rounded,
        'color': Colors.blue,
        'change': '+5%',
        'isPositive': true,
      },
      {
        'title': 'Contractors',
        'value': contractorsCount.toString(),
        'icon': Icons.business_rounded,
        'color': Colors.blue,
        'change': '+3%',
        'isPositive': true,
      },
      {
        'title': 'Painters',
        'value': paintersCount.toString(),
        'icon': Icons.format_paint_rounded,
        'color': Colors.blue,
        'change': '+8%',
        'isPositive': true,
      },
    ];

    if (isMobile) {
      // Mobile layout - single column
      return Column(
        children: List.generate(stats.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildStatCard(
              stats[index]['title'] as String,
              stats[index]['value'] as String,
              stats[index]['icon'] as IconData,
              stats[index]['color'] as Color,
              stats[index]['change'] as String,
              stats[index]['isPositive'] as bool,
              _cardAnimations[index],
              isMobile: true,
            ),
          );
        }),
      );
    } else if (isTablet) {
      // Tablet layout - 2x2 grid
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          return _buildStatCard(
            stats[index]['title'] as String,
            stats[index]['value'] as String,
            stats[index]['icon'] as IconData,
            stats[index]['color'] as Color,
            stats[index]['change'] as String,
            stats[index]['isPositive'] as bool,
            _cardAnimations[index],
            isMobile: false,
          );
        },
      );
    } else {
      // Desktop layout - single row
      return Row(
        children: List.generate(stats.length, (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < stats.length - 1 ? 16 : 0,
              ),
              child: _buildStatCard(
                stats[index]['title'] as String,
                stats[index]['value'] as String,
                stats[index]['icon'] as IconData,
                stats[index]['color'] as Color,
                stats[index]['change'] as String,
                stats[index]['isPositive'] as bool,
                _cardAnimations[index],
                isMobile: false,
              ),
            ),
          );
        }),
      );
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
    bool isPositive,
    Animation<double> animation, {
    required bool isMobile,
  }) {
    return ScaleTransition(
      scale: animation,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: isMobile ? 40 : 48,
                  height: isMobile ? 40 : 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: isMobile ? 20 : 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        change,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isMobile) {
    return Container(
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
          Text(
            'Search & Filter',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (isMobile)
            Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search registrations',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: _filterRegistrations,
                ),
                const SizedBox(height: 16),
                ModernDropdown(
                  label: 'Filter by type',
                  icon: Icons.filter_list,
                  items: ['All', 'Contractor', 'Painter'],
                  value: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                      _filterRegistrations('');
                    });
                  },
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search registrations',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onChanged: _filterRegistrations,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ModernDropdown(
                    label: 'Filter by type',
                    icon: Icons.filter_list,
                    items: ['All', 'Contractor', 'Painter'],
                    value: _selectedFilter,
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                        _filterRegistrations('');
                      });
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPendingRegistrations(bool isMobile) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending Registrations',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${_filteredRegistrations.length} items',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_filteredRegistrations.isEmpty)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No registrations found',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredRegistrations.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final registration = _filteredRegistrations[index];
                return _buildRegistrationTile(registration, isMobile);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRegistrationTile(
    Map<String, dynamic> registration,
    bool isMobile,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Text(
          registration['avatar'] as String,
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        registration['name'] as String,
        style: TextStyle(
          fontSize: isMobile ? 14 : 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${registration['type']} • ${registration['date']}',
        style: TextStyle(
          fontSize: isMobile ? 12 : 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              registration['status'] as String,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/registration-details',
          arguments: registration,
        );
      },
    );
  }

  void _filterRegistrations(String query) {
    setState(() {
      _filteredRegistrations = _pendingRegistrations.where((registration) {
        final name = registration['name'].toString().toLowerCase();
        final id = registration['id'].toString().toLowerCase();
        final type = registration['type'].toString().toLowerCase();
        final searchLower = query.toLowerCase();

        final matchesSearch =
            name.contains(searchLower) ||
            id.contains(searchLower) ||
            type.contains(searchLower);

        final matchesFilter =
            _selectedFilter == 'All' || registration['type'] == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }
}
