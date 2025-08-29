import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rak_web/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  late AnimationController _mainController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  List<AnimationController> _cardControllers = [];
  List<Animation<double>> _cardAnimations = [];

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
      ),
    );

    // Initialize card animations
    for (int i = 0; i < 4; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      final animation = CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      );
      _cardControllers.add(controller);
      _cardAnimations.add(animation);

      // Stagger the card animations
      Future.delayed(Duration(milliseconds: 300 + (i * 150)), () {
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
      floatingActionButton: _buildFloatingActionButton(),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with animation
                        _buildAnimatedHeader(isMobile, isTablet, isDesktop),

                        SizedBox(height: isMobile ? 24 : 32),

                        // Stats Cards
                        _buildStatsCards(isMobile, isTablet, isDesktop),

                        SizedBox(height: isMobile ? 24 : 32),

                        // Registration Trends Chart
                        _buildRegistrationTrends(isMobile),

                        SizedBox(height: isMobile ? 24 : 32),

                        // Recent Registrations
                        _buildRecentRegistrations(isMobile),

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
      foregroundColor: Colors.blue.shade800,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      title: Text(
        'Dashboard',
        style: AppTheme.headline.copyWith(color: Colors.blue.shade800),
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/approval-dashboard'),
          icon: const Icon(Icons.approval_rounded),
          tooltip: 'Approvals',
        ),
        IconButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          ),
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Logout',
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
      child: FloatingActionButton.extended(
        onPressed: _exportReport,
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.download_rounded),
        label: Text(
          'Export',
          style: AppTheme.body.copyWith(color: Colors.white),
        ),
        elevation: 4,
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
                        'Dashboard',
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
                    Icons.dashboard_rounded,
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
    final stats = [
      {
        'title': 'Total Registrations',
        'value': '156',
        'icon': Icons.group_rounded,
        'color': Colors.blue,
        'change': '+12%',
        'isPositive': true,
      },
      {
        'title': 'Contractors',
        'value': '89',
        'icon': Icons.business_rounded,
        'color': Colors.blue,
        'change': '+8%',
        'isPositive': true,
      },
      {
        'title': 'Painters',
        'value': '67',
        'icon': Icons.format_paint_rounded,
        'color': Colors.blue,
        'change': '+15%',
        'isPositive': true,
      },
      {
        'title': 'Pending',
        'value': '12',
        'icon': Icons.pending_actions_rounded,
        'color': Colors.red,
        'change': '-3%',
        'isPositive': false,
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

  Widget _buildRegistrationTrends(bool isMobile) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registration Trends',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (!isMobile)
                ElevatedButton.icon(
                  onPressed: _exportReport,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range_rounded),
                  label: Text(
                    '${_startDate.toString().split(' ')[0]} - ${_endDate.toString().split(' ')[0]}',
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
              ),
              if (isMobile) const SizedBox(width: 16),
              if (isMobile)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportReport,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: isMobile ? 250 : 300,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Registration Chart',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Visual representation of registration trends',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRegistrations(bool isMobile) {
    final registrations = [
      {
        'name': 'John Doe',
        'type': 'Contractor',
        'status': 'Approved',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'avatar': 'JD',
      },
      {
        'name': 'Ahmed Ali',
        'type': 'Painter',
        'status': 'Pending',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'avatar': 'AA',
      },
      {
        'name': 'Mohammed Khan',
        'type': 'Contractor',
        'status': 'Approved',
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'avatar': 'MK',
      },
      {
        'name': 'Sara Johnson',
        'type': 'Painter',
        'status': 'Rejected',
        'date': DateTime.now().subtract(const Duration(days: 4)),
        'avatar': 'SJ',
      },
      {
        'name': 'Ali Hassan',
        'type': 'Contractor',
        'status': 'Approved',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'avatar': 'AH',
      },
    ];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Registrations',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/approval-dashboard'),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: registrations.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final registration = registrations[index];
              final statusColor = registration['status'] == 'Approved'
                  ? Colors.green
                  : registration['status'] == 'Pending'
                  ? Colors.orange
                  : Colors.red;

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
                  '${registration['type']} • ${registration['status']}',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        registration['status'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  // Navigate to registration details
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Report exported successfully',
          style: AppTheme.body.copyWith(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }
}
